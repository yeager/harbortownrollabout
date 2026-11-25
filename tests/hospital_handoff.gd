extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func fail(reason: String) -> void:
	printerr(reason)
	quit(1)

func verify() -> void:
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(0)
	game.start_button.pressed.emit()
	game.phone.open_button.pressed.emit()
	game.phone.take_job.pressed.emit()
	game.traffic_data.clear()
	var square: Vector3 = game._mission_destination()
	game.ambulance.position = square
	game.speed = 0.0
	game._help_at_target()
	if game.mission_index != 1 or game._vehicle_payload() != 75.0 or game.square_neighbour.visible:
		fail("Picking up the patient did not put them aboard the ambulance")
		return
	game.ambulance.position = Vector3(game.HOSPITAL_INTAKE_STOP.x, 0, -48.0)
	game.ambulance.basis = Basis.looking_at(Vector3.FORWARD)
	game._help_at_target()
	if game.mission_index != 1:
		fail("The patient could be dropped off from the street")
		return
	game.mouse_gas = true
	for step in 120:
		game._drive(.035)
		if game._at_target():
			break
	game.mouse_gas = false
	game.speed = 0.0
	if not game._at_target():
		fail("The ambulance could not drive into the intake: %s" % game.ambulance.position)
		return
	var coins: int = game.wallet
	game._help_at_target()
	game._help_at_target()
	if game.mission_index != 2 or game._vehicle_payload() != 0.0 or game.wallet != coins + 10:
		fail("Patient handoff did not complete exactly once")
		return
	var receipt_count: int = game.phone.delivery_receipts.count(game.phone.HOSPITAL_RECEIPT)
	if receipt_count != 1 or not game.square_neighbour.visible or not game.waiting_medic.visible:
		fail("The bay did not show the patient and medic or create the hospital receipt")
		return
	var bay_side := Vector3(125.7, 0, -54.3)
	if not game._on_foot_clear(bay_side) or game._on_foot_clear(Vector3(128, 0, -60)):
		fail("Walk access must reach the intake and stop at the hospital ward")
		return
	var receipt: String = game.phone.HOSPITAL_RECEIPT
	game.queue_free()
	await process_frame
	game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	if game.phone.delivery_receipts.count(receipt) != 1:
		fail("The hospital receipt was lost or duplicated on reload")
		return
	var resume := game.find_child("ResumeCheckpoint", true, false) as Button
	if not resume:
		fail("Patient handoff did not save the next mission step")
		return
	resume.pressed.emit()
	if game.vehicle_index != 0 or game.mission_index != 2 or game.wallet != coins + 10 or game._vehicle_payload() != 0.0:
		fail("The saved ambulance did not resume with the patient handed off and reward paid")
		return
	game._help_at_target()
	if game.mission_index != 2 or game.wallet != coins + 10 or game.phone.delivery_receipts.count(receipt) != 1:
		fail("The previous patient could be handed off again after resuming")
		return
	print("Ambulance drove into the hospital, handed off its patient once, and left a receipt. The ward stays closed.")
	quit()
