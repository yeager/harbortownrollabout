extends SceneTree

func _initialize() -> void:
	call_deferred("check_response")

func check_response() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.ambulance.hide()
	game.traffic_data.clear()
	for parked: Node3D in game.parked_cars:
		parked.hide()
	game._spawn_traffic(game.VEHICLE_SCENES_ALL[game.QUATTRO], -36, 2.35, 1, 5.0)
	var civilian: Dictionary = game.traffic_data.back()
	game._spawn_emergency_traffic(0, -50, 2.35, 1)
	var ambulance: Dictionary = game.traffic_data.back()
	var route := Curve3D.new()
	route.add_point(Vector3(-58, 0, 2.35))
	route.add_point(Vector3(40, 0, 2.35))
	for item: Dictionary in [civilian, ambulance]:
		item.route = route
		item.distance = item.actor.position.x + 58.0
		game._place_traffic(item)
	game.street_signals.phase = 3
	var moved_aside := false
	var passed := false
	for tick in 200:
		game._update_traffic(.05)
		moved_aside = moved_aside or float(civilian.get("yield_offset", 0.0)) > 1.5
		if game._traffic_bounds(civilian).intersects(game._traffic_bounds(ambulance)):
			printerr("Civilian and responding ambulance overlapped")
			quit(1)
			return
		if ambulance.actor.position.x > 5:
			passed = true
			break
	if not moved_aside or not passed or civilian.actor.position.x + civilian.length > -game.street_signals.BOULEVARD_STOP_DISTANCE + .01:
		printerr("Traffic did not yield, the ambulance stopped at red, or the civilian crossed red: ",
			civilian.actor.position, " / ", ambulance.actor.position)
		quit(1)
		return
	print("A civilian pulled over for a responding ambulance, which passed the red light without contact.")
	game.traffic_data.clear()
	game.ambulance.show()
	game.ambulance.position = Vector3(-30, 0, 2.35)
	game.ambulance.basis = Basis.looking_at(Vector3.RIGHT)
	game.allow_red_lights = false
	game.sound_on = false
	game.lights_on = true
	game.mouse_gas = true
	game.speed = 0.0
	for tick in 130:
		game._drive(.05)
		if game.ambulance.position.x > 5.0:
			break
	if game.ambulance.position.x <= 5.0 or game.message == "Red light! Stop at the line and wait for green.":
		printerr("The player ambulance could not use its blue lights to cross red")
		quit(1)
		return
	print("The player ambulance also passed the red light with blue lights and no siren.")
	quit()
