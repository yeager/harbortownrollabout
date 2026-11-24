extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var start := Transform3D(Basis(Vector3.UP,-PI*.5), Vector3(-118,0,109))
	for index in [game.QUATTRO, game.DAM_PICKUP, game.BUS]:
		game.mode = "menu"
		game._on_vehicle_selected(index)
		game.start_button.pressed.emit()
		game.set_process(false)
		game.free_drive = true
		game.gentle_driving = false
		game.allow_red_lights = true
		game.traffic_data.clear()
		game.practice_active = true
		for steering in [-1.0,1.0]:
			if not check_corner(game,start,steering):
				return
	game.practice_active = false
	game.ambulance.position = Vector3(48,game._surface_height(48,-14),-14)
	game.ambulance.rotation.y = -PI*.5
	game.speed = 12.0
	game.mouse_steering = .7
	game.snow_slip_angle = .25
	for frame in 60:
		game._drive(1.0/60.0)
		for span: Vector2 in game.OPEN_WATER:
			if game._shore_overlap(span,game.ambulance.position,game._player_extent()) > .01:
				printerr("Snow slide entered the canal")
				quit(1)
				return
	game.ambulance.position = Vector3(-110,game._surface_height(-110,0),0)
	game.ambulance.rotation.y = -PI*.5
	var parked: Transform3D = game.ambulance.global_transform
	var plough_start := Transform3D(Basis.IDENTITY, parked.origin + Vector3(-9,0,-.3))
	var plough_end := Transform3D(Basis.IDENTITY, parked.origin + Vector3(-9,0,.3))
	game.ground_work.sweep(plough_start,plough_end,Vector3.ZERO,Vector3(18,0,0),false)
	if not is_equal_approx(game._road_coverage().x,1.0):
		printerr("Clearing the middle of the lane affected tyres still on snow")
		quit(1)
		return
	plough_start.origin.z = -3.0
	plough_end.origin.z = 3.0
	game.ground_work.sweep(plough_start,plough_end,Vector3.ZERO,Vector3(18,0,0),false)
	if not is_zero_approx(game._road_coverage().x):
		printerr("Vehicle still detected snow with all tyres on the cleared strip")
		quit(1)
		return
	game.speed = 12.0
	game.steering = .9
	game.mouse_steering = .9
	game.snow_slip_angle = 0.0
	game._drive(1.0/60.0)
	if not is_zero_approx(game.snow_slip_angle):
		printerr("Vehicle slid on cleared road")
		quit(1)
		return
	print("Ploughed road regains grip once all tyres are over the cleared surface.")
	print("Dry and slow remain stable. Fast cornering slides on snow, draws tyre tracks and regains grip. Verified on Quattro, pickup and bus in both turning directions. The bus stayed out of the canal.")
	game._finish_quit()

func check_corner(game, start: Transform3D, steering: float) -> bool:
	for condition: Vector2 in [Vector2(0,12),Vector2(1,4),Vector2(1,12)]:
		game.ambulance.transform = start
		game.weather.snow = condition.x
		game.speed = condition.y
		game.steering = steering
		game.mouse_gas = true
		game.mouse_steering = steering
		game.snow_slip_angle = 0.0
		game.snow_marks.visible_instance_count = 0
		game.snow_cursor = 0
		game._end_skid()
		var outside_motion := 0.0
		for frame in 20:
			var previous: Vector3 = game.ambulance.position
			game._drive(1.0/60.0)
			var step: Vector3 = game.ambulance.position - previous
			outside_motion -= steering*step.dot(game.ambulance.global_basis.x)
		var expects_slide := condition == Vector2(1,12)
		if (expects_slide and outside_motion <= .1) or (not expects_slide and absf(outside_motion) > .01):
			printerr(game.VEHICLE_NAMES_ALL[game.vehicle_index], " unexpected sideways motion for ",condition, " turn ", steering, ": ",outside_motion)
			quit(1)
			return false
		if expects_slide and game.snow_marks.visible_instance_count == 0:
			printerr(game.VEHICLE_NAMES_ALL[game.vehicle_index], " left no skid marks on snow")
			quit(1)
			return false
	game.mouse_steering = 0.0
	for frame in 65:
		game._drive(1.0/60.0)
	if absf(game.snow_slip_angle) > .01:
		printerr(game.VEHICLE_NAMES_ALL[game.vehicle_index], " did not recover grip")
		quit(1)
		return false
	return true
