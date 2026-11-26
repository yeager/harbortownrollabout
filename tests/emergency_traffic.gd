extends SceneTree

func _initialize() -> void:
	call_deferred("check_response")

func check_response() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.set_process(false)
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
	game.emergency_traffic.clear()
	game.vehicle_index = game.A_TRACTOR
	game._load_vehicle_model()
	game.ambulance.position = Vector3(-80,0,2.35)
	game.gentle_driving = false
	game.speed = 0.0
	for tick in 85:
		game._drive(.05)
		if game.speed > 30.0 / 3.6 + .001:
			printerr("A-tractor exceeded 30 km/h")
			quit(1)
			return
	if game.speed < 8.25:
		printerr("A-tractor did not reach its speed limit: ", game.speed)
		quit(1)
		return

	game.vehicle_index = game.QUATTRO
	game._load_vehicle_model()
	game.mouse_gas = false
	game.speed = 0.0
	var stop_x: float = -game.street_signals.BOULEVARD_STOP_DISTANCE - game.front_reach - .10
	game.ambulance.position = Vector3(stop_x,0,2.35)
	game._spawn_traffic(game.VEHICLE_SCENES_ALL[game.QUATTRO],stop_x-7,2.35,1,5.0)
	var follower: Dictionary = game.traffic_data.back()
	follower.route = route
	follower.distance = follower.actor.position.x + 58.0
	game._place_traffic(follower)
	game.street_signals.phase = 3
	game._update_traffic(.1)
	if not game.waited_at_red or follower.horn_wait > 0.0:
		printerr("A driver waiting legally at red was honked at")
		quit(1)
		return
	game.street_signals.phase = 0
	game.waiting_for_clear_crossing = true
	for tick in 24:
		game._update_traffic(.1)
	if follower.horn_wait > 0.0 or follower.horn.playing:
		printerr("Following car honked while the crossing was blocked")
		quit(1)
		return
	game.waiting_for_clear_crossing = false
	game.police_stop_left = 3.0
	for tick in 24:
		game._update_traffic(.1)
	if follower.horn_wait > 0.0 or follower.horn.playing:
		printerr("Following car honked during a police stop")
		quit(1)
		return
	game.police_stop_left = 0.0
	var honks := 0
	for tick in 48:
		var before: float = follower.horn_wait
		game._update_traffic(.1)
		if before > 0.0 and follower.horn_wait == 0.0:
			honks += 1
	if honks < 2:
		printerr("Following car did not repeat its green-light horn: ", honks)
		quit(1)
		return
	game.speed = 1.0
	game._update_traffic(.1)
	if follower.horn_wait > 0.0 or follower.horn.playing or game.waiting_after_green:
		printerr("Green-light horn persisted after moving")
		quit(1)
		return

	game.vehicle_index = game.A_TRACTOR
	game._load_vehicle_model()
	game.ambulance.position = Vector3(-game.street_signals.BOULEVARD_STOP_DISTANCE - game.front_reach - .10,0,2.35)
	game.street_signals.phase = 3
	game.speed = 0.0
	for tick in 24:
		game._update_traffic(.1)
	if follower.horn_wait != 0.0 or follower.horn.playing:
		printerr("Following car honked at an A-tractor waiting on red")
		quit(1)
		return
	game.speed = 2.0
	game.street_signals.phase = 0
	game._update_traffic(.1)
	if follower.horn_wait <= 0.0:
		printerr("Following car did not react to the slow player A-tractor")
		quit(1)
		return

	game.traffic_data.clear()
	game.vehicle_index = game.QUATTRO
	game._load_vehicle_model()
	game._spawn_emergency_traffic(1,-18,-2.35,-1)
	var police: Dictionary = game.traffic_data.back()
	game.street_signals.phase = 3
	game.ambulance.position = Vector3(stop_x,0,2.35)
	game.allow_red_lights = true
	game.mouse_gas = true
	game.speed = 5.0
	game._drive(.1)
	var stopped_at: Vector3 = game.ambulance.position
	if game.police_stop_left <= 0.0 or game.speed != 0.0 or not police.horn.playing:
		printerr("Nearby police did not stop a red-light runner")
		quit(1)
		return
	game._drive(.1)
	if game.ambulance.position != stopped_at:
		printerr("Player could drive during the police stop")
		quit(1)
		return
	game.street_signals.phase = 0
	game._drive(.1)
	if game.police_stop_left != 0.0 or game.ambulance.position.x <= stopped_at.x:
		printerr("Player remained stopped when the light turned green")
		quit(1)
		return
	# A distant patrol cannot enforce a stop at this junction.
	police.actor.position = Vector3(-90,0,-2.35)
	game.street_signals.phase = 3
	game.ambulance.position = Vector3(stop_x,0,2.35)
	game.speed = 5.0
	game.message = ""
	game._drive(.1)
	if game.police_stop_left > 0.0 or game.ambulance.position.x <= stopped_at.x or game.message != "Red light! Stop at the line and wait for green.":
		printerr("A distant patrol intervened, or the red-light warning was missing")
		quit(1)
		return

	police.actor.position = Vector3(-18,0,-2.35)
	game.street_signals.phase = 1
	game.ambulance.position = Vector3(stop_x,0,2.35)
	game.speed = 5.0
	game.message = ""
	game._drive(.1)
	if game.police_stop_left > 0.0 or game.ambulance.position.x <= stopped_at.x or not game.message.is_empty():
		printerr("An amber signal triggered red-light enforcement")
		quit(1)
		return
	print("A-tractor speed, repeated horn at green and nearby police stop verified.")
	quit()
