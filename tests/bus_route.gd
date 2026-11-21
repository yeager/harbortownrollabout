extends SceneTree
## Run from the imported project with godot --headless --script res://tests/bus_route.gd

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.BUS)
	game._start_game()
	var stops := ["TORGET", "SJÖSTADSSKOLAN", "SMÅBÅTSHAMNEN", "VÅRDCENTRALEN", "VÄSTRA TORGET", "VÄSTERÄNGEN"]
	var starting_balance: int = game.wallet
	for leg in range(stops.size() + 1):
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
	game.queue_free()
	await process_frame
	await process_frame
	print("Both bus displays followed the six stops and three completed journeys paid once each.")
	quit()
