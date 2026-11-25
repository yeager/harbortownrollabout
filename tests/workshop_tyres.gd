extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func fail(reason: String) -> void:
	printerr(reason)
	quit(1)

func check() -> void:
	var scene := preload("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.QUATTRO)
	game.start_button.pressed.emit()
	game.set_process(false)
	game.weather.season_setting = 4
	game.weather.weather_setting = 3
	game.weather.tick(160)
	game.traffic_data.clear()
	game.gentle_driving = false
	game.allow_red_lights = true
	game.ambulance.position = game.STATION_DROP
	game.speed = 3
	game._refresh_status()
	if game.tyre_service_button.visible:
		fail("Tyre service available while moving")
		return
	game.speed = 0
	game._refresh_status()
	var snowy_surface: float = game.weather.snow
	var wet_surface: float = game.weather.wet
	var summer := measure_grip(game)
	var summer_launch := measure_launch(game)
	game.weather.snow = 0.0
	game.weather.wet = 0.0
	var dry_summer := measure_grip(game)
	game.practice_active = false
	game.speed = 0
	game._refresh_status()
	game.tyre_service_button.pressed.emit()
	if game.tyre_service_button.visible or not game.winter_tyre_models.is_empty():
		fail("Tyres could be changed away from the workshop")
		return
	game.weather.snow = snowy_surface
	game.weather.wet = wet_surface
	game.practice_active = false
	game.ambulance.position = game.STATION_DROP
	game.speed = 0
	game._refresh_status()
	if not game.tyre_service_button.visible or game.tyre_service_button.text != "Fit winter tyres":
		fail("Stopped car at the workshop could not select winter tyres")
		return
	game.phone.toggle()
	game._refresh_status()
	game.tyre_service_button.pressed.emit()
	if game.tyre_service_button.visible or not game.winter_tyre_models.is_empty():
		fail("The workshop changed tyres while the phone was open")
		return
	game.phone.toggle()
	game._refresh_status()
	if not game.tyre_service_button.visible:
		fail("The tyre service did not return after closing the phone")
		return
	game.tyre_service_button.pressed.emit()
	if game.tyre_service_button.text != "Fit summer tyres":
		fail("Workshop did not install winter tyres")
		return
	var winter := measure_grip(game)
	var winter_launch := measure_launch(game)
	if winter_launch <= summer_launch * 1.2:
		fail("Winter tyres did not improve assisted starts: summer %s, winter %s" % [summer_launch, winter_launch])
		return
	print("Gentle driving launch speed after half a second: ", [summer_launch, winter_launch], " m/s.")
	game.weather.snow = 0.0
	game.weather.wet = 0.0
	var dry_winter := measure_grip(game)
	if dry_summer.x > .01 or dry_winter.distance_to(dry_summer) > .01 or dry_winter.y >= winter.y:
		fail("Dry-road grip regressed: summer %s, winter %s" % [dry_summer,dry_winter])
		return
	game.weather.snow = snowy_surface
	game.weather.wet = wet_surface
	print("Dry-road braking is stronger than on snow and neither tyre slides on dry asphalt.")
	if winter.x <= .01 or winter.x >= .65*summer.x or winter.y >= summer.y-.04:
		fail("Winter tyres did not substantially improve cornering and braking: summer %s, winter %s" % [summer,winter])
		return
	game.practice_active = false
	game.ambulance.position = game.STATION_DROP
	game.speed = 0
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	var resume := game.find_child("ResumeCheckpoint",true,false) as Button
	if resume == null:
		fail("Missing saved workshop visit")
		return
	resume.pressed.emit()
	if game.vehicle_index != game.QUATTRO or not game.tyre_service_button.visible or game.tyre_service_button.text != "Fit summer tyres":
		fail("Fitted tyres were lost when resuming")
		return
	game.mode = "menu"
	game._on_vehicle_selected(game.DAM_PICKUP)
	game.start_button.pressed.emit()
	game.ambulance.position = game.STATION_DROP
	game.speed = 0
	game._refresh_status()
	if game.tyre_service_button.text != "Fit winter tyres":
		fail("Quattro's tyre choice leaked onto the pickup")
		return
	game.traffic_data.clear()
	game.weather.snow = snowy_surface
	game.weather.wet = wet_surface
	var pickup_summer_snow := measure_launch(game)
	var pickup_summer_reverse := measure_launch(game, true)
	game.weather.snow = 0.0
	game.weather.wet = 0.0
	var pickup_summer_dry := measure_launch(game)
	game.practice_active = false
	game.ambulance.position = game.STATION_DROP
	game.speed = 0
	game.tyre_service_button.pressed.emit()
	var pickup_winter_dry := measure_launch(game)
	game.weather.snow = snowy_surface
	game.weather.wet = wet_surface
	var pickup_winter_snow := measure_launch(game)
	var pickup_winter_reverse := measure_launch(game, true)
	if not is_equal_approx(pickup_summer_dry, pickup_winter_dry) or pickup_winter_snow <= pickup_summer_snow * 1.2:
		fail("Unexpected pickup start speeds on dry asphalt and snow: %s, %s, %s, %s" % [pickup_summer_dry, pickup_winter_dry, pickup_summer_snow, pickup_winter_snow])
		return
	if pickup_summer_reverse >= -.01 or pickup_winter_reverse >= pickup_summer_reverse * 1.2:
		fail("Pickup did not gain traction while reversing on snow: %s, %s" % [pickup_summer_reverse, pickup_winter_reverse])
		return
	print("Pickup also reverses with stronger traction on winter tyres.")
	print("Pickup starts faster with winter tyres on snow and equally fast with either tyre on dry asphalt.")
	game.practice_active = false
	game.mode = "menu"
	game._on_vehicle_selected(game.QUATTRO)
	game.start_button.pressed.emit()
	game.ambulance.position = game.STATION_DROP
	game.speed = 0
	game.tyre_service_button.pressed.emit()
	if game.VEHICLE_SCENES_ALL[game.QUATTRO] in game.winter_tyre_models:
		fail("Could not change back to summer tyres")
		return
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	resume = game.find_child("ResumeCheckpoint",true,false) as Button
	if resume == null:
		fail("Missing workshop checkpoint after switching to summer tyres")
		return
	resume.pressed.emit()
	if game.vehicle_index != game.QUATTRO or not game.tyre_service_button.visible or game.tyre_service_button.text != "Fit winter tyres":
		fail("The return to summer tyres was lost on restart")
		return
	if game.VEHICLE_SCENES_ALL[game.DAM_PICKUP] not in game.winter_tyre_models:
		fail("Fitting summer tyres to the Quattro changed the saved pickup tyres")
		return
	print("Workshop swaps both ways and retains individual tyre choices on restart. Summer %s, winter %s (slide metres, speed after braking)." % [summer,winter])
	game._finish_quit()

func measure_launch(game, reversing := false) -> float:
	game.practice_active = true
	game.gentle_driving = true
	game.ambulance.transform = Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(-118,0,109))
	game.speed = 0.0
	game.steering = 0.0
	game.snow_slip_angle = 0.0
	game.mouse_steering = 0.0
	game.brake_held = false
	game.mouse_gas = not reversing
	game.mouse_brake = reversing
	for frame in 30:
		game._drive(1.0/60.0)
	game.mouse_gas = false
	game.mouse_brake = false
	game.gentle_driving = false
	return game.speed

func measure_grip(game) -> Vector2:
	game.practice_active = true
	var start := Transform3D(Basis(Vector3.UP,-PI*.5),Vector3(-118,0,109))
	game.ambulance.transform = start
	game.speed = 12.0
	game.steering = 1.0
	game.mouse_gas = true
	game.mouse_brake = false
	game.mouse_steering = 1.0
	game.snow_slip_angle = 0.0
	var slide := 0.0
	for frame in 20:
		var before: Vector3 = game.ambulance.position
		game._drive(1.0/60.0)
		slide += absf((game.ambulance.position-before).dot(game.ambulance.global_basis.x))
	game.ambulance.transform = start
	game.speed = 12.0
	game.steering = 0
	game.snow_slip_angle = 0
	game.mouse_gas = false
	game.mouse_brake = true
	game.mouse_steering = 0
	for frame in 24:
		game._drive(1.0/60.0)
	game.mouse_brake = false
	return Vector2(slide,game.speed)
