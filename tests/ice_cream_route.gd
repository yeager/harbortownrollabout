extends SceneTree

func _initialize() -> void:
	call_deferred("check_route")

func check_route() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.ICE_CREAM)
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	if not game.free_drive or not game.phone.take_job.is_visible_in_tree():
		printerr("The vehicle must start in free exploration and offer a job in the phone")
		quit(1)
		return
	game.phone.take_job.pressed.emit()
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
		if leg == 1:
			game.gentle_driving = false
			game._help_at_target()
		else:
			game.gentle_driving = true
			game._update_arrival(game.HELP_DURATION)
		if game.wallet != starting_balance + 10 * (leg+1) or game.horn.stream.resource_path != "res://audio/horn_icecream.wav":
			printerr("Missing payout or van chime")
			quit(1)
			return
	var receipt: String = game.tr("Ice cream served! You earned 10 points and 10 coins.")
	if game.mode != "complete" or game.passenger.visible or not game.subtitle_label.text.ends_with(receipt):
		printerr("Ice cream route did not finish")
		quit(1)
		return
	print("Three ice cream customers served, three payouts and the van chime verified.")
	game._request_quit()
	game.quit_dialog.confirmed.emit()
