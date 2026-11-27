extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func axis(which: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 1
	event.axis = which
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func button(which: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 1
	event.button_index = which
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var start_focus := root.gui_get_focus_owner()
	button(JOY_BUTTON_DPAD_UP)
	if root.gui_get_focus_owner() == start_focus:
		printerr("The D-pad did not move menu focus")
		quit(1)
		return
	game.start_button.grab_focus()
	button(JOY_BUTTON_A)
	await process_frame
	if game.mode != "playing":
		printerr("The gamepad could not start from the menu")
		quit(1)
		return
	var old_lights: bool = game.lights_on
	var old_sound: bool = game.sound_on
	button(JOY_BUTTON_LEFT_SHOULDER)
	button(JOY_BUTTON_B)
	if game.lights_on == old_lights or game.sound_on == old_sound:
		printerr("Gamepad emergency light or siren control failed")
		quit(1)
		return
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	axis(JOY_AXIS_LEFT_X, .55)
	for frame in 45:
		game._drive(1.0 / 60)
	if game.speed <= .5 or game.steering <= .15:
		printerr("Gamepad throttle or steering failed")
		quit(1)
		return
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	axis(JOY_AXIS_LEFT_X, 0)
	axis(JOY_AXIS_TRIGGER_LEFT, 1)
	for frame in 120:
		game._drive(1.0 / 60)
	if absf(game.speed) > .05:
		printerr("Gamepad braking failed")
		quit(1)
		return
	axis(JOY_AXIS_TRIGGER_LEFT, 0)
	game._drive(1.0 / 60)
	axis(JOY_AXIS_TRIGGER_LEFT, 1)
	for frame in 60:
		game._drive(1.0 / 60)
	if game.speed >= -.3:
		printerr("Gamepad brake/reverse failed")
		quit(1)
		return
	axis(JOY_AXIS_TRIGGER_LEFT, 0)
	button(JOY_BUTTON_START)
	if not game.paused:
		printerr("Gamepad pause failed")
		quit(1)
		return
	button(JOY_BUTTON_START)
	if game.paused:
		printerr("Gamepad resume failed")
		quit(1)
		return
	var old_orbit: float = game.orbit_angle
	axis(JOY_AXIS_RIGHT_X, .8)
	game._process(1.0 / 60)
	axis(JOY_AXIS_RIGHT_X, 0)
	if is_equal_approx(old_orbit, game.orbit_angle):
		printerr("Gamepad camera control failed")
		quit(1)
		return
	button(JOY_BUTTON_BACK)
	if not game.phone.handset.is_visible_in_tree() or not game.phone.handset.is_ancestor_of(root.gui_get_focus_owner()):
		printerr("Gamepad phone control failed")
		quit(1)
		return
	button(JOY_BUTTON_LEFT_SHOULDER)
	button(JOY_BUTTON_B)
	if game.lights_on == old_lights or game.sound_on == old_sound:
		printerr("Gamepad emergency controls must stay inactive while the phone is open")
		quit(1)
		return
	button(JOY_BUTTON_BACK)
	if root.gui_get_focus_owner() != null:
		printerr("Closing the phone left menu focus behind")
		quit(1)
		return
	game.speed = 0
	button(JOY_BUTTON_X)
	if not game.walker.visible:
		printerr("Gamepad exit failed")
		quit(1)
		return
	var before: Vector3 = game.walker.position
	axis(JOY_AXIS_LEFT_Y, -1)
	for frame in 45:
		game._walk(1.0 / 60)
	axis(JOY_AXIS_LEFT_Y, 0)
	if before.distance_to(game.walker.position) < .3:
		printerr("Gamepad walk failed")
		quit(1)
		return
	game.walker.position = Vector3(71, game._foot_height(71, 0), 0)
	game.walker.rotation.y = PI
	button(JOY_BUTTON_LEFT_STICK)
	if not game.scooter.visible:
		printerr("The gamepad could not unfold the scooter")
		quit(1)
		return
	button(JOY_BUTTON_LEFT_STICK)
	if game.scooter.visible:
		printerr("The gamepad could not put away the scooter")
		quit(1)
		return
	game.free_drive = true
	game._refresh_ui()
	button(JOY_BUTTON_RIGHT_STICK)
	await process_frame
	var map := game.find_child("TownMap", true, false) as Window
	if not map or not map.visible or not game.paused or not map.gui_get_focus_owner():
		printerr("The gamepad could not open and focus the town map")
		quit(1)
		return
	button(JOY_BUTTON_B)
	await process_frame
	if map.visible or game.paused:
		printerr("The gamepad could not close the town map")
		quit(1)
		return
	print("Gamepad menu, steering, pedals, pause, camera, phone, map, emergency controls, seat and walking passed.")
	game.queue_free()
	await process_frame
	quit()
