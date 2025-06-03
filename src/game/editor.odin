package game

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

editor_x :: 500
editor_height :: 500
editor_width :: 300

render_editor :: proc(game: ^Game) {

	panel_rect := rl.Rectangle {
		x      = editor_x,
		y      = 0,
		width  = editor_width,
		height = editor_height,
	}
	rl.GuiPanel(panel_rect, "Editor Controls")

	y_pos := i32(30)

	rl.DrawText(
		rl.TextFormat("Material: %s", material_properties[int(game.current_material)].name),
		editor_x + 10,
		y_pos,
		20,
		rl.BLACK,
	)

	y_pos += 20
	rl.DrawText(
		rl.TextFormat("Brush Size: %d", game.brush_size),
		editor_x + 10,
		y_pos,
		20,
		rl.BLACK,
	)

	y_pos += 20

	// Create layer buttons in a row
	button_width := f32(35)
	button_height := f32(35)

	for i in 0 ..< len(material_properties) {
		layer_btn_rect := rl.Rectangle {
			x      = editor_x + 10 + f32(i) * (button_width + 2),
			y      = f32(y_pos),
			width  = button_width,
			height = button_height,
		}
		props := material_properties[i]

		rl.DrawRectangleRec(layer_btn_rect, props.color)

		// Highlight selected layer
		if props.type == game.current_material {
			rl.DrawRectangleLinesEx(layer_btn_rect, 2, rl.BLACK)
		}
	}
}
