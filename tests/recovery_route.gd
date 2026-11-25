extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	# This pedestrian reaches the station driveway during the second delivery.
	seed(2)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.RECOVERY)
	game.gentle_driving = true
	game.allow_crashes = true
	game.allow_red_lights = false
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var starting_balance: int = game.wallet
	var starting_points: int = game.delivery_points
	for leg in 4:
		var loading := leg % 2 == 0
		if game.bonnet_smoke.emitting != (leg == 0) or game.loose_wheel.visible != (leg == 2):
			printerr("Wrong breakdown at leg ", leg)
			quit(1)
			return
		if not loading and (game.casualty.get_parent() != game.ambulance or game.SERVICE_STOPS[leg] != game.STATION_DROP):
			printerr("Tow truck must carry its load to the station")
			quit(1)
			return
		if loading:
			game.ambulance.position = game._mission_destination()
			game.ambulance.basis = Basis.looking_at(Vector3.RIGHT if leg == 0 else Vector3.LEFT)
			game.speed = 2
			game._update_arrival(game.HELP_DURATION)
			if game.recovery_leg != leg:
				printerr("Recovery advanced while moving")
				quit(1)
				return
			game.speed = 0
			game._update_arrival(game.HELP_DURATION)
		elif leg == 1:
			drive_to_station(game, leg)
		else:
			game.ambulance.position = game._mission_destination()
			game.speed = 0.0
			game._update_arrival(game.HELP_DURATION)
		if game.delivery_points != starting_points + 20*floori((leg+1)/2.0) or game.recovery_leg != leg+1 or game.wallet != starting_balance + 20*floori((leg+1)/2.0):
			printerr("Recovery leg %d ended at leg %d, position %s, speed %.2f, balance %d, status %s" % [
				leg, game.recovery_leg, game.ambulance.position, game.speed, game.wallet, game.status_label.text])
			quit(1)
			return
		if leg == 0:
			var saved_position: Vector3 = game.ambulance.position
			game.queue_free()
			await process_frame
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			game._resume_road_checkpoint()
			if game.free_drive or game.vehicle_index != game.RECOVERY or not game.ambulance.position.is_equal_approx(saved_position) or game.casualty.get_parent() != game.ambulance:
				printerr("Loaded tow truck did not resume at pickup")
				quit(1)
				return
		if not loading and not game.phone.messages.has("Recovery complete. You earned 20 points and 20 coins."):
			printerr("Missing delivery receipt")
			quit(1)
			return
	if game.phone.messages.count("Recovery complete. You earned 20 points and 20 coins.") != 2:
		printerr("Expected one receipt per delivered car")
		quit(1)
		return
	game.ambulance.position = game._mission_destination()
	game.speed = 0
	game._help_at_target()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if game.recovery_leg != 5 or game.casualty.get_parent() != game.ambulance:
		printerr("Could not resume the next round with a car on the flatbed")
		quit(1)
		return
	var expected_score: int = starting_points + 40 + game.foot_quest_points + game.collected_stars.size() * game.POINTS_PER_STAR
	game.queue_free()
	await process_frame
	await process_frame
	var reopened = load("res://main.tscn").instantiate()
	root.add_child(reopened)
	reopened._start_game()
	var score_text: String = reopened.tr_n("★ %d point", "★ %d points", expected_score) % expected_score
	if reopened.delivery_points != starting_points + 40 or reopened.wallet != starting_balance + 40 or not reopened.wallet_label.text.begins_with(score_text):
		printerr("Recovery rewards were not restored in the player's score and wallet")
		quit(1)
		return
	reopened.queue_free()
	await process_frame
	print("Both deliveries paid once. The score and wallet were restored after reopening.")
	quit()

func drive_to_station(game: Node, leg: int) -> void:
	var origin: Vector3 = game.ambulance.position
	var forward: Vector3 = -game.ambulance.basis.z
	var goal := Vector2(game.STATION_DROP.x, game.STATION_DROP.z)
	var route := Curve2D.new()
	for point in game.navigator.driving_path(Vector2(origin.x, origin.z), goal, Vector2(forward.x, forward.z), true):
		route.add_point(point)
	# Aim five metres ahead on the route as the live traffic simulation advances.
	for frame in 2800:
		var position := Vector2(game.ambulance.position.x, game.ambulance.position.z)
		var target := route.sample_baked(minf(route.get_closest_offset(position) + 5, route.get_baked_length()))
		forward = -game.ambulance.basis.z
		var angle := Vector2(forward.x, forward.z).angle_to(position.direction_to(target))
		Input.action_press("ui_right", clampf(angle * 2.6, 0, 1))
		Input.action_press("ui_left", clampf(-angle * 2.6, 0, 1))
		game.mouse_brake = position.distance_to(goal) < 1.7
		Input.action_press("ui_up", 0 if game.mouse_brake else .65)
		game._process(.05)
		if game.recovery_leg != leg:
			break
	for action in ["ui_right", "ui_left", "ui_up"]:
		Input.action_release(action)
	game.mouse_brake = false
