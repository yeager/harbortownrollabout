extends SceneTree
## Run from the imported project with godot --headless --script res://tests/ferry_passenger.gd

func _initialize() -> void:
	call_deferred("check_crossings")

func check_crossings() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.play_as_alma = true
	game._apply_player_appearance()
	game._start_game()
	game._change_seat()
	var original_scale: Vector3 = game.walker.scale
	for departure in game.FERRY_LANDINGS.size():
		var quay_z: float = game.FERRY_LANDINGS[departure]
		game.walker.position = Vector3(64.9, game._foot_height(64.9, quay_z), quay_z)
		game.wave_time = departure * 29.0 + 1.0
		game._update_moorings(0.0)
		game._change_seat()
		game._update_moorings(10.0)
		game._change_seat()
		if not game.ferry_passenger:
			printerr("Passenger stepped off over open water from landing ", departure)
			quit(1)
			return
		game._update_moorings(19.0)
		if game.ferry_passenger or game._near_ferry_landing() != 1 - departure:
			printerr("Requested exit did not reach the opposite pier")
			quit(1)
			return
		if not game._feet_supported(game.walker.position) or not game.walker.scale.is_equal_approx(original_scale):
			printerr("Disembarkation changed Alma's scale or left her without footing")
			quit(1)
			return
	print("Both Lotten crossings preserved passenger scale and pier footing.")
	quit()
