extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.MOWER)
	game.find_child("PracticeDriving", true, false).pressed.emit()
	var start: Vector3 = game.ambulance.position
	game.mouse_gas = true
	for frame in 90: game._drive(1.0/60)
	if game.speed < 1 or game.ambulance.position.distance_to(start) < 1:
		printerr("Practice car did not accelerate")
		quit(1)
		return
	game.mouse_gas = false
	game.mouse_brake = true
	for frame in 180: game._drive(1.0/60)
	if not is_zero_approx(game.speed):
		quit(1)
		return
	game.mouse_brake = false
	game._drive(1.0/60)
	game.mouse_brake = true
	for frame in 60: game._drive(1.0/60)
	if game.speed >= 0:
		printerr("Practice car did not brake and reverse")
		quit(1)
		return
	game.ambulance.position.z = game.PRACTICE_YARD.end.y + 1
	game._recover_position()
	if game.ambulance.position != start:
		printerr("Mower displaced beyond the course did not recover at its start")
		quit(1)
		return
	game._change_seat()
	if not game.walker.visible or game._play_bounds(game.walker.position) != game.PRACTICE_YARD:
		printerr("Could not get out inside practice yard")
		quit(1)
		return
	game._recover_position()
	game._change_seat()
	if game.walker.visible or game.ambulance.position != start:
		printerr("Could not recover and re-enter practice car")
		quit(1)
		return
	for on_foot in [false,true]:
		game.ambulance.position=game.PRACTICE_START
		if on_foot: game._change_seat()
		game._refresh_ui()
		if not game.leave_practice_button.is_visible_in_tree(): quit(1); return
		game.leave_practice_button.pressed.emit()
		var actor=game.walker if on_foot else game.ambulance
		if not game.CITY_INTERIOR.has_point(Vector2(actor.position.x,actor.position.z)) or game.leave_practice_button.visible:
			quit(1)
			return
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.TAXI)
	game._start_practice()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var taxi_position: Vector3 = game.ambulance.position
	if game.practice_active or game.free_drive or not game.CITY_INTERIOR.has_point(Vector2(taxi_position.x,taxi_position.z)) or game.phone.current_job != "Taxi requested at the square.":
		printerr("Accepting a town job from practice should take the driver to town.")
		quit(1)
		return
	print("Practice course acceleration, braking, reverse, recovery and boarding passed.")
	quit()
