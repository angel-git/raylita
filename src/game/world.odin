package game

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"


MaterialType :: enum u8 {
	Empty,
	Sand,
	Water,
	Stone,
}

MaterialProperties :: struct {
	name:      string,
	color:     rl.Color,
	density:   f32,
	is_liquid: bool,
	is_static: bool,
}
World :: struct {
	width:     int, // 100
	height:    int, // 100
	cell_size: f32, // Size of each cell when rendering
	grid:      [100][100]MaterialType, // Material type at each position
	updated:   [100][100]bool, // Tracks which cells were updated this frame
}


// Material properties lookup
material_properties := []MaterialProperties {
	{name = "Empty", color = rl.BLACK, density = 0.0, is_liquid = false, is_static = true},
	{name = "Sand", color = rl.GOLD, density = 2.0, is_liquid = false, is_static = false},
	{name = "Water", color = rl.BLUE, density = 1.0, is_liquid = true, is_static = false},
	{name = "Stone", color = rl.GRAY, density = 3.0, is_liquid = false, is_static = true},
}

// Initialize a new world
new_world :: proc() -> World {
	world := World {
		width     = 100,
		height    = 100,
		cell_size = 5.0, // Renders each cell as 5x5 pixels
		grid      = {}, // Initialize with zeros (Empty)
		updated   = {}, // Initialize with zeros (false)
	}
	return world
}


screen_to_grid :: proc(world: ^World, screen_x, screen_y, offset_x, offset_y: int) -> (int, int) {
	grid_x := int(f32(screen_x - offset_x) / world.cell_size)
	grid_y := int(f32(screen_y - offset_y) / world.cell_size)

	return grid_x, grid_y
}

clear_world :: proc(world: ^World) {
	for y := 0; y < world.height; y += 1 {
		for x := 0; x < world.width; x += 1 {
			world.grid[y][x] = .Empty
		}
	}
}

update_world :: proc(world: ^World) {
	// Reset the updated flag for this frame
	for y := 0; y < world.height; y += 1 {
		for x := 0; x < world.width; x += 1 {
			world.updated[y][x] = false
		}
	}

	// Update cells from bottom to top, so things fall correctly
	for y := world.height - 1; y >= 0; y -= 1 {
		for x := 0; x < world.width; x += 1 {
			update_cell(world, x, y)
		}
	}
}

render_world :: proc(world: ^World, pos_x, pos_y: int) {
	for y := 0; y < world.height; y += 1 {
		for x := 0; x < world.width; x += 1 {
			material := world.grid[y][x]
			if material != .Empty {
				props := material_properties[int(material)]

				screen_x := pos_x + int(f32(x) * world.cell_size)
				screen_y := pos_y + int(f32(y) * world.cell_size)
				cell_size := int(world.cell_size)

				rl.DrawRectangle(
					i32(screen_x),
					i32(screen_y),
					i32(cell_size),
					i32(cell_size),
					props.color,
				)
			}
		}
	}
}

add_material_with_brush :: proc(
	world: ^World,
	x, y: int,
	material: MaterialType,
	brush_size: int,
) {
	for by := -brush_size; by <= brush_size; by += 1 {
		for bx := -brush_size; bx <= brush_size; bx += 1 {
			// Skip if outside brush radius
			if bx * bx + by * by > brush_size * brush_size {
				continue
			}

			target_x := x + bx
			target_y := y + by

			// Skip if outside world bounds
			if target_x < 0 ||
			   target_x >= world.width ||
			   target_y < 0 ||
			   target_y >= world.height {
				continue
			}

			// Set material at this position
			world.grid[target_y][target_x] = material
		}
	}
}


@(private = "file")
can_move_into :: proc(world: ^World, x, y: int, material: MaterialType) -> bool {
	if x < 0 || x >= world.width || y < 0 || y >= world.height {
		return false
	}

	target_material := world.grid[y][x]
	if target_material == .Empty {
		return true
	}

	// Can move if the current material is denser than the target
	material_props := material_properties[int(material)]
	target_props := material_properties[int(target_material)]

	return material_props.density > target_props.density && !target_props.is_static
}


@(private = "file")
update_cell :: proc(world: ^World, x, y: int) {
	if x < 0 || x >= world.width || y < 0 || y >= world.height {
		return
	}

	// Skip if cell was already updated this frame
	if world.updated[y][x] {
		return
	}

	material := world.grid[y][x]
	if material == .Empty {
		return
	}

	props := material_properties[int(material)]
	if props.is_static {
		return
	}

	// Mark this cell as updated
	world.updated[y][x] = true

	// Try to move down
	if can_move_into(world, x, y + 1, material) {
		world.grid[y][x] = world.grid[y + 1][x]
		world.grid[y + 1][x] = material
		world.updated[y + 1][x] = true
		return
	}

	// For liquids and falling particles, try to move diagonally
	if !props.is_static {
		// Choose randomly between left and right diagonal first
		dx := rand.int31_max(2) * 2 - 1 // -1 or 1

		// Try diagonal down
		if can_move_into(world, x + int(dx), y + 1, material) {
			world.grid[y][x] = world.grid[y + 1][x + int(dx)]
			world.grid[y + 1][x + int(dx)] = material
			world.updated[y + 1][x + int(dx)] = true
			return
		}

		// Try opposite diagonal
		if can_move_into(world, x - int(dx), y + 1, material) {
			world.grid[y][x] = world.grid[y + 1][x - int(dx)]
			world.grid[y + 1][x - int(dx)] = material
			world.updated[y + 1][x - int(dx)] = true
			return
		}
	}

	// For liquids, try moving sideways
	if props.is_liquid {
		// Choose randomly between left and right
		dx := rand.int31_max(2) * 2 - 1 // -1 or 1

		if can_move_into(world, x + int(dx), y, material) {
			world.grid[y][x] = world.grid[y][x + int(dx)]
			world.grid[y][x + int(dx)] = material
			world.updated[y][x + int(dx)] = true
			return
		}

		// Try opposite side
		if can_move_into(world, x - int(dx), y, material) {
			world.grid[y][x] = world.grid[y][x - int(dx)]
			world.grid[y][x - int(dx)] = material
			world.updated[y][x - int(dx)] = true
			return
		}
	}
}
