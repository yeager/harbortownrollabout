extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.vehicle_selector.get_child(game.REFUSE).pressed.emit()
	game.start_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var initial_points: int = game.delivery_points
	var initial_wallet: int = game.wallet
	var launch_speeds: Array[float] = []
	for stop in 3:
		game.ambulance.position = game._mission_destination()
		if game._vehicle_payload() != stop * 400 or (stop < 2 and not game.refuse_bins[stop].visible):
			printerr("Unexpected bin or payload at stop ", stop)
			quit(1)
			return
		game.mouse_gas = true
		game._drive(1.0 / 60.0)
		launch_speeds.append(game.speed)
		game.mouse_gas = false
		game.speed = 0.0
		var curb: Vector3 = game.refuse_bins[stop].global_position if stop < 2 else Vector3.ZERO
		game._help_at_target()
		if stop < 2:
			await create_timer(1.25).timeout
			var bin: Node3D = game.refuse_bins[stop]
			if bin.global_position.y <= curb.y + .8:
				printerr("Bin did not lift above the loading edge")
				quit(1)
				return
			await create_timer(1.45).timeout
			if not bin.visible or bin.global_position.distance_to(curb) > .01 or absf(bin.rotation.x) > .01:
				printerr("Bin did not return upright to the curb")
				quit(1)
				return
		if game.mission_index != stop + 1:
			printerr("Refuse truck stop failed: ", stop)
			quit(1)
			return
	if not (launch_speeds[0] > launch_speeds[1] and launch_speeds[1] > launch_speeds[2] and launch_speeds[2] > 0):
		printerr("Payload did not affect acceleration: ", launch_speeds)
		quit(1)
		return
	if game.mode != "complete" or game._vehicle_payload() != 0 or game.delivery_points != initial_points + 30 or game.wallet != initial_wallet + 30:
		printerr("Unloading or payment failed")
		quit(1)
		return
	print("Refuse collection, unloading and payment passed.")
	game._finish_quit()
