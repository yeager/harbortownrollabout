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
		# The center is on the bridge but the leading wheel is over the water.
		rider.position = Vector3(71,game._foot_height(71,5.1),5.1)
		rider.rotation.y = PI
		var edge_pose := rider.transform
		if not game._feet_supported(rider.position):
			printerr("Expected supported feet at bridge edge")
			quit(1)
			return
		game._toggle_scooter()
		if game.scooter.visible or not rider.transform.is_equal_approx(edge_pose):
			printerr("Scooter unfolded with an unsupported front wheel")
			quit(1)
			return
		rider.position = Vector3(71,game._foot_height(71,0),0)
		rider.rotation.y = PI
		game._toggle_scooter()
		if not game.scooter.is_visible_in_tree() or not rider.is_visible_in_tree():
			printerr("Expected a visible mounted rider")
			quit(1)
			return
		if not grips_aligned(rider, game.scooter):
			quit(1)
			return
		var saved_pose := rider.transform
		game._save_checkpoint()
		game.queue_free()
		await process_frame
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		game.traffic_data.clear()
		rider = game.walker
		if not game.scooter.visible or not rider.transform.is_equal_approx(saved_pose) or not grips_aligned(rider, game.scooter):
			printerr("Mounted rider or deck height lost after restart")
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
		if game.scooter.turn_signals.direction != 1 or not game.scooter.turn_signals.right[0].visible:
			printerr("The scooter did not signal right while turning")
			quit(1)
			return
		for frame in 120:
			game.scooter.ride(game,1.0,0.0,1.0/60.0)
		if game.scooter.turn_signals.direction != 0:
			printerr("The scooter did not cancel its indicator after the turn")
			quit(1)
			return
		var front := rider.position - rider.basis.z*.48
		if rider.position.z < 3.0 or not game._feet_supported(front) or game.scooter.speed != 0:
			printerr("Both wheels should stop on the bridge")
			quit(1)
			return
		game.roadside_solids.append(AABB(Vector3(19,-1,5.8),Vector3(2,4,2)))
		game.scooter.speed = 3
		game.scooter.yaw_input = .5
		game._recover_position()
		game.roadside_solids.pop_back()
		var recovered := rider.position
		var alternate := Vector2(recovered.x, recovered.z)
		if alternate.distance_to(Vector2(-23,-6.8)) > .01 and alternate.distance_to(Vector2(90,-24)) > .01:
			printerr("Mounted recovery must select a free alternate landing")
			quit(1)
			return
		game.scooter.ride(game,0,0,1.0/60.0)
		if not game.scooter.visible or game.scooter.speed != 0 or game.scooter.yaw_input != 0 or not rider.position.is_equal_approx(recovered):
			printerr("Mounted recovery must leave the rider stationary at deck height")
			quit(1)
			return
		for tick in 39:
			game._process(.1)
		if game.status_label.text != "Back in a safe place.":
			printerr("Recovery confirmation disappeared before four seconds")
			quit(1)
			return
		game._process(.11)
		if game.status_label.text != game.tr("Electric scooter · %d km/h") % 0:
			printerr("Scooter speed did not return after the recovery confirmation")
			quit(1)
			return
		game._change_seat()
		if game.scooter.visible or absf(rider.position.y-game._foot_height(rider.position.x,rider.position.z))>.001:
			printerr("Dismount should leave the player on safe ground")
			quit(1)
			return
		var limbs: Array = rider.get_meta("legs") + rider.get_meta("arms")
		for i in limbs.size():
			if not limbs[i].transform.is_equal_approx(game.scooter.stance[i]):
				printerr("Dismount failed to restore the standing pose")
				quit(1)
				return
	for item in game.walker_data:
		if item.has("scooter"):
			var start: Vector3 = item.actor.position
			game._update_pedestrians(.2)
			if start.distance_to(item.actor.position) > .1 and item.scooter.is_visible_in_tree():
				if not grips_aligned(item.actor, item.scooter):
					quit(1)
					return
				print("Both playable riders and the scooter neighbour passed.")
				game._finish_quit()
				return
	printerr("Missing travelling scooter neighbour")
	quit(1)

func grips_aligned(rider: Node3D, scooter: Node3D) -> bool:
	var handles := scooter.find_children("Handle grip*", "MeshInstance3D", true, false)
	if handles.size() != 2:
		printerr("Expected two handlebar grips in the scooter model")
		return false
	for grip: MeshInstance3D in handles:
		var centre := grip.to_global(grip.get_aabb().get_center())
		var side := 0 if rider.to_local(centre).x < 0 else 1
		var palm: Node3D = rider.get_meta("gait").palms[side]
		if palm.global_position.distance_to(centre) > .005:
			printerr("Scooter rider missed handlebar grip ", grip.name)
			return false
	return true
