extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func fail(reason: String) -> void:
	printerr(reason)
	quit(1)

func verify() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	world._start_game()
	var train = world.tram
	var length: float = train.track.get_baked_length()
	if length < 650 or train.stops.size()!=4 or train.road_cars.size()!=4:
		fail("Incomplete tram corridor")
		return
	for i in train.stations.size():
		var station: Node3D = train.stations[i]
		var toe := station.to_global(Vector3(2.81,0,-6.999))
		if absf(train.platform_height(toe)-world._surface_height(toe.x,toe.z)) > .002:
			fail("Step from road to ramp at stop "+str(i))
			return
		if world._on_foot_clear(station.to_global(Vector3(3.8,.29,.9))):
			fail("Can walk through shelter glass at stop "+str(i))
			return
		if not world._on_foot_clear(station.to_global(Vector3(2.8,.29,.9))):
			fail("Shelter blocks boarding aisle at stop "+str(i))
			return
		var signs = train.stations[i].find_children("*","Label3D",true,false)
		if signs.size()!=2 or signs[0].text!=train.STATION_NAMES[i] or signs[1].text!=train.STATION_NAMES[i]:
			fail("Incorrect platform sign at stop "+str(i))
			return
	for metre in ceili(length):
		var p: Vector3 = train.track.sample_baked(metre)
		if absf(p.y-world._surface_height(p.x,p.z))>.12:
			fail("Track not at street level at "+str(p))
			return
		for side in [-1,1]:
			var pose: Transform3D = train._carriageway_pose(metre,side)
			if world._surface_height(pose.origin.x,pose.origin.z)<-.1:
				fail("Traffic lane runs off-road at "+str(pose.origin))
				return
	world._change_seat()
	for stop in train.stations.size():
		train.stop_at_station(stop)
		train.advance(1,false,false,false)
		for car: Node3D in train.sections:
			for side in [-1,1]:
				var doorway := car.to_global(Vector3(1.5,.29,.13))
				world.walker.position = car.to_global(Vector3(2.8,.29,.13+side*.55))
				world.walker.look_at(Vector3(doorway.x,world.walker.position.y,doorway.z))
				Input.action_press("ui_up")
				for frame in 60:
					world._walk(1.0/60)
					if world.tram_mode == 1: break
				Input.action_release("ui_up")
				if world.tram_mode != 1:
					fail("Diagonal boarding failed at stop %d, car %s, side %d" % [stop,car.name,side])
					return
				world._change_seat()
				if not world.walker.visible or train.platform_at(world.walker.position) != stop:
					fail("Alighting failed at stop "+str(stop))
					return
	train.stop_at_station(0)
	train.advance(1,false,false,false)
	var platform: Node3D = train.stations[0]
	world.walker.position = platform.to_global(Vector3(2.8,.29,0))
	world.walker.rotation.y = platform.global_rotation.y + PI / 2
	Input.action_press("ui_up")
	for frame in 60:
		world._walk(1.0/60)
		if world.tram_mode == 1: break
	Input.action_release("ui_up")
	if world.tram_mode != 1 or world.walker.visible:
		fail("Could not board through open doors")
		return
	var reached := 0
	var previous: int = train.next_stop
	# A full circuit includes six independently timed junctions.
	for tick in 4200:
		train.advance(.1,false,false,false)
		if world.tram.open_station()<0:
			world._change_seat()
			if world.tram_mode!=1:
				fail("Could leave train between stations")
				return
		if train.next_stop!=previous:
			var expected: String = train.STATION_NAMES[train.next_stop]
			if train.next_stop_display.text!=expected or train.front_display.text!=expected or train.rear_display.text!=expected or train.interior_displays.size()!=3:
				fail("Missing or incorrect destination display")
				return
			for display in train.interior_displays:
				if display.text!=expected:
					fail("Incorrect saloon display before "+expected)
					return
			reached+=1
			previous=train.next_stop
			if reached==4: break
	if reached!=4 or train.distance!=0:
		fail("Failed to complete four-stop service")
		return
	train.advance(1,false,false,false)
	world.free_drive = true
	world._refresh_ui()
	world.map_button.pressed.emit()
	var map: AcceptDialog = world.get_node("TownMap")
	if not map.visible:
		fail("Could not open the map aboard the tram")
		return
	var chart = map.get_child(0).get_child(0)
	chart.picked.emit(0)
	var destination_after_tram: Vector3 = chart.stops[0]
	if world.map_goal != destination_after_tram:
		fail("Could not choose a destination aboard the tram")
		return
	world._change_seat()
	if world.tram_mode!=0 or not world.walker.visible or train.platform_at(world.walker.position)!=0:
		fail("Could not alight on platform")
		return
	world._update_route_arrows()
	if world.map_goal != destination_after_tram or not world.route_arrows.any(func(arrow): return arrow.visible):
		fail("Walking guidance did not resume after leaving the tram")
		return
	world.map_button.pressed.emit()
	var route: PackedVector2Array = chart.route_preview
	var platform_position := Vector2(world.walker.position.x, world.walker.position.z)
	var destination_point := Vector2(destination_after_tram.x, destination_after_tram.z)
	if route.size() < 2 or not route[0].is_equal_approx(platform_position) or not route[-1].is_equal_approx(destination_point):
		fail("Map route did not connect the player's position on the platform to the destination")
		return
	map.hide()
	# Stand on the track and verify service stops before the train reaches the player.
	var ahead: Vector3 = train.track.sample_baked(16)
	world.walker.position = ahead
	for tick in 100: train.advance(.2,false,false,false)
	if train.distance>=14 or train.distance<8 or train.velocity>.01:
		fail("Unsafe approach to player on tracks at offset "+str(train.distance))
		return
	world.walker.position=platform.to_global(Vector3(2.8,.29,0))
	for tick in 30: train.advance(.2,true,true,false)
	if train.distance <= 16:
		fail("Driver could not restart with clear track")
		return
	for role in [1, 2]:
		world._select_gallery_activity(role + 1)
		var saved_distance: float = train.distance
		var destination: int = train.next_stop
		world._save_checkpoint()
		world.queue_free()
		await process_frame
		world = load("res://main.tscn").instantiate()
		root.add_child(world)
		world._resume_road_checkpoint()
		train = world.tram
		if world.tram_mode != role or not is_equal_approx(saved_distance, train.distance) or train.next_stop != destination:
			fail("Lost tram trip after restart")
			return
		var mouse_hint := tr("Hold left mouse to accelerate or right mouse to brake.")
		if world.driving_hints.text.contains(mouse_hint) != (role == 2):
			fail("Tram mouse help does not match the player's role")
			return
		for frame in 60:
			train.advance(.05, role == 2, role == 2, false)
		if train.distance <= saved_distance:
			fail("Resumed tram did not move")
			return
	var exit_key := InputEventKey.new()
	exit_key.pressed = true
	exit_key.keycode = KEY_F
	world._unhandled_key_input(exit_key)
	if world.tram_mode != 2 or not world.tram_driver_exit_requested:
		fail("Driving exit request did not wait for the platform")
		return
	var exit_station: int = train.next_stop
	world._save_checkpoint()
	world.queue_free()
	await process_frame
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	world._resume_road_checkpoint()
	train = world.tram
	if world.tram_mode != 2 or not world.tram_driver_exit_requested or not world.seat_button.disabled:
		fail("The pending tram exit was lost after reload")
		return
	world.mouse_gas = true
	for tick in 1800:
		world._process(.05)
		if world.tram_mode == 0: break
	world.mouse_gas = false
	if world.tram_mode != 0 or not world.walker.visible or train.platform_at(world.walker.position) != exit_station:
		fail("The driver did not leave when the doors opened at the platform")
		return
	print("Verified ", snappedf(length,.1), " m of at-grade track, opposing traffic lanes, four station stops, boarding, alighting and person protection.")
	quit()
