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

func set_button(which: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 1
	event.button_index = which
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func button(which: int) -> void:
	set_button(which, true)
	set_button(which, false)

func check_excavator(game) -> bool:
	game.mode = "menu"
	game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size()).pressed.emit()
	game.start_button.pressed.emit()
	if not game.operating_excavator:
		return false
	game.boom_joint.rotation.x = -.40
	game.stick_joint.rotation.x = 0
	game.bucket_joint.rotation.x = 0
	var hull: Transform3D = game.excavator.transform
	var slew: float = game.cab_turntable.rotation.y
	var orbit: float = game.orbit_angle
	set_button(JOY_BUTTON_LEFT_SHOULDER, true)
	axis(JOY_AXIS_LEFT_X, .8)
	axis(JOY_AXIS_LEFT_Y, -.8)
	axis(JOY_AXIS_RIGHT_X, .8)
	axis(JOY_AXIS_RIGHT_Y, -.8)
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	game._process(.15)
	var arm_moved: bool = (
		game.cab_turntable.rotation.y < slew - .03
		and game.boom_joint.rotation.x < -.42
		and game.stick_joint.rotation.x > .03
		and game.bucket_joint.rotation.x > .03
	)
	set_button(JOY_BUTTON_LEFT_SHOULDER, false)
	for stick_axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		axis(stick_axis, 0)
	game._drive_excavator(.15)
	var blocked: bool = game.excavator.transform.is_equal_approx(hull) and is_equal_approx(game.orbit_angle, orbit)
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	game._drive_excavator(.05)
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	for frame in 45:
		game._drive_excavator(1.0 / 60)
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	return arm_moved and blocked and hull.origin.distance_to(game.excavator.position) > .3

func check_watercraft_and_tram(game) -> bool:
	game.mode = "menu"
	game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size() + 2).pressed.emit()
	game.start_button.pressed.emit()
	if not game.boating:
		return false
	var berth: Transform3D = game.launch.transform
	axis(JOY_AXIS_TRIGGER_RIGHT, .6)
	game._drive_launch(.25)
	var partial_speed: float = game.launch_speed
	game.launch.transform = berth
	game.launch_speed = 0.0
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	game._drive_launch(.25)
	var full_speed: float = game.launch_speed
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	if partial_speed <= 0.0 or not is_equal_approx(partial_speed, full_speed * .5):
		return false
	axis(JOY_AXIS_LEFT_X, -.8)
	axis(JOY_AXIS_TRIGGER_LEFT, 1)
	game._drive_launch(.5)
	var backed_and_turned: bool = game.launch_speed < 0.0 and not game.launch.basis.is_equal_approx(berth.basis)
	axis(JOY_AXIS_LEFT_X, 0)
	axis(JOY_AXIS_TRIGGER_LEFT, 0)
	if not backed_and_turned:
		return false
	game.mode = "menu"
	game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size() + 1).pressed.emit()
	game.start_button.pressed.emit()
	if game.tram_mode != 2:
		return false
	game.tram.dwell = 0.0
	axis(JOY_AXIS_TRIGGER_RIGHT, .6)
	game._process(.15)
	var partial_acceleration: float = game.tram.velocity
	game.tram.velocity = 0.0
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	game._process(.15)
	var full_acceleration: float = game.tram.velocity
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	if partial_acceleration <= 0.0 or not is_equal_approx(partial_acceleration, full_acceleration * .5):
		return false

	game.tram.velocity = 2.0
	axis(JOY_AXIS_TRIGGER_LEFT, .6)
	game._process(.15)
	var partial_braking: float = 2.0 - game.tram.velocity
	game.tram.velocity = 2.0
	axis(JOY_AXIS_TRIGGER_LEFT, 1)
	game._process(.15)
	var full_braking: float = 2.0 - game.tram.velocity
	axis(JOY_AXIS_TRIGGER_LEFT, 0)
	return partial_braking > 0.0 and is_equal_approx(partial_braking, full_braking * .5)

func check_settings(game) -> bool:
	var dialog := game.find_child("GameSettings", true, false) as AcceptDialog
	var deadzone := dialog.find_child("GamepadDeadzone", true, false) as HSlider
	var camera_speed := dialog.find_child("GamepadCameraSpeed", true, false) as HSlider
	var invert := dialog.find_child("GamepadInvertY", true, false) as CheckButton
	var tabs := deadzone.get_parent().get_parent().get_parent().get_parent() as TabContainer
	var settings := game.find_child("SettingsButton", true, false) as Button
	settings.grab_focus()
	button(JOY_BUTTON_A)
	await process_frame
	button(JOY_BUTTON_LEFT_SHOULDER)
	if tabs.current_tab != tabs.get_tab_count() - 1:
		return false
	if dialog.gui_get_focus_owner() != deadzone:
		return false
	button(JOY_BUTTON_DPAD_RIGHT)
	if not is_equal_approx(deadzone.value, 25.0):
		return false
	deadzone.value = 40.0
	button(JOY_BUTTON_DPAD_DOWN)
	if dialog.gui_get_focus_owner() != camera_speed:
		return false
	camera_speed.value = 150.0
	button(JOY_BUTTON_DPAD_DOWN)
	if dialog.gui_get_focus_owner() != invert:
		return false
	button(JOY_BUTTON_A)
	button(JOY_BUTTON_B)
	if dialog.visible:
		return false
	game.gamepad_deadzone = .20
	game.gamepad_camera_speed = 1.0
	game.gamepad_invert_y = false
	game._load_preferences()
	axis(JOY_AXIS_LEFT_X, .30)
	var ignores_drift := is_zero_approx(Input.get_action_strength("pad_right")) and is_zero_approx(Input.get_action_strength("ui_right"))
	axis(JOY_AXIS_LEFT_X, 0)
	return ignores_drift and is_equal_approx(game.gamepad_deadzone, .40) and is_equal_approx(game.gamepad_camera_speed, 1.5) and game.gamepad_invert_y

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not await check_settings(game):
		printerr("Gamepad settings navigation, saving or deadzone failed")
		quit(1)
		return
	game.start_button.grab_focus()
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
	if game.speed <= .5 or not is_equal_approx(float(game.steering), .25):
		printerr("Expected 25% steering from 55% stick input with a 40% dead zone, got ", game.steering)
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
	var old_height: float = game.orbit_height
	axis(JOY_AXIS_RIGHT_Y, .8)
	game._process(1.0 / 60)
	axis(JOY_AXIS_RIGHT_Y, 0)
	if game.orbit_height >= old_height:
		printerr("Gamepad vertical camera inversion failed")
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
	button(JOY_BUTTON_BACK)
	var phone_pose: Transform3D = game.walker.transform
	set_button(JOY_BUTTON_DPAD_RIGHT, true)
	axis(JOY_AXIS_LEFT_Y, -1)
	game._walk(.1)
	axis(JOY_AXIS_LEFT_Y, 0)
	set_button(JOY_BUTTON_DPAD_RIGHT, false)
	button(JOY_BUTTON_BACK)
	if not game.walker.transform.is_equal_approx(phone_pose):
		printerr("The phone must block gamepad walking and turning")
		quit(1)
		return
	game.walker.position = Vector3(game.shops.storefront_x(3), 0, 44)
	game.shops.update_customer(true, game.walker.position, true)
	await process_frame
	var first_product := root.gui_get_focus_owner()
	button(JOY_BUTTON_DPAD_DOWN)
	if root.gui_get_focus_owner() == first_product:
		printerr("The D-pad did not move focus in the shop")
		quit(1)
		return
	var shop_heading: float = game.walker.rotation.y
	set_button(JOY_BUTTON_DPAD_RIGHT, true)
	game._walk(.1)
	set_button(JOY_BUTTON_DPAD_RIGHT, false)
	if not game.shops.shop_card.visible or not is_equal_approx(shop_heading, game.walker.rotation.y):
		printerr("D-pad shop navigation must not turn the player")
		quit(1)
		return
	axis(JOY_AXIS_LEFT_X, .8)
	game._walk(.1)
	axis(JOY_AXIS_LEFT_X, 0)
	if is_equal_approx(shop_heading, game.walker.rotation.y):
		printerr("The left stick must still turn the player in the shop")
		quit(1)
		return
	game.shops.update_customer(false, game.walker.position, true)
	if not check_excavator(game):
		printerr("Gamepad excavator arm, isolation or track control failed")
		quit(1)
		return
	if not check_watercraft_and_tram(game):
		printerr("Gamepad launch or tram controls failed")
		quit(1)
		return
	print("Gamepad settings, menu, steering, pedals, pause, camera, phone, map, emergency controls, seat, walking, boat and tram passed.")
	game.queue_free()
	await process_frame
	quit()
