extends SceneTree
## Exercise each road vehicle through the menu and the normal driving routine.

func _initialize() -> void:
	call_deferred("check_gallery")

func check_gallery() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var expected_tiles: int = game.VEHICLE_NAMES_ALL.size() + game.EXTRA_GALLERY_NAMES.size()
	if game.vehicle_selector.get_child_count() != expected_tiles:
		printerr("Missing vehicle picture buttons")
		quit(1)
		return
	var thumbnails := {}
	var atlas_image := preload("res://vehicles/menu_thumbnails.png").get_image()
	for tile: Button in game.vehicle_selector.get_children():
		var picture := tile.icon as AtlasTexture
		if not picture or picture.atlas != preload("res://vehicles/menu_thumbnails.png") or thumbnails.has(picture.region):
			printerr("Missing or reused picture on ", tile.text)
			quit(1)
			return
		var image := atlas_image.get_region(Rect2i(picture.region))
		if image.get_used_rect().has_area() == false:
			printerr("Empty vehicle picture on ", tile.text)
			quit(1)
			return
		thumbnails[picture.region] = true
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
	for extra in game.EXTRA_GALLERY_NAMES.size():
		game.mode = "menu"
		var tile: Button = game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size() + extra)
		tile.pressed.emit()
		game.start_button.pressed.emit()
		if not tile.button_pressed or game.mode != "playing" or game.operating_excavator != (extra == 0) or (game.tram_mode == 2) != (extra == 1) or game.boating != (extra == 2):
			printerr("Wrong activity after selecting ", tile.text)
			quit(1)
			return
	print("All three special vehicle pictures launched their driving activities.")
	game._finish_quit()
