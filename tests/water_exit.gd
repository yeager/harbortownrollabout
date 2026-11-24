extends SceneTree
## Run from the imported project with godot --headless --script res://tests/water_exit.gd

func _initialize() -> void:
	call_deferred("check_exits")

func check_exits() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.traffic_data.clear()
	for center_z in [0.0, -48.0]:
		for side in [-1.0, 1.0]:
			var z: float = center_z + side * 4.1
			game.ambulance.position = Vector3(71, game._surface_height(71, z), z)
			game.ambulance.rotation.y = -side * PI / 2
			game._change_seat()
			if not game.walker.visible or absf(game.walker.position.z - center_z) > 4.9:
				printerr("Expected player on bridge after leaving car at ", game.ambulance.position)
				quit(1)
				return
			game._change_seat()
			if game.walker.visible:
				printerr("Could not return to the car from the bridge")
				quit(1)
				return
	game._select_gallery_activity(4)
	game.launch.position = Vector3(71, 0, 25)
	game._change_seat()
	if game.walker.visible or not game.boating or game.listener.get_parent() != game.launch:
		printerr("Player left the motorboat over open water")
		quit(1)
		return
	game.launch.rotation.y = .7
	var saved_pose: Transform3D = game.launch.transform
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if not game.boating or game.listener.get_parent() != game.launch or not game.launch.transform.is_equal_approx(saved_pose):
		printerr("Boat position, heading or controls lost after reopening")
		quit(1)
		return
	game.mouse_gas = true
	for frame in 60:
		game._process(1.0 / 60)
	if game.launch.position.distance_to(saved_pose.origin) < .3:
		printerr("Boat did not move after reopening")
		quit(1)
		return
	game._recover_position()
	game._change_seat()
	if game.boating or not game.walker.visible or not game._feet_supported(game.walker.position):
		printerr("Could not step onto the motorboat landing")
		quit(1)
		return
	game._change_seat()
	if not game.boating or game.walker.visible or game.listener.get_parent() != game.launch:
		printerr("Could not reboard the motorboat from the landing")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await process_frame
	print("Both edges of both bridges and the offshore motorboat exit passed.")
	quit()
