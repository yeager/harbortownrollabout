extends SceneTree

func _initialize() -> void:
	call_deferred("check_resume")

func check_resume() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size()).pressed.emit()
	game.start_button.pressed.emit()
	game.mouse_gas = true
	game.mouse_steering = .1
	for frame in 30:
		game._drive_excavator(1.0 / 60)
	game.cab_turntable.rotation.y = .6
	game.boom_joint.rotation.x = -.6
	game.stick_joint.rotation.x = .2
	game.bucket_joint.rotation.x = -.3
	game._drive_excavator(0)
	var bucket_pose: Transform3D = game.bucket_joint.global_transform
	var base: Transform3D = game.excavator.transform
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if not game.operating_excavator or game.listener.get_parent() != game.cab_turntable or not game.excavator.transform.is_equal_approx(base) or not game.bucket_joint.global_transform.is_equal_approx(bucket_pose):
		printerr("Excavator or bucket pose lost after restart")
		quit(1)
		return
	game.mouse_gas = true
	for frame in 45:
		game._process(1.0 / 60)
	if game.excavator.position.distance_to(base.origin) < .5:
		printerr("Excavator did not drive after restart")
		quit(1)
		return
	print("Restored excavator and articulated bucket, then drove away.")
	game.queue_free()
	await process_frame
	quit()
