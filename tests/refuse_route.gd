extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.vehicle_selector.get_child(game.REFUSE).pressed.emit()
	game.start_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	game._update_route_arrows()
	if not game.navigator.cached_wide_turns:
		printerr("Refuse collection requires the long-vehicle route")
		quit(1)
		return
	if not check_tram_junctions(game.navigator):
		quit(1)
		return
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
			var loading_pose: Transform3D = game.ambulance.transform
			game.mouse_gas = true
			game._drive(1.0 / 60.0)
			game.mouse_gas = false
			game.mouse_brake = true
			game._drive(1.0 / 60.0)
			game.mouse_brake = false
			if game.speed != 0 or not game.ambulance.transform.is_equal_approx(loading_pose):
				printerr("Truck moved during bin lift")
				quit(1)
				return
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

func check_tram_junctions(navigator) -> bool:
	for heading: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var junction := Vector2(-330, -48) if heading.y == 0 else Vector2(-420, 0)
		var lane_offset := Vector2(-heading.y, heading.x) * 6.0
		var pickup := junction - heading * 22 - lane_offset
		for distance: float in [-2.0, -1.5, -1.0, 0.0, 1.0]:
			var start := junction + heading * distance + lane_offset
			var route: PackedVector2Array = navigator.path(start, pickup, heading, true)
			if route.size() < 2 or not route[-1].is_equal_approx(pickup) or route[0].direction_to(route[1]).dot(heading) < .99:
				printerr("Incorrect route to pickup behind truck at ", start, " facing ", heading)
				return false
	return true
