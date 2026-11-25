extends SceneTree

func _initialize() -> void:
	call_deferred("check_routes")

func check_routes() -> void:
	var scene := preload("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	var receipt_count_after_pickup := 0
	for vehicle in [0, 1, 2, 3, game.XC60_POLICE, game.FARM_TRACTOR, game.FOOD_TRUCK, game.SNOWMOBILE, game.DAM_PICKUP]:
		game._on_vehicle_selected(vehicle)
		game.start_button.pressed.emit()
		game.phone.open_button.pressed.emit()
		game.phone.take_job.pressed.emit()
		var balance: int = game.wallet
		var points: int = game.delivery_points
		var receipt_count: int = game.phone.delivery_receipts.size()
		for step in game.TARGETS.size():
			var target: Vector3 = game._mission_destination()
			var instruction: String = game.phone.current_job
			game.queue_free()
			await process_frame
			game = scene.instantiate()
			root.add_child(game)
			var resume := game.find_child("ResumeCheckpoint", true, false) as Button
			if not resume:
				printerr("Missing automatic checkpoint for vehicle ", vehicle, " step ", step)
				quit(1)
				return
			resume.pressed.emit()
			if game.vehicle_index != vehicle or game.mission_index != step or game._mission_destination() != target or game.phone.current_job != instruction:
				printerr("Lost instruction or destination for vehicle ", vehicle, " step ", step)
				quit(1)
				return
			if vehicle == game.DAM_PICKUP:
				var expected_payload: float = [0.0, 41.0, 9.0][step]
				if not is_equal_approx(game._vehicle_payload(),expected_payload) or game.phone.delivery_receipts.size() != receipt_count + maxi(0,step-1):
					printerr("Pickup lost its payload or receipt history after restart at step ",step)
					quit(1)
					return
			game.ambulance.position = target
			game._help_at_target()
			if vehicle == 2 and step == 2:
				game._update_arrival(2.5)
			if game.wallet != balance + 10 * (step + 1) or game.delivery_points != points + 10 * (step + 1):
				printerr("Incorrect reward after restart for vehicle ", vehicle, " step ", step)
				quit(1)
				return
		if game.mode != "complete":
			printerr("Route did not finish for vehicle ", vehicle)
			quit(1)
			return
		if vehicle == game.DAM_PICKUP:
			receipt_count_after_pickup = receipt_count + 2
		game.queue_free()
		await process_frame
		game = scene.instantiate()
		root.add_child(game)
	if game.phone.delivery_receipts.size() != receipt_count_after_pickup or game.phone.delivery_receipts[-2] != game.phone.CLINIC_RECEIPT or game.phone.delivery_receipts[-1] != game.phone.MARINA_RECEIPT:
		printerr("Pickup receipts were not retained after completing the route")
		quit(1)
		return
	print("Resumed and completed all 27 steps across nine mission vehicles, including pickup payload and receipts.")
	quit()
