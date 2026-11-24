extends SceneTree
## Run from the imported project with godot --headless --script res://tests/bus_route.gd

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.BUS)
	# This route exercises automatic service after stopping.
	game.gentle_driving = true
	game.start_button.pressed.emit()
	if not check_driver(game):
		quit(1)
		return
	var headlamps: Array[Node] = game.vehicle_model.find_children("Bus headlight lens*","MeshInstance3D",true,false)
	if headlamps.size() != 4 or game.headlights.size() != 2:
		printerr("The bus must have four lenses and two headlight beams")
		quit(1)
		return
	for beam: SpotLight3D in game.headlights:
		var aligned := false
		for lamp: MeshInstance3D in headlamps:
			aligned = aligned or lamp.to_global(lamp.get_aabb().get_center()).distance_to(beam.global_position) < .05
		if not aligned:
			printerr("A bus headlight beam is detached from its lens")
			quit(1)
			return
	if game.side_bus_board.text != game.BUS_DESTINATION:
		printerr("The side display must show the bus line and destination")
		quit(1)
		return
	var original_time: int = game.time_mode
	for night in [false,true,false]:
		game.time_mode = 1 if night else 0
		game._update_daylight(0.0)
		if game.bus_ceiling_lights.size() != 3:
			printerr("The bus must have three saloon lights")
			quit(1)
			return
		for lamp: SpotLight3D in game.bus_ceiling_lights:
			if lamp.visible != night or (lamp.light_energy > 0.0) != night:
				printerr("The bus saloon lights did not follow the time of day")
				quit(1)
				return
	game.time_mode = original_time
	game._update_daylight(0.0)
	if game.driver_bus_stop_board.visible:
		printerr("The dashboard stop display should be off in free drive")
		quit(1)
		return
	game.phone.open_button.pressed.emit()
	if not game.free_drive or not game.phone.take_job.is_visible_in_tree():
		printerr("The vehicle must start in free exploration and offer a job in the phone")
		quit(1)
		return
	game.phone.take_job.pressed.emit()
	TranslationServer.set_locale("sv")
	await process_frame
	var stops := ["TORGET", "SJÖSTADSSKOLAN", "SMÅBÅTSHAMNEN", "VÅRDCENTRALEN", "VÄSTRA TORGET", "SICKLA UDDE"]
	var starting_balance: int = game.wallet
	for leg in range(stops.size() + 1):
		if leg == 1:
			game._save_checkpoint()
			game.queue_free()
			await process_frame
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			var resume = game.find_child("ResumeCheckpoint", true, false)
			if not resume or not resume.is_visible_in_tree():
				printerr("Missing resume button on the main menu")
				quit(1)
				return
			resume.pressed.emit()
			TranslationServer.set_locale("sv")
			await process_frame
		if leg == 1:
			for locale in ["en","de","es","fi","fr","nb","sv"]:
				TranslationServer.set_locale(locale)
				await process_frame
				var school: String = game.tr("HARBOR TOWN SCHOOL")
				var expected: String = game.tr("Next stop: %s") % school
				if game.next_bus_stop_board.text != expected or game.driver_bus_stop_board.text != expected or game.bus_leg != leg:
					printerr("Interior display lost the current stop after switching to ", locale)
					quit(1)
					return
				for sign: Label3D in get_nodes_in_group("bus_stop_labels"):
					if sign.text != game.BUS_DESTINATION + "\n" + game.tr(sign.get_meta("stop_name")):
						printerr("Stale stop sign after switching to ", locale)
						quit(1)
						return
		var row: HBoxContainer = game.phone.action_rows.get_child(0)
		var picture: AtlasTexture = row.get_child(0).texture
		var action: int = game.phone.Action.BOARD if leg % 2 == 0 else game.phone.Action.ALIGHT
		if picture.region.position.x != action * 48 or row.get_child(1).text != game.phone.current_job:
			printerr("Passenger action picture did not follow the next stop")
			quit(1)
			return
		if game.seated_bus_riders.get_child_count() != 2 or game.seated_bus_riders.is_visible_in_tree() != (leg % 2 == 1):
			printerr("Wrong passenger count or visibility at stop ", leg)
			quit(1)
			return
		if game._vehicle_payload() != (450.0 if leg % 2 else 0.0):
			printerr("Incorrect passenger payload")
			quit(1)
			return
		if leg > 0 and leg % 2 == 0:
			var badge: Button = game.reward_badge
			if not badge.is_visible_in_tree() or badge.icon.region.position.x != game.phone.Action.ALIGHT * 48 or not badge.text.contains("15 mynt"):
				printerr("Bus reward must show the completed drop-off and its fare")
				quit(1)
				return
		var nearest_sign: Label3D
		var nearest_distance := INF
		for sign: Label3D in get_nodes_in_group("bus_stop_labels"):
			var distance := sign.global_position.distance_to(game._mission_destination())
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_sign = sign
		var stop_index := leg % stops.size()
		if not nearest_sign or nearest_distance > 12 or nearest_sign.text != "74  SICKLA UDDE\n" + stops[stop_index]:
			printerr("The route marker should lead to the stop sign for ", stops[stop_index])
			quit(1)
			return
		if game.phone.current_job != game.BUS_MESSAGES[stop_index] or game.mission_marker.get_node("MissionLabel").text != game.tr(game.phone.current_job).to_upper():
			printerr("Phone instruction and route marker disagree at ", stops[stop_index])
			quit(1)
			return
		if not game.next_bus_stop_board.is_visible_in_tree() or game.next_bus_stop_board.text != "Nästa hållplats: " + stops[stop_index]:
			printerr("Interior display disagrees with the stop sign at ", stops[stop_index])
			quit(1)
			return
		var destination := "74  SICKLA UDDE"
		if game.bus_board.text != destination or game.rear_bus_board.text != destination:
			printerr("Expected both destination displays to show ", destination)
			quit(1)
			return
		var expected_fares := floori(leg / 2.0)
		if game.wallet != starting_balance + expected_fares * 15:
			printerr("Incorrect bus fare payout after stop ", leg)
			quit(1)
			return
		if leg < stops.size():
			game.ambulance.position = game._mission_destination()
			game._update_arrival(game.HELP_DURATION)
	TranslationServer.set_locale("en")
	await process_frame
	if game.bus_board.text != "74  SICKLA UDDE" or game.rear_bus_board.text != game.bus_board.text:
		printerr("Changing language did not update the bus displays")
		quit(1)
		return
	var labels := get_nodes_in_group("bus_stop_labels")
	for label in labels:
		if label.text != "74  SICKLA UDDE\n" + str(label.get_meta("stop_name")):
			printerr("Changing language did not update the stop sign")
			quit(1)
			return
	if labels.size() != 12:
		printerr("Expected two signs at each of six stops")
		quit(1)
		return
	game._save_checkpoint()
	write_incomplete_checkpoint(game)
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if game.find_child("ResumeCheckpoint", true, false) or game.wallet != starting_balance + 45:
		printerr("Incomplete checkpoint affected the menu or wallet")
		quit(1)
		return
	game.start_button.pressed.emit()
	if game.mode != "playing":
		printerr("Fresh start unavailable after incomplete checkpoint")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Both bus displays followed the six stops and three completed journeys paid once each.")
	quit()

func write_incomplete_checkpoint(game: Node) -> void:
	var damaged: Dictionary = game.road_checkpoint.duplicate(true)
	damaged["tram"] = {"mode": 1}
	var config := ConfigFile.new()
	config.load(game.SETTINGS_PATH)
	config.set_value("player", "road_checkpoint", damaged)
	config.save(game.SETTINGS_PATH)


func check_driver(game: Node) -> bool:
	var wheel: Node3D = game.cabin_wheel
	var driver: Node3D = game.road_driver
	var bus: Node3D = game.ambulance
	if not wheel or bus.to_local(wheel.global_position).x >= 0.0:
		printerr("Bus steering wheel is missing or is on the wrong side")
		return false
	var door_sills: Array[Node] = game.vehicle_model.find_children("Passenger door sill*","MeshInstance3D",true,false)
	var tyres: Array[Node] = game.vehicle_model.find_children("Däck*","MeshInstance3D",true,false)
	if door_sills.size() != 3 or tyres.size() != 4:
		printerr("Bus door or wheel geometry is missing: ",door_sills.size()," sills, ",tyres.size()," tyres")
		return false
	for alma in [true,false]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		game._refresh_ui()
		if not driver.is_visible_in_tree() or absf(bus.to_local(driver.global_position).x-bus.to_local(wheel.global_position).x) > .03:
			printerr("Bus driver is not seated behind the wheel")
			return false
		for turn in [-1.0,1.0,0.0]:
			game.mouse_steering = turn
			game.steering = turn
			game._drive(1.0/60.0)
			if game.front_knuckles.size() != 2:
				printerr("Both front wheels must steer")
				return false
			for joint: Node3D in game.front_knuckles:
				if not is_equal_approx(joint.rotation.y,-turn*deg_to_rad(33.0)):
					printerr("Front wheel did not reach the tested steering angle")
					return false
			var bus_inverse := bus.global_transform.affine_inverse()
			for sill: MeshInstance3D in door_sills:
				var door_bounds: AABB = (bus_inverse*sill.global_transform)*sill.get_aabb()
				for tyre: MeshInstance3D in tyres:
					var tyre_bounds: AABB = (bus_inverse*tyre.global_transform)*tyre.get_aabb()
					var longitudinal_gap := maxf(door_bounds.position.z-tyre_bounds.end.z,tyre_bounds.position.z-door_bounds.end.z)
					if longitudinal_gap < .06:
						printerr("A bus door is too close to a wheel: ",longitudinal_gap)
						return false
			var arms: Array = driver.get_meta("arms")
			for index in arms.size():
				var hand: Node3D = arms[index].get_node("Hand")
				var grip: Vector3 = wheel.to_global(Vector3.RIGHT*game.grip_radius*(-1 if index == 0 else 1))
				if hand.to_global(game.PALM_GRIP).distance_to(grip) > .01:
					printerr("Bus driver lost their grip while steering")
					return false
	var blades := bus.find_children("Windscreen wiper blade*","MeshInstance3D",true,false)
	if blades.size() != 2 or game.wiper_pivots.size() != 2:
		printerr("Both bus wipers must have a working pivot")
		return false
	var parked_heights: Array[float] = []
	game.weather.intensity = Vector2.ZERO
	game._advance_wipers(TAU)
	for blade: MeshInstance3D in blades:
		parked_heights.append(blade.to_global(blade.get_aabb().get_center()).y)
	for precipitation in [Vector2.RIGHT,Vector2.DOWN]:
		game.weather.intensity = precipitation
		game._advance_wipers(PI/5.4)
		for index in blades.size():
			var blade := blades[index] as MeshInstance3D
			if blade.to_global(blade.get_aabb().get_center()).y <= parked_heights[index]+.1:
				printerr("Precipitation did not lift both bus wipers")
				return false
		game.weather.intensity = Vector2.ZERO
		game._advance_wipers(TAU)
		for index in blades.size():
			var blade := blades[index] as MeshInstance3D
			if not is_equal_approx(blade.to_global(blade.get_aabb().get_center()).y,parked_heights[index]):
				printerr("A bus wiper did not return to its parked position")
				return false
	game._toggle_camera_view()
	if not game.cockpit_view or driver.visible:
		printerr("Bus driver obstructed the cockpit camera")
		return false
	var previous_locale := TranslationServer.get_locale()
	for locale in ["en","de","es","fi","fr","nb","sv"]:
		TranslationServer.set_locale(locale)
		for speed_mps in [0.0,5.0,-2.0]:
			game.speed = speed_mps
			game._refresh_status()
			var expected := game.tr("%d km/h") % roundi(absf(speed_mps)*3.6)
			if game.dash_speed.text != expected:
				printerr("Bus dashboard did not report the current speed")
				return false
			if speed_mps < 0.0 and game.dash_direction.text != "Reversing":
				printerr("Bus dashboard did not indicate reverse")
				return false
			for label: Label3D in [game.dash_speed,game.dash_direction]:
				var width := ThemeDB.fallback_font.get_string_size(label.atr(label.text),HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x
				if width*label.pixel_size > .311:
					printerr("Bus dashboard text is wider than its screen in ",locale)
					return false
	TranslationServer.set_locale(previous_locale)
	game.speed = 0.0
	game._toggle_camera_view()
	return driver.visible
