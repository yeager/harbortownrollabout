extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func fail(reason: String) -> void:
	printerr(reason)
	quit(1)

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	var lights = game.street_signals
	var train = game.tram
	var approach := Vector3(.8660254,0,.5)
	var stop_point := Vector3(-lights.WEST_STOP_DISTANCE,0,1.85)
	lights.phase = 3
	if not is_equal_approx(lights.red_clearance(stop_point-approach*5,approach,2,true),3.0):
		fail("Angled approach missed the red stop line")
		return
	if lights.red_clearance(stop_point+Vector3.BACK*8-approach*5,approach,2,true) < INF:
		fail("Stop line extended beyond the crossing")
		return
	lights.advance(0)
	if lights.tram_crossings.size()!=6:
		fail("Missing crossing signals")
		return
	for c in lights.tram_crossings:
		for stage in lights.STAGE_SECONDS.size():
			c.stage = stage
			lights._show_crossing(c)
			for group in ["boulevard","side"]:
				var green_stage: int = lights.Stage.BOULEVARD if group=="boulevard" else lights.Stage.SIDE_STREET
				var expected := 2 if stage==green_stage else 1 if stage==green_stage+1 else 0
				for head in c[group]:
					for i in 3:
						if head.lamps[i].visible!=(i==expected):
							fail("Signal lamp disagrees with phase")
							return
			for head in c.pedestrians:
				if head.figures[1].visible!=(stage==lights.Stage.WALK) or head.figures[0].visible==head.figures[1].visible:
					fail("Pedestrian phases conflict")
					return
	var crossing: Dictionary = lights.tram_crossings.back()
	for manual in [false,true]:
		crossing.stage=lights.Stage.SIDE_STREET
		crossing.timer=-20
		train.distance=crossing.offset-35
		train.velocity=7
		train.dwell=0
		train.place_sections()
		for i in 120: train.advance(.1,manual,true,false)
		var gap: float = crossing.offset-train.distance-lights.BOULEVARD_LINE-train.CAB_REACH
		if absf(gap)>.08 or train.velocity>.01:
			fail("Tram failed to stop at red, gap %f" % gap)
			return
		crossing.stage=lights.Stage.BOULEVARD
		crossing.timer=0
		for i in 30: train.advance(.1,manual,true,false)
		if train.velocity<1:
			fail("Tram failed to restart at green")
			return
	var car: Dictionary = train.road_cars[0]
	var unobstructed: Array[AABB] = []
	for travel in [-1,1]:
		car.direction=travel
		car.offset=float(crossing.offset)-travel*30
		car.actor.transform=train._carriageway_pose(car.offset,travel)
		car.speed=car.cruise
		crossing.stage=lights.Stage.SIDE_STREET
		for i in 100: train._advance_road_cars(.1,unobstructed)
		var remaining: float = (float(crossing.offset)-float(car.offset))*travel-lights.BOULEVARD_LINE-float(car.length)
		if absf(remaining)>.15 or car.speed>.15:
			fail("Boulevard traffic crossed a red signal: %f" % remaining)
			return
		crossing.stage=lights.Stage.BOULEVARD
		var initial: float = car.offset
		for i in 20: train._advance_road_cars(.1,unobstructed)
		if (float(car.offset)-initial)*travel<=1:
			fail("Boulevard traffic did not restart on green")
			return
	var axis: Vector3 = crossing.across
	game.ambulance.position = crossing.center-axis*25+axis.cross(Vector3.UP)*2.3
	game.ambulance.basis=Basis.looking_at(axis)
	game.allow_red_lights=false
	game.mouse_gas=true
	game.speed=7
	for i in 120: game._drive(.1)
	var car_gap: float = (Vector3(crossing.center)-game.ambulance.position).dot(axis)-lights.SIDE_LINE-game.front_reach
	if absf(car_gap)>.25 or absf(game.speed)>.05:
		fail("Player car failed to stop at red, gap %f" % car_gap)
		return
	game.allow_red_lights = true
	for i in 20: game._drive(.1)
	if (Vector3(crossing.center)-game.ambulance.position).dot(axis) >= lights.SIDE_LINE+game.front_reach or game.message != "Red light! Stop at the line and wait for green.":
		fail("Crossing red with permission must show the traffic rule")
		return
	var original_locale := TranslationServer.get_locale()
	var warning_key := "Red light! Stop at the line and wait for green."
	for locale in ["en", "sv", "de", "es", "fi", "fr", "nb"]:
		TranslationServer.set_locale(locale)
		game._refresh_status()
		var expected := String(TranslationServer.translate(warning_key))
		if (locale != "en" and expected == warning_key) or game.status_label.tr(game.status_label.text) != expected:
			fail("Active red-light warning did not follow locale "+locale)
			return
	TranslationServer.set_locale(original_locale)
	for index in game.shops.SHOPS.size():
		var x: float = game.shops.storefront_x(index)
		for crashes in [true,false]:
			game.allow_crashes = crashes
			game.ambulance.position = Vector3(x,0,38)
			game.ambulance.basis = Basis.looking_at(Vector3.BACK)
			game.speed = 5
			for tick in 35: game._drive(.1)
			if game.ambulance.position.z+game.front_reach > game.shops.FRONT_Z+.05:
				fail("Vehicle entered a shop")
				return
		if index == 2:
			for z in [42.0,43.0]:
				if not game._on_foot_clear(Vector3(x,0,z)):
					fail("Pizzeria doorway blocked on foot")
					return
	var user: Vector3 = Vector3(crossing.center) + Vector3(crossing.tangent)*lights.ZEBRA_OFFSET
	if lights.pedestrian_may_enter(user+axis*8.75,user+axis*8.65):
		fail("Red figure let pedestrian enter")
		return
	crossing.stage=lights.Stage.WALK
	if not lights.pedestrian_may_enter(user+axis*8.75,user+axis*8.65):
		fail("Green figure blocked pedestrian")
		return
	train.distance=crossing.offset
	train.place_sections()
	crossing.stage=lights.Stage.CLEAR_BOULEVARD
	crossing.timer=20
	lights.advance_tram_crossings(.1)
	if crossing.stage!=lights.Stage.CLEAR_BOULEVARD:
		fail("Granted crossing traffic green underneath tram")
		return
	train.distance = crossing.offset + 50
	train.place_sections()
	var traffic_actor: Node3D = game.traffic_data[0].actor
	traffic_actor.position = crossing.center
	crossing.stage = lights.Stage.CLEAR_SIDE
	crossing.timer = 20
	lights.advance_tram_crossings(.1)
	if crossing.stage != lights.Stage.CLEAR_SIDE:
		fail("Granted pedestrians green while street traffic occupied the crossing")
		return
	# A pedestrian on the station crossing stops its lane. Moving to the far
	# pavement must release the queue even while the person remains nearby.
	var station: Node3D = train.stations[1]
	var cars: Array = train.road_cars.filter(func(item): return item.direction > 0)
	for index in cars.size():
		var queued_car: Dictionary = cars[index]
		queued_car.offset = train.stops[1] - 8.0 - index*17.0
		queued_car.actor.transform = train._carriageway_pose(queued_car.offset,1)
		queued_car.speed = 5.0
	var pedestrian := AABB(station.to_global(Vector3(4,0,-8))-Vector3(.3,0,.3),Vector3(.6,1.8,.6))
	var users: Array[AABB] = [pedestrian]
	for tick in 240:
		train._advance_road_cars(.05,users)
	var lead: Dictionary = cars[0]
	var following: Dictionary = cars[1]
	if lead.speed > .01 or following.speed > .01 or lead.offset-following.offset < lead.length+following.length+.99:
		fail("Queue failed to stop with clearance at Lindparken")
		return
	var stopped_at := float(lead.offset)
	if stopped_at < train.stops[1] or stopped_at + lead.length > train.stops[1]+6.3:
		fail("Leading car did not stop at the platform crossing")
		return
	users[0].position = station.to_global(Vector3(-10,0,-8))-Vector3(.3,0,.3)
	for tick in 80:
		train._advance_road_cars(.05,users)
	if following.speed < 1 or lead.offset < stopped_at+5:
		fail("Pedestrian on opposite pavement held the station queue")
		return
	finish.call_deferred(game)

func finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	# Give the audio mixer time to release the stopped siren and radio streams.
	await create_timer(.4).timeout
	print("All six crossings, all eight phases, manual and automatic tram stopping, driver stopping, pedestrian permission and junction clearance verified.")
	quit()
