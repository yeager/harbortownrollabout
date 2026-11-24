extends SceneTree
## Run from the imported project with godot --headless --script res://tests/water_exit.gd

func _initialize() -> void:
	call_deferred("check_exits")

func check_exits() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.traffic_data.clear()
	if not check_land_vehicles(game):
		return
	game.mode = "menu"
	game._on_vehicle_selected(0)
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
	game.free_drive = true
	game.map_goal = game.LAUNCH_MAP_STOP
	game.ambulance.position = game.LAUNCH_ROAD_STOP
	game.ambulance.rotation.y = 0
	game._update_route_arrows()
	if game.map_goal != game.LAUNCH_MAP_STOP or game.route_arrows[0].visible:
		printerr("Arriving at the parking bay did not preserve the motorboat as a walking destination")
		quit(1)
		return
	game._change_seat()
	game._update_route_arrows()
	if not game.walker.visible or not game.route_arrows[0].visible:
		printerr("Walking guidance did not start at the motorboat parking bay")
		quit(1)
		return
	game._select_gallery_activity(4)
	game.walker.hide()
	game.launch.position = Vector3(71, 0, 25)
	game._process(0)
	if game.seat_button.visible:
		printerr("The disembark button was visible offshore")
		quit(1)
		return
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
	game.launch.position = Vector3(76, -.94, game.LAUNCH_LANDING.y)
	game.launch.rotation.y = -PI * .5
	game.launch_speed = 4.0
	for frame in 60:
		game._drive_launch(1.0 / 60.0)
	if game.launch.position.x > game.LAUNCH_PIER.position.x - 2.69 or not is_zero_approx(game.launch_speed):
		printerr("The motorboat bow passed through the pier")
		quit(1)
		return
	var stopped_x: float = game.launch.position.x
	game.mouse_gas = false
	game.mouse_brake = true
	for frame in 60:
		game._drive_launch(1.0 / 60.0)
	game.mouse_brake = false
	if game.launch.position.x >= stopped_x - .5 or game.launch_speed >= 0.0:
		printerr("The motorboat could not reverse away from the pier")
		quit(1)
		return
	game._recover_position()
	if not game.seat_button.visible or game.seat_button.disabled:
		printerr("The disembark button was unavailable at the berth")
		quit(1)
		return
	game.free_drive = true
	game.map_goal = game.TARGETS[0]
	game._change_seat()
	if game.boating or not game.walker.visible or not game._feet_supported(game.walker.position):
		printerr("Could not step onto the motorboat landing")
		quit(1)
		return
	if not game.route_arrows[0].visible or game.route_arrows[0].position.x <= game.walker.position.x or not game.LAUNCH_PIER.has_point(Vector2(game.route_arrows[0].position.x, game.route_arrows[0].position.z)):
		printerr("Walking guidance did not lead along the motorboat pier toward the east bank")
		quit(1)
		return
	var landing: Vector3 = game.walker.position
	game.map_button.pressed.emit()
	var town_map: AcceptDialog = game.get_node("TownMap")
	var town_chart = town_map.get_child(0).get_child(0)
	var outbound: PackedVector2Array = town_chart.route_preview
	var pier_exit := Vector2(game.LAUNCH_PIER.end.x + .5, game.LAUNCH_LANDING.y)
	if outbound.size() <= 3 or not outbound[0].is_equal_approx(Vector2(landing.x, landing.z)) or not outbound[2].is_equal_approx(pier_exit):
		printerr("Map route from the boat did not begin along the pier toward the quay")
		quit(1)
		return
	town_map.hide()
	Input.action_press("ui_up")
	for direction in [1.0, -1.0]:
		if direction < 0:
			game.map_button.pressed.emit()
			var map: AcceptDialog = game.get_node("TownMap")
			var chart = map.get_child(0).get_child(0)
			var pin := chart.get_child(chart.stops.find(game.LAUNCH_MAP_STOP)) as Button
			pin.pressed.emit()
			if game.map_goal != game.LAUNCH_MAP_STOP:
				printerr("The motorboat map pin did not select the landing")
				quit(1)
				return
			game.map_button.pressed.emit()
			var preview: PackedVector2Array = chart.route_preview
			var pier_entrance := Vector2(game.LAUNCH_PIER.end.x + .5, game.LAUNCH_LANDING.y)
			var player_point := Vector2(game.walker.position.x, game.walker.position.z)
			if preview.size() < 3 or not preview[0].is_equal_approx(player_point) or not preview[-2].is_equal_approx(pier_entrance) or not preview[-1].is_equal_approx(game.LAUNCH_LANDING):
				printerr("Map preview did not follow the pier from the quay to the motorboat")
				quit(1)
				return
		game.walker.rotation.y = -direction * PI * .5
		game.walking_velocity = Vector3.ZERO
		for frame in 300:
			game._walk(1.0 / 60.0)
			if direction > 0 and game.walker.position.x > game.LAUNCH_PIER.end.x + .4:
				break
			if direction < 0 and game.walker.position.distance_to(landing) < .4:
				break
		if (direction > 0 and game.walker.position.x <= game.LAUNCH_PIER.end.x + .4) or (direction < 0 and game.walker.position.distance_to(landing) >= .4):
			Input.action_release("ui_up")
			printerr("Could not walk between the motorboat landing and the quay")
			quit(1)
			return
	Input.action_release("ui_up")
	game._update_route_arrows()
	if game.map_goal.is_finite():
		printerr("The motorboat route did not finish at the landing")
		quit(1)
		return
	var saved_landing: Vector3 = game.walker.position
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if game.map_goal.is_finite() or game.boating or not game.walker.visible or not game.walker.position.is_equal_approx(saved_landing) or not game._feet_supported(game.walker.position):
		printerr("Saved walking position on the motorboat pier was not restored")
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
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.BUS)
	game._start_game()
	game.ambulance.position = Vector3(70, 0, 20)
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	for span: Vector2 in game.OPEN_WATER:
		if game.vehicle_index != game.BUS or game._shore_overlap(span, game.ambulance.position, game._player_extent()) > .01:
			printerr("A bus saved in the canal was not moved onto dry land")
			quit(1)
			return
	for bridge_z: float in [0.0, -48.0]:
		var bridge_position := Vector3(71, game._surface_height(71, bridge_z), bridge_z)
		game.ambulance.position = bridge_position
		game.ambulance.rotation.y = -PI * .5
		game._save_checkpoint()
		game.queue_free()
		await process_frame
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		if game.vehicle_index != game.BUS or not game.ambulance.position.is_equal_approx(bridge_position):
			printerr("A valid bus checkpoint moved off the bridge at z = ", bridge_z)
			quit(1)
			return
	print("Bridge exits, offshore safety and the motorboat pier checkpoint passed.")
	quit()


func check_land_vehicles(game: Node) -> bool:
	for index in game.VEHICLE_NAMES_ALL.size():
		game.mode = "menu"
		game._on_vehicle_selected(index)
		game._start_game()
		game.traffic_data.clear()
		for reverse in [false, true]:
			game.ambulance.position = Vector3(42, game._surface_height(42, -14), -14)
			game.ambulance.rotation.y = PI * .5 if reverse else -PI * .5
			game.speed = -4.0 if reverse else 4.0
			game.brake_held = false
			game.mouse_gas = not reverse
			game.mouse_brake = reverse
			for frame in 520:
				game._drive(1.0 / 60.0)
				var extent: Vector2 = game._player_extent()
				for span: Vector2 in game.OPEN_WATER:
					if game._shore_overlap(span, game.ambulance.position, extent) > .01:
						printerr(game.VEHICLE_NAMES_ALL[index], " entered the canal, reverse: ", reverse)
						quit(1)
						return false
			if game.ambulance.position.x < 42.5 or absf(game.speed) > .05:
				printerr(game.VEHICLE_NAMES_ALL[index], " did not approach and stop before the canal, reverse: ", reverse)
				quit(1)
				return false
		game.mouse_brake = false
		game.mouse_gas = false
	print("All road vehicles stayed out of the canal in forward and reverse.")
	return true
