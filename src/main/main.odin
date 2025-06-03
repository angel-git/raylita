package main

import game "../game"
import w "../window"
import "core:fmt"
import "core:mem"

main :: proc() {

	/////// Tracking allocator
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		for _, entry in track.allocation_map {
			fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
		}
		for entry in track.bad_free_array {
			fmt.eprintf("%v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track)
	}
	/////////////////////////////
	w.init_window()

	game.start()
	for game.is_game_running() {
		game.loop()
		free_all(context.temp_allocator)
	}
	game.shutdown()

	w.close_window()
	free_all(context.temp_allocator)

}

