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
	var stops := ["TORGET", "SJÖSTADSSKOLAN", "SMÅBÅTSHAMNEN", "VÅRDCENTRALEN", "VÄSTRA TORGET", "SICKLA UDDE"]
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
		if leg == 1:
			for locale in ["en","de","es","fi","fr","nb","sv"]:
				TranslationServer.set_locale(locale)
				await process_frame
				var school: String = game.tr("HARBOR TOWN SCHOOL")
				var expected: String = game.tr("Next stop: %s") % school
				if game.next_bus_stop_board.text != expected or game.bus_leg != leg:
					printerr("Interior display lost the current stop after switching to ", locale)
					quit(1)
					return
				for sign: Label3D in get_nodes_in_group("bus_stop_labels"):
					if sign.text != game.BUS_DESTINATION + "\n" + game.tr(sign.get_meta("stop_name")):
						printerr("Stale stop sign after switching to ", locale)
						quit(1)
						return
		var row: HBoxContainer = game.phone.action_rows.get_child(0)
		var picture: AtlasTexture = row.get_child(0).texture
		var action: int = game.phone.Action.BOARD if leg % 2 == 0 else game.phone.Action.ALIGHT
		if picture.region.position.x != action * 48 or row.get_child(1).text != game.phone.current_job:
			printerr("Passenger action picture did not follow the next stop")
			quit(1)
			return
		if game.seated_bus_riders.get_child_count() != 2 or game.seated_bus_riders.is_visible_in_tree() != (leg % 2 == 1):
			printerr("Wrong passenger count or visibility at stop ", leg)
			quit(1)
			return
		if game._vehicle_payload() != (450.0 if leg % 2 else 0.0):
			printerr("Incorrect passenger payload")
			quit(1)
			return
		if leg > 0 and leg % 2 == 0:
			var badge: Button = game.reward_badge
			if not badge.is_visible_in_tree() or badge.icon.region.position.x != game.phone.Action.ALIGHT * 48 or not badge.text.contains("15 mynt"):
				printerr("Bus reward must show the completed drop-off and its fare")
				quit(1)
				return
		var nearest_sign: Label3D
		var nearest_distance := INF
		for sign: Label3D in get_nodes_in_group("bus_stop_labels"):
			var distance := sign.global_position.distance_to(game._mission_destination())
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_sign = sign
		var stop_index := leg % stops.size()
		if not nearest_sign or nearest_distance > 12 or nearest_sign.text != "74  SICKLA UDDE\n" + stops[stop_index]:
			printerr("The route marker should lead to the stop sign for ", stops[stop_index])
			quit(1)
			return
		if game.phone.current_job != game.BUS_MESSAGES[stop_index] or game.mission_marker.get_node("MissionLabel").text != game.tr(game.phone.current_job).to_upper():
			printerr("Phone instruction and route marker disagree at ", stops[stop_index])
			quit(1)
			return
		if not game.next_bus_stop_board.is_visible_in_tree() or game.next_bus_stop_board.text != "Nästa hållplats: " + stops[stop_index]:
			printerr("Interior display disagrees with the stop sign at ", stops[stop_index])
			quit(1)
			return
		var destination := "74  SICKLA UDDE"
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
	if game.bus_board.text != "74  SICKLA UDDE" or game.rear_bus_board.text != game.bus_board.text:
		printerr("Changing language did not update the bus displays")
		quit(1)
		return
	var labels := get_nodes_in_group("bus_stop_labels")
	for label in labels:
		if label.text != "74  SICKLA UDDE\n" + str(label.get_meta("stop_name")):
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
