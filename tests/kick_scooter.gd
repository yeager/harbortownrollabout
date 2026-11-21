extends SceneTree

func _initialize() -> void:
	call_deferred("check_scooters")

func check_scooters() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game._change_seat()
	game.traffic_data.clear()
	var rider: Node3D = game.walker
	for alma in [false,true]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		rider.position = Vector3(71,game._foot_height(71,0),0)
		rider.rotation.y = PI
		game._toggle_scooter()
		if not game.scooter.is_visible_in_tree() or not rider.is_visible_in_tree():
			printerr("Expected a visible mounted rider")
			quit(1)
			return
		var start := rider.position
		for frame in 60:
			game.scooter.ride(game,1.0,0.0,1.0/60.0)
		if game.scooter.speed < 2 or rider.position.z <= start.z+1:
			printerr("Scooter failed to accelerate")
			quit(1)
			return
		var prior_speed: float = game.scooter.speed
		for frame in 8:
			game.scooter.ride(game,-1.0,0.0,1.0/60.0)
		if game.scooter.speed >= prior_speed or absf(game.scooter.wheels[0].rotation.x) < .01:
			printerr("Brake and wheel motion should respond to rider input")
			quit(1)
			return
		var initial_yaw := rider.rotation.y
		for frame in 12:
			game.scooter.ride(game,1.0,.6,1.0/60.0)
		if absf(angle_difference(initial_yaw,rider.rotation.y)) < .025:
			printerr("Handlebar input failed to steer")
			quit(1)
			return
		for frame in 120:
			game.scooter.ride(game,1.0,0.0,1.0/60.0)
		var front := rider.position - rider.basis.z*.48
		if rider.position.z < 3.0 or not game._feet_supported(front) or game.scooter.speed != 0:
			printerr("Both wheels should stop on the bridge")
			quit(1)
			return
		game._change_seat()
		if game.scooter.visible or absf(rider.position.y-game._foot_height(rider.position.x,rider.position.z))>.001:
			printerr("Dismount should leave the player on safe ground")
			quit(1)
			return
	for item in game.walker_data:
		if item.has("scooter"):
			var start: Vector3 = item.actor.position
			game._update_pedestrians(.2)
			if start.distance_to(item.actor.position) > .1 and item.scooter.is_visible_in_tree():
				print("Both playable riders and the scooter neighbour passed.")
				quit()
				return
	printerr("Missing travelling scooter neighbour")
	quit(1)
