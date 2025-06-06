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
	Fire,
	Smoke,
	Oil,
}

MaterialProperties :: struct {
	type:              MaterialType,
	name:              string,
	color:             rl.Color,
	alternative_color: rl.Color,
	density:           f32,
	is_liquid:         bool,
	is_static:         bool,
	rises:             bool,
	lifetime:          int, // -1 always 0-100%
	flammable:         bool,
	transformations:   []MaterialTransformation,
}

MaterialTransformation :: struct {
	trigger_material: MaterialType, // Material that causes the transformation
	result_material:  MaterialType, // Material that results from the transformation
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
	{
		type = .Empty,
		name = "Empty",
		color = {0, 0, 0, 0},
		alternative_color = rl.BLACK,
		density = 0.0,
		is_liquid = false,
		is_static = true,
		lifetime = -1,
		rises = false,
	},
	{
		type = .Sand,
		name = "Sand",
		color = rl.GOLD,
		alternative_color = rl.GOLD,
		density = 2.0,
		is_liquid = false,
		is_static = false,
		lifetime = -1,
		rises = false,
	},
	{
		type = .Water,
		name = "Water",
		color = rl.BLUE,
		alternative_color = rl.DARKBLUE,
		density = 1.0,
		is_liquid = true,
		is_static = false,
		lifetime = -1,
		rises = false,
		transformations = {{trigger_material = .Fire, result_material = .Smoke}},
	},
	{
		type = .Stone,
		name = "Stone",
		color = rl.GRAY,
		alternative_color = rl.GRAY,
		density = 3.0,
		is_liquid = false,
		is_static = true,
		lifetime = -1,
		rises = false,
	},
	{
		type = .Fire,
		name = "Fire",
		color = rl.RED,
		alternative_color = rl.ORANGE,
		density = 1.0,
		is_liquid = true,
		is_static = false,
		lifetime = 1,
		rises = false,
		transformations = {{trigger_material = .Water, result_material = .Smoke}},
	},
	{
		type = .Smoke,
		name = "Smoke",
		color = rl.DARKGRAY,
		alternative_color = rl.GRAY,
		density = 1.0,
		is_liquid = false,
		is_static = false,
		lifetime = 2,
		rises = true,
	},
	{
		type = .Oil,
		name = "Oil",
		color = rl.DARKBROWN,
		alternative_color = rl.DARKBROWN,
		density = 2.0,
		is_liquid = true,
		is_static = false,
		lifetime = -1,
		rises = false,
		flammable = true,
		transformations = {{trigger_material = .Fire, result_material = .Smoke}},
	},
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

render_world :: proc(world: ^World) {
	for y := 0; y < world.height; y += 1 {
		for x := 0; x < world.width; x += 1 {
			material := world.grid[y][x]
			if material != .Empty {
				props := material_properties[int(material)]

				screen_x := int(f32(x) * world.cell_size)
				screen_y := int(f32(y) * world.cell_size)
				cell_size := int(world.cell_size)

				// random color
				color := props.color
				dx := rand.int31_max(2) * 2 - 1 // -1 or 1
				if (dx < 0) {
					color = props.alternative_color
				}

				rl.DrawRectangle(
					i32(screen_x),
					i32(screen_y),
					i32(cell_size),
					i32(cell_size),
					color,
				)
			}
		}
	}
}

add_material_with_brush :: proc(
	world: ^World,
	screen_x, screen_y: int,
	material: MaterialType,
	brush_size: int,
) {
	grid_x, grid_y := screen_to_grid(world, screen_x, screen_y)

	for by := -brush_size; by <= brush_size; by += 1 {
		for bx := -brush_size; bx <= brush_size; bx += 1 {
			// Skip if outside brush radius
			if bx * bx + by * by > brush_size * brush_size {
				continue
			}

			target_x := grid_x + bx
			target_y := grid_y + by

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

render_brush :: proc(
	world: ^World,
	screen_x, screen_y: int,
	material: MaterialType,
	brush_size: int,
) {
	grid_x, grid_y := screen_to_grid(world, screen_x, screen_y)

	props := material_properties[int(material)]

	center_x := int(f32(grid_x) * world.cell_size + world.cell_size / 2)
	center_y := int(f32(grid_y) * world.cell_size + world.cell_size / 2)
	radius := int(f32(brush_size) * world.cell_size)
	rl.DrawCircle(i32(center_x), i32(center_y), f32(radius), rl.ColorAlpha(props.color, 0.5))
}


@(private = "file")
screen_to_grid :: proc(world: ^World, screen_x, screen_y: int) -> (int, int) {
	grid_x := int(f32(screen_x) / world.cell_size)
	grid_y := int(f32(screen_y) / world.cell_size)

	return grid_x, grid_y
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

	if props.lifetime > 0 {
		if rand.int31_max(100) < i32(props.lifetime) {
			world.grid[y][x] = .Empty
			return
		}
	}

	check_and_transform_material(world, x, y)


	if props.rises {
		// Try to move up (for rising materials like smoke)
		if y > 0 && can_move_into(world, x, y - 1, material) {
			world.grid[y][x] = world.grid[y - 1][x]
			world.grid[y - 1][x] = material
			world.updated[y - 1][x] = true
			return
		}

		// Choose randomly between left and right diagonal first
		dx := rand.int31_max(2) * 2 - 1 // -1 or 1

		// Try diagonal up
		if y > 0 && can_move_into(world, x + int(dx), y - 1, material) {
			world.grid[y][x] = world.grid[y - 1][x + int(dx)]
			world.grid[y - 1][x + int(dx)] = material
			world.updated[y - 1][x + int(dx)] = true
			return
		}

		// Try opposite diagonal up
		if y > 0 && can_move_into(world, x - int(dx), y - 1, material) {
			world.grid[y][x] = world.grid[y - 1][x - int(dx)]
			world.grid[y - 1][x - int(dx)] = material
			world.updated[y - 1][x - int(dx)] = true
			return
		}
	} else {
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
}

@(private = "file")
check_and_transform_material :: proc(world: ^World, x, y: int) {
	current_material := world.grid[y][x]
	if current_material == .Empty {
		return
	}

	props := material_properties[int(current_material)]

	// Check all neighboring cells for potential transformations
	for dy := -1; dy <= 1; dy += 1 {
		for dx := -1; dx <= 1; dx += 1 {
			// Skip the current cell
			if dx == 0 && dy == 0 {
				continue
			}

			nx, ny := x + dx, y + dy

			// Skip if outside world bounds
			if nx < 0 || nx >= world.width || ny < 0 || ny >= world.height {
				continue
			}

			neighbor_material := world.grid[ny][nx]
			if neighbor_material == .Empty {
				continue
			}

			// Check for transformations
			for transformation in props.transformations {
				if neighbor_material == transformation.trigger_material {
					// Transform the current material
					world.grid[y][x] = transformation.result_material
					// Flag this cell as updated to prevent processing it again this frame
					world.updated[y][x] = true
					return
				}
			}

			if props.flammable && neighbor_material == .Fire {
				world.grid[y][x] = .Fire
				world.updated[y][x] = true
				return
			}

		}
	}
}
