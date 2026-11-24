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
	# Amber requests braking, but crossing the line is only a red-light
	# violation once the red lens is lit.
	lights.elapsed = 6.5
	lights.advance(0)
	for head in lights.heads:
		if head.has("lamps") and head.east_west:
			if head.lamps[0].visible or not head.lamps[1].visible or head.lamps[2].visible:
				fail("East-west amber must light only the middle lens")
				return
	var before_line := stop_point - approach*5
	if not is_equal_approx(lights.red_clearance(before_line,approach,2),3.0):
		fail("Amber did not request braking at the stop line")
		return
	if lights._central_clearance(before_line,approach,2,true) < INF:
		fail("Amber was counted as a red-light violation")
		return
	lights.elapsed = 0
	for zebra in lights.street_crosswalks:
		for side in [-1,1]:
			var axis: Vector3 = zebra.axis * side
			var curb: Vector3 = zebra.center + axis*(zebra.curb_distance+.1)
			lights.phase = (zebra.walk_phase+1)%6
			if lights.pedestrian_may_enter(curb,curb-axis*.2) or not lights.pedestrian_may_enter(curb-axis*.2,curb):
				fail("Pedestrian red must block entry and allow exit")
				return
			if not lights.pedestrian_may_enter(curb-axis*.2,curb-axis*.6):
				fail("Pedestrian already crossing stopped on red")
				return
			var lateral := axis.cross(Vector3.UP)
			var end := curb-axis*.4
			if lights.pedestrian_may_enter(curb+lateral*1.3,end+lateral*1.6):
				fail("Diagonal step crossed the marked curb on red")
				return
			if not lights.pedestrian_may_enter(curb+lateral*1.6,end+lateral*1.3):
				fail("Diagonal step outside the marked curb was blocked")
				return
			lights.phase = zebra.walk_phase
			if not lights.pedestrian_may_enter(curb,curb-axis*.2):
				fail("Pedestrian green must allow entry")
				return
	lights.advance(0)
	# Sample two cycles so a red interval crossing the timer wrap is measured too.
	var red_seconds := [0.0, 0.0]
	var longest_red := [0.0, 0.0]
	for tick in 320:
		lights.advance(.1)
		for direction in 2:
			if lights.heads[direction].lamps[0].visible:
				red_seconds[direction] += .1
				longest_red[direction] = maxf(longest_red[direction], red_seconds[direction])
			else:
				red_seconds[direction] = 0.0
	for seconds: float in longest_red:
		if seconds <= 0.0 or seconds > 10.001:
			fail("Unexpected red-light duration: %f seconds" % seconds)
			return
	print("Longest central red per direction: ", longest_red)
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
				var walk_stage: int = lights.Stage.SIDE_STREET if c.center.is_equal_approx(Vector3(train.EAST,0,0)) else lights.Stage.WALK
				if head.figures[1].visible!=(stage==walk_stage) or head.figures[0].visible==head.figures[1].visible:
					fail("Pedestrian phases conflict")
					return
	# Isolate a stop line away from the town traffic. A long rear overhang
	# must not count as an equally long nose while the driver waits at red.
	var isolated := {"center": Vector3(400, 0, 400), "tangent": Vector3.FORWARD}
	var original_pose: Transform3D = game.ambulance.transform
	var original_front: float = game.front_reach
	var original_rear: float = game.rear_reach
	var original_size: Vector2 = game.player_half_size
	game.front_reach = 1.5
	game.rear_reach = 5.5
	game.player_half_size = Vector2(1.2, 5.5)
	game.ambulance.transform = Transform3D(Basis.IDENTITY, isolated.center + Vector3.BACK * (lights.BOULEVARD_LINE + game.front_reach))
	if lights._junction_occupied(isolated):
		fail("A vehicle behind the stop line held the crossing at red")
		return
	game.ambulance.position.z -= 4
	if not lights._junction_occupied(isolated):
		fail("A vehicle entering the crossing was missed")
		return
	game.ambulance.transform = original_pose
	game.front_reach = original_front
	game.rear_reach = original_rear
	game.player_half_size = original_size
	var parked: Node3D = game.parked_cars[game.vehicle_index]
	var original_parking := parked.transform
	parked.position = isolated.center
	parked.show()
	if not lights._junction_occupied(isolated):
		fail("A parked vehicle in the crossing was missed")
		return
	parked.hide()
	if lights._junction_occupied(isolated):
		fail("Hidden parking model held the crossing at red")
		return
	parked.transform = original_parking
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
	var red_stage: int = crossing.stage
	crossing.stage = lights.Stage.SIDE_AMBER
	var saw_amber_hint := false
	for tick in 100:
		game._drive(.1)
		game._refresh_status()
		if game.status_label.text == game.tr("Orange light. Slow down."):
			saw_amber_hint = true
			break
	if not saw_amber_hint:
		fail("Driver missed the orange light braking hint")
		return
	crossing.stage = red_stage
	for i in 120: game._drive(.1)
	var car_gap: float = (Vector3(crossing.center)-game.ambulance.position).dot(axis)-lights.SIDE_LINE-game.front_reach
	if absf(car_gap)>.25 or absf(game.speed)>.05:
		fail("Player car failed to stop at red, gap %f" % car_gap)
		return
	var saved_stage: int = crossing.stage
	crossing.stage = lights.Stage.SIDE_STREET
	crossing.blocked_entry = true
	game._drive(.1)
	game._refresh_status()
	if not game.waiting_for_clear_crossing or game.status_label.text != game.tr("Wait until the crossing is clear."):
		fail("Stopped driver was told to wait for a light that was already green")
		return
	crossing.stage = saved_stage
	crossing.blocked_entry = false
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
	# Keep a pedestrian waiting outside the roadway so a walk phase is requested.
	var saved_center: Vector3 = crossing.center
	var saved_actor := traffic_actor.transform
	var saved_walker: Transform3D = game.walker.transform
	var walker_visible: bool = game.walker.visible
	crossing.center += Vector3(900,0,0)
	user += Vector3(900,0,0)
	traffic_actor.position = crossing.center
	game.walker.show()
	game.walker.position = user + axis*10
	for tick in 10:
		lights.advance_tram_crossings(.1)
	if crossing.stage != lights.Stage.WALK or crossing.pedestrians[0].figures[1].visible or lights.pedestrian_may_enter(user+axis*8.75,user+axis*8.65):
		fail("Occupied zebra displayed green or allowed entry during the walk phase")
		return
	traffic_actor.position += axis*40
	lights.advance_tram_crossings(.1)
	if not crossing.pedestrians[0].figures[1].visible or not lights.pedestrian_may_enter(user+axis*8.75,user+axis*8.65):
		fail("Cleared zebra did not show green and release the waiting pedestrian")
		return
	crossing.center = saved_center
	traffic_actor.transform = saved_actor
	game.walker.transform = saved_walker
	game.walker.visible = walker_visible
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
	var red_intervals := {}
	var longest_tram_red := 0.0
	for tick in 320:
		lights.advance_tram_crossings(.1)
		for c in lights.tram_crossings:
			for group in ["boulevard", "side"]:
				var lamp: Node3D = c[group][0].lamps[0]
				var duration := float(red_intervals.get(lamp, 0.0)) + .1 if lamp.visible else 0.0
				red_intervals[lamp] = duration
				longest_tram_red = maxf(longest_tram_red, duration)
	if longest_tram_red <= 0.0 or longest_tram_red > 10.001:
		fail("Unexpected red-light duration at tram junction: %f" % longest_tram_red)
		return
	print("Longest tram junction red: ", longest_tram_red)
	# Use a real traffic vehicle and its normal movement update on a clear approach.
	var traffic_car: Dictionary = game.traffic_data[0]
	game.traffic_data.assign([traffic_car])
	var route := Curve3D.new()
	route.add_point(stop_point - Vector3.RIGHT * (float(traffic_car.length) + 4.0))
	route.add_point(stop_point + Vector3.RIGHT * 25.0)
	traffic_car.route = route
	traffic_car.distance = 0.0
	traffic_car.speed = 6.0
	traffic_car.cruise = 8.0
	game._place_traffic(traffic_car)
	lights.elapsed = 6.5
	lights.advance(0)
	game._update_traffic(.1)
	if traffic_car.speed <= 0.0 or traffic_car.speed >= 6.0:
		fail("Traffic should brake progressively on amber")
		return
	lights.elapsed = 8.0
	lights.advance(0)
	for tick in 100:
		game._update_traffic(.1)
	var front_x := float(traffic_car.actor.position.x) + float(traffic_car.length)
	if traffic_car.speed > .01 or absf(front_x - stop_point.x) > .15:
		fail("Traffic should stop at the red line")
		return
	lights.elapsed = 0
	lights.advance(0)
	game._update_traffic(.1)
	if traffic_car.speed <= 0.0:
		fail("Traffic should move off on green")
		return
	finish.call_deferred(game)

func finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	# Give the audio mixer time to release the stopped siren and radio streams.
	await create_timer(.4).timeout
	print("All six crossings, all eight phases, manual and automatic tram stopping, driver stopping, pedestrian permission and junction clearance verified.")
	quit()
