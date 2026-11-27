extends SceneTree
## Exercise each road vehicle through the menu and the normal driving routine.

func _initialize() -> void:
	call_deferred("check_gallery")

func check_y5_wheels(game) -> bool:
	for scene in [
		preload("res://vehicles/luxury_suv.glb"),
		preload("res://vehicles/traffic_suv_blue.glb"),
		preload("res://vehicles/traffic_suv_silver.glb"),
	]:
		var model := scene.instantiate() as Node3D
		root.add_child(model)
		var front := 0
		var rear := 0
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			if not (mesh.name.begins_with("Performance tire") or mesh.get_parent().name.begins_with("Performance tire")):
				continue
			var bounds: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
			var axle := bounds.get_center().z
			if absf(bounds.size.y - bounds.size.z) > .001 or absf(absf(axle) - 1.4875) > .001 or absf(bounds.position.y) > .001:
				printerr("Y5 tire is out of round, off its axle, or above the road in ", scene.resource_path)
				model.free()
				return false
			if axle < 0.0:
				front += 1
			else:
				rear += 1
		if front != 2 or rear != 2:
			printerr("Expected two Y5 tires per axle in ", scene.resource_path)
			model.free()
			return false
		var pivots: Array[Node3D] = game._rig_wheels(model)
		if pivots.size() != 4:
			printerr("Expected four rolling Y5 wheels in ", scene.resource_path)
			model.free()
			return false
		for pivot in pivots:
			var valves := pivot.find_children("Tire valve*", "MeshInstance3D", false, false)
			var caliper := pivot.get_parent().find_child("Red brake caliper*", false, false)
			if valves.size() != 3 or not caliper:
				printerr("Y5 wheel valves must roll with the rim and calipers must stay on the knuckle in ", scene.resource_path)
				model.free()
				return false
		model.free()
	return true

func check_wipers(game, spindle_pattern: String) -> bool:
	var spindles: Array[Node] = game.vehicle_model.find_children(spindle_pattern, "MeshInstance3D", true, false)
	var pivots: Array[Node3D] = game.wiper_pivots
	var expected_count := 2
	if game.vehicle_index == game.MULTUM:
		spindles.append_array(game.vehicle_model.find_children("Rear wiper spindle", "MeshInstance3D", true, false))
		expected_count = 3
	if spindles.size() != expected_count or pivots.size() != expected_count:
		return false
	for i in pivots.size():
		var spindle := spindles[i] as MeshInstance3D
		if not pivots[i].global_position.is_equal_approx(spindle.to_global(spindle.get_aabb().get_center())):
			return false
	game.weather.intensity = Vector2.RIGHT
	game._advance_wipers(PI / 5.4)
	var swept := pivots.all(func(pivot: Node3D): return not pivot.basis.is_equal_approx(Basis.IDENTITY))
	game.weather.intensity = Vector2.ZERO
	game._advance_wipers(TAU)
	return swept and pivots.all(func(pivot: Node3D): return pivot.basis.is_equal_approx(Basis.IDENTITY))

func check_gallery() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if not check_y5_wheels(game):
		quit(1)
		return
	game.steady_player_lights = true
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
		if index in [3, game.MULTUM, game.VOVLO_434]:
			var spindle_pattern: String = {
				3: "Windscreen wiper spindle cap*",
				game.MULTUM: "Windscreen wiper spindle*",
				game.VOVLO_434: "Wiper pivot*",
			}[index]
			if not check_wipers(game, spindle_pattern):
				printerr("Wipers must swing around their modeled spindles and park after rain on ", tile.text)
				quit(1)
				return
		game._update_traffic(0.0)
		var signals = game.driven_turn_signals
		if signals.left.size() < 2 or signals.right.size() < 2 or signals.direction != 1:
			printerr("Missing paired turn indicators or right turn intent on ", tile.text)
			quit(1)
			return
		if not signals.right.all(func(lamp: MeshInstance3D): return lamp.visible) or signals.left.any(func(lamp: MeshInstance3D): return lamp.visible):
			printerr("Turning right did not light only the right side of ", tile.text)
			quit(1)
			return
		if tile.text in ["Saav 97", "BWM M3 E33"] or index in [0, game.SHOPPER, game.A_TRACTOR, game.ICE_CREAM, game.MULTUM, game.VOVLO_434]:
			for lamps in [signals.left, signals.right]:
				var names: Array = lamps.map(func(lamp: MeshInstance3D): return String(lamp.get_parent().name))
				for prefix in ["Front amber indicator", "Rear indicator lens"]:
					if not names.any(func(lens_name: String): return lens_name.begins_with(prefix)):
						printerr("An indicator is missing its modeled lens on ", tile.text)
						quit(1)
						return
		if index == game.MULTUM:
			if game.player_wheels.size() != 4 or game.front_knuckles.size() != 2:
				printerr("Multum must have four wheel pivots and two steering knuckles")
				quit(1)
				return
			for wheel: Node3D in game.player_wheels:
				if is_zero_approx(wheel.rotation.x) or wheel.find_children("Alloy wheel rim lip*", "MeshInstance3D", true, false).size() != 1 or wheel.find_children("Alloy wheel swept spoke*", "MeshInstance3D", true, false).size() != 7:
					printerr("Each Multum wheel must roll with its rim lip and seven spokes")
					quit(1)
					return
		if index == game.VOVLO_434:
			if game.player_wheels.size() != 4 or game.front_knuckles.size() != 2:
				printerr("Vovlo 434 must have four rolling wheels and two steering knuckles")
				quit(1)
				return
			for wheel: Node3D in game.player_wheels:
				if is_zero_approx(wheel.rotation.x):
					printerr("A Vovlo 434 wheel did not roll")
					quit(1)
					return
				for pattern in ["Pressed steel wheel rim*", "Wheel hub cap*", "Tire valve stem*", "Tire valve cap*"]:
					if wheel.find_children(pattern, "MeshInstance3D", true, false).size() != 1:
						printerr("A Vovlo 434 wheel did not carry its ", pattern)
						quit(1)
						return
		if index == game.DAM_PICKUP:
			if game.player_wheels.size() != 4 or game.front_knuckles.size() != 2 or game.rear_tire_contacts.size() != 2:
				printerr("DAM pickup axle layout is incomplete")
				quit(1)
				return
			for wheel in game.player_wheels:
				if is_zero_approx(wheel.rotation.x):
					printerr("DAM pickup wheel did not roll")
					quit(1)
					return
		if index == game.QUATTRO:
			if tile.text != "Audo Sport Kvattro" or not game.vehicle_model.find_child("Kvattro badge", true, false):
				printerr("The Sport Kvattro needs its fictional name in the gallery and on the car")
				quit(1)
				return
			var rings: Array = game.vehicle_model.find_children("Polished grille ring*","MeshInstance3D",true,false)
			if rings.size() != 5 or game.cabin_wheel == null or not game.road_driver.visible:
				printerr("Quattro grille or driver layout is incomplete")
				quit(1)
				return
			if game.ambulance.to_local(game.cabin_wheel.global_position).x >= 0.0 or game.road_driver.position.x >= 0.0:
				printerr("Quattro driver or wheel moved off the left seat")
				quit(1)
				return
			for lamps in [signals.left, signals.right]:
				if not lamps.any(func(lamp: MeshInstance3D): return String(lamp.get_parent().name).begins_with("Rear indicator lens")):
					printerr("Quattro rear turn signal is detached from the taillight")
					quit(1)
					return
			var wheel_axis: Vector3 = game.cabin_wheel_axis
			var expected_axis := Vector3(0.0, sin(deg_to_rad(17.0)), cos(deg_to_rad(17.0)))
			var rest_basis: Basis = game.cabin_wheel_rest_basis
			var turned_basis: Basis = rest_basis.inverse() * game.cabin_wheel.basis
			if not wheel_axis.is_equal_approx(expected_axis) or turned_basis.is_equal_approx(Basis.IDENTITY) or not (turned_basis * wheel_axis).is_equal_approx(wheel_axis):
				printerr("Quattro steering wheel must lean toward the dash and turn around its tilted axis")
				quit(1)
				return
			if game.quattro_speed_needle == null or game.quattro_speed_needle.rotation.z >= 0.0:
				printerr("Quattro speedometer did not follow forward motion")
				quit(1)
				return
		if index in [2, game.SHOPPER, game.REFUSE, game.QUATTRO, game.A_TRACTOR, game.MULTUM, game.VOVLO_434]:
			var lens_pattern: String = {2: "Swept transparent headlamp cover*", game.MULTUM: "Lower headlight lens*"}.get(index, "Headlight lens*")
			var lenses: Array = game.vehicle_model.find_children(lens_pattern, "MeshInstance3D", true, false)
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
		if index in [game.SHOPPER, game.MULTUM]:
			for night in [true,false]:
				game.time_mode = 1 if night else 0
				game._update_daylight(0)
				if not game.headlights.all(func(beam: SpotLight3D): return beam.visible == night and (beam.light_energy > 0) == night) or (game.projector_finish.emission_energy_multiplier > 0) != night:
					printerr("Beams and lenses did not follow the day/night setting on ", tile.text)
					quit(1)
					return
		if index == game.SHOPPER:
			if tile.text != "Norrsjö Shoppa" or not game.vehicle_model.find_child("Norrsjö Shoppa rear badge", true, false):
				printerr("The shopping trike needs its fictional name in the gallery and on the body")
				quit(1)
				return
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
		Input.action_press("ui_down")
		for frame in 90:
			game._drive(1.0/60.0)
		Input.action_release("ui_down")
		if not is_zero_approx(game.speed):
			printerr("Holding the brake did not stop ", tile.text, " speed=", game.speed)
			quit(1)
			return
		if index in [game.DAM_PICKUP, game.MULTUM]:
			var brake: StandardMaterial3D = game.player_brake_lens
			var reverse: StandardMaterial3D = game.reverse_lens
			if brake == null or reverse == null or not brake.has_meta("centre_lamp") or not brake.get_meta("centre_lamp").emission_enabled or brake.emission_energy_multiplier < 2.39 or reverse.emission_energy_multiplier > 0:
				printerr("Braking did not light the red lenses only on ", tile.text)
				quit(1)
				return
		if index == game.QUATTRO:
			if game.player_brake_lens == null or game.reverse_lens == null or game.player_brake_lens.emission_energy_multiplier < 2.39 or game.reverse_lens.emission_energy_multiplier > 0:
				printerr("Quattro brake lights did not work independently of the reverse lights")
				quit(1)
				return
		if index == game.SHOPPER:
			var lens := game.vehicle_model.find_child("Tail lamp fluted lens", true, false) as MeshInstance3D
			if not lens or not game.player_brake_lens or lens.get_active_material(0) != game.player_brake_lens or game.player_brake_lens.emission_energy_multiplier < 2.39:
				printerr("The Shoppa's molded rear lens must light when braking")
				quit(1)
				return
		if index == game.MOWER:
			var tail_lenses: Array = game.vehicle_model.find_children("Mower rear lamp lens*", "MeshInstance3D", true, false)
			if tail_lenses.size() != 2 or not game.player_brake_lens or game.player_brake_lens.emission_energy_multiplier < 2.39 or not tail_lenses.all(func(lens: MeshInstance3D): return lens.get_active_material(0) == game.player_brake_lens):
				printerr("Both mower rear lenses must light when braking")
				quit(1)
				return
		var has_paired_reverse_lenses: bool = index in [game.REFUSE, game.MOWER, game.A_TRACTOR, game.FOOD_TRUCK, game.ICE_CREAM, game.MULTUM, game.VOVLO_434] or tile.text == "Saav 97"
		if has_paired_reverse_lenses:
			var lenses: Array = game.vehicle_model.find_children("Reversing lens*", "MeshInstance3D", true, false)
			if lenses.size() != 2 or not game.reverse_lens or game.reverse_lens.emission_energy_multiplier > 0.0 or not lenses.all(func(lens: MeshInstance3D): return lens.get_active_material(0) == game.reverse_lens):
				printerr("Expected two inactive reverse lenses when braking ", tile.text)
				quit(1)
				return
		game._drive(1.0/60.0)
		var stopped: Transform3D = game.ambulance.transform
		Input.action_press("ui_down")
		for frame in 60:
			game._drive(1.0/60.0)
		Input.action_release("ui_down")
		var reverse_travel: float = (game.ambulance.position - stopped.origin).dot(stopped.basis.z)
		if reverse_travel < .3 or game.speed >= 0:
			printerr("Reverse failed for ", tile.text, " distance=", reverse_travel)
			quit(1)
			return
		if has_paired_reverse_lenses and game.reverse_lens.emission_energy_multiplier < 1.99:
			printerr("Reverse lenses did not light on ", tile.text)
			quit(1)
			return
		if index in [game.DAM_PICKUP, game.MULTUM]:
			if game.reverse_lens.emission_energy_multiplier < 1.99 or game.player_brake_lens.get_meta("centre_lamp").emission_enabled:
				printerr("Reversing did not light the white lenses independently on ", tile.text)
				quit(1)
				return
		if index == game.QUATTRO:
			if game.reverse_lens.emission_energy_multiplier < 1.99 or game.player_brake_lens.emission_energy_multiplier >= 2.39:
				printerr("Quattro reverse lights did not activate independently")
				quit(1)
				return
		Input.action_press("ui_left")
		for frame in 20:
			game._drive(1.0 / 60.0)
		Input.action_release("ui_left")
		game._update_traffic(0.0)
		if signals.direction != -1 or not signals.left.all(func(lamp: MeshInstance3D): return lamp.visible) or signals.right.any(func(lamp: MeshInstance3D): return lamp.visible):
			printerr("Turning left did not light only the left side of ", tile.text)
			quit(1)
			return
		for frame in 45:
			game._drive(1.0 / 60.0)
		game._update_traffic(0.0)
		if signals.direction != 0:
			printerr("Indicators did not cancel after straightening ", tile.text)
			quit(1)
			return
	print("All ",game.VEHICLE_NAMES_ALL.size()," road vehicles started, moved, steered, braked and reversed from the picture menu.")
	for extra in game.EXTRA_GALLERY_NAMES.size():
		game.mode = "menu"
		var tile: Button = game.vehicle_selector.get_child(game.VEHICLE_NAMES_ALL.size() + extra)
		Input.action_press("ui_up")
		tile.pressed.emit()
		game.start_button.pressed.emit()
		var pedal_armed: bool = game._keyboard_pedals_available()
		Input.action_release("ui_up")
		game._keyboard_pedals_available()
		if pedal_armed:
			printerr("The special vehicle accepted a pedal already held on entry")
			quit(1)
			return
		if not tile.button_pressed or game.mode != "playing" or game.operating_excavator != (extra == 0) or (game.tram_mode == 2) != (extra == 1) or game.boating != (extra == 2):
			printerr("Wrong activity after selecting ", tile.text)
			quit(1)
			return
		if extra == 0:
			var original_look_key: int = game.look_key
			for look_key in [KEY_V, KEY_F12]:
				game.look_key = look_key
				game._refresh_ui()
				var expected_hint: String = game.tr("Hold %s and move the mouse to look around") % OS.get_keycode_string(look_key)
				if not game.driving_hints.text.contains(expected_hint):
					printerr("The excavator did not display its configured camera control")
					quit(1)
					return
			game.look_key = original_look_key
			var parked_pose: Transform3D = game.excavator.transform
			game.phone.toggle()
			Input.action_press("ui_up")
			Input.action_press("ui_left")
			game._drive_excavator(.1)
			Input.action_release("ui_left")
			game.phone.toggle()
			game._drive_excavator(.1)
			Input.action_release("ui_up")
			if not game.excavator.transform.is_equal_approx(parked_pose):
				printerr("Excavator moved behind the phone or before the accelerator was released")
				quit(1)
				return
			game._drive_excavator(.01)
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
			Input.action_press("ui_left")
			game._drive_excavator(.1)
			Input.action_release("ui_left")
			if game.excavator_turn_signals.direction != -1 or not game.excavator_turn_signals.left[0].visible:
				printerr("The tracked excavator did not signal left while turning")
				quit(1)
				return
	print("All three special vehicle pictures launched their driving activities.")
	game._finish_quit()
