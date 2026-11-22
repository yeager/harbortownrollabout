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
	world._change_seat()
	if world.tram_mode!=0 or not world.walker.visible or train.platform_at(world.walker.position)!=0:
		fail("Could not alight on platform")
		return
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
	print("Verified ", snappedf(length,.1), " m of at-grade track, opposing traffic lanes, four station stops, boarding, alighting and person protection.")
	quit()
