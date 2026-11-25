extends SceneTree

func _initialize() -> void:
	call_deferred("check_rounds")

func check_rounds() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.free_drive = true
	var map_key := InputEventKey.new()
	map_key.keycode = KEY_F5
	map_key.pressed = true
	game._unhandled_key_input(map_key)
	var dialog = game.find_child("TownMap",true,false)
	if not dialog.visible or not game.paused:
		printerr("Map shortcut did not open the town map and pause play")
		quit(1)
		return
	var court_pin: Button
	for button in dialog.find_children("*","Button",true,false):
		if button.tooltip_text == game.tr("Boule court"):
			court_pin = button
			break
	if not court_pin:
		printerr("Court missing from town map")
		quit(1)
		return
	var chart_node := court_pin.get_parent()
	var pins := chart_node.get_children().filter(func(child): return child is Button)
	for pin: Button in pins:
		for other: Button in pins:
			if pin != other and pin.get_rect().intersects(other.get_rect()):
				printerr("Overlapping map destinations: ", pin.text, " and ", other.text)
				quit(1)
				return
	court_pin.pressed.emit()
	var court_goal: Vector3 = game.map_goal
	var map_binding := game.find_child("MapF11", true, false) as CheckButton
	for alternate in [false, true]:
		map_binding.button_pressed = alternate
		map_key.keycode = KEY_F11 if alternate else KEY_F5
		map_key.alt_pressed = true
		game._unhandled_key_input(map_key)
		if dialog.visible or game.paused:
			printerr("A modified shortcut opened the town map")
			quit(1)
			return
		map_key.alt_pressed = false
		game._unhandled_key_input(map_key)
		if not dialog.visible or not game.paused:
			printerr("Configured shortcut failed to open the town map")
			quit(1)
			return
		map_key.alt_pressed = true
		dialog.window_input.emit(map_key)
		if not dialog.visible or not game.paused:
			printerr("A modified shortcut closed the town map")
			quit(1)
			return
		map_key.alt_pressed = false
		dialog.window_input.emit(map_key)
		if dialog.visible or game.paused or game.map_goal != court_goal:
			printerr("Closing the town map did not preserve the route and resume play")
			quit(1)
			return
	for first_key in [KEY_1, KEY_KP_1]:
		for index in [9, 0, 1, 2, 3, 4, 5, 6, 7, 8]:
			game.map_button.pressed.emit()
			var number := InputEventKey.new()
			number.keycode = first_key - 1 if index == 9 else first_key + index
			number.pressed = true
			dialog.window_input.emit(number)
			var chart = court_pin.get_parent()
			if dialog.visible or game.paused or game.map_goal != chart.stops[index]:
				printerr("Number key selected the wrong map destination: ", number.keycode)
				quit(1)
				return
	if game.map_goal != game.shops.pizzeria_entrance():
		printerr("Destination 9 should lead to the pizzeria")
		quit(1)
		return
	game.ambulance.position = game.map_goal + Vector3.FORWARD * 3
	game._update_route_arrows()
	if game.map_goal == Vector3.INF:
		printerr("Parking cleared the pizzeria destination")
		quit(1)
		return
	game.walker.show()
	game.walker.position = game.map_goal + Vector3.FORWARD * 1.8
	game._update_route_arrows()
	var arrow = game.route_arrows[0]
	if not arrow.visible or not is_equal_approx(arrow.position.x, game.map_goal.x) or arrow.position.z <= game.walker.position.z or arrow.position.z >= game.map_goal.z:
		printerr("Final walking arrow should point through the pizzeria doorway")
		quit(1)
		return
	game.walker.position = game.map_goal
	game.shops.update_customer(true,game.walker.position,true)
	game._update_route_arrows()
	if game.map_goal != Vector3.INF or game.shops.inside != 2:
		printerr("Entering the pizzeria should finish the walking route")
		quit(1)
		return
	game.walker.hide()
	game.shops.update_customer(false,game.walker.position,true)
	game.map_button.pressed.emit()
	court_pin.pressed.emit()
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if game.map_goal != game.BOULE_BENCH_APPROACH:
		printerr("Court destination lost after resume: ",game.map_goal)
		quit(1)
		return
	game.map_button.pressed.emit()
	dialog = game.find_child("TownMap",true,false)
	var selected := 0
	for button in dialog.find_children("*","Button",true,false):
		if button.button_pressed:
			if button.tooltip_text != game.tr("Boule court") and not button.text.ends_with(game.tr("Boule court")):
				printerr("Wrong destination highlighted")
				quit(1)
				return
			selected += 1
	if selected != 2:
		printerr("Expected the saved destination on the map and in the legend")
		quit(1)
		return
	map_key.echo = true
	dialog.window_input.emit(map_key)
	if not dialog.visible:
		printerr("Holding F5 closed the map")
		quit(1)
		return
	map_key.echo = false
	dialog.window_input.emit(map_key)
	if dialog.visible or game.paused or game.map_goal != game.BOULE_BENCH_APPROACH:
		printerr("Closing the map with F5 should resume the selected route")
		quit(1)
		return
	game.ambulance.position = game.map_goal + Vector3.LEFT * 4
	game._update_route_arrows()
	if game.map_goal == Vector3.INF:
		printerr("Parking near the court cleared the walking destination")
		quit(1)
		return
	game.walker.show()
	game.walker.position = game.map_goal + Vector3.LEFT * 1.5
	game._update_route_arrows()
	if game.map_goal == Vector3.INF or not game.route_arrows.any(func(arrow): return arrow.visible):
		printerr("Directions ended before the spectator could sit down")
		quit(1)
		return
	game.walker.position = game.BOULE_BENCH_APPROACH
	game._update_route_arrows()
	if not game._at_boule_bench() or game.map_goal != Vector3.INF:
		printerr("The bench should be usable when directions end")
		quit(1)
		return
	var gait: RefCounted
	for alma in [false, true]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		game._set_boule_seated(true)
		gait = game.walker.get_meta("gait")
		if gait.legs[0].rotation.x < .9:
			printerr("The avatar did not sit on the bench")
			quit(1)
			return
		for shoe: Node3D in gait.shoes:
			var sole := shoe.to_global(Vector3.DOWN * gait.SOLE_HEIGHT)
			if absf(sole.y - game._foot_height(sole.x, sole.z)) > .004:
				printerr("A seated foot did not rest on the ground: ", sole, " ground=", game._foot_height(sole.x, sole.z), " hip=", gait.legs[0].global_position)
				quit(1)
				return
	game._recover_position()
	if game.boule_seated or absf(gait.legs[0].rotation.x) > .20:
		printerr("Recovery left the avatar in the seated pose")
		quit(1)
		return
	for step: float in [1.0/60.0, 0.1]:
		var throws: Array[int] = []
		var pickups: Array[int] = []
		var saw_result := false
		for frame in ceili(70.0/step):
			var before: Array = game.boule_grounded.duplicate()
			game._update_boule(step)
			for i in before.size():
				if before[i] != game.boule_grounded[i]:
					if before[i]: pickups.append(i)
					else: throws.append(i)
			if game.boule_result_rings.any(func(ring): return ring.visible):
				if not game.boule_grounded.all(func(grounded): return grounded):
					printerr("Result shown before all three throws settled")
					quit(1)
					return
				saw_result = true
			if pickups.size() == 3 and game.boule_collector == -1: break
		if throws != [0,1,2] or pickups != throws or not saw_result or game.boule_turn != 0 or game.boule_collector != -1:
			printerr("Incomplete round: throws ",throws,", pickups ",pickups)
			quit(1)
			return
		for i in game.boules.size():
			var person: Node3D = game.boule_players[i]
			var hand: Node3D = person.get_meta("gait").palms[1]
			if person.position.distance_to(game._boule_waiting_spot(i)) > .01 or game.boules[i].position.distance_to(hand.to_global(game.PALM_GRIP)) > .01 or game.boule_result_rings[i].visible:
				printerr("Player ",i," did not return holding the ball")
				quit(1)
				return
	print("Two successive boule rounds completed at different frame rates.")
	game._finish_quit(false)
