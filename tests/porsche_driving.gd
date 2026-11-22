extends SceneTree
## Run with godot --headless --script res://tests/porsche_driving.gd

func _initialize() -> void:
	call_deferred("check_porsche")

func measure_car(game, vehicle: int, gentle: bool) -> Vector2:
	game.paused = true
	game._on_vehicle_selected(vehicle)
	game.paused = false
	game.gentle_driving = gentle
	game.ambulance.position = Vector3(-490, 0, -45.8)
	game.ambulance.rotation.y = -PI * 0.5
	game.mouse_gas = true
	var after_one_second := 0.0
	var peak := 0.0
	for frame in 360:
		# Measure the powertrain on a clear section, away from junctions.
		game.ambulance.position = Vector3(-490, 0, -45.8)
		game._drive(1.0 / 60.0)
		peak = maxf(peak, game.speed)
		if frame == 59:
			after_one_second = game.speed
	return Vector2(after_one_second, peak)

func check_porsche() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	var porsche: int = game.PORSCHE
	if porsche < 0:
		printerr("Porsche missing from vehicle selector")
		quit(1)
		return
	for gentle in [true, false]:
		var taxi := measure_car(game, game.TAXI, gentle)
		var sports := measure_car(game, porsche, gentle)
		print("Gentle ", gentle, " | taxi and GT3 RS at 1 s and maximum (m/s): ", taxi, " ", sports)
		if taxi.x <= 0 or not is_equal_approx(sports.x, taxi.x * 3) or not is_equal_approx(sports.y, taxi.y * 3):
			printerr("Expected rapid acceleration and three times the ordinary top speed")
			quit(1)
			return
	if game.player_wheels.size() != 4 or not game.player_brake_lens:
		printerr("Porsche wheel or brake-light rig missing")
		quit(1)
		return
	for time in [1, 0]:
		game.time_mode = time
		game._update_daylight(0)
		var lenses = game.vehicle_model.find_children("Headlight lens*", "MeshInstance3D", true, false)
		if lenses.size() != 2 or game.headlights.size() != 2:
			printerr("Expected two projector headlights")
			quit(1)
			return
		for i in lenses.size():
			var lens = lenses[i]
			var beam = game.headlights[i]
			var origin = lens.to_global(lens.get_aabb().get_center())
			var night: bool = time == 1
			if beam.global_position.distance_to(origin) > .05 or beam.visible != night or (lens.get_active_material(0).emission_energy_multiplier > 0) != night:
				printerr("Headlight lens and beam did not match the selected time of day")
				quit(1)
				return
	game.mouse_gas = false
	game.mouse_brake = true
	for frame in 360:
		game._drive(1.0 / 60.0)
	if not game.reverse_lens or game.reverse_lens.emission_energy_multiplier != 0 or game.player_brake_lens.emission_energy_multiplier < 2:
		printerr("Expected red brake lights and unlit reversing lights at a braked stop")
		quit(1)
		return
	game.mouse_brake = false
	game._drive(1.0 / 60.0)
	Input.action_press("ui_down")
	game._drive(1.0 / 60.0)
	Input.action_release("ui_down")
	if game.speed >= 0 or game.reverse_lens.emission_energy_multiplier < 1:
		printerr("Expected white reversing lights while backing up")
		quit(1)
		return
	game.mouse_brake = true
	game._drive(1.0 / 60.0)
	game._change_seat()
	if not game.walker.visible or not game.parked_cars[porsche].visible:
		printerr("Could not park and leave the GT3 RS")
		quit(1)
		return
	game._change_seat()
	if game.vehicle_index != porsche or game.walker.visible:
		printerr("Could not re-enter the GT3 RS")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await process_frame
	quit()
