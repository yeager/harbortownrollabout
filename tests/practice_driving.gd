extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.MOWER)
	game.find_child("PracticeDriving", true, false).pressed.emit()
	var roof_sign: Node3D = game.vehicle_model.get_node_or_null("SchoolCarSign")
	if game.vehicle_index != game.SCHOOL_CAR or not is_instance_valid(roof_sign) or not roof_sign.is_visible_in_tree():
		printerr("Practice menu did not start in a marked school car")
		quit(1)
		return
	var start: Vector3 = game.ambulance.position
	for line_name in ["Practice stop line", "Practice signal stop line"]:
		var line := game.get_node(line_name) as MeshInstance3D
		var expected_x: float = game.PRACTICE_STOP_X if line_name == "Practice stop line" else game.PRACTICE_SIGNAL_X
		if not is_equal_approx(line.to_global(line.get_aabb().position).x, expected_x):
			printerr("Practise lesson threshold does not match the visible edge of ", line_name)
			quit(1)
			return
	var entrance := game.get_node("Driving school entrance light") as SpotLight3D
	var previous_time: int = game.time_mode
	for time in [0, 1, 0]:
		game.time_mode = time
		game._update_daylight(0.0)
		if entrance.visible != (time == 1) or (entrance.light_energy > 0.0) != (time == 1):
			printerr("The driving school entrance light did not follow the day cycle")
			quit(1)
			return
	game.time_mode = previous_time
	game._update_daylight(0.0)
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
	# Opening and closing the phone can release the pedal between physics ticks.
	game.phone.open_button.pressed.emit()
	if game.mouse_brake or game.brake_held:
		printerr("Opening the phone left the mouse brake latched")
		quit(1)
		return
	game.phone.toggle()
	game.mouse_brake = true
	for frame in 60: game._drive(1.0/60)
	if game.speed >= 0:
		printerr("Practice car did not brake and reverse")
		quit(1)
		return
	game.mouse_brake = false
	game.ambulance.position = start
	game.speed = 4.0
	game._drive(.1)
	if game.practice_speed_distance <= 0:
		printerr("Legal forward driving did not count for the speed exercise")
		quit(1)
		return
	game.speed = 7.0
	game._drive(.1)
	if game.practice_speed_distance != 0:
		printerr("Exceeding the limit did not reset the speed exercise")
		quit(1)
		return
	for frame in 50:
		game.speed = 4.0
		game._drive(.1)
	if game.practice_speed_distance < game.PRACTICE_SPEED_DISTANCE:
		printerr("Could not complete the speed exercise at a legal speed")
		quit(1)
		return
	var line_x: float = game.PRACTICE_STOP_X
	var lane_z: float = game.PRACTICE_STOP_LANE_Z
	var before := Vector3(line_x-3.0,0,lane_z)
	var over := Vector3(line_x-1.5,0,lane_z)
	game.speed = .1
	game._track_practice_stop(before,2.0,1.0)
	game._track_practice_stop(over+Vector3.BACK*6.0,2.0,1.0)
	if not game.practice_stop_missed or game.practice_stop_complete:
		printerr("Driving around the stop line did not trigger a retry")
		quit(1)
		return
	var retry_hint: String = game.tr("You passed the line. Reverse until this message clears.")
	game.speed = -7.0
	game._refresh_status()
	if not game.status_label.text.begins_with(retry_hint):
		printerr("The retry hint disappeared while reversing behind the stop line")
		quit(1)
		return
	game.speed = 0.0
	game._track_practice_stop(before,2.0,1.0)
	if not game.practice_stop_missed or game.practice_stop_complete:
		printerr("Backing just behind the line counted as a fresh stop attempt")
		quit(1)
		return
	var retry := before-Vector3.RIGHT
	game._track_practice_stop(retry,2.0,1.0)
	game._refresh_status()
	if not game.status_label.text.begins_with(game.tr("Come to a full stop at the stop line.")):
		printerr("The stop instruction did not return after resetting the attempt")
		quit(1)
		return
	game._track_practice_stop(before,2.0,1.0)
	if game.practice_stop_missed or not game.practice_stop_complete:
		printerr("A full stop at the line was not accepted")
		quit(1)
		return
	var signal_x: float = game.PRACTICE_SIGNAL_X
	var signal_wait := Vector3(signal_x-2.5,0,lane_z)
	var signal_cross := Vector3(signal_x-1.5,0,lane_z)
	game.speed = 2.0
	game._track_practice_signal(signal_wait,signal_cross,2.0,1.0,.2)
	if not game.practice_signal_missed or game.practice_signal_complete:
		printerr("Crossing the practice signal on red was accepted")
		quit(1)
		return
	game._refresh_status()
	if not game.status_label.text.begins_with(retry_hint):
		printerr("Crossing on red did not show the retry hint")
		quit(1)
		return
	var signal_retry := signal_wait-Vector3.RIGHT*4.0
	game._track_practice_signal(signal_cross,signal_retry,2.0,1.0,.1)
	game.speed = 0.0
	for frame in 81:
		game._track_practice_signal(signal_wait,signal_wait,2.0,1.0,.1)
	if game.practice_signal_phase != 1:
		printerr("The practice signal did not change to amber")
		quit(1)
		return
	game.speed = 2.0
	game._track_practice_signal(signal_wait,signal_cross,2.0,1.0,.2)
	if not game.practice_signal_missed or game.practice_signal_complete:
		printerr("Crossing the practice signal on amber was accepted")
		quit(1)
		return
	game._track_practice_signal(signal_cross,signal_retry,2.0,1.0,.1)
	game.speed = 0.0
	for frame in 21:
		game._track_practice_signal(signal_wait,signal_wait,2.0,1.0,.1)
	if game.practice_signal_phase != 2 or game.practice_signal_missed:
		printerr("Stopping at the practice signal did not produce green")
		quit(1)
		return
	game.speed = 2.0
	game._track_practice_signal(signal_wait,signal_cross+Vector3.BACK*6.0,2.0,1.0,.2)
	if not game.practice_signal_missed or game.practice_signal_complete:
		printerr("Driving around the practice signal on green was accepted")
		quit(1)
		return
	game._track_practice_signal(signal_cross,signal_wait,2.0,1.0,.1)
	game._track_practice_signal(signal_wait,signal_cross,2.0,1.0,.1)
	if not game.practice_signal_missed or game.practice_signal_complete:
		printerr("Crossing again without resetting the signal attempt was accepted")
		quit(1)
		return
	game._track_practice_signal(signal_cross,signal_retry,2.0,1.0,.1)
	game.speed = 0.0
	for frame in 21:
		game._track_practice_signal(signal_wait,signal_wait,2.0,1.0,.1)
	game.speed = 2.0
	game._track_practice_signal(signal_wait,signal_cross,2.0,1.0,.2)
	if not game.practice_signal_complete:
		printerr("Crossing on green did not complete the lesson")
		quit(1)
		return
	game.ambulance.position.z = game.PRACTICE_YARD.end.y + 1
	game._recover_position()
	if game.ambulance.position != start:
		printerr("Car displaced beyond the course did not recover at its start")
		quit(1)
		return
	game._change_seat()
	if not game.walker.visible or game._play_bounds() != game.PRACTICE_YARD:
		printerr("Could not get out inside practice yard")
		quit(1)
		return
	var parked_sign: Node3D = game.parked_cars[game.SCHOOL_CAR].find_child("SchoolCarSign",true,false)
	if not parked_sign.is_visible_in_tree():
		printerr("Parked school car lost its roof sign")
		quit(1)
		return
	game._recover_position()
	game._change_seat()
	if game.walker.visible or game.ambulance.position != start:
		printerr("Could not recover and re-enter practice car")
		quit(1)
		return
	for on_foot in [false,true]:
		if on_foot:
			game.free()
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			game._on_vehicle_selected(game.MOWER)
			game._start_practice()
		if on_foot: game._change_seat()
		game._refresh_ui()
		if not game.leave_practice_button.is_visible_in_tree(): quit(1); return
		game.leave_practice_button.pressed.emit()
		var actor=game.walker if on_foot else game.ambulance
		if not game.CITY_INTERIOR.has_point(Vector2(actor.position.x,actor.position.z)) or game.leave_practice_button.visible:
			quit(1)
			return
		if not on_foot and (game.vehicle_model.get_node("SchoolCarSign").visible or parked_sign.visible):
			printerr("School marking remained after leaving practice")
			quit(1)
			return
	game.find_child("BackspaceRecovery", true, false).button_pressed = true
	game.find_child("HornF4", true, false).button_pressed = true
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.TAXI)
	game._start_practice()
	TranslationServer.set_locale("sv")
	game._refresh_ui()
	if not game.driving_hints.text.contains("Fastnat? Tryck Backspace") or game.phone.recovery_hint.text != "Fastnat? Tryck Backspace":
		printerr("Recovery hints did not follow the saved binding")
		quit(1)
		return
	game.ambulance.position.z += 3
	var displaced: Vector3 = game.ambulance.position
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_R
	game._unhandled_key_input(key)
	if game.ambulance.position != displaced:
		printerr("Old recovery binding was still active")
		quit(1)
		return
	key.keycode = KEY_BACKSPACE
	game._unhandled_key_input(key)
	if game.ambulance.position != game.PRACTICE_START:
		printerr("Saved Backspace binding did not recover the vehicle")
		quit(1)
		return
	game.phone.open_button.pressed.emit()
	for horn_key in [KEY_H, KEY_F4]:
		key.keycode = horn_key
		game._unhandled_key_input(key)
		if game.horn.playing:
			printerr("Horn interrupted the open phone")
			quit(1)
			return
	game.phone.toggle()
	key.alt_pressed = true
	game._unhandled_key_input(key)
	if game.horn.playing:
		printerr("Alt+F4 sounded the horn")
		quit(1)
		return
	key.alt_pressed = false
	for horn_key in [KEY_H, KEY_F4]:
		key.keycode = horn_key
		game._unhandled_key_input(key)
		if not game.horn.playing:
			printerr("Horn binding stopped working after closing the phone")
			quit(1)
			return
		game.horn.stop()
	game.phone.open_button.pressed.emit()
	if game.phone.take_job.tr(game.phone.take_job.text) != "Åk till staden för ett uppdrag":
		printerr("Job button should explain that accepting leaves practice")
		quit(1)
		return
	game.phone.take_job.pressed.emit()
	var taxi_position: Vector3 = game.ambulance.position
	if game.practice_active or game.free_drive or not game.CITY_INTERIOR.has_point(Vector2(taxi_position.x,taxi_position.z)) or game.phone.current_job != "Taxi requested at the square.":
		printerr("Accepting a town job from practice should take the driver to town.")
		quit(1)
		return
	game.free()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.find_child("PracticeDriving", true, false).pressed.emit()
	game.practice_speed_distance = game.PRACTICE_SPEED_DISTANCE
	game.practice_stop_complete = true
	game.practice_signal_waited = true
	game._set_practice_signal(2)
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.find_child("ResumeCheckpoint", true, false).pressed.emit()
	if not game.practice_active or game.practice_speed_distance != game.PRACTICE_SPEED_DISTANCE or not game.practice_stop_complete or game.practice_signal_complete or game.practice_signal_phase != 0 or game.practice_signal_waited:
		printerr("Resuming a lesson lost its completed stages or did not restart at red")
		quit(1)
		return
	game.practice_signal_complete = true
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.find_child("ResumeCheckpoint", true, false).pressed.emit()
	if not game.practice_signal_complete:
		printerr("Resuming a completed lesson lost its result")
		quit(1)
		return
	print("Practice course acceleration, braking, reverse, recovery and boarding passed.")
	quit()
