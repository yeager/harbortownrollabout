extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.weather.season_setting = 4
	game.weather.weather_setting = 3
	game.weather.tick(160)
	game._process(0)
	game._on_vehicle_selected(game.FARM_TRACTOR)
	game.start_button.pressed.emit()
	game.set_process(false)
	game.traffic_data.clear()
	game.allow_red_lights = true
	game.gentle_driving = false
	game.ambulance.position = Vector3(-119,game._surface_height(-119,2.35),2.35)
	game.ambulance.rotation.y = -PI*.5
	game.speed = 5
	game.sound_on = true
	game.mouse_gas = true
	if not game.spreader_button.visible or not game.spreader_button.button_pressed:
		printerr("Winter tractor has no active spreader control")
		quit(1)
		return
	var tractor_start: Transform3D = game.ambulance.transform
	game.spreader_button.button_pressed = false
	for frame in 20:
		game._drive(1.0/60.0)
	if game.spreader_particles.emitting or game.ground_work.has_gritted or not game.ground_work.has_ploughed:
		printerr("Turning off the spreader also stopped ploughing or still laid grit")
		quit(1)
		return
	game.ambulance.transform = tractor_start
	game.speed = 5
	game.spreader_button.button_pressed = true
	for frame in 105: game._drive(1.0/60.0)
	var trail := Vector3(-116,0,2.35)
	if not game.ground_work.gritted_at(trail) or not game.spreader_particles.emitting or not game.spreader_audio.playing:
		printerr("Driving the tractor failed to spread grit; position ",game.ambulance.position)
		quit(1)
		return
	game.mouse_gas = false
	game.speed = 0.0
	game._drive(1.0/60.0)
	if game.spreader_particles.emitting or game.spreader_audio.playing:
		printerr("Stationary tractor kept spreading")
		quit(1)
		return
	game.speed = -3.0
	game.mouse_brake = true
	game.brake_held = false
	game.ground_work.has_gritted = false
	var reverse_start: Vector3 = game.ambulance.position
	for frame in 20:
		game._drive(1.0/60.0)
	if game.ambulance.position.distance_to(reverse_start) < .4 or game.ground_work.has_gritted or game.spreader_particles.emitting or game.spreader_audio.playing:
		printerr("Reversing the tractor activated grit or did not move")
		quit(1)
		return
	game.mouse_brake = false
	game.brake_held = false
	print("Tractor reversed without spreading grit.")
	game.ground_work.has_gritted = true
	game.mode = "menu"
	game._on_vehicle_selected(game.QUATTRO)
	game.start_button.pressed.emit()
	if game.spreader_button.visible:
		printerr("The following car kept the tractor spreader control")
		quit(1)
		return
	game.ambulance.position = trail
	game.ambulance.rotation.y = -PI*.5
	var covered: Vector2 = game._road_coverage()
	if covered.y < .99:
		printerr("The following car did not detect the gritted lane: ",covered)
		quit(1)
		return
	var start: Transform3D = game.ambulance.transform
	var brake_speeds: Array[float] = []
	for treated in [false,true]:
		game.ground_work.has_gritted = treated
		game.ambulance.transform = start
		game.speed = 10.0
		game.mouse_gas = false
		game.mouse_brake = true
		game.brake_held = false
		game._drive(1.0/60.0)
		brake_speeds.append(game.speed)
	if brake_speeds[1] >= brake_speeds[0] - .015:
		printerr("Grit did not improve braking on the same ploughed road: ",brake_speeds)
		quit(1)
		return
	var traffic: Node3D = game._spawn_traffic("res://vehicles/traffic_bmw_blue.glb",trail.x,trail.z,1,9.0)
	var item: Dictionary = game.traffic_data.back()
	item.cruise = 0.0
	var route := Curve3D.new()
	route.add_point(trail)
	route.add_point(trail+Vector3(20,0,0))
	item.route = route
	var traffic_speeds: Array[float] = []
	game.ambulance.hide()
	for treated in [false,true]:
		game.ground_work.has_gritted = treated
		traffic.position = trail
		traffic.rotation.y = -PI*.5
		item.speed = 9.0
		item.distance = 0.0
		game._update_traffic(1.0/60.0)
		traffic_speeds.append(item.speed)
	if traffic_speeds[1] >= traffic_speeds[0] - .012:
		printerr("Traffic car did not brake harder with grit under the tyres: ",traffic_speeds)
		quit(1)
		return
	item.cruise = 9.0
	var pull_away_speeds: Array[float] = []
	for treated in [false,true]:
		game.ground_work.has_gritted = treated
		traffic.position = trail
		traffic.rotation.y = -PI*.5
		item.speed = 0.0
		item.distance = 0.0
		game._update_traffic(.2)
		pull_away_speeds.append(item.speed)
	if pull_away_speeds[1] <= pull_away_speeds[0] + .02:
		printerr("Traffic car did not pull away faster on grit: ",pull_away_speeds)
		quit(1)
		return
	item.cruise = 0.0
	print("Traffic also pulls away faster on gritted road.")
	var unploughed := trail + Vector3.BACK * 4.0
	var snow: float = game.weather.snow
	var wet: float = game.weather.wet
	var surface_speeds: Array[float] = []
	game.ground_work.has_gritted = false
	for cover in [snow, 0.0]:
		game.weather.snow = cover
		game.weather.wet = 0.0
		traffic.position = unploughed
		traffic.rotation.y = -PI*.5
		item.speed = 9.0
		item.distance = 0.0
		game._update_traffic(1.0/60.0)
		surface_speeds.append(item.speed)
	game.weather.snow = snow
	game.weather.wet = wet
	if surface_speeds[0] <= surface_speeds[1] + .01:
		printerr("Traffic did not lose braking grip on untreated snow: ",surface_speeds)
		quit(1)
		return
	game.ground_work.has_gritted = true
	print("Traffic brakes less firmly on untreated snow than on dry road.")
	game.ambulance.show()
	print("Traffic cars also brake harder on grit.")
	game.ground_work.update(1,0)
	if game.ground_work.gritted_at(trail):
		printerr("Winter grit was not cleared after the thaw")
		quit(1)
		return
	print("Winter tractor spreads grit, the following car brakes harder on it, and it clears when the snow melts.")
	game.mode = "menu"
	game._on_vehicle_selected(game.FARM_TRACTOR)
	game.start_button.pressed.emit()
	game.spreader_button.button_pressed = false
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var resume := game.find_child("ResumeCheckpoint",true,false) as Button
	if resume == null:
		printerr("Missing tractor checkpoint")
		quit(1)
		return
	resume.pressed.emit()
	if game.vehicle_index != game.FARM_TRACTOR or not game.spreader_button.visible or game.spreader_button.button_pressed or game.spreader_enabled:
		printerr("Resumed tractor did not retain spreader off")
		quit(1)
		return
	print("Spreader off remained selected after resuming the tractor checkpoint.")
	var shortcut := InputEventKey.new()
	shortcut.pressed = true
	shortcut.keycode = KEY_7
	game._unhandled_key_input(shortcut)
	if game.spreader_enabled:
		printerr("Spreader shortcut worked with number shortcuts disabled")
		quit(1)
		return
	var number_switches := game.find_child("NumberVehicleSwitches", true, false) as CheckButton
	number_switches.button_pressed = true
	game._unhandled_key_input(shortcut)
	if not game.spreader_enabled or not game.spreader_button.text.ends_with(" · 7"):
		printerr("Main keyboard 7 did not activate the spreader")
		quit(1)
		return
	shortcut.keycode = KEY_KP_7
	game._unhandled_key_input(shortcut)
	if game.spreader_enabled:
		printerr("Keypad 7 did not deactivate the spreader")
		quit(1)
		return
	print("Spreader keyboard shortcut verified on both keyboards.")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(800, 600)
	game.large_text = true
	game._apply_reading_size()
	var settings := game.find_child("GameSettings", true, false) as AcceptDialog
	var tabs := number_switches.get_parent().get_parent().get_parent() as TabContainer
	tabs.current_tab = number_switches.get_parent().get_parent().get_index()
	settings.popup_centered_clamped(Vector2i(710, 530), .94)
	if DisplayServer.get_name() == "headless": settings.size = Vector2i(710, 530)
	var driving_page := number_switches.get_parent().get_parent() as ScrollContainer
	for locale in ["en", "sv", "de", "es", "fi", "fr", "nb"]:
		TranslationServer.set_locale(locale)
		await process_frame
		await process_frame
		if number_switches.get_minimum_size().x > driving_page.size.x - driving_page.get_v_scroll_bar().size.x:
			printerr("Spreader shortcut label does not fit in ", locale, ": ", number_switches.get_minimum_size(), " in ", driving_page.size, " dialog ", settings.size, " tabs ", tabs.size, " index ", tabs.current_tab)
			quit(1)
			return
	settings.hide()
	print("Spreader shortcut setting fits at 800 × 600 in all seven languages.")
	game._finish_quit()
