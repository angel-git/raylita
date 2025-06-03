package game

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Game :: struct {
	is_running:       bool,
	is_paused:        bool,
	world:            World,
	current_material: MaterialType,
	brush_size:       int,
}

game: Game

start :: proc() {
	rand.reset(1)
	game = Game {
		is_running       = true,
		world            = new_world(),
		current_material = .Sand,
		brush_size       = 3,
	}
}

loop :: proc() {
	rl.DrawFPS(10, 10)
	handle_events()

	if !game.is_paused {
		update_world(&game.world)
	}

	render()
}

is_game_running :: proc() -> bool {
	return game.is_running
}
shutdown :: proc() {
	// TODO clean
}

@(private = "file")
handle_events :: proc() {
	if rl.WindowShouldClose() {
		game.is_running = false
	}

	if rl.IsKeyPressed(.SPACE) {
		game.is_paused = !game.is_paused
	}

	if rl.IsKeyPressed(.C) {
		clear_world(&game.world)
	}

	if rl.IsKeyPressed(.ZERO) {
		game.current_material = .Empty
	} else if rl.IsKeyPressed(.ONE) {
		game.current_material = .Sand
	} else if rl.IsKeyPressed(.TWO) {
		game.current_material = .Water
	} else if rl.IsKeyPressed(.THREE) {
		game.current_material = .Stone
	} else if rl.IsKeyPressed(.FOUR) {
		game.current_material = .Fire
	} else if rl.IsKeyPressed(.FIVE) {
		game.current_material = .Smoke
	} else if rl.IsKeyPressed(.SIX) {
		game.current_material = .Oil
	}

	if rl.IsKeyPressed(.LEFT_BRACKET) && game.brush_size > 1 {
		game.brush_size -= 1
	} else if rl.IsKeyPressed(.RIGHT_BRACKET) && game.brush_size < 10 {
		game.brush_size += 1
	}

	if rl.IsMouseButtonDown(.LEFT) {
		mouse_x := rl.GetMouseX()
		mouse_y := rl.GetMouseY()

		// Add material at the mouse position
		add_material_with_brush(
			&game.world,
			int(mouse_x),
			int(mouse_y),
			game.current_material,
			game.brush_size,
		)
	}
}

@(private = "file")
render :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	render_world(&game.world)

	mouse_x := rl.GetMouseX()
	mouse_y := rl.GetMouseY()

	render_brush(&game.world, int(mouse_x), int(mouse_y), game.current_material, game.brush_size)

	render_editor(&game)

	if game.is_paused {
		rl.DrawText("PAUSED", 10, 70, 20, rl.YELLOW)
	}
	rl.EndDrawing()
}
