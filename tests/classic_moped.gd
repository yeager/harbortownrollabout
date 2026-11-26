extends SceneTree

func _initialize() -> void:
	call_deferred("check_dakota")

func check_dakota() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var index: int = game.PUCH_DAKOTA
	if game.vehicle_selector.get_child(index).text != "Pusch Dakotta":
		printerr("Missing Pusch Dakotta from the vehicle selector")
		quit(1)
		return
	for choose_alma in [false,true]:
		game.mode = "menu"
		game.play_as_alma = choose_alma
		game._apply_player_appearance()
		game.vehicle_selector.get_child(index).pressed.emit()
		game._start_game()
		game.ambulance.position = Vector3(-389,game._surface_height(-389,2.35),2.35)
		var start: Vector3 = game.ambulance.position
		var model: Node3D = game.vehicle_model
		if not game.moped_pose.is_visible_in_tree() or game.road_driver.get_node("AlmaPortrait").visible != choose_alma or game.player_wheels.size() != 2:
			printerr("Expected the chosen character and two working wheels")
			quit(1)
			return
		for i in 2:
			var suffix := "Left" if i == 0 else "Right"
			var grip: Node3D = model.find_child("Grip"+suffix,true,false)
			var hand: MeshInstance3D = game.moped_pose.hands[i]
			if hand.global_position.distance_to(grip.global_position) > .005 or (game.road_driver.to_local(hand.global_position).x < 0) != (i == 0):
				printerr("Rider's hand is on the wrong grip")
				quit(1)
				return
		game.mouse_gas = true
		for frame in 45:
			game._drive(1.0/60)
		game.mouse_gas = false
		if not is_instance_valid(game.moped_speed_needle) or not is_equal_approx(game.moped_speed_needle.rotation.y, deg_to_rad(-252.0) * game.speed * 3.6 / 40.0):
			printerr("Speedometer did not follow the moped speed")
			quit(1)
			return
		if game.speed < 1 or start.distance_to(game.ambulance.position) < .35 or absf(game.player_wheels[0].rotation.x) < .05:
			printerr("Dakota did not move with visible wheel rotation")
			quit(1)
			return
		var straight: float = game.ambulance.rotation.y
		Input.action_press("ui_right")
		game.mouse_gas = true
		for frame in 18:
			game._drive(1.0/60)
		Input.action_release("ui_right")
		game.mouse_gas = false
		if absf(angle_difference(straight, game.ambulance.rotation.y)) < .01:
			printerr("The rider cannot steer the Dakota")
			quit(1)
			return
		game.mouse_brake = true
		for frame in 30:
			game._drive(1.0/60)
		if not is_zero_approx(game.speed) or not is_zero_approx(game.moped_speed_needle.rotation.y):
			printerr("Dakota failed to stop while braking")
			quit(1)
			return
		var stopped_at: Vector3 = game.ambulance.position
		for frame in 15:
			game._drive(1.0/60)
		if not stopped_at.is_equal_approx(game.ambulance.position):
			printerr("Holding the brake moved the stopped Dakota")
			quit(1)
			return
		game.mouse_brake = false
		game._change_seat()
		if not game.walker.visible or not game.parked_cars[index].visible or game.road_driver.is_visible_in_tree():
			printerr("Dismount did not leave a parked moped")
			quit(1)
			return
		game._change_seat()
		if game.walker.visible or game.vehicle_index != index or not game.road_driver.is_visible_in_tree():
			printerr("Could not remount the parked moped")
			quit(1)
			return
	game.mode = "menu"
	game._on_vehicle_selected(0)
	game._start_game()
	game._change_seat()
	var parked_moped: Node3D = game.parked_cars[index]
	var approach := parked_moped.to_global(Vector3(.85,0,-.12))
	game.walker.position = Vector3(approach.x, game._foot_height(approach.x,approach.z), approach.z)
	game._change_seat()
	if game.vehicle_index != index or game.walker.visible or parked_moped.visible:
		printerr("The moped could not be picked up from its depot bay")
		quit(1)
		return
	for item in game.traffic_data:
		if item.has("rider"):
			var start: Vector3 = item.actor.position
			var pose: Node3D = item.rider.find_child("Helmet",true,false)
			game._update_traffic(.12)
			if pose and pose.is_visible_in_tree() and item.wheels.size() == 2 and start.distance_to(item.actor.position) > .1:
				print("Pusch Dakotta menu, Axel, Alma, grips, depot, brakes, wheels and NPC passed")
				game._finish_quit()
				return
	printerr("Missing moving Dakota with seated NPC rider")
	quit(1)
