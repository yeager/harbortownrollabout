extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.ICE_CREAM)
	game._start_game()
	var starting_balance: int = game.wallet
	for leg in game.ICE_STOPS.size():
		var curb: Vector3 = game._stop_curb(game.ICE_STOPS[leg])
		if not game.passenger.visible or not game._mission_destination().is_equal_approx(Vector3(curb.x, game._surface_height(curb.x,curb.z), curb.z)):
			printerr("Missing ice cream customer or incorrect stop ", leg)
			quit(1)
			return
		game.ambulance.position = game._mission_destination()
		game.speed = 2
		game._help_at_target()
		if game.mission_index != leg:
			printerr("Served ice cream while moving")
			quit(1)
			return
		game.speed = 0
		game._update_arrival(game.HELP_DURATION)
		if game.wallet != starting_balance + 10 * (leg+1) or game.horn.stream.resource_path != "res://audio/horn_icecream.wav":
			printerr("Missing payout or van chime")
			quit(1)
			return
	if game.mode != "complete" or game.passenger.visible:
		printerr("Ice cream route did not finish")
		quit(1)
		return
	game.queue_free()
	await process_frame
	print("Three ice cream customers served, three payouts and the van chime verified.")
	quit()
