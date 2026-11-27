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
	for z in range(int(game.FERRY_LANDINGS[0]), int(game.FERRY_LANDINGS[1])+1):
		var height: float = game._pier_height(58.0, z)
		if is_nan(height) or absf(height + .66) > .01:
			printerr("Missing boardwalk deck between the ferry landings at ", z)
			quit(1)
			return
	var bridge_parts := get_nodes_in_group("north_bridge_deck")
	for pier: MeshInstance3D in get_nodes_in_group("north_bridge_piers"):
		bridge_parts.append(pier)
		bridge_parts.append(pier.get_child(0))
	var ferry: Node3D = game.ferry
	var mast_lens := ferry.find_child("Mast lantern lens", true, false) as MeshInstance3D
	if not mast_lens:
		printerr("Lotten is missing its modeled mast lantern")
		quit(1)
		return
	var original_time_mode: int = game.time_mode
	var lantern := mast_lens.get_active_material(0) as StandardMaterial3D
	game.time_mode = 1
	game._update_daylight(0)
	if game.ferry_sidelights.size() != 2 or not game.ferry_sidelights.all(
			func(lens: StandardMaterial3D): return lens.emission_enabled and lens.emission_energy_multiplier > 0):
		printerr("Both Lotten sidelights must light at night")
		quit(1)
		return
	if game.ferry_deck_lights.size() != 4 or not game.ferry_deck_lights.all(
			func(light: SpotLight3D): return light.visible and light.light_energy > 0):
		printerr("Lotten must light both boarding decks at night")
		quit(1)
		return
	var lit_at_night := lantern.emission_enabled and lantern.emission_energy_multiplier > 0
	game.time_mode = 0
	game._update_daylight(0)
	if game.ferry_deck_lights.any(func(light: SpotLight3D): return light.visible):
		printerr("Lotten boarding deck lights must turn off in daylight")
		quit(1)
		return
	if not lit_at_night or not is_zero_approx(lantern.emission_energy_multiplier):
		printerr("Lotten mast lantern must light only at night")
		quit(1)
		return
	game.time_mode = original_time_mode
	game._update_daylight(0)
	var ferry_bounds: AABB = game._model_bounds(ferry, ferry)
	var radar: Node3D = game.ferry_radar
	if not radar or radar.get_child_count() != 4:
		printerr("Lotten radar needs a swivel for its scanner, end caps and antenna face")
		quit(1)
		return
	var radar_bounds: AABB = game._model_bounds(radar, radar)
	for frame in 58:
		game.wave_time = float(frame)
		game._update_moorings(0.0)
		var hull := ferry.global_transform * ferry_bounds
		if not is_equal_approx(radar.rotation.y, fposmod(float(frame), 2.5) * TAU / 2.5):
			printerr("Lotten radar did not rotate with game time")
			quit(1)
			return
		var port: int = 1 if frame < 29 else 0
		if game.ferry_sidelights[port].emission != Color("#dc3936") or game.ferry_sidelights[1-port].emission != Color("#359e64"):
			printerr("Lotten sidelights did not follow the direction of travel")
			quit(1)
			return
		var scanner := radar.global_transform * radar_bounds
		for part: MeshInstance3D in bridge_parts:
			var obstacle := part.global_transform * part.get_aabb()
			if hull.intersects(obstacle) or scanner.intersects(obstacle):
				printerr("Lotten overlaps the northern bridge at ", ferry.position, " on ", part.name)
				quit(1)
				return
		if not check_mooring_lines(game):
			quit(1)
			return
	print("Lotten cleared the northern bridge in both directions. All seven moorings held through 58 wave samples.")
	var original_scale: Vector3 = game.walker.scale
	for departure in game.FERRY_LANDINGS.size():
		game.wave_time = departure*29.0 + 1.9
		game._update_moorings(.2)
		var lamp = game.ferry_boarding_lamps[departure]
		if not lamp.visible or game.ferry_boarding_lamps[1-departure].visible or not game.ferry_boarding_chime.playing or game.ferry_boarding_chime.position != lamp.position:
			printerr("Missing local boarding signal before departure ",departure)
			quit(1)
			return
		game.ferry_boarding_chime.stop()
		game._update_moorings(.5)
		if not lamp.visible or game.ferry_boarding_chime.playing:
			printerr("Boarding signal repeated its chime")
			quit(1)
			return
		game._update_moorings(2.5)
		if lamp.visible:
			printerr("Boarding beacon still lit after departure")
			quit(1)
			return
		var quay_z: float = game.FERRY_LANDINGS[departure]
		game.walker.position = Vector3(64.9, game._foot_height(64.9, quay_z), quay_z)
		game.wave_time = departure * 29.0 + 1.0
		game._update_moorings(0.0)
		if not check_localized_button(game, "Board Lotten · F"):
			return
		var seat_binding := game.find_child("SeatF3", true, false) as CheckButton
		seat_binding.button_pressed = false
		var seat_key := InputEventKey.new()
		seat_key.pressed = true
		seat_key.keycode = KEY_F3
		game._unhandled_key_input(seat_key)
		if game.ferry_passenger:
			printerr("F3 boarded Lotten with the shortcut disabled")
			quit(1)
			return
		var alternate: bool = departure == 1
		seat_binding.button_pressed = alternate
		seat_key.keycode = KEY_F3 if alternate else KEY_F
		game._unhandled_key_input(seat_key)
		if not check_localized_button(game, "Step ashore · F"):
			return
		game._update_moorings(10.0)
		if not check_localized_button(game, "Get off at next landing · F"):
			return
		game._unhandled_key_input(seat_key)
		if not check_localized_button(game, "Stay on board · F"):
			return
		if not game.ferry_passenger:
			printerr("Passenger stepped off over open water from landing ", departure)
			quit(1)
			return
		var deck_position: Vector3 = game.walker.position
		game.map_button.pressed.emit()
		var map: AcceptDialog = game.get_node("TownMap")
		var chart = map.get_child(0).get_child(0)
		var destination: Vector3 = chart.stops[0]
		if not map.visible:
			printerr("Could not open the town map aboard Lotten")
			quit(1)
			return
		chart.picked.emit(0)
		game.queue_free()
		await process_frame
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		if game.seat_f3 != alternate:
			printerr("F3 setting did not survive reloading the game aboard Lotten")
			quit(1)
			return
		if not game.ferry_passenger or not game.ferry_exit_requested or not game.walker.position.is_equal_approx(deck_position):
			printerr("Lost passenger position or requested landing during restart")
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
		game._update_route_arrows()
		if game.map_goal != destination or not game.route_arrows.any(func(arrow): return arrow.visible):
			printerr("Walking guidance did not resume after leaving Lotten")
			quit(1)
			return
		game.map_button.pressed.emit()
		var reopened_map: AcceptDialog = game.get_node("TownMap")
		var reopened_chart = reopened_map.get_child(0).get_child(0)
		var route: PackedVector2Array = reopened_chart.route_preview
		var arrival_z: float = game.FERRY_LANDINGS[1 - departure]
		var start := Vector2(game.walker.position.x, game.walker.position.z)
		if route.size() <= 3 or not route[0].is_equal_approx(start) or not route[2].is_equal_approx(Vector2(48, arrival_z)):
			printerr("Map did not route from Lotten's landing through the quay")
			quit(1)
			return
		reopened_map.hide()
	var hull: AABB = game._model_bounds(game.ferry, game.ferry)
	var bridge := []
	for part in game.get_children():
		if part is MeshInstance3D and part.mesh is BoxMesh and absf(part.position.z + 48) < 5 and part.position.x > 50 and part.position.x < 99:
			bridge.append(part)
	var clearance := INF
	for frame in range(580):
		game.wave_time = frame * .1
		game._update_moorings(0)
		var occupied: AABB = game.ferry.global_transform * hull
		for part: MeshInstance3D in bridge:
			var span := part.global_transform * part.get_aabb()
			if occupied.position.x < span.end.x and span.position.x < occupied.end.x and occupied.position.z < span.end.z and span.position.z < occupied.end.z:
				clearance = minf(clearance, span.position.y - occupied.end.y)
	if clearance < .5 or not is_finite(clearance):
		printerr("Unexpected clearance along ferry route: ", clearance)
		quit(1)
		return
	print("Minimum overhead clearance on both crossings: %.2f m" % clearance)
	print("Both Lotten crossings preserved passenger scale and pier footing.")
	quit()

func check_localized_button(game: Node, key: String) -> bool:
	var original := TranslationServer.get_locale()
	var original_seat_f3: bool = game.seat_f3
	for locale in ["de", "es", "fi", "fr", "nb", "sv", "en"]:
		TranslationServer.set_locale(locale)
		for alternate in [false, true]:
			game.seat_f3 = alternate
			game._update_entry_button()
			game._refresh_status()
			var translated := String(TranslationServer.translate(key))
			var expected := translated + (" / F3" if alternate else "")
			var action: String = game.seat_button.atr(game.seat_button.text)
			var status_matches: bool = key != "Step ashore · F" or game.status_label.text == expected
			if game.seat_button.disabled or action != expected or not status_matches or (locale != "en" and translated == key):
				printerr("Incorrect ferry action in ", locale, " for ", key, ", F3 enabled: ", alternate)
				quit(1)
				return false
	game.seat_f3 = original_seat_f3
	TranslationServer.set_locale(original)
	return true

func check_mooring_lines(game: Node) -> bool:
	for berth in game.moorings:
		var buoy: Node3D = berth.buoy
		var boat: Node3D = berth.boat
		var bow: Vector3 = berth.bow_line.global_position
		var offset: float = game.EAST_QUAY_WATER_EDGE - buoy.position.x
		if offset < 7.0 or offset > 8.0 or buoy.position.x >= bow.x:
			printerr("Mooring buoy is not 7–8 metres out from the quay, beyond the bow")
			return false
		for index in berth.lines.size():
			var line: MeshInstance3D = berth.lines[index]
			var side := -1.0 if index == 1 else 1.0
			var boat_end := bow if index == 0 else boat.to_global(Vector3(2.44,.56,.71*side))
			var anchor: Node3D = berth.eye if index == 0 else berth.cleats[index-1]
			if line.to_global(Vector3.DOWN*.5).distance_to(boat_end) > .001 or line.to_global(Vector3.UP*.5).distance_to(anchor.global_position) > .001:
				printerr("Mooring line missed an attachment point at wave time ", game.wave_time)
				return false
	return true
