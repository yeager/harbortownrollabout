extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.RECOVERY)
	game.gentle_driving = true
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var starting_balance: int = game.wallet
	for leg in 4:
		var loading := leg % 2 == 0
		if game.bonnet_smoke.emitting != (leg == 0) or game.loose_wheel.visible != (leg == 2):
			printerr("Wrong breakdown at leg ", leg)
			quit(1)
			return
		if not loading and (game.casualty.get_parent() != game.ambulance or game.SERVICE_STOPS[leg] != game.STATION_DROP):
			printerr("Tow truck must carry its load to the station")
			quit(1)
			return
		game.ambulance.position = game._mission_destination()
		game.speed = 2
		game._update_arrival(game.HELP_DURATION)
		if game.recovery_leg != leg:
			printerr("Recovery advanced while moving")
			quit(1)
			return
		game.speed = 0
		game._update_arrival(game.HELP_DURATION)
		if game.recovery_leg != leg+1 or game.wallet != starting_balance + 20*floori((leg+1)/2.0):
			printerr("Unexpected recovery progress or payout at leg ", leg)
			quit(1)
			return
		if not loading and not game.phone.messages.has("Recovery complete. You earned 20 coins."):
			printerr("Missing delivery receipt")
			quit(1)
			return
	if game.phone.messages.count("Recovery complete. You earned 20 coins.") != 2:
		printerr("Expected one receipt per delivered car")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await process_frame
	print("Both breakdowns loaded at rest and delivered for 20 coins and one receipt each.")
	quit()
