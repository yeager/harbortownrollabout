extends SceneTree
## Run from the imported project with godot --headless --script res://tests/taxi_dispatch.gd

func _initialize() -> void:
	call_deferred("check_fare")

func check_fare() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.TAXI)
	game._start_game()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var initial_wallet: int = game.wallet
	game.ambulance.position = game._mission_destination()
	var help_key := InputEventKey.new()
	help_key.pressed = true
	help_key.keycode = KEY_INSERT
	game._unhandled_key_input(help_key)
	if game._vehicle_payload() != 0:
		printerr("Insert should be inactive by default")
		quit(1)
		return
	game.find_child("InsertHelp", true, false).button_pressed = true
	game.phone.open_button.pressed.emit()
	for key in [KEY_SPACE, KEY_INSERT]:
		help_key.keycode = key
		game._unhandled_key_input(help_key)
		if game._vehicle_payload() != 0:
			printerr("A mission shortcut collected a passenger while the phone was open")
			quit(1)
			return
	game.phone.toggle()
	help_key.keycode = KEY_SPACE
	game._unhandled_key_input(help_key)
	if game._vehicle_payload() != 75.0:
		printerr("Incorrect passenger payload")
		quit(1)
		return
	var dropoff: Vector3 = game._mission_destination()

	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if game._vehicle_payload() != 75.0 or game._mission_destination() != dropoff:
		printerr("Lost current taxi fare after restart")
		quit(1)
		return

	game.paused = true
	game._on_vehicle_selected(game.BUS)
	if game.phone.current_job != "Collect passengers at the square.":
		printerr("Bus dispatch did not replace the taxi fare")
		quit(1)
		return
	game._on_vehicle_selected(game.TAXI)
	game.paused = false
	if game.phone.current_job != "Please take me to the marina." or game._mission_destination() != dropoff:
		printerr("Returning to the taxi lost the passenger's destination")
		quit(1)
		return

	game.ambulance.position = dropoff
	TranslationServer.set_locale("sv")
	game.message_timer = 0
	game.gentle_driving = false
	game._refresh_ui()
	if not game.driving_hints.text.contains("Mellanslag / Insert för att hjälpa") or game.status_label.text != "Tryck på Mellanslag / Insert för att släppa av passageraren.":
		printerr("Unexpected Swedish driving or drop-off hint: ", game.status_label.text, " / ", game.driving_hints.text)
		quit(1)
		return
	help_key.keycode = KEY_INSERT
	game._unhandled_key_input(help_key)
	if game.wallet != initial_wallet + 15:
		printerr("Saved Insert binding did not complete the fare")
		quit(1)
		return
	game._help_at_target()
	if game.wallet != initial_wallet + 15 or game.phone.current_job != "A pupil is waiting at the square.":
		printerr("Expected one fare payment and the next school pickup")
		quit(1)
		return
	for expected_load in [35.0, 0.0]:
		game.ambulance.position = game._mission_destination()
		game._help_at_target()
		if game._vehicle_payload() != expected_load:
			printerr("Incorrect school fare payload at leg ", game.taxi_leg)
			quit(1)
			return
	game.queue_free()
	await process_frame
	await process_frame
	print("Taxi resumed the correct fare, paid once, and dispatched a school pickup.")
	quit()
