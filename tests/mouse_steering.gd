extends SceneTree

const POINTER := Vector2(600, 370)

func _initialize() -> void:
	call_deferred("check")

func pedal(button: MouseButton, pressed: bool, at := POINTER) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = button
	event.pressed = pressed
	root.push_input(event, true)

func drag(horizontal: float, mask: MouseButtonMask) -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(horizontal, 0)
	event.relative = event.screen_relative * 0.5
	event.position = POINTER + event.relative
	event.button_mask = mask
	root.push_input(event, true)

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_button.pressed.emit()
	await process_frame
	pedal(MOUSE_BUTTON_LEFT, true)
	drag(120, MOUSE_BUTTON_MASK_LEFT)
	if not is_equal_approx(game.mouse_steering, 0.8):
		printerr("Viewport scaling changed the steering sensitivity")
		quit(1)
		return
	var forward_heading: float = game.ambulance.rotation.y
	for frame in 8:
		game._drive(.05)
	if game.speed <= 0 or game.steering <= 0 or angle_difference(forward_heading, game.ambulance.rotation.y) >= 0:
		printerr("Dragging right while accelerating must turn the wheels right")
		quit(1)
		return
	pedal(MOUSE_BUTTON_LEFT, false)
	var controls: Control = game.driving_controls
	var brake_center := controls.get_global_transform_with_canvas() * (controls.size - Vector2(68,93))
	pedal(MOUSE_BUTTON_LEFT, true, brake_center)
	drag(-120, MOUSE_BUTTON_MASK_LEFT)
	var previous_speed: float = game.speed
	game._drive(.05)
	if game.speed >= previous_speed or not controls.brake or controls.gas or game.mouse_steering >= 0:
		printerr("Dragging off the on-screen brake must keep braking and steer left")
		quit(1)
		return
	pedal(MOUSE_BUTTON_LEFT, false)
	pedal(MOUSE_BUTTON_LEFT, true)
	drag(120, MOUSE_BUTTON_MASK_LEFT)
	# Changing pedals mid-turn must preserve the steering until both are released.
	pedal(MOUSE_BUTTON_RIGHT, true)
	var held_angle: float = game.mouse_steering
	pedal(MOUSE_BUTTON_LEFT, false)
	if game.mouse_steering != held_angle or not game.mouse_brake:
		printerr("Releasing the accelerator cancelled steering or braking")
		quit(1)
		return
	drag(-240, MOUSE_BUTTON_MASK_RIGHT)
	for frame in 20:
		game._drive(.05)
	if not is_zero_approx(game.speed) or game.steering >= 0:
		printerr("The held brake must keep the vehicle stopped with the wheels turned left")
		quit(1)
		return
	# Release and press again before the next driving tick.
	pedal(MOUSE_BUTTON_RIGHT, false)
	pedal(MOUSE_BUTTON_RIGHT, true)
	drag(120, MOUSE_BUTTON_MASK_RIGHT)
	var reverse_heading: float = game.ambulance.rotation.y
	for frame in 20:
		game._drive(.05)
	if game.speed >= 0 or game.steering <= 0 or angle_difference(reverse_heading, game.ambulance.rotation.y) <= 0:
		printerr("A second press must allow reversing and steering right")
		quit(1)
		return
	pedal(MOUSE_BUTTON_RIGHT, false)
	for frame in 20:
		game._drive(.05)
	if not is_zero_approx(game.steering):
		printerr("Releasing the mouse must centre the steering")
		quit(1)
		return
	# The boat can go straight from slowing down to reversing on the same press.
	game.boating = true
	game.launch.position = Vector3(71, -0.94, 40)
	game.launch_speed = 1.0
	pedal(MOUSE_BUTTON_RIGHT, true)
	drag(120, MOUSE_BUTTON_MASK_RIGHT)
	for frame in 10:
		game._drive_launch(.05)
	var boat_heading: float = game.launch.rotation.y
	game._drive_launch(.05)
	if game.launch_speed >= 0 or angle_difference(boat_heading, game.launch.rotation.y) <= 0:
		printerr("Holding the brake and steering must turn the reversing boat")
		quit(1)
		return
	pedal(MOUSE_BUTTON_RIGHT, false)
	game.boating = false
	game.mode = "menu"
	game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size()).pressed.emit()
	game.start_button.pressed.emit()
	var crawler_start: Transform3D = game.excavator.transform
	pedal(MOUSE_BUTTON_RIGHT, true)
	drag(-90, MOUSE_BUTTON_MASK_RIGHT)
	for frame in 8:
		game._drive_excavator(.05)
	var crawler_travel: Vector3 = game.excavator.position - crawler_start.origin
	if not game.operating_excavator or crawler_travel.dot(crawler_start.basis.z) >= -0.1 or crawler_start.basis.z.signed_angle_to(game.excavator.basis.z, Vector3.UP) <= 0:
		printerr("The excavator must reverse and turn its tracks with the right mouse button held")
		quit(1)
		return
	game._refresh_status()
	if game.status_label.text != game.tr("Speed  %02d km/h") % roundi(absf(game.crawler_speed) * 3.6):
		printerr("The speed display must follow the moving tracks")
		quit(1)
		return
	game._change_seat()
	if game.operating_excavator or not game.walker.visible or game.mouse_brake or not is_zero_approx(game.crawler_speed):
		printerr("Leaving the moving excavator must stop the tracks and release its pedal")
		quit(1)
		return
	pedal(MOUSE_BUTTON_RIGHT, false)
	game._change_seat()
	var parked: Transform3D = game.excavator.transform
	game._drive_excavator(.05)
	if not game.operating_excavator or not game.excavator.transform.is_equal_approx(parked):
		printerr("Re-entering the excavator should keep it parked until a pedal is pressed")
		quit(1)
		return
	# A release outside the game window may never reach the viewport.
	pedal(MOUSE_BUTTON_LEFT, true)
	drag(-90, MOUSE_BUTTON_MASK_LEFT)
	if not game.mouse_gas or game.mouse_steering >= 0:
		printerr("Expected active mouse driving before switching windows")
		quit(1)
		return
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if not game.paused or game.mouse_gas or not is_zero_approx(game.mouse_steering):
		printerr("Switching windows must pause play and release mouse driving inputs")
		quit(1)
		return
	game._finish_quit()
