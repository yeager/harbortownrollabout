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
	court_pin.pressed.emit()
	for first_key in [KEY_1, KEY_KP_1]:
		for index in game.MAP_NAMES.size():
			game.map_button.pressed.emit()
			var number := InputEventKey.new()
			number.keycode = first_key + index
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
	quit()
