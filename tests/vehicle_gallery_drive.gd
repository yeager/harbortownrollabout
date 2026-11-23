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
		if index in [game.SHOPPER, game.REFUSE]:
			var lenses: Array = game.vehicle_model.find_children("Headlight lens*", "MeshInstance3D", true, false)
			if lenses.size() != (1 if index == game.SHOPPER else 2) or lenses.size() != game.headlights.size():
				printerr("Headlight count differs from vehicle body")
				quit(1)
				return
			for i in lenses.size():
				var center: Vector3 = lenses[i].to_global(lenses[i].get_aabb().get_center())
				if center.distance_to(game.headlights[i].global_position) > .05:
					printerr("Headlight beam offset from lens")
					quit(1)
					return
		if index == game.SHOPPER:
			var mat := game.vehicle_model.find_child("Rubber foot mat*",true,false) as MeshInstance3D
			if mat == null:
				printerr("Shopping trike has no foot mat")
				quit(1)
				return
			var vehicle_frame: Transform3D = game.ambulance.global_transform.affine_inverse()
			var floor_bounds: AABB = (vehicle_frame*mat.global_transform)*mat.get_aabb()
			var mat_outline := Rect2(floor_bounds.position.x,floor_bounds.position.z,floor_bounds.size.x,floor_bounds.size.z)
			for alma in [false,true]:
				game.play_as_alma = alma
				game._refresh_ui()
				var pose = game.road_driver.get_node("AlmaShopperLegs" if alma else "AxelShopperLegs")
				for boot_index in [2,5]:
					var boot: MeshInstance3D = pose.get_child(boot_index)
					var bounds: AABB = (vehicle_frame*boot.global_transform)*boot.get_aabb()
					var sole := Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z)
					if not pose.visible or absf(bounds.position.y-floor_bounds.end.y) > .025 or not mat_outline.encloses(sole):
						printerr("Shopping trike boot outside footwell: ",bounds)
						quit(1)
						return
			if game.player_wheels.size() != 3 or game.front_knuckles.size() != 2 or game.rear_tire_contacts.size() != 1:
				printerr("Shopping trike axle layout changed")
				quit(1)
				return
			for joint in game.front_knuckles:
				var inside: bool = game.ambulance.to_local(joint.global_position).x > 0
				if (absf(joint.rotation.y) > game.steering * deg_to_rad(33.0)) != inside:
					printerr("Shopping trike inner and outer steering angles disagree")
					quit(1)
					return
			for wheel in game.player_wheels:
				if is_zero_approx(wheel.rotation.x):
					printerr("Stationary shopping trike wheel while driving")
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
		if extra == 0:
			var origin: Vector3 = game.excavator.position
			Input.action_press("ui_up")
			for frame in 240:
				game._drive_excavator(1.0 / 240.0)
			Input.action_release("ui_up")
			var released: Vector3 = game.excavator.position
			for frame in 240:
				game._drive_excavator(1.0 / 240.0)
			if origin.distance_to(released) < 1.5 or released.distance_to(game.excavator.position) < .45 or game.crawler_speed != 0:
				printerr("Excavator did not accelerate and coast to rest")
				quit(1)
				return
	print("All three special vehicle pictures launched their driving activities.")
	game._finish_quit()
