extends SceneTree
## Run from the imported project with godot --headless --script res://tests/water_exit.gd

func _initialize() -> void:
	call_deferred("check_exits")

func check_exits() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	if not check_traffic_circuits(game):
		quit(1)
		return
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
	game.map_goal = game.FOUNTAIN_APPROACH
	game.ambulance.position = game.FOUNTAIN_APPROACH + Vector3.FORWARD * 2.5
	game._update_route_arrows()
	if game.map_goal != game.FOUNTAIN_APPROACH or game.route_arrows[0].visible:
		printerr("Parking near the fountain should preserve the walking destination")
		quit(1)
		return
	game.walker.show()
	game.walker.position = game.ambulance.position
	game._update_route_arrows()
	if not game.route_arrows[0].visible:
		printerr("Walking directions to the fountain are missing")
		quit(1)
		return
	game.walker.position = game.FOUNTAIN_APPROACH
	game._update_route_arrows()
	if game.map_goal.is_finite() or game.route_arrows[0].visible:
		printerr("Walking to the fountain did not finish navigation")
		quit(1)
		return
	game.walker.hide()
	game.map_goal = game.LAUNCH_MAP_STOP
	game.ambulance.position = game.LAUNCH_ROAD_STOP
	for heading: float in [0.0, PI]:
		game.ambulance.rotation.y = heading
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
		if is_zero_approx(heading):
			var saved_walk: Vector3 = game.walker.position
			game._save_checkpoint()
			game.queue_free()
			await process_frame
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			game._resume_road_checkpoint()
			game.traffic_data.clear()
			if not game.walker.visible or not game.walker.position.is_equal_approx(saved_walk) or game.map_goal != game.LAUNCH_MAP_STOP or not game.route_arrows[0].visible:
				printerr("Guidance to the motorboat was lost when resuming beside the parked car")
				quit(1)
				return
		var walk_start := Vector2(game.walker.position.x, game.walker.position.z)
		var path: PackedVector2Array = game._launch_walking_path(walk_start)
		game.map_button.pressed.emit()
		var parking_map := game.get_node("TownMap") as AcceptDialog
		var parking_chart = parking_map.get_child(0).get_child(0)
		if parking_chart.route_preview != path:
			printerr("The town map and walking arrows disagreed at the motorboat parking bay")
			quit(1)
			return
		parking_map.hide()
		for segment in range(1, path.size()):
			var steps := maxi(1, ceili(path[segment-1].distance_to(path[segment]) / .25))
			for step in range(1, steps + 1):
				var sample := path[segment-1].lerp(path[segment], float(step) / steps)
				var foot := Vector3(sample.x, game._foot_height(sample.x, sample.y), sample.y)
				if not game._on_foot_clear(foot):
					printerr("Motorboat walking guidance crosses an obstruction at ", foot)
					quit(1)
					return
		game._change_seat()
		if game.walker.visible:
			printerr("Could not re-enter the car at the motorboat parking bay")
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
	var phone_pose: Transform3D = game.launch.transform
	game.phone.toggle()
	Input.action_press("ui_up")
	Input.action_press("ui_left")
	game._drive_launch(.25)
	Input.action_release("ui_left")
	game.phone.toggle()
	game._drive_launch(.25)
	Input.action_release("ui_up")
	if not game.launch.transform.is_equal_approx(phone_pose) or not is_zero_approx(game.launch_speed):
		printerr("Motorboat responded to driving keys while the phone was open")
		quit(1)
		return
	game.mouse_gas = true
	for frame in 60:
		game._process(1.0 / 60)
	if game.launch.position.distance_to(saved_pose.origin) < .3:
		printerr("Boat did not move after reopening")
		quit(1)
		return
	if not check_boat_bridges(game):
		quit(1)
		return
	var ferry_bounds: AABB = game.ferry.global_transform * game.ferry_hull_bounds
	game.launch.position = Vector3(77, -.94, ferry_bounds.get_center().z)
	game.launch.rotation.y = PI * .5
	game.launch_speed = 0.0
	for frame in 260:
		game._drive_launch(1.0 / 60.0)
	if game.launch.position.x > 75.0 or game.launch.position.x - 2.7 < ferry_bounds.end.x - .01 or not is_zero_approx(game.launch_speed):
		printerr("The motorboat did not stop before Lotten: ", game.launch.position, " bounds=", ferry_bounds)
		quit(1)
		return
	var berth: Dictionary = game.moorings[3]
	var moored: Node3D = berth.boat
	var moored_bounds: AABB = moored.global_transform * berth.hull_bounds
	game.launch.position = Vector3(73, -.94, moored.position.z)
	game.launch.rotation.y = -PI * .5
	game.launch_speed = 0.0
	for frame in 240:
		game._drive_launch(1.0 / 60.0)
	if game.launch.position.x < 74.0 or game.launch.position.x + 2.7 > moored_bounds.position.x + .01 or not is_zero_approx(game.launch_speed):
		printerr("Motorboat did not stop before the moored hull: ", game.launch.position, " speed=", game.launch_speed, " bounds=", moored_bounds)
		quit(1)
		return
	var blocked_at: float = game.launch.position.x
	game.mouse_gas = false
	game.mouse_brake = true
	for frame in 60:
		game._drive_launch(1.0 / 60.0)
	if game.launch.position.x > blocked_at - .5 or game.launch_speed >= 0.0:
		printerr("The motorboat could not reverse away from the moored hull")
		quit(1)
		return
	game.mouse_brake = false
	game.mouse_gas = true
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
	var docked_pose: Transform3D = game.launch.transform
	var board_key := InputEventKey.new()
	board_key.pressed = true
	board_key.keycode = KEY_F3
	game.seat_f3 = true
	game.launch.position += Vector3.LEFT * 3.0
	game._update_entry_button()
	game._unhandled_key_input(board_key)
	if not game.seat_button.disabled or game.boating or not game.walker.visible:
		printerr("The motorboat could be boarded while away from the berth")
		quit(1)
		return
	game.launch.transform = docked_pose
	game._update_entry_button()
	if game.seat_button.disabled or not game.seat_button.text.ends_with(" / F3"):
		printerr("The motorboat did not advertise the configured boarding shortcut")
		quit(1)
		return
	Input.action_press("ui_up")
	game._unhandled_key_input(board_key)
	game._drive_launch(.25)
	Input.action_release("ui_up")
	if game.launch.transform != docked_pose or not is_zero_approx(game.launch_speed):
		printerr("Motorboat moved with a key carried over from walking")
		quit(1)
		return
	if not game.boating or game.walker.visible or game.listener.get_parent() != game.launch:
		printerr("Could not reboard the motorboat from the landing")
		quit(1)
		return
	if not check_ferry_yields(game):
		quit(1)
		return
	game.queue_free()
	await process_frame
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for index in [game.BUS, game.DAM_PICKUP]:
		game.mode = "menu"
		game._on_vehicle_selected(index)
		game._start_game()
		game.ambulance.position = Vector3(70, 0, 20)
		game._save_checkpoint()
		game.queue_free()
		await process_frame
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		for span: Vector2 in game.OPEN_WATER:
			if game.vehicle_index != index or game._shore_overlap(span, game.ambulance.position, game._player_extent()) > .01:
				printerr(game.VEHICLE_NAMES_ALL[index], " saved in the canal was not moved onto dry land")
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
			if game.vehicle_index != index or not game.ambulance.position.is_equal_approx(bridge_position):
				printerr(game.VEHICLE_NAMES_ALL[index], " checkpoint moved off the bridge at z = ", bridge_z)
				quit(1)
				return
	print("Bridge exits, offshore safety and the motorboat pier checkpoint passed.")
	quit()


func check_traffic_circuits(game: Node) -> bool:
	if game.traffic_data.is_empty():
		printerr("No street traffic was available for the canal test")
		return false
	for item: Dictionary in game.traffic_data:
		var circuit: Curve3D = item.route
		var length := circuit.get_baked_length()
		if length <= 0:
			printerr("An ambient vehicle has an empty circuit")
			return false
		var initial_distance: float = item.distance
		var samples := ceili(length / .25)
		for sample in samples:
			item.distance = length * float(sample) / samples
			game._place_traffic(item)
			var actor: Node3D = item.actor
			var extent: Vector2 = game._traffic_extent(item)
			for span: Vector2 in game.OPEN_WATER:
				if game._shore_overlap(span, actor.position, extent) > .01:
					printerr(actor.name, " crosses open water at ", actor.position)
					return false
		item.distance = initial_distance
		game._place_traffic(item)
	print("All ambient traffic circuits stayed out of open water, including at the bridges.")
	return true

func check_land_vehicles(game: Node) -> bool:
	var vehicles := range(game.VEHICLE_NAMES_ALL.size())
	vehicles.append(game.BUS)
	var original_snow: float = game.weather.snow
	for pass_index in vehicles.size():
		var index: int = vehicles[pass_index]
		var snow_trial := pass_index == vehicles.size() - 1
		game.mode = "menu"
		game._on_vehicle_selected(index)
		game._start_game()
		game.traffic_data.clear()
		game.weather.snow = .95 if snow_trial else 0.0
		for start_x: float in [42.0, 98.0]:
			var toward_water := 1.0 if start_x < 55.0 else -1.0
			var approach_z := -14.0 if toward_water > 0 else -64.0
			for reverse in [false, true]:
				game.ambulance.position = Vector3(start_x, game._surface_height(start_x, approach_z), approach_z)
				game.ambulance.rotation.y = toward_water * (PI * .5 if reverse else -PI * .5)
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
				if (game.ambulance.position.x - start_x) * toward_water < .5 or absf(game.speed) > .05:
					printerr(game.VEHICLE_NAMES_ALL[index], " did not approach and stop before the canal, start: ", start_x, " end: ", game.ambulance.position, " speed: ", game.speed, " reverse: ", reverse)
					quit(1)
					return false
			game.mouse_brake = false
		game.mouse_gas = false
	game.weather.snow = original_snow
	print("All road vehicles stayed out of the canal from both banks in forward and reverse. The bus passed on snow as well.")
	return true

func check_boat_bridges(game: Node3D) -> bool:
	var decks := get_nodes_in_group("south_bridge_deck") + get_nodes_in_group("north_bridge_deck")
	if decks.is_empty():
		printerr("Missing canal bridge decks")
		return false
	var launch: Node3D = game.launch
	var bounds: AABB = game._model_bounds(launch, launch)
	for southbound in [false, true]:
		var destination := 12.0 if southbound else -60.0
		var direction := 1.0 if southbound else -1.0
		launch.position = Vector3(73, -.94, -60.0 if southbound else 12.0)
		launch.rotation = Vector3(0, PI if southbound else 0.0, 0)
		game.launch_speed = 0.0
		for frame in 1200:
			game._drive_launch(1.0 / 60.0)
			game._update_camera(0.0, true)
			if absf(launch.position.z) < 5.8 and game.camera.position.y > game.SOUTH_BRIDGE_RISE - .58:
				printerr("The motorboat camera ended up above the southern bridge deck")
				return false
			var hull := launch.global_transform * bounds
			for part: MeshInstance3D in decks:
				if hull.intersects(part.global_transform * part.get_aabb()):
					printerr("The motorboat hit a deck under ", part.name, " at ", launch.position)
					return false
			if direction * (launch.position.z - destination) >= 0.0:
				break
		if direction * (launch.position.z - destination) < 0.0:
			printerr("The motorboat stopped short of crossing both bridges at ", launch.position)
			return false
	print("The motorboat cleared both canal bridges in both directions.")
	return true

func check_ferry_yields(game: Node3D) -> bool:
	for sign_value: float in [1.0, -1.0]:
		game.ferry_delay = 0.0
		game.ferry_speed_factor = 1.0
		game.wave_time = 10.0 if sign_value > 0.0 else 39.0
		game._update_moorings(0.0)
		var start_z: float = game.ferry.position.z
		game.launch.position = Vector3(68.0, -.94, -41.5)
		game.launch.rotation.y = 0.0
		var launch_hull: Rect2 = game._launch_footprint(game.launch.position, game.launch.rotation.y)
		for frame in 900:
			game._update_moorings(1.0 / 60.0)
			var bounds: AABB = game.ferry.global_transform * game.ferry_hull_bounds
			var ferry_hull := Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)
			if ferry_hull.intersection(launch_hull.grow_individual(0.0, .55, 0.0, .55)).get_area() > .01:
				printerr("Lotten did not leave room in front of the stopped motorboat")
				return false
		var stopped_z: float = game.ferry.position.z
		var stopped_clock: float = game._ferry_clock()
		if sign_value * (stopped_z - start_z) < 4.0 or game.ferry_delay < 1.0:
			printerr("Lotten did not approach the boat and then yield")
			return false
		game.launch.position.x = 74.0
		game._update_moorings(1.0 / 60.0)
		if game._ferry_clock() <= stopped_clock or game.ferry_speed_factor >= .10:
			printerr("Lotten restarted at full speed")
			return false
		for frame in 120:
			game._update_moorings(1.0 / 60.0)
		if game.ferry_speed_factor < .99 or game._ferry_clock() - stopped_clock < 1.5 or sign_value * (game.ferry.position.z - stopped_z) < 2.0:
			printerr("Lotten did not continue after the channel cleared")
			return false
	print("Lotten yielded to the stopped motorboat and continued in both directions.")
	return true
