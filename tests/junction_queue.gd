extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func fail(reason: String) -> void:
	printerr(reason)
	quit(1)

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.TAXI)
	game._start_game()
	game.set_process(false)
	var line: float = game.street_signals.BOULEVARD_STOP_DISTANCE
	game.street_signals.phase = 0
	game.traffic_data.clear()
	var blocker: Node3D = game._spawn_traffic("res://vehicles/traffic_suv_blue.glb", 18.5, 2.35, 1.0, 0.0)
	var queue: Dictionary = game.traffic_data[0]
	var start := Vector3(-27, -.02, 2.35)
	game.ambulance.position = start
	game.ambulance.rotation.y = -PI / 2
	game.speed = 6.0
	game.mouse_gas = true
	for tick in 100:
		game._drive(.05)
	var front: float = game.ambulance.position.x + game.front_reach
	if front > -line or front < -line - .45 or absf(game.speed) > .05 or not game.waiting_for_clear_crossing:
		fail("Player did not wait outside a junction blocked on green: %f" % front)
		return
	blocker.position.x = 39.0
	game.street_signals.phase = 3
	for tick in 60:
		game._drive(.05)
	if game.ambulance.position.x + game.front_reach > -line or absf(game.speed) > .05:
		fail("Player entered on red when the outlet cleared")
		return
	game.street_signals.phase = 0
	for tick in 160:
		game._drive(.05)
	if game.ambulance.position.x <= line:
		fail("Player did not proceed when the exit opened: %s, speed %s" % [game.ambulance.position, game.speed])
		return

	game.ambulance.hide()
	blocker.position.x = 18.5
	var follower: Node3D = game._spawn_traffic("res://vehicles/traffic_suv_blue.glb", start.x, start.z, 1.0, 6.0)
	var follower_data: Dictionary = game.traffic_data[1]
	var path := Curve3D.new()
	path.add_point(start)
	path.add_point(Vector3(43, -.02, 2.35))
	follower_data.route = path
	follower_data.distance = 0.0
	queue.route = path
	queue.distance = start.distance_to(blocker.position)
	game._place_traffic(follower_data)
	game._place_traffic(queue)
	for tick in 160:
		game._update_traffic(.05)
	front = follower.position.x + float(follower_data.length)
	if front > -line or front < -line - .65 or float(follower_data.speed) > .05:
		fail("Ambient traffic did not wait outside the blocked junction: %f, speed %f" % [front, follower_data.speed])
		return
	queue.distance = 66.0
	game._place_traffic(queue)
	for tick in 160:
		game._update_traffic(.05)
	if follower.position.x <= line:
		fail("Ambient traffic stayed stopped when the exit opened")
		return

	# This eastbound route turns onto the southbound leg, where the queue sits.
	var corner := Curve3D.new()
	corner.add_point(Vector3(-23, 0, 2.35))
	corner.add_point(Vector3(-2.35, 0, 2.35))
	corner.add_point(Vector3(-2.35, 0, 30))
	var exit_obstacles: Array[AABB] = [AABB(Vector3(-3.15, -1, 10), Vector3(1.6, 3, 4))]
	var right := Vector3.RIGHT
	var lights = game.street_signals
	if is_inf(lights.junction_queue_gap(corner.get_point_position(0), right, 2.0, 4.0, .9, exit_obstacles, corner)):
		fail("A turning route did not check the street it joins")
		return
	if not is_inf(lights.junction_queue_gap(corner.get_point_position(0), right, 2.0, 4.0, .9, exit_obstacles)):
		fail("A side street queue also blocked the unobstructed straight lane")
		return
	print("Player, ambient traffic and turning route kept the junction clear until their exits opened.")
	quit()
