extends SceneTree

func _initialize() -> void:
	verify.call_deferred()

func verify() -> void:
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.DAM_PICKUP)
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	var expected_receipts := PackedStringArray([game.phone.CLINIC_RECEIPT, game.phone.MARINA_RECEIPT])
	var starting_wallet: int = game.wallet
	for leg in range(3):
		game.ambulance.position = game._mission_destination()
		game.speed = 0.0
		game._help_at_target()
		game._help_at_target()
		var onboard := 0
		for parcel: Node3D in game.delivery_parcels:
			if parcel.is_visible_in_tree() and parcel.get_parent() == game.ambulance:
				onboard += 1
		var expected_mass: float = [41.0, 9.0, 0.0][leg]
		if onboard != 2 - leg or not is_equal_approx(game._vehicle_payload(), expected_mass):
			printerr("Visible freight and payload did not agree after stop ", leg)
			quit(1)
			return
		if game.mission_index != leg + 1 or game.wallet != starting_wallet + 10 * (leg + 1) or game.phone.delivery_receipts != expected_receipts.slice(0, leg):
			printerr("Freight stop did not advance, pay and record its receipt exactly once: ", leg)
			quit(1)
			return
		game.queue_free()
		await process_frame
		game = preload("res://main.tscn").instantiate()
		root.add_child(game)
		if game.phone.delivery_receipts != expected_receipts.slice(0, leg) or game.wallet != starting_wallet + 10 * (leg + 1):
			printerr("Freight receipts changed on restart after stop ", leg)
			quit(1)
			return
		if leg < 2:
			game._resume_road_checkpoint()
			if game.vehicle_index != game.DAM_PICKUP or game.mission_index != leg + 1 or not is_equal_approx(game._vehicle_payload(), expected_mass):
				printerr("Freight checkpoint did not restore the pickup, stop and load after stop ", leg)
				quit(1)
				return
	if game.find_child("ResumeCheckpoint", true, false):
		printerr("Completed freight run remained resumable")
		quit(1)
		return
	game.phone.receipt_menu.about_to_popup.emit()
	var receipts: PopupMenu = game.phone.receipt_menu.get_popup()
	if receipts.item_count != expected_receipts.size():
		printerr("The phone did not list both saved receipts")
		quit(1)
		return
	for index in receipts.item_count:
		var receipt_id := receipts.get_item_id(index)
		receipts.id_pressed.emit(receipt_id)
		if game.phone.receipt_dialog.dialog_text != game.tr(expected_receipts[receipt_id]):
			printerr("The phone did not reopen the selected receipt")
			quit(1)
			return
		game.phone.receipt_dialog.hide()
	print("Two visible parcels, decreasing payload, mid-route resume and both persistent delivery receipts verified.")
	game._finish_quit(false)
