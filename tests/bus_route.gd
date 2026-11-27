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
	if not check_glazing(game, game.vehicle_model) or not check_registration(game.vehicle_model):
		quit(1)
		return
	var original_time: int = game.time_mode
	if game.reverse_lens == null:
		printerr("The bus is missing its reversing light material")
		quit(1)
		return
	game.speed = -1.0
	game.mouse_brake = true
	game._drive(.016)
	game.mouse_brake = false
	if game.reverse_lens.emission_energy_multiplier <= 0.0:
		printerr("Bus reversing lights did not turn on")
		quit(1)
		return
	var centre_brake: StandardMaterial3D = game.player_brake_lens.get_meta("centre_lamp", null)
	if centre_brake == null or centre_brake.emission_enabled:
		printerr("The bus centre brake light should be present and initially off")
		quit(1)
		return
	game.speed = 3.0
	game.mouse_brake = true
	game._drive(.016)
	game.mouse_brake = false
	if game.reverse_lens.emission_energy_multiplier > 0.0:
		printerr("Bus reversing lights stayed on after forward travel")
		quit(1)
		return
	if not centre_brake.emission_enabled:
		printerr("The bus centre brake light did not turn on under braking")
		quit(1)
		return
	for lighting in [1, 0]:
		game.time_mode = lighting
		game._update_daylight(0.0)
		if not centre_brake.emission_enabled or not is_equal_approx(game.player_brake_lens.emission_energy_multiplier, 2.4):
			printerr("Changing the time of day interrupted an active bus brake light")
			quit(1)
			return
	game.time_mode = 1
	game._update_daylight(0.0)
	game.speed = 0.0
	game._drive(.016)
	if centre_brake.emission_enabled or not is_equal_approx(game.player_brake_lens.emission_energy_multiplier, .75):
		printerr("The bus centre brake light stayed on after releasing the brake")
		quit(1)
		return
	var rear_markers: Array[Node] = game.vehicle_model.find_children("Bus rear upper marker lens*", "MeshInstance3D", true, false)
	if rear_markers.size() != 2:
		printerr("The city bus needs two upper rear position lights")
		quit(1)
		return
	for night in [false,true,false]:
		game.time_mode = 1 if night else 0
		game._update_daylight(0.0)
		if (float(game.bus_glazing.get_shader_parameter("night")) > .5) != night:
			printerr("Bus window reflections did not follow daylight")
			quit(1)
			return
		if not rear_markers.all(func(lens: MeshInstance3D): return (lens.material_override.emission_energy_multiplier > 0.0) == night):
			printerr("Upper rear position lights did not follow the time of day")
			quit(1)
			return
		if (game.bus_plate_finish.emission_energy_multiplier > 0) != night or (game.bus_plate_lamp_finish.emission_energy_multiplier > 0) != night:
			printerr("The rear registration plate lights did not follow the time of day")
			quit(1)
			return
		if game.projector_finish == null or (game.projector_finish.emission_energy_multiplier > 0.0) != night:
			printerr("The bus headlight lenses did not follow the time of day")
			quit(1)
			return
		for beam: SpotLight3D in game.headlights:
			if beam.visible != night or (beam.light_energy > 0.0) != night:
				printerr("The bus headlight beams did not follow the time of day")
				quit(1)
				return
		if (game.bus_dashboard_backlight.emission_energy_multiplier > 0.0) != night:
			printerr("The bus dashboard backlight did not follow the time of day")
			quit(1)
			return
		if game.bus_ceiling_lights.size() != 3:
			printerr("The bus must have three saloon lights")
			quit(1)
			return
		for lamp: SpotLight3D in game.bus_ceiling_lights:
			if lamp.visible != night or (lamp.light_energy > 0.0) != night:
				printerr("The bus saloon lights did not follow the time of day")
				quit(1)
				return
	var original_phase: float = game.day_phase
	game.time_mode = 2
	var levels := PackedFloat32Array()
	for phase: float in [0.0, .25, .5, .75, 0.0]:
		game.day_phase = phase
		game._update_daylight(0.0)
		levels.append(game.projector_finish.emission_energy_multiplier)
		for beam: SpotLight3D in game.headlights:
			if beam.visible != (levels[-1] > 0) or not is_equal_approx(beam.light_energy, levels[-1] * 1.5):
				printerr("Bus road lighting disagreed with its lenses at day phase ", phase)
				quit(1)
				return
			var direction := -beam.basis.z.normalized()
			var ground_distance := -beam.position.y / minf(direction.y, -.001)
			if direction.dot(Vector3.FORWARD) < .95 or ground_distance <= 0.0 or ground_distance >= beam.spot_range:
				printerr("A bus headlight is not aimed at the road within its range")
				quit(1)
				return
	if levels[0] != 0 or levels[4] != 0 or not (0 < levels[1] and levels[1] < levels[2] and is_equal_approx(levels[1], levels[3])):
		printerr("Bus headlight brightness did not follow dusk, midnight and dawn: ", levels)
		quit(1)
		return
	game.day_phase = original_phase
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
	var clear_road_pose := Transform3D(Basis(Vector3.UP, -PI * .5), Vector3(-35, 0, 0))
	var starting_balance: int = game.wallet
	for leg in range(stops.size() + 1):
		if leg == 1:
			var curb: Vector3 = game._mission_destination()
			game.ambulance.position = curb + Vector3.RIGHT * 30
			game._update_bus_stop_request(.5)
			if game.bus_stop_request.visible:
				printerr("Passengers requested a stop before approaching the curb")
				quit(1)
				return
			game.ambulance.position = curb + Vector3.RIGHT * 15
			game._update_bus_stop_request(.5)
			game.ambulance.position = curb + Vector3.RIGHT * 30
			game._toggle_camera_view()
			game._save_checkpoint()
			game.queue_free()
			await process_frame
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			game.cockpit_look = Vector2(.9, .3)
			var resume = game.find_child("ResumeCheckpoint", true, false)
			if not resume or not resume.is_visible_in_tree():
				printerr("Missing resume button on the main menu")
				quit(1)
				return
			Input.action_press("ui_up")
			resume.pressed.emit()
			var resumed_pose: Transform3D = game.ambulance.transform
			game.ambulance.transform = clear_road_pose
			game._drive(.1)
			Input.action_release("ui_up")
			if not is_zero_approx(game.speed):
				printerr("The bus accelerated using a key held while resuming")
				quit(1)
				return
			game._drive(.01)
			Input.action_press("ui_up")
			game._drive(.1)
			Input.action_release("ui_up")
			if game.speed <= 0.0:
				printerr("The resumed bus did not respond to a fresh accelerator press")
				quit(1)
				return
			game.ambulance.transform = resumed_pose
			game.speed = 0.0
			if not game.cockpit_view or game.road_driver.visible or not game.cockpit_look.is_zero_approx():
				printerr("The saved bus did not resume in driver view")
				quit(1)
				return
			TranslationServer.set_locale("sv")
			await process_frame
		for locale in ["en","de","es","fi","fr","nb","sv"]:
			TranslationServer.set_locale(locale)
			await process_frame
			var stop_name: String = game.BUS_STOP_NAMES[game.BUS_STOPS[leg % stops.size()]]
			var expected: String = game.tr("Next stop: %s") % game.tr(stop_name)
			var driver_expected: String = game.tr("Stop requested") if leg == 1 else expected
			if game.next_bus_stop_board.text != expected or game.driver_bus_stop_board.text != driver_expected or game.bus_leg != leg:
				printerr("Interior display lost stop ", leg, " after switching to ", locale)
				quit(1)
				return
			for board: Label3D in [game.next_bus_stop_board, game.driver_bus_stop_board]:
				var limit := 1.61 if board == game.next_bus_stop_board else .31
				var width := ThemeDB.fallback_font.get_string_size(board.text, HORIZONTAL_ALIGNMENT_LEFT, -1, board.font_size).x * board.pixel_size
				if width > limit + .001:
					printerr("Interior display text overflows at stop ", leg, " in ", locale)
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
		var stop_button: MeshInstance3D = game.vehicle_model.find_child("Stop button", true, false)
		var button_finish := stop_button.material_override as StandardMaterial3D
		if (button_finish.emission_energy_multiplier > 0.0) != (leg == 1):
			printerr("The stop button did not follow the saved or cleared request")
			quit(1)
			return
		if game.bus_stop_request.visible != (leg == 1) or not is_zero_approx(game.bus_request_arm.rotation.x):
			printerr("A stop request carried over to leg ", leg)
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
			if leg % 2 == 1 and leg != 1:
				var curb: Vector3 = game._mission_destination()
				game.ambulance.position = curb
				game.walker.position = curb
				game.walker.show()
				game._update_bus_stop_request(.5)
				game._update_arrival(game.HELP_DURATION)
				game._help_at_target()
				if game.bus_stop_request.visible or game.bus_leg != leg or game.wallet != starting_balance + expected_fares * 15:
					printerr("Passengers requested or completed a stop while the driver was outside")
					quit(1)
					return
				game.walker.hide()
				game.ambulance.position = curb + Vector3.RIGHT * 30
				game._update_bus_stop_request(.5)
				if game.bus_stop_request.visible or not is_zero_approx(game.bus_press_time):
					printerr("Passengers requested a stop before approaching the curb")
					quit(1)
					return
				game.ambulance.position = curb + Vector3.RIGHT * 15
				game._update_bus_stop_request(.2)
				game.ambulance.position = curb + Vector3.RIGHT * 30
				game._update_bus_stop_request(.5)
				if game.bus_stop_request.visible or not is_zero_approx(game.bus_request_arm.rotation.x):
					printerr("A partial stop request continued after leaving the stop area")
					quit(1)
					return
				game.ambulance.position = curb + Vector3.RIGHT * 15
				game._update_bus_stop_request(.2)
				game.walker.show()
				game._update_bus_stop_request(.5)
				if game.bus_stop_request.visible or button_finish.emission_energy_multiplier > 0.0:
					printerr("A partially pressed stop button activated after the driver stepped out")
					quit(1)
					return
				game.walker.hide()
				# Finish the press in short frames on one leg and a single long frame on the other.
				var frames := 18 if leg == 3 else 1
				for frame in frames:
					game._update_bus_stop_request(.3 / frames)
				if not game.bus_stop_request.is_visible_in_tree() or game.bus_request_arm.rotation.x < 1.0 or button_finish.emission_energy_multiplier <= 0.0:
					printerr("Passengers did not signal the upcoming stop")
					quit(1)
					return
				if game.driver_bus_stop_board.text != game.tr("Stop requested") or game.driver_bus_stop_board.modulate != game.bus_stop_request.modulate:
					printerr("The dashboard did not show the passenger stop request")
					quit(1)
					return
				game.ambulance.position = curb + Vector3.RIGHT * 30
				game._update_bus_stop_request(1.0)
				if not game.bus_stop_request.visible or button_finish.emission_energy_multiplier <= 0.0 or not is_zero_approx(game.bus_request_arm.rotation.x):
					printerr("An active stop request was lost after the bus passed the stop")
					quit(1)
					return
			game.ambulance.position = game._mission_destination()
			game._update_arrival(game.HELP_DURATION)
	# Simulate leaving without a second save after the final fare.
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if game.bus_leg != stops.size() or game.wallet != starting_balance + 45:
		printerr("The last fare and its completed bus leg did not restore together")
		quit(1)
		return
	if not game.bus_departure_pending or not is_equal_approx(game.bus_merge_time, game.BUS_MERGE_SECONDS):
		printerr("A waiting bus departure was lost on resume")
		quit(1)
		return
	if not check_departure_indicator(game):
		quit(1)
		return
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
	if not check_traffic_lights(game):
		quit(1)
		return
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Both bus displays followed the six stops and three completed journeys paid once each.")
	quit()

func check_glazing(game: Node, body: Node3D) -> bool:
	var doors := body.find_children("Passenger door tinted glazing*", "MeshInstance3D", true, false)
	var cabin := body.find_child("Cabin", true, false) as MeshInstance3D
	var cabin_uses_glazing := false
	if cabin:
		for surface in cabin.mesh.get_surface_count():
			if cabin.get_surface_override_material(surface) == game.bus_glazing:
				cabin_uses_glazing = true
				break
	if not cabin_uses_glazing or doors.size() != 6 or not doors.all(func(pane: MeshInstance3D): return pane.material_override == game.bus_glazing):
		printerr("Unexpected bus glazing on ", body.name, " (", doors.size(), " panes, cabin override ", cabin_uses_glazing, ")")
		return false
	return true

func check_departure_indicator(game: Node) -> bool:
	var calm: bool = game.calm_mode
	var steady: bool = game.steady_player_lights
	game.calm_mode = false
	game.steady_player_lights = false
	game.speed = 0.0
	game.steering = 0.0
	game.driven_turn_signals.advance(0.0, 0.0, false)
	for tick in 20:
		game._update_traffic(.4)
	game._update_traffic(.1)
	var lamps: Array[MeshInstance3D] = game.bus_departure_lamps
	var right_lamps: Array[MeshInstance3D] = game.driven_turn_signals.right
	if not check_bus_indicator_mounts(game.vehicle_model, lamps, 1.0) \
			or not check_bus_indicator_mounts(game.vehicle_model, right_lamps, -1.0):
		return false
	var arrow: Label3D = game.vehicle_model.find_child("Dashboard left indicator", true, false)
	var right_arrow: Label3D = game.vehicle_model.find_child("Dashboard right indicator", true, false)
	if not arrow.visible or right_arrow.visible:
		printerr("Dashboard did not indicate the left turn")
		return false
	if not game.bus_departure_pending or lamps.size() != 3 or not lamps.all(func(lamp: MeshInstance3D): return lamp.visible):
		printerr("Departure indicators expired before the bus could move: ", game.bus_departure_pending,
			", ", lamps.size(), " lamps, phase ", game.driven_turn_signals.phase)
		return false
	game._update_traffic(.4)
	if arrow.visible or lamps.any(func(lamp: MeshInstance3D): return lamp.visible):
		printerr("Departure lights did not blink together while waiting")
		return false
	var departure_time: float = game.bus_merge_time
	game.speed = -1.0
	game._update_traffic(.1)
	if not game.bus_departure_pending or game.bus_merge_time != departure_time or game.driven_turn_signals.direction != 0:
		printerr("Reversing started or cancelled the bus departure")
		return false
	game.speed = 0.0
	game._update_traffic(.1)
	if game.driven_turn_signals.direction != -1 or not arrow.visible:
		printerr("The departure signal did not resume after reversing")
		return false
	game.speed = 2.0
	for tick in 60:
		game._update_traffic(.1)
	game._update_traffic(.1)
	game.speed = 0.0
	game.calm_mode = calm
	game.steady_player_lights = steady
	if game.bus_departure_pending or game.bus_merge_time != 0 or lamps.any(func(lamp: MeshInstance3D): return lamp.visible):
		printerr("Departure indicators stayed on after leaving the stop")
		return false
	game.driven_turn_signals.advance(1.0, .1, false)
	if arrow.visible or not right_arrow.visible:
		printerr("Dashboard did not indicate the right turn")
		return false
	if not right_lamps.all(func(lamp: MeshInstance3D): return lamp.visible) \
			or lamps.any(func(lamp: MeshInstance3D): return lamp.visible):
		printerr("The right turn did not light just the three right-side indicators")
		return false
	game.driven_turn_signals.advance(0.0, 0.0, false)
	print("All three departure indicators blinked through the wait and switched off after moving.")
	return true

func check_bus_indicator_mounts(body: Node3D, lamps: Array[MeshInstance3D], expected_side: float) -> bool:
	var front_attached := false
	var rear_attached := false
	var side_attached := false
	for lamp in lamps:
		var lens := lamp.get_parent() as MeshInstance3D
		if lens == null or signf(body.to_local(lens.global_position).x) != expected_side:
			printerr("A bus turn indicator is on the wrong side")
			return false
		if lamp.mesh != lens.mesh:
			continue
		front_attached = front_attached or lens.name.begins_with("Bus front indicator lens")
		rear_attached = rear_attached or lens.name.begins_with("Amber lens")
		side_attached = side_attached or lens.name.begins_with("Bus side indicator amber lens")
	if lamps.size() != 3 or not (front_attached and rear_attached and side_attached):
		printerr("Expected three bus indicators using their lens meshes")
		return false
	return true

func check_registration(body: Node3D) -> bool:
	var front := body.find_child("Bus front registration", true, false) as Label3D
	var rear := body.find_child("Bus rear registration", true, false) as Label3D
	var imported := body.find_child("Bus fleet registration", true, false) as MeshInstance3D
	if not front or not rear or not imported or imported.visible or front.text != "HBR 074" or rear.text != front.text:
		printerr("The front and rear registrations do not match on ", body.name)
		return false
	return true

func check_traffic_lights(game: Node) -> bool:
	var bus: Node3D = game._spawn_traffic(game.VEHICLE_SCENES_ALL[game.BUS], -480, 56, 1, 5.0, .8)
	var traffic_bus: Dictionary = game.traffic_data.back()
	var route := Curve3D.new()
	route.add_point(Vector3(-480,0,65))
	route.add_point(Vector3(-480,0,10))
	traffic_bus.route = route
	traffic_bus.distance = 9.0
	game._place_traffic(traffic_bus)
	var beams := bus.find_children("*", "SpotLight3D", false, false)
	var lenses := bus.find_children("Bus headlight lens*", "MeshInstance3D", true, false)
	if not check_glazing(game, bus) or not check_glazing(game, game.parked_cars[game.BUS]):
		return false
	for body: Node3D in [bus, game.parked_cars[game.BUS]]:
		if not check_registration(body):
			return false
		var markers := body.find_children("Bus rear upper marker lens*", "MeshInstance3D", true, false)
		if markers.size() != 2 or not markers.all(func(lens: MeshInstance3D): return lens.material_override == game.bus_rear_marker_finish):
			printerr("A bus variant did not use the shared rear position lights")
			return false
		var plate := body.find_child("Bus rear number plate", true, false) as MeshInstance3D
		var badge := body.find_child("Bus front badge", true, false) as Label3D
		if badge == null or badge.text != "SKANIA" or badge.position.z <= 5.25:
			printerr("A bus variant is missing its front badge")
			return false
		if body.find_children("Bus mirror housing*", "MeshInstance3D", true, false).size() != 2 or body.find_children("Bus mirror glass*", "MeshInstance3D", true, false).size() != 4:
			printerr("A bus variant is missing its side mirror assemblies")
			return false
		for shell: MeshInstance3D in body.find_children("Mirror*", "MeshInstance3D", true, false):
			if shell.visible:
				printerr("An imported mirror shell is visible below its replacement")
				return false
		if plate == null or plate.material_override != game.bus_plate_finish:
			printerr("A bus variant did not use the day-controlled registration plate")
			return false
		var lamps := 0
		for part in plate.get_children():
			if part is MeshInstance3D and part.material_override == game.bus_plate_lamp_finish:
				lamps += 1
		if lamps != 2:
			printerr("A bus variant did not have two day-controlled plate lamps")
			return false
	if beams.size() != 2 or lenses.size() != 4:
		printerr("The traffic bus should have two beams and four lenses")
		return false
	for beam: SpotLight3D in beams:
		if not lenses.any(func(lens: MeshInstance3D): return lens.to_global(lens.get_aabb().get_center()).distance_to(beam.global_position) < .05):
			printerr("A traffic bus beam is detached from its lens")
			return false
	for night in [true, false]:
		game.time_mode = 1 if night else 0
		game._update_daylight(0)
		if not beams.all(func(beam: SpotLight3D): return beam.visible == night) or not lenses.all(func(lens: MeshInstance3D): return (lens.get_active_material(0).emission_energy_multiplier > 0) == night):
			printerr("Traffic bus beams or lenses did not follow the day cycle")
			return false
	var centre: StandardMaterial3D = traffic_bus.brake_lens.get_meta("centre_lamp", null)
	if centre == null or centre.emission_enabled:
		printerr("The traffic bus centre brake lamp should start off")
		return false
	traffic_bus.speed = 4.0
	traffic_bus.cruise = 0.0
	game._update_traffic(.016)
	if not centre.emission_enabled:
		printerr("Traffic braking did not activate the bus centre lamp")
		return false
	traffic_bus.cruise = 5.0
	traffic_bus.speed = 0.0
	game._update_traffic(.016)
	if centre.emission_enabled:
		printerr("Traffic acceleration did not release the bus centre lamp")
		return false
	return true

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
	game.camera_f6 = true
	var view_key := InputEventKey.new()
	view_key.pressed = true
	game.phone.open_button.pressed.emit()
	for key in [KEY_C, KEY_F6]:
		view_key.keycode = key
		game._unhandled_key_input(view_key)
		if game.cockpit_view:
			printerr("A camera shortcut changed the view while the phone was open")
			return false
	game.phone.toggle()
	game._unhandled_key_input(view_key)
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
	game.mode = "complete"
	view_key.keycode = KEY_ENTER
	game._unhandled_key_input(view_key)
	if game.cockpit_view or not driver.visible:
		printerr("A new bus trip inherited the previous driver's camera")
		return false
	return true
