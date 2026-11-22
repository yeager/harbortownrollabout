extends SceneTree
## Exercise each road vehicle through the menu and the normal driving routine.

func _initialize() -> void:
	call_deferred("check_gallery")

func check_gallery() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for index in game.VEHICLE_NAMES_ALL.size():
		game.mode = "menu"
		var tile: Button = game.vehicle_selector.get_child(index)
		tile.pressed.emit()
		game.start_button.pressed.emit()
		var start: Transform3D = game.ambulance.transform
		Input.action_press("ui_up")
		Input.action_press("ui_right", .35)
		for frame in 60:
			game._drive(1.0/60.0)
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		var travel: float = start.origin.distance_to(game.ambulance.position)
		var turn: float = start.basis.z.angle_to(game.ambulance.basis.z)
		if game.vehicle_index != index or travel < .3 or turn < .005:
			printerr("Menu driving failed for ",tile.text," distance=",travel," turn=",turn)
			quit(1)
			return
		game.ambulance.transform = start
		game.speed = 0.0
		Input.action_press("ui_down")
		for frame in 60:
			game._drive(1.0/60.0)
		Input.action_release("ui_down")
		var reverse_travel: float = (game.ambulance.position - start.origin).dot(start.basis.z)
		if reverse_travel < .3 or game.speed >= 0:
			printerr("Reverse failed for ", tile.text, " distance=", reverse_travel)
			quit(1)
			return
	print("All ",game.VEHICLE_NAMES_ALL.size()," road vehicles started, moved, steered and reversed from the picture menu.")
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	quit()
