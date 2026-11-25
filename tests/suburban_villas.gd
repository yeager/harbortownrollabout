extends SceneTree

func _initialize() -> void:
	check_villas.call_deferred()

func check_villas() -> void:
	var scene := preload("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	game._start_game()
	game.traffic_data.clear()
	var villas: Node3D = game.suburban_villas
	TranslationServer.set_locale("sv")
	await process_frame
	game.map_button.pressed.emit()
	var stop: Button
	for button: Button in game.get_node("TownMap").find_children("*", "Button", true, false):
		if button.text.ends_with("Villakvarteret"):
			stop = button
			break
	if not stop:
		printerr("Villakvarteret was missing from the Swedish town map")
		quit(1)
		return
	stop.pressed.emit()
	if game.map_goal != villas.MAP_STOP or not game.route_arrows.any(func(arrow): return arrow.visible):
		printerr("Selecting Villakvarteret did not provide directions")
		quit(1)
		return
	game.free()
	game = scene.instantiate()
	root.add_child(game)
	var resume := game.find_child("ResumeCheckpoint", true, false) as Button
	if not resume:
		printerr("Selecting the villa destination did not save a checkpoint")
		quit(1)
		return
	resume.pressed.emit()
	villas = game.suburban_villas
	game.traffic_data.clear()
	if game.map_goal != villas.MAP_STOP or not game.route_arrows.any(func(arrow): return arrow.visible):
		printerr("Villa directions did not return after resuming")
		quit(1)
		return
	# The goal is in the driveway, beyond the pavement.
	game.ambulance.position = villas.MAP_STOP + Vector3.BACK * 3.6
	game.ambulance.rotation.y = 0.0
	game._update_route_arrows()
	if not game.map_goal.is_finite() or not game.route_arrows.any(func(arrow): return arrow.visible):
		printerr("Directions ended at the pavement instead of the driveway")
		quit(1)
		return
	game.map_button.pressed.emit()
	var chart: Control = game.get_node("TownMap").get_child(0).get_child(0)
	if chart.route_preview.size() != 2 or not chart.route_preview[0].is_equal_approx(chart.player):
		printerr("The town map route doubled back at the driveway")
		quit(1)
		return
	game.get_node("TownMap").hide()
	game.ambulance.position = villas.MAP_STOP
	game._update_route_arrows()
	if game.map_goal.is_finite():
		printerr("Directions continued after reaching the villa driveway")
		quit(1)
		return
	game.free()
	game = scene.instantiate()
	root.add_child(game)
	game.find_child("ResumeCheckpoint", true, false).pressed.emit()
	villas = game.suburban_villas
	game.traffic_data.clear()
	if game.map_goal.is_finite() or not game.ambulance.position.is_equal_approx(villas.MAP_STOP):
		printerr("Resuming after arrival should restore the parked position without directions")
		quit(1)
		return
	var driveways := get_nodes_in_group("villa_driveways")
	var parked := get_nodes_in_group("villa_resident_cars")
	var residents := get_nodes_in_group("villa_residents")
	if driveways.size() != 4 or parked.size() != 2 or residents.size() != 2:
		printerr("Expected four villa driveways, two parked cars and two residents")
		quit(1)
		return
	for index in [1, 3]:
		var driveway := driveways[index] as MeshInstance3D
		var bounds := driveway.global_transform * driveway.get_aabb()
		var x := bounds.get_center().x
		game.ambulance.position = Vector3(x, game._surface_height(x, -54.1), -54.1)
		game.ambulance.rotation.y = 0.0
		game.speed = 0.0
		game.mouse_gas = true
		for frame in 220:
			game._drive(1.0 / 60.0)
			if game.ambulance.position.z < bounds.get_center().z:
				break
		if game.ambulance.position.z >= bounds.get_center().z:
			printerr("Could not drive from the street into the free driveway at ", x)
			quit(1)
			return
	for car: Node3D in parked:
		var local_bounds: AABB = game._model_bounds(car, car)
		var bounds := car.global_transform * local_bounds
		var x := bounds.get_center().x
		var start_z := -54.1
		game.ambulance.position = Vector3(x, game._surface_height(x, start_z), start_z)
		game.ambulance.rotation.y = 0.0
		game.speed = 0.0
		for frame in 240:
			game._drive(1.0 / 60.0)
		var bumper: float = game.ambulance.position.z - game.front_reach
		if bumper < bounds.end.z - .03 or bumper > bounds.end.z + .65 or absf(game.speed) > .01:
			printerr("Player vehicle did not stop at the parked car: ", bumper, " vs ", bounds.end.z)
			quit(1)
			return
		var foot := Vector3(x, game._foot_height(x, bounds.get_center().z), bounds.get_center().z)
		if game._on_foot_clear(foot):
			printerr("The player could walk through a parked car")
			quit(1)
			return
	game.mouse_gas = false
	var resident := residents[0] as Node3D
	var start := resident.position
	for frame in 60:
		game._update_pedestrians(1.0 / 60.0)
	if resident.position.distance_to(start) < .50:
		printerr("A resident did not walk along the pavement")
		quit(1)
		return
	game.time_mode = 1
	game.weather.season = 4
	game.weather.snow = .85
	game._update_daylight(0)
	if not villas.winter_trim.visible or villas.flower_heads.visible or villas.bulb_finishes[0].emission_energy_multiplier < 1.5:
		printerr("The gardens did not switch to winter evening decorations")
		quit(1)
		return
	for finish: ShaderMaterial in villas.roof_finishes:
		if not is_equal_approx(float(finish.get_shader_parameter("snow_cover")), .85):
			printerr("A villa roof did not receive snow coverage")
			quit(1)
			return
	game.time_mode = 0
	game.weather.season = 2
	game.weather.snow = 0.0
	game._update_daylight(0)
	if villas.winter_trim.visible or not villas.flower_heads.visible:
		printerr("The gardens did not switch back to summer")
		quit(1)
		return
	print("Four villa driveways, two free approaches, two solid parked cars and both seasonal displays passed.")
	quit()
