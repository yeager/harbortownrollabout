extends SceneTree
## Run from the imported project with godot --headless --script res://tests/bus_route.gd

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.BUS)
	# This route exercises automatic service after stopping.
	game.gentle_driving = true
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	if not game.free_drive or not game.phone.take_job.is_visible_in_tree():
		printerr("The vehicle must start in free exploration and offer a job in the phone")
		quit(1)
		return
	game.phone.take_job.pressed.emit()
	TranslationServer.set_locale("sv")
	await process_frame
	var stops := ["TORGET", "SJÖSTADSSKOLAN", "SMÅBÅTSHAMNEN", "VÅRDCENTRALEN", "VÄSTRA TORGET", "VÄSTERÄNGEN"]
	var starting_balance: int = game.wallet
	for leg in range(stops.size() + 1):
		if leg == 1:
			game._save_checkpoint()
			game.queue_free()
			await process_frame
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			var resume = game.find_child("ResumeCheckpoint", true, false)
			if not resume or not resume.is_visible_in_tree():
				printerr("Missing resume button on the main menu")
				quit(1)
				return
			resume.pressed.emit()
			TranslationServer.set_locale("sv")
			await process_frame
		var row: HBoxContainer = game.phone.action_rows.get_child(0)
		var picture: AtlasTexture = row.get_child(0).texture
		var action: int = game.phone.Action.BOARD if leg % 2 == 0 else game.phone.Action.ALIGHT
		if picture.region.position.x != action * 48 or row.get_child(1).text != game.phone.current_job:
			printerr("Passenger action picture did not follow the next stop")
			quit(1)
			return
		if game._vehicle_payload() != (450.0 if leg % 2 else 0.0):
			printerr("Incorrect passenger payload")
			quit(1)
			return
		var destination := "502  " + str(stops[leg % stops.size()])
		if game.bus_board.text != destination or game.rear_bus_board.text != destination:
			printerr("Expected both destination displays to show ", destination)
			quit(1)
			return
		var expected_fares := floori(leg / 2.0)
		if game.wallet != starting_balance + expected_fares * 15:
			printerr("Incorrect bus fare payout after stop ", leg)
			quit(1)
			return
		if leg < stops.size():
			game.ambulance.position = game._mission_destination()
			game._update_arrival(game.HELP_DURATION)
	TranslationServer.set_locale("en")
	await process_frame
	if game.bus_board.text != "502  THE SQUARE" or game.rear_bus_board.text != game.bus_board.text:
		printerr("Changing language did not update the bus displays")
		quit(1)
		return
	var labels := get_nodes_in_group("bus_stop_labels")
	for label in labels:
		if label.text != "502\n" + str(label.get_meta("stop_name")):
			printerr("Changing language did not update the stop sign")
			quit(1)
			return
	if labels.size() != 12:
		printerr("Expected two signs at each of six stops")
		quit(1)
		return
	game._save_checkpoint()
	write_incomplete_checkpoint(game)
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if game.find_child("ResumeCheckpoint", true, false) or game.wallet != starting_balance + 45:
		printerr("Incomplete checkpoint affected the menu or wallet")
		quit(1)
		return
	game.start_button.pressed.emit()
	if game.mode != "playing":
		printerr("Fresh start unavailable after incomplete checkpoint")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Both bus displays followed the six stops and three completed journeys paid once each.")
	quit()

func write_incomplete_checkpoint(game: Node) -> void:
	var damaged: Dictionary = game.road_checkpoint.duplicate(true)
	damaged["tram"] = {"mode": 1}
	var config := ConfigFile.new()
	config.load(game.SETTINGS_PATH)
	config.set_value("player", "road_checkpoint", damaged)
	config.save(game.SETTINGS_PATH)
