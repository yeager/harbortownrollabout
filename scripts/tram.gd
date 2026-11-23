extends Node3D

const STATION_NAMES := ["Västra torget", "Lindparken", "Verkstadstorget", "Norra allén"]
const STATION_CENTRES := [Vector2(-183,35), Vector2(-370,35), Vector2(-378,-48), Vector2(-195,-48)]
const WEST := -420.0
const EAST := -150.0
const NORTH := -48.0
const SOUTH := 35.0
const RADIUS := 12.0
const LANE_OFFSET := 6.0
var stations: Array[Node3D] = []
var road_cars: Array[Dictionary] = []

const Mass := preload("res://vehicles/mass.gd")
const SERVICE_BRAKE := 75600.0 / Mass.TRAM_KG
const CAB_REACH := 2.98

var track := Curve3D.new()
var sections: Array[Node3D] = []
var gangways: Array[MeshInstance3D] = []
var gangway_contour := _gangway_profile()
var bellows_finish := StandardMaterial3D.new()
const CAR_SPACING := 4.83
var boarding_steps: Array[MeshInstance3D] = []
var platform_door_leaves: Array[Node3D] = []
var interior_displays: Array[Label3D] = []
var next_stop_display: Label3D
var rear_display: Label3D
var front_display: Label3D
var ramp_starts: Array[float] = []
var stops: Array[float] = []
var platform_riders: Array[Node3D] = []
var onboard_rider: Node3D
var exchange_finished := false
var next_stop := 1
var distance := 0.0
var velocity := 0.0
var door_chime := AudioStreamPlayer3D.new()
const STOP_DURATION := 6.0
const DOOR_TRAVEL_TIME := 0.85
var dwell := STOP_DURATION

func beam(a: Vector3, b: Vector3, width: float, height: float, color: Color, mount: Node3D = self) -> void:
	var piece = get_parent()._make_box("Track", Vector3(width,height,a.distance_to(b)+.015), (a+b)/2, color,false,mount)
	piece.look_at(mount.to_global(b))

func sign_at(parent: Node3D, words: String, at: Vector3, angle: float, scale_factor: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.rotation.y = angle
	label.pixel_size = scale_factor
	label.font_size = 42
	label.outline_size = 4
	parent.add_child(label)
	return label

func _door_window(side: int, direction: int, leaf: Node3D) -> void:
	# The two leaves form a split oval when the doors meet.
	var vertices := PackedVector3Array()
	var centre := Vector3(side*.048,.20,-direction*.225)
	for point in 16:
		var a := PI*point/16.0
		var b := PI*(point+1)/16.0
		vertices.append(centre)
		vertices.append(centre+Vector3(0,.55*cos(a),direction*.405*sin(a)))
		vertices.append(centre+Vector3(0,.55*cos(b),direction*.405*sin(b)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.RIGHT*side)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var window := MeshInstance3D.new()
	window.mesh = mesh
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color("#29404a")
	tint.roughness = .21
	tint.metallic = .24
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	window.material_override = tint
	leaf.add_child(window)

func _add_track_point(x: float, z: float) -> void:
	track.add_point(Vector3(x,.04,z))

func _build_track() -> void:
	_add_track_point(STATION_CENTRES[0].x,SOUTH)
	for corner in [
		[Vector2(WEST+RADIUS,SOUTH-RADIUS),PI/2],
		[Vector2(WEST+RADIUS,NORTH+RADIUS),PI],
		[Vector2(EAST-RADIUS,NORTH+RADIUS),PI*1.5],
		[Vector2(EAST-RADIUS,SOUTH-RADIUS),0.0]
	]:
		var centre: Vector2 = corner[0]
		for i in 17:
			var angle: float = corner[1] + PI*.5*i/16
			_add_track_point(centre.x+RADIUS*cos(angle),centre.y+RADIUS*sin(angle))
	_add_track_point(STATION_CENTRES[0].x,SOUTH)

func _track_pose(offset: float) -> Transform3D:
	var length := track.get_baked_length()
	var here := track.sample_baked(fposmod(offset,length))
	var ahead := track.sample_baked(fposmod(offset+.2,length))
	return Transform3D(Basis.looking_at(here.direction_to(ahead)),here)

func crossing_centers() -> Array[Vector3]:
	return [Vector3(WEST,0,0),Vector3(EAST,0,0),Vector3(-330,0,NORTH),Vector3(-240,0,NORTH),
		Vector3(-330,0,SOUTH),Vector3(-240,0,SOUTH)]

func _cross_street(p: Vector3) -> bool:
	for center in crossing_centers():
		var direction := Vector3.BACK if center.z==0 else Vector3.RIGHT
		var offset := p-center
		if absf(offset.dot(direction))<8 and absf(offset.dot(direction.cross(Vector3.UP)))<1: return true
	return false

func _rail_batch(label: String, transforms: Array[Transform3D], color: Color) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	box.material = get_parent()._material(color)
	# Local batches let the compatibility renderer select lights near each stretch.
	var cells := {}
	for pose in transforms:
		var cell := Vector2i(floori(pose.origin.x/24), floori(pose.origin.z/24))
		if not cells.has(cell): cells[cell] = []
		cells[cell].append(pose)
	for poses: Array in cells.values():
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = box
		batch.instance_count = poses.size()
		for i in poses.size(): batch.set_instance_transform(i,poses[i])
		var model := MultiMeshInstance3D.new()
		model.name = label
		model.multimesh = batch
		add_child(model,true)

func _build_trackbed() -> void:
	var length := track.get_baked_length()
	var rails: Array[Transform3D] = []
	var grass: Array[Transform3D] = []
	var wires: Array[Transform3D] = []
	var count := ceili(length/1.1)
	for i in count:
		var from := track.sample_baked(length*i/count)
		var to := track.sample_baked(length*(i+1)/count)
		var heading := Basis.looking_at(from.direction_to(to))
		var mid := (from+to)*.5
		var span := from.distance_to(to)+.055
		for side in [-1,1]:
			rails.append(Transform3D(heading.scaled_local(Vector3(.075,.055,span)),mid+heading.x*.72*side))
		if not _cross_street(mid):
			grass.append(Transform3D(heading.scaled_local(Vector3(3.25,.06,span)),mid-Vector3.UP*.05))
		wires.append(Transform3D(heading.scaled_local(Vector3(.027,.03,span)),mid+Vector3.UP*4.2))
		if i%19==0 and not _cross_street(mid):
			var pole := mid-heading.x*1.57
			get_parent()._make_roadside_solid("Contact mast",Vector3(.11,4.53,.11),pole+Vector3.UP*2.18,Color("#698076"),false,self)
			beam(pole+Vector3.UP*4.39,mid+Vector3.UP*4.24,.07,.06,Color("#66746f"))
	_rail_batch("Grooved street rails",rails,Color("#97a3a9"))
	_rail_batch("Grass reservation",grass,Color("#778c5e"))
	_rail_batch("Contact wire",wires,Color("#464e4c"))

func _ready() -> void:
	var world := get_parent()
	_build_track()
	_build_trackbed()
	var length := track.get_baked_length()
	var shelter_glass := StandardMaterial3D.new()
	shelter_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shelter_glass.albedo_color = Color(.64,.82,.84,.22)
	shelter_glass.roughness = .20
	for i in STATION_CENTRES.size():
		var point: Vector2 = STATION_CENTRES[i]
		var offset := track.get_closest_offset(Vector3(point.x,.04,point.y)) if i>0 else 0.0
		stops.append(offset)
		var station := Node3D.new()
		add_child(station)
		stations.append(station)
		station.position = track.sample_baked(offset)
		station.look_at(track.sample_baked(offset+.2))
		# Stops lie on the straight portions with space for all three cars.
		world._make_box("Island platform",Vector3(2.55,.34,17),Vector3(2.81,.12,4.5),Color("#c4bbaa"),false,station)
		world._make_box("Tactile strip",Vector3(.18,.019,16.8),Vector3(1.69,.299,4.5),Color("#edce73"),false,station)
		for car_index in 3:
			var door_z := CAR_SPACING * car_index + .13
			for side in [-1,1]:
				var stripe := world._make_box("Boarding chevron",Vector3(.49,.014,.085),Vector3(2.13,.31,door_z+side*.13),Color("#ffdf57"),false,station) as MeshInstance3D
				stripe.rotation.y = -side*.59
		var toe := station.to_global(Vector3(2.81,0,-7))
		var bottom: float = world._surface_height(toe.x,toe.z) - station.position.y
		ramp_starts.append(bottom)
		var rise := .29 - bottom
		var angle := -atan2(rise,3.0)
		var ramp := world._make_box("Platform access ramp",Vector3(2.55,.09,Vector2(3,rise).length()),Vector3(2.81,(bottom+.29)*.5,-5.5),Color("#c4bbaa"),false,station) as MeshInstance3D
		ramp.rotation.x = angle
		ramp.position -= ramp.basis.y*.045
		# Cross the near carriageway at the level landing before the ramp begins.
		for stripe in 7:
			var paint_at := Vector3(3.53+stripe*.74,0,-8.06)
			var street_at := station.to_global(paint_at)
			paint_at.y = world._surface_height(street_at.x,street_at.z) - station.position.y + .012
			var paint := world._make_box("Pedestrian access",Vector3(.40,.014,1.95),paint_at,Color.WHITE,false,station) as MeshInstance3D
			paint.material_override = world.marking_finish
		world._make_box("Shelter roof",Vector3(2.1,.12,5.2),Vector3(3,2.7,0),Color("#475963"),false,station)
		for z in [-1.55,1.55]:
			var fixture := world._make_box("Shelter ceiling light",Vector3(.13,.035,.95),Vector3(2.85,2.622,z),Color.WHITE,false,station) as MeshInstance3D
			fixture.material_override = world.entrance_diffuser
			var light := SpotLight3D.new()
			light.position = fixture.position - Vector3.UP*.04
			light.rotation_degrees.x = -90
			light.spot_angle = 64
			light.spot_range = 6.5
			light.light_color = Color("#ffebce")
			light.distance_fade_enabled = true
			light.distance_fade_begin = 32
			station.add_child(light)
			world.entrance_lights.append(light)
		for z in [-2,2]:
			world._make_roadside_solid("Shelter post",Vector3(.1,2.4,.1),Vector3(3.8,1.5,z),Color("#697778"),false,station)
		# The posts and glass make one continuous barrier behind the bench.
		var screen_bounds := AABB(Vector3(3.75,.29,-2.05),Vector3(.10,2.35,4.10))
		world.building_bounds.append(station.global_transform * screen_bounds)
		world._make_box("Shelter centre mullion",Vector3(.067,2.32,.060),Vector3(3.8,1.49,0),Color("#697778"),false,station)
		for z in [-1,1]:
			var pane := world._make_roadside_solid("Shelter windscreen",Vector3(.027,2.07,1.93),Vector3(3.8,1.51,z),Color.WHITE,false,station) as MeshInstance3D
			pane.material_override = shelter_glass
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for height in [1.30,1.39]:
				world._make_box("Glass visibility band",Vector3(.033,.024,1.93),Vector3(3.8,height,z),Color("#e3e6df"),false,station)
		world._make_roadside_solid("Bench seat",Vector3(.43,.085,2.5),Vector3(3.53,.80,0),Color("#a87547"),false,station)
		world._make_box("Bench back",Vector3(.07,.29,2.5),Vector3(3.72,1.06,0),Color("#a87547"),false,station)
		for z in [-.9,.9]:
			world._make_box("Bench leg",Vector3(.25,.44,.08),Vector3(3.53,.55,z),Color("#49565c"),false,station)
		world._make_box("Station name board",Vector3(.08,.43,3.8),Vector3(2.15,2.45,0),Color("#16496a"),false,station)
		for side in [-1,1]:
			sign_at(station,STATION_NAMES[i],Vector3(2.15+side*.045,2.45,0),side*PI/2,.0068)
	for i in 3:
		var car := Node3D.new()
		add_child(car)
		sections.append(car)
		if i == 1:
			door_chime.bus = &"Traffic and radio"
			door_chime.stream = preload("res://audio/tram_doors.wav")
			door_chime.position = Vector3(1.1, 2.3, 0)
			door_chime.unit_size = 4
			door_chime.max_distance = 30
			door_chime.volume_db = -10
			car.add_child(door_chime)
		var display := sign_at(car, STATION_NAMES[next_stop], Vector3(0,2.145,-2.085), 0, .0019)
		display.modulate = Color("#ffbd58")
		display.outline_size = 0
		interior_displays.append(display)
		car.add_child(preload("res://vehicles/tram_saloon.glb").instantiate())
		var step := world._make_box("Boarding threshold",Vector3(.38,.045,.99),Vector3(1.07,.30,.13),Color("#ffdf57"),false,car) as MeshInstance3D
		boarding_steps.append(step)
		for s in [-1,1]:
			for opening_direction in [-1,1]:
				var leaf := Node3D.new()
				car.add_child(leaf)
				leaf.position = Vector3(s*1.21,1.49,.13+opening_direction*.26)
				world._make_box("Door panel",Vector3(.08,1.875,.50),Vector3(0,-.1475,0),Color("#147db0"),false,leaf)
				world._make_box("Interior door lining", Vector3(.008,1.865,.49), Vector3(-s*.043,-.1475,0), Color("#dbd1b4"),false,leaf)
				_door_window(s, opening_direction, leaf)
				_door_window(-s, opening_direction, leaf)
				if s==1:
					platform_door_leaves.append(leaf)
		if i==1:
			_mark_stroller_bay(car)
			var steel := Color("#384448")
			world._make_box("Pantograph base",Vector3(1.05,.18,1.26),Vector3(0,2.78,.25),steel,false,car)
			for side in [-1,1]:
				var heel := Vector3(side*.33,2.87,.67)
				var elbow := Vector3(side*.28,3.53,-.54)
				var crown := Vector3(side*.39,4.13,0)
				beam(heel,elbow,.065,.083,steel,car)
				beam(elbow,crown,.048,.065,steel,car)
			world._make_box("Contact shoe",Vector3(1.22,.065,.13),Vector3(0,4.16,0),steel,false,car)
		if i in [0, 2]:
			var cab := preload("res://vehicles/tram_cab.glb").instantiate() as Node3D
			var end := -1 if i == 0 else 1
			cab.rotation.y = 0 if i == 0 else PI
			car.add_child(cab)
			if i == 2:
				var tail_lens := StandardMaterial3D.new()
				tail_lens.albedo_color = Color("#cb2435")
				tail_lens.emission_enabled = true
				tail_lens.emission = Color("#f52029")
				tail_lens.emission_energy_multiplier = 1.5
				var unlit := StandardMaterial3D.new()
				unlit.albedo_color = Color("#505b60")
				unlit.roughness = .22
				for lens in cab.find_children("Marker light*", "MeshInstance3D", true, false):
					lens.material_override = tail_lens
				for lens in cab.find_children("Dipped LED lens*", "MeshInstance3D", true, false):
					lens.material_override = unlit
			world._make_box("Cab bulkhead", Vector3(2.12,2.08,.12), Vector3(0,1.41,end*2.17), Color("#374b58"),false,car)
			var end_display := sign_at(cab,STATION_NAMES[next_stop],Vector3(0,2.335,-2.558),PI,.0034)
			end_display.modulate = Color("#ffc267")
			end_display.outline_size = 0
			if i == 0:
				front_display = end_display
			else:
				rear_display = end_display
		if i==0:
			for side in [-1,1]:
				var headlight := SpotLight3D.new()
				headlight.position = Vector3(side*.86,.955,-2.97)
				headlight.rotation_degrees.x = -8
				headlight.spot_range = 24
				headlight.spot_angle = 24
				headlight.light_color = Color("#fff1dc")
				headlight.distance_fade_enabled = true
				headlight.distance_fade_begin = 38
				headlight.visible = world.last_night > .05
				headlight.light_energy = 2.8 * maxf(world.last_night,0.0)
				car.add_child(headlight)
				world.traffic_headlights.append(headlight)
			world._make_box("Next stop display",Vector3(.04,.32,1.74),Vector3(1.20,2.48,-1.32),Color("#192426"),false,car)
			next_stop_display = sign_at(car,STATION_NAMES[next_stop],Vector3(1.23,2.48,-1.32),PI/2,.0044)
			next_stop_display.modulate = Color("#ffbd58")
			next_stop_display.outline_size = 0
			world._make_box("Door notice",Vector3(.035,.32,1.4),Vector3(1.21,1.04,1.46),Color("#174460"),false,car)
			var notice := sign_at(car,"We don’t go to Ekerö",Vector3(1.24,1.04,1.46),PI/2,.003)
			world._size_world_sign(notice,1.32)
	bellows_finish.albedo_color = Color("#41494b")
	bellows_finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	for joint in sections.size()-1:
		var gangway := MeshInstance3D.new()
		gangway.mesh = ImmediateMesh.new()
		gangway.material_override = bellows_finish
		add_child(gangway)
		gangways.append(gangway)
	place_sections()
	onboard_rider = _new_rider(sections[0],Color("#925649"),Vector3(.36,.51,.13))
	for i in stations.size():
		platform_riders.append(_new_rider(stations[i],Color.from_hsv(.16+i*.16,.45,.7),Vector3(2.36,.29,-.70)))
	for i in 4:
		var travel := 1 if i%2==0 else -1
		var offset := (i+.35)*length/4
		var pose := _carriageway_pose(offset,travel)
		var scene := "res://vehicles/traffic_bmw_blue.glb" if travel>0 else "res://vehicles/traffic_bmw_silver.glb"
		var actor: Node3D = world._spawn_traffic(scene,pose.origin.x,pose.origin.z,travel,4.8)
		var road_car: Dictionary = world.traffic_data.pop_back()
		road_car.offset = offset
		road_cars.append(road_car)
		actor.transform = pose

func _new_rider(parent: Node3D, shirt: Color, at: Vector3) -> Node3D:
	var world := get_parent()
	world._make_walker("Tram passenger",0,0,1,shirt,Color("#34414b"))
	var rider: Node3D = world.walker_data.pop_back().actor
	rider.reparent(parent,false)
	rider.position = at
	return rider

func _move_rider(rider: Node3D, target: Vector3, delta: float) -> void:
	var step := target-rider.position
	if step.length_squared() > .000001:
		rider.rotation.y = atan2(-step.x,-step.z)
	rider.position = target
	get_parent()._animate_steps(rider,step.length(),delta)

func _exchange_riders(delta: float) -> void:
	if exchange_finished or STOP_DURATION-dwell < DOOR_TRAVEL_TIME: return
	var index := posmod(next_stop-1,stops.size())
	var car := sections[0]
	var station := stations[index]
	var elapsed := STOP_DURATION-dwell-DOOR_TRAVEL_TIME
	var waiting := platform_riders[index]
	var inside := Vector3(.36,.51,.13)
	var outside := Vector3(2.36,.29,.13)
	var queue_side := float(station.get_meta("queue_side",-1.0))
	var aside := outside-Vector3.BACK*queue_side*.83
	var exit_progress := clampf(elapsed/1.45,0,1)
	var exit_at := inside.lerp(outside,exit_progress)
	exit_at = exit_at.lerp(aside,clampf((elapsed-1.45)/.70,0,1))
	_move_rider(onboard_rider,exit_at,delta)
	if elapsed < 2.15: return
	var queue := outside+Vector3.BACK*queue_side*.83
	var entry := queue.lerp(outside,clampf((elapsed-2.15)/.65,0,1))
	entry = entry.lerp(inside,clampf((elapsed-2.80)/1.35,0,1))
	_move_rider(waiting,station.to_local(car.to_global(entry)),delta)
	if elapsed >= 4.15:
		onboard_rider.reparent(station,true)
		waiting.reparent(car,true)
		station.set_meta("queue_side",-queue_side)
		platform_riders[index] = onboard_rider
		onboard_rider = waiting
		exchange_finished = true

func _carriageway_pose(offset: float, travel: int) -> Transform3D:
	var pose := _track_pose(offset)
	pose.origin += pose.basis.x * LANE_OFFSET * travel
	pose.origin.y = -.015
	if travel < 0: pose.basis = pose.basis.rotated(Vector3.UP,PI)
	return pose

func _street_users() -> Array[AABB]:
	var world := get_parent()
	var users: Array[AABB] = []
	if world.tram_mode==0 and world.walker.visible:
		users.append(AABB(world.walker.position-Vector3(.35,.2,.35),Vector3(.7,2,.7)))
	if world.ambulance.visible:
		var ext: Vector2 = world._player_extent()
		users.append(AABB(world.ambulance.position-Vector3(ext.x,.2,ext.y),Vector3(ext.x*2,3,ext.y*2)))
	for i in world.parked_cars.size():
		if world.parked_cars[i].visible:
			users.append(world._parked_bounds(i))
	for person in world.walker_data:
		var point: Vector3 = person.actor.position
		users.append(AABB(point-Vector3(.32,.2,.32),Vector3(.64,2,.64)))
	return users

func _advance_road_cars(delta: float, users: Array[AABB]) -> void:
	var world := get_parent()
	var occupied_crossings := PackedFloat32Array()
	for i in stations.size():
		var crossing := stations[i].global_transform * AABB(Vector3(3.25,-.2,-9.1),Vector3(5.05,2.5,2.1))
		if users.any(func(body: AABB): return crossing.intersects(body)):
			occupied_crossings.append(stops[i]+7.0)
	for car in road_cars:
		var actor: Node3D = car.actor
		var travel := int(car.direction)
		var clearance: float = world.street_signals.red_clearance(actor.position,-actor.basis.z,car.length)
		if travel > 0:
			for crossing_offset in occupied_crossings:
				var gap := fposmod(crossing_offset-float(car.offset),track.get_baked_length()) - float(car.length) - .8
				clearance = minf(clearance,maxf(0,gap))
		for other in road_cars:
			if other.actor == actor or other.direction != car.direction:
				continue
			var spacing := fposmod((float(other.offset)-float(car.offset))*travel,track.get_baked_length())
			var free_space := spacing - float(other.length) - float(car.length) - 1.0
			clearance = minf(clearance,maxf(0,free_space))
		var previous_speed := float(car.speed)
		var pace := move_toward(previous_speed,float(car.cruise),2.0*Mass.road_response(car.mass_kg)*delta)
		var permitted := sqrt(8.0*maxf(0,clearance-.05))
		car.speed = minf(pace,permitted)
		var step := minf(float(car.speed)*delta,maxf(0,clearance-.03))
		var next_offset := float(car.offset) + travel * step
		var next := _carriageway_pose(next_offset,travel)
		var sweep := next * AABB(Vector3(-.98,-.3,-2.85),Vector3(1.96,2.6,5.2))
		var blocked := users.any(func(body: AABB): return sweep.intersects(body))
		if car.brake_lens:
			var braking := blocked or permitted < .01 or float(car.speed) < previous_speed - .0001
			world._set_rear_lights(car.brake_lens,braking)
		if blocked:
			car.speed = 0
			continue
		world._roll_wheels(car.wheels,actor.position.distance_to(next.origin))
		actor.transform = next
		car.offset = fposmod(next_offset,track.get_baked_length())

func _safe_tram_step(step: float, users: Array[AABB]) -> float:
	var safety_length := CAB_REACH + .9 + step
	var lead := _track_pose(distance)
	var nearby: Array[AABB] = []
	for body in users:
		if body.grow(safety_length+2).has_point(lead.origin):
			nearby.append(body)
	if nearby.is_empty(): return step
	var samples := maxi(1,ceili(step/.25))
	for i in range(1,samples+1):
		var pose := _track_pose(distance+step*i/samples)
		var nose := pose*AABB(Vector3(-1.28,-.3,-CAB_REACH-.12),Vector3(2.56,3.5,CAB_REACH+.12))
		for body in nearby:
			if nose.intersects(body): return step*(i-1)/samples
	return step

func platform_height(p: Vector3) -> float:
	for i in stations.size():
		var station := stations[i]
		var local := station.to_local(p)
		if local.x >= 1.47 and local.x <= 4.085 and local.z >= -7 and local.z <= 13:
			return station.position.y+lerpf(ramp_starts[i],.29,clampf((local.z+7)/3,0,1))
	return NAN

func _mark_stroller_bay(car: Node3D) -> void:
	var world := get_parent()
	var mat := world._make_box("Stroller bay",Vector3(1.16,.006,.85),Vector3(-.55,.514,.13),Color("#235c76"),false,car) as MeshInstance3D
	for side in [-1,1]:
		world._make_box("Bay edge",Vector3(1.12,.003,.018),Vector3(0,.005,side*.40),Color.WHITE,false,mat)
		world._make_box("Bay end",Vector3(.018,.003,.80),Vector3(side*.55,.005,0),Color.WHITE,false,mat)
	var label := sign_at(mat,"Stroller space",Vector3(0,.008,0),0,.003)
	label.rotation = Vector3(-PI/2,0,PI/2)
	world._size_world_sign(label,.75)

func platform_at(p: Vector3) -> int:
	for i in stations.size():
		var local := stations[i].to_local(p)
		if local.x >= 1.48 and local.x <= 4.2 and local.z >= -3.5 and local.z <= 12.8: return i
	return -1

func crosses_boarding_edge(start: Vector3, finish: Vector3) -> bool:
	var stop := open_station()
	if stop < 0 or platform_at(start) != stop: return false
	for car in sections:
		var before := car.to_local(start)
		var after := car.to_local(finish)
		if after.x < before.x and before.x >= 1.48 and after.x <= 1.70 and absf(after.z - .13) <= .5:
			return true
	return false

func open_station() -> int:
	return posmod(next_stop-1, stops.size()) if dwell >= DOOR_TRAVEL_TIME and dwell <= STOP_DURATION - DOOR_TRAVEL_TIME else -1

func car_bounds() -> Array[AABB]:
	var bodies: Array[AABB] = []
	for i in sections.size():
		var front := CAB_REACH if i==0 else 2.21
		var rear := CAB_REACH if i==sections.size()-1 else 2.21
		bodies.append(sections[i].transform*AABB(Vector3(-1.25,-.3,-front),Vector3(2.5,3.5,front+rear)))
	for item in road_cars:
		var car: Node3D = item.actor
		bodies.append(car.transform*AABB(Vector3(-.94,-.3,-2.35),Vector3(1.88,2.4,4.7)))
	return bodies

func distance_to_next_stop() -> float:
	return fposmod(stops[next_stop]-distance,track.get_baked_length())

func advance(delta: float, manual: bool, gas: bool, brake: bool) -> void:
	get_parent().street_signals.advance_tram_crossings(delta)
	var users := _street_users()
	_advance_road_cars(delta,users)
	if dwell>0:
		var previous_dwell := dwell
		dwell=maxf(0,dwell-delta)
		_exchange_riders(delta)
		if previous_dwell > 1.4 and dwell <= 1.4:
			door_chime.play()
		var opening := smoothstep(0,DOOR_TRAVEL_TIME,minf(STOP_DURATION-dwell,dwell))
		for threshold in boarding_steps:
			threshold.position.x = lerpf(1.07,1.40,opening)
		for i in platform_door_leaves.size():
			var direction := -1 if i%2==0 else 1
			platform_door_leaves[i].position.z = .13+direction*(.26+.51*opening)
		return
	var length := track.get_baked_length()
	var remaining := distance_to_next_stop()
	var signal_gap: float = get_parent().street_signals.tram_clearance(distance,length)
	var stopping_gap := minf(remaining,signal_gap)
	var target := 7.0
	if manual:
		target = 0 if brake else (7 if gas else velocity)
	# Reserve the distance travelled this frame as well as the braking distance afterwards.
	var initial := velocity
	var half_change := SERVICE_BRAKE * delta * .5
	var approach_speed := sqrt(maxf(0,half_change*half_change + SERVICE_BRAKE*(2*stopping_gap-initial*delta))) - half_change
	velocity = move_toward(initial,clampf(approach_speed,0,target),delta*(126000.0 / Mass.TRAM_KG if brake else SERVICE_BRAKE))
	var step := minf((initial + velocity) * .5 * delta, signal_gap)
	if step >= signal_gap: velocity = 0.0
	var safe_step := _safe_tram_step(step,users)
	if safe_step < step:
		step = safe_step
		velocity = 0
	if step <= 0.0 and remaining > .0001:
		return
	if remaining <= step + .0001:
		stop_at_station(next_stop)
		return
	else:
		distance=fposmod(distance+step,length)
	place_sections()

func stop_at_station(index: int) -> void:
	distance = stops[index]
	next_stop = (index + 1) % stops.size()
	var destination: String = STATION_NAMES[next_stop]
	next_stop_display.text = destination
	front_display.text = destination
	rear_display.text = destination
	for display in interior_displays:
		display.text = destination
	velocity = 0
	dwell = STOP_DURATION
	exchange_finished = false
	place_sections()

func place_sections() -> void:
	var length := track.get_baked_length()
	for i in sections.size():
		var p := fposmod(distance-CAR_SPACING*i,length)
		sections[i].position=track.sample_baked(p)
		sections[i].look_at(track.sample_baked(fposmod(p+.2,length)))
	for i in gangways.size():
		_shape_gangway(gangways[i].mesh, sections[i].transform, sections[i+1].transform)

func _gangway_profile() -> PackedVector2Array:
	# A rounded rectangular diaphragm matches the rolled roof and lower skirts.
	# Intermediate points prevent a faceted shoulder as cars swing around a bend.
	var contour := PackedVector2Array()
	var radius := .19
	for corner in [Vector3(1.15-radius,2.61-radius,0),Vector3(-1.15+radius,2.61-radius,90),
			Vector3(-1.15+radius,.39+radius,180),Vector3(1.15-radius,.39+radius,270)]:
		for i in 6:
			var angle := deg_to_rad(corner.z+18*i)
			contour.append(Vector2(corner.x+radius*cos(angle),corner.y+radius*sin(angle)))
	return contour

func _shape_gangway(mesh: ImmediateMesh, leading: Transform3D, trailing: Transform3D) -> void:
	# Each fold spans matching points on the two moving saloon end frames.
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := PackedVector3Array()
	for ridge in 9:
		var ring := PackedVector3Array()
		for point in gangway_contour:
			var inset := 1.0 if ridge % 2 == 0 else .93
			var x := point.x*inset
			var y := 1.5+(point.y-1.5)*inset
			var start := leading * Vector3(x,y,2.19)
			var end := trailing * Vector3(x,y,-2.19)
			ring.append(start.lerp(end,float(ridge)/8.0))
		if ridge > 0:
			for k in gangway_contour.size():
				var j := (k+1)%gangway_contour.size()
				var normal := (previous[j]-previous[k]).cross(ring[k]-previous[k]).normalized()
				for vertex in [previous[k],ring[k],previous[j],previous[j],ring[k],ring[j]]:
					mesh.surface_set_normal(normal)
					mesh.surface_add_vertex(vertex)
		previous = ring
	mesh.surface_end()
