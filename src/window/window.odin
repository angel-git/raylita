package window

import rl "vendor:raylib"

init_window :: proc() {

	// rl.SetConfigFlags(rl.ConfigFlags{.VSYNC_HINT})
	rl.InitWindow(800, 500, "NOITA CLONE")
	rl.InitAudioDevice()
	// icon := load_image(.ProgramIcon)
	// rl.SetWindowIcon(icon)
	// rl.UnloadImage(icon)
	rl.SetTargetFPS(144)
}

close_window :: proc() {
	rl.CloseAudioDevice()
	rl.CloseWindow()
}
