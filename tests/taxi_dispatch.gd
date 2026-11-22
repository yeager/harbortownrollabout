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
	game._help_at_target()
	var dropoff: Vector3 = game._mission_destination()

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
	game._help_at_target()
	game._help_at_target()
	if game.wallet != initial_wallet + 15 or game.phone.current_job != "A pupil is waiting at the square.":
		printerr("Expected one fare payment and the next school pickup")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await process_frame
	print("Taxi resumed the correct fare, paid once, and dispatched a school pickup.")
	quit()
