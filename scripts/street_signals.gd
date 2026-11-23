extends Node3D

# The main junction clears before the north/south traffic and pedestrians get green.
var elapsed := 0.0
var heads: Array[Dictionary] = []
var phase := -1
# Boulevard and tram share a phase. Crossing traffic and pedestrians each have
# their own green, separated by amber and all-red clearance intervals.
enum Stage { BOULEVARD, BOULEVARD_AMBER, CLEAR_BOULEVARD, SIDE_STREET, SIDE_AMBER, CLEAR_SIDE, WALK, CLEAR_WALK }
const STAGE_SECONDS := [2.6,0.8,0.4,2.6,0.8,0.4,1.8,0.4]
const MAX_EXTRA_CLEARANCE := .8
const BOULEVARD_LINE := 10.0
const SIDE_LINE := 10.5
const ZEBRA_OFFSET := 6.3
var tram_crossings: Array[Dictionary] = []
var street_crosswalks: Array[Dictionary] = []
const SHOP_CROSSING := Vector3(-39,0,35)
const EAST_CROSSINGS := [Vector3(91,0,0),Vector3(91,0,-48),Vector3(143,0,-48)]
const CROSSING_X := -12.0
const WEST_STOP_DISTANCE := 15.0
const JUNCTION_STOP_DISTANCE := 8.0

func _ready() -> void:
	for i in 4:
		var mast := Node3D.new()
		add_child(mast)
		mast.rotation.y = i*PI/2
		mast.position = mast.basis*Vector3(5.4,0,6)
		if i==3:
			mast.position.x=-13.65
		heads.append(_vehicle_head(mast,i%2==1))
	for approach in [Vector3.RIGHT,Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
		var forward: Vector3 = approach
		var setback := WEST_STOP_DISTANCE if forward == Vector3.RIGHT else JUNCTION_STOP_DISTANCE
		var center := -forward*setback + forward.cross(Vector3.UP)*1.85
		center.y = get_parent()._surface_height(center.x,center.z)+.016
		var size := Vector3(.22,.018,3.3) if forward.x != 0 else Vector3(3.3,.018,.22)
		get_parent()._make_box("Junction stop line",size,center,Color("#eee9d9"),false,self)
	_build_street_crossing(SHOP_CROSSING)
	for center: Vector3 in EAST_CROSSINGS:
		_build_street_crossing(center)
	heads.append_array(_street_crosswalk(Vector3(CROSSING_X,0,0),false,6.31))
	for z in [-6.35,6.35]:
		heads.append_array(_street_crosswalk(Vector3(0,0,z),true,5.15))
	_build_tram_crossings()
	advance(0)

func _build_street_crossing(center: Vector3) -> void:
	center.y = get_parent()._surface_height(center.x,center.z)
	heads.append_array(_street_crosswalk(center,false))
	for direction in [-1,1]:
		var mast := Node3D.new()
		add_child(mast)
		mast.position = center + Vector3(-3*direction,0,4.1*direction)
		mast.rotation.y = -direction*PI/2
		heads.append(_vehicle_head(mast,true))
		get_parent()._make_box("Crossing stop line",Vector3(.21,.016,3.25),
			center+Vector3(-3*direction,.016,1.85*direction),Color("#eee9d9"),false,self)

func _vehicle_head(mast: Node3D, east_west: bool) -> Dictionary:
	get_parent()._make_roadside_solid("Signal mast",Vector3(.12,3.7,.12),Vector3.UP*1.85,Color("#777e78"),false,mast)
	if visor_mesh == null:
		visor_mesh = _make_visor()
	var lamps: Array = []
	var colors := [Color("#ff2622"),Color("#ffab16"),Color("#15d279")]
	for j in 3:
		var pos := Vector3(0,3.85-.31*j,.25)
		get_parent()._make_box("Signal housing",Vector3(.316,.308,.24),pos-Vector3.BACK*.13,
			Color("#191b1b"),false,mast)
		var glass := lens(mast,pos,colors[j])
		glass.material_override = get_parent()._material(colors[j].darkened(.79),.33)
		var visor := MeshInstance3D.new()
		visor.mesh = visor_mesh
		mast.add_child(visor)
		visor.position = pos
		var lit := lens(mast,pos+Vector3.BACK*.002,colors[j])
		var finish := lit.material_override as StandardMaterial3D
		finish.emission_enabled = false
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lamps.append(lit)
	return {"lamps":lamps,"east_west":east_west}

var visor_mesh: ArrayMesh

func _make_visor() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var finish: StandardMaterial3D = get_parent()._material(Color("#17191a"),.48)
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(finish)
	# The lower half has a shallow rim, the upper half shelters the lens.
	for i in 48:
		var corners := PackedVector3Array()
		for angle in [TAU*i/48, TAU*(i+1)/48]:
			var radial := Vector3(cos(angle),sin(angle),0)
			var depth := .032+.14*smoothstep(-.25,.70,radial.y)
			corners.append(radial*.139-Vector3.BACK*.012)
			corners.append(radial*.137+Vector3.BACK*depth)
		for index in [0,2,1,1,2,3]:
			surface.set_normal(Vector3(corners[index].x,corners[index].y,0).normalized())
			surface.add_vertex(corners[index])
	return surface.commit()

func _street_crosswalk(center: Vector3, east_west: bool, curb_distance := 4.0) -> Array[Dictionary]:
	street_crosswalks.append({"center":center, "axis":Vector3.RIGHT if east_west else Vector3.BACK,
		"walk_phase":0 if east_west else 3, "curb_distance":curb_distance})
	return _add_crossing(center,east_west)

func _add_crossing(center: Vector3, east_west: bool, pavement_offset := 5.45) -> Array[Dictionary]:
	var signals: Array[Dictionary] = []
	for side in [-1,1]:
		var mast := Node3D.new()
		add_child(mast)
		mast.position = center + Vector3(pavement_offset*side,0,-1.55*side) if east_west else center + Vector3(-1.55*side,0,pavement_offset*side)
		mast.rotation.y = (-PI/2 if side==1 else PI/2) if east_west else (PI if side==1 else 0.)
		get_parent()._make_roadside_solid("Crossing pole",Vector3(.09,2.45,.09),Vector3.UP*1.22,Color("#737d7a"),false,mast)
		get_parent()._make_box("Pedestrian signal",Vector3(.52,.9,.18),Vector3.UP*2.2,Color("#202927"),false,mast)
		if side == 1:
			_add_crossing_light(mast, center)
		var signs: Array = []
		for j in 2:
			var figure := Node3D.new()
			mast.add_child(figure)
			figure.position=Vector3(0,2.43-.45*j,.115)
			var color := Color.RED if j==0 else Color.LIME_GREEN
			lens(figure,Vector3(0,.12,0),color).scale=Vector3.ONE*.27
			for segment in [[0,.015,.0,.16],[-.05,-.09,.48*j,.14],[.05,-.09,-.48*j,.14],[-.065,.02,-.5,.11],[.065,.02,.55,.11]]:
				var limb = get_parent()._make_box("Figure",Vector3(.038,segment[3],.02),Vector3(segment[0],segment[1],0),color,false,figure)
				limb.rotation.z=segment[2]
				limb.material_override=get_parent()._material(color,.35,true)
			signs.append(figure)
		signals.append({"figures":signs,"walk_phase":0 if east_west else 3})
	return signals

func _add_crossing_light(mast: Node3D, center: Vector3) -> void:
	var world := get_parent()
	world._make_box("Crossing mast extension",Vector3(.09,1.36,.09),Vector3.UP*3.1,Color("#737d7a"),false,mast)
	world._make_box("Crossing luminaire",Vector3(.28,.12,.56),Vector3(0,3.75,.19),Color("#424b4c"),false,mast)
	var diffuser = world._make_box("Crossing diffuser",Vector3(.22,.025,.34),Vector3(0,3.68,.26),Color.WHITE,false,mast)
	diffuser.material_override = world.lamp_glass
	var light := SpotLight3D.new()
	mast.add_child(light)
	light.position = Vector3(0,3.64,.26)
	light.look_at(to_global(center))
	light.light_color = Color("#ffebce")
	light.spot_range = 14
	light.spot_angle = 36
	light.distance_fade_enabled = true
	light.distance_fade_begin = 34
	light.distance_fade_length = 20
	light.visible = world.last_night > .05
	light.light_energy = maxf(0,world.last_night)*3.2
	world.street_lights.append(light)

func lens(parent: Node3D, pos: Vector3, color: Color) -> MeshInstance3D:
	var lamp := MeshInstance3D.new()
	var globe := SphereMesh.new()
	globe.radius=.126
	globe.height=.252
	lamp.mesh=globe
	parent.add_child(lamp)
	lamp.position=pos
	lamp.scale.z=.3
	lamp.material_override=get_parent()._material(color,.32,true)
	return lamp

func advance(delta: float) -> void:
	elapsed=fmod(elapsed+delta,16)
	var current := 0 if elapsed<6 else 1 if elapsed<7 else 2 if elapsed<8 else 3 if elapsed<14 else 4 if elapsed<15 else 5
	if current==phase: return
	phase=current
	for head in heads:
		if head.has("figures"):
			head.figures[0].visible=phase!=head.walk_phase
			head.figures[1].visible=phase==head.walk_phase
		else:
			var green := 0 if head.east_west else 3
			for j in 3:
				head.lamps[j].visible = j==(2 if phase==green else 1 if phase==green+1 else 0)

func _build_tram_crossings() -> void:
	var world := get_parent()
	var train = world.tram
	for center: Vector3 in train.crossing_centers():
		var offset: float = train.track.get_closest_offset(center)
		var pose: Transform3D = train._track_pose(offset)
		var tangent := -pose.basis.z
		var across := pose.basis.x
		var zebra := center + tangent * ZEBRA_OFFSET
		var crossing := {"center":center,"tangent":tangent,"across":across,"offset":offset,
			"parallel_walk":center.is_equal_approx(Vector3(train.EAST,0,0)),
			"stage":Stage.BOULEVARD,"timer":fmod(offset*.1,STAGE_SECONDS[0]),"boulevard":[],"side":[],
			"pedestrians":_add_crossing(zebra,absf(across.x)>.9,9.15)}
		for stripe in range(-9,10):
			var mark = world._make_box("Spårövergång",Vector3(2.1,.012,.49),zebra+across*stripe*.91+Vector3.UP*.006,Color("#dfdfd4"),false,self)
			mark.basis = Basis.looking_at(across)
		for along_tram in [true,false]:
			for direction in [-1,1]:
				var forward: Vector3 = (tangent if along_tram else across)*direction
				# At the T-junctions there is no approach from outside the block.
				if not along_tram and ((center.z==train.NORTH and forward.z>0) or (center.z==train.SOUTH and forward.z<0)):
					continue
				var right := forward.cross(Vector3.UP)
				var setback := BOULEVARD_LINE if along_tram else SIDE_LINE
				var edge := center-forward*setback
				var mast := Node3D.new()
				add_child(mast)
				mast.position = edge+right*(8.7 if along_tram else 4.9)
				mast.basis = Basis.looking_at(forward)
				var group: Array = crossing.boulevard if along_tram else crossing.side
				group.append(_vehicle_head(mast,absf(forward.x)>.9))
				var line = world._make_box("Haltlinje",Vector3(4.4 if along_tram else 4.1,.018,.22),edge+right*(6 if along_tram else 2.3),Color("#f0eadc"),false,self)
				line.basis = mast.basis
		# Separate trackside head facing the tram operator.
		var rail_mast := Node3D.new()
		add_child(rail_mast)
		rail_mast.position = center-tangent*BOULEVARD_LINE+across*1.68
		rail_mast.basis = pose.basis
		crossing.boulevard.append(_vehicle_head(rail_mast,absf(tangent.x)>.9))
		tram_crossings.append(crossing)
		_show_crossing(crossing)

func _show_crossing(crossing: Dictionary) -> void:
	var stage := int(crossing.stage)
	for group in ["boulevard","side"]:
		var green := Stage.BOULEVARD if group=="boulevard" else Stage.SIDE_STREET
		var color := 2 if stage==green else 1 if stage==green+1 else 0
		for head in crossing[group]:
			for i in 3: head.lamps[i].visible = i==color
	for head in crossing.pedestrians:
		head.figures[0].visible = not _walk_green(crossing)
		head.figures[1].visible = _walk_green(crossing)

func _walk_green(crossing: Dictionary) -> bool:
	# The east zebra lies beside the side street and runs parallel to its lanes.
	return not crossing.get("blocked_entry", false) and crossing.stage == (Stage.SIDE_STREET if crossing.parallel_walk else Stage.WALK)

func _junction_occupied(crossing: Dictionary) -> bool:
	var world := get_parent()
	var basis := Basis.looking_at(crossing.tangent)
	var zone := Transform3D(basis,crossing.center)*AABB(Vector3(-8.45,-.6,-7.65),Vector3(16.9,4,15.3))
	for body in world.tram.car_bounds():
		if zone.intersects(body): return true
	for item in world.traffic_data:
		var actor: Node3D = item.actor
		var half_size := Vector3(item.width, 1.2, item.length)
		var footprint := actor.transform * AABB(Vector3(-half_size.x, -.2, -half_size.z), half_size * 2)
		if zone.intersects(footprint): return true
	for i in world.parked_cars.size():
		if world.parked_cars[i].visible and zone.intersects(world._parked_bounds(i)):
			return true
	if world.ambulance.visible:
		var half_width: float = world.player_half_size.x
		var local_body := AABB(Vector3(-half_width, -.2, -world.front_reach),
			Vector3(2 * half_width, 3, world.front_reach + world.rear_reach))
		var player_car: AABB = world.ambulance.transform * local_body
		if zone.intersects(player_car): return true
	if world.walker.visible and zone.has_point(world.walker.position): return true
	for item in world.walker_data:
		if zone.has_point(item.actor.position): return true
	return false

func _pedestrian_near_crosswalk(crossing: Dictionary) -> bool:
	var world := get_parent()
	var zebra: Vector3 = crossing.center + crossing.tangent * ZEBRA_OFFSET
	var basis := Basis.looking_at(crossing.tangent)
	# Include both waiting pavements and the full zebra crossing.
	var approach := Transform3D(basis,zebra) * AABB(Vector3(-13,-1,-2.4),Vector3(26,4,4.8))
	if world.walker.visible and approach.has_point(world.walker.position): return true
	for item in world.walker_data:
		if approach.has_point(item.actor.position): return true
	return false

func advance_tram_crossings(delta: float) -> void:
	for crossing in tram_crossings:
		if crossing.get("blocked_entry", false) and not _junction_occupied(crossing):
			crossing.blocked_entry = false
			_show_crossing(crossing)
		crossing.timer += delta
		var duration: float = STAGE_SECONDS[crossing.stage]
		if crossing.parallel_walk and crossing.stage == Stage.BOULEVARD:
			duration = 2.0
		if crossing.timer < duration: continue
		if crossing.stage in [Stage.CLEAR_BOULEVARD, Stage.CLEAR_SIDE, Stage.CLEAR_WALK] and _junction_occupied(crossing):
			crossing.clearance_wait = float(crossing.get("clearance_wait", 0.0)) + delta
			if crossing.clearance_wait < MAX_EXTRA_CLEARANCE:
				crossing.timer = duration
				continue
			# Resume the signal cycle but keep approaching traffic at its line
			# until the vehicle or pedestrian already inside has cleared it.
			crossing.blocked_entry = true
		crossing.clearance_wait = 0.0
		crossing.timer = minf(crossing.timer - duration, delta)
		crossing.stage = (int(crossing.stage)+1)%STAGE_SECONDS.size()
		if crossing.stage == Stage.WALK and (crossing.parallel_walk or not _pedestrian_near_crosswalk(crossing)):
			crossing.stage = Stage.BOULEVARD
		_show_crossing(crossing)

func tram_clearance(distance: float, length: float) -> float:
	var nearest := INF
	for crossing in tram_crossings:
		if crossing.stage==Stage.BOULEVARD and not crossing.get("blocked_entry", false): continue
		# Once the cab passes its line, let the whole articulated train clear it.
		var gap: float = fposmod(float(crossing.offset)-distance,length)-BOULEVARD_LINE-get_parent().tram.CAB_REACH
		if gap >= -.001: nearest = minf(nearest,maxf(0,gap))
	return nearest

func _enters_crosswalk(from: Vector3, to: Vector3, center: Vector3, axis: Vector3, curb_distance: float) -> bool:
	var start := (from-center).dot(axis)
	if absf(start) < curb_distance: return false
	var inward := (from-to).dot(axis) * signf(start)
	var to_curb := absf(start) - curb_distance
	if inward <= to_curb: return false
	var intersection := from.lerp(to,to_curb/inward)
	return absf((intersection-center).dot(axis.cross(Vector3.UP))) <= 1.45

func pedestrian_may_enter(from: Vector3, to: Vector3) -> bool:
	for zebra in street_crosswalks:
		if phase != zebra.walk_phase and _enters_crosswalk(from,to,zebra.center,zebra.axis,zebra.curb_distance):
			return false
	for c in tram_crossings:
		if _walk_green(c): continue
		var center: Vector3 = c.center + c.tangent * ZEBRA_OFFSET
		if _enters_crosswalk(from,to,center,c.across,8.7): return false
	return true

func red_clearance(pos: Vector3, heading: Vector3, half_length: float, red_only := false, signals_only := false) -> float:
	var nearest := _central_clearance(pos,heading,half_length,red_only)
	for crossing in tram_crossings:
		var tangent: Vector3 = crossing.tangent
		var across: Vector3 = crossing.across
		var along := absf(heading.dot(tangent)) >= absf(heading.dot(across))
		var green := Stage.BOULEVARD if along else Stage.SIDE_STREET
		if crossing.stage==green and (signals_only or red_only or not crossing.get("blocked_entry", false)): continue
		if red_only and crossing.stage==green+1: continue
		var axis := tangent if along else across
		var gap := _line_clearance(pos,heading,half_length,crossing.center,axis,
			BOULEVARD_LINE if along else SIDE_LINE,8.45 if along else 4.85)
		nearest = minf(nearest,gap)
	return nearest

func _line_clearance(pos: Vector3, heading: Vector3, reach: float, center: Vector3, axis: Vector3, setback: float, width: float) -> float:
	var approach := heading.dot(axis)
	if absf(approach) < .001: return INF
	var distance := ((center-pos).dot(axis)-signf(approach)*setback)/approach
	var gap := distance-reach
	if gap < -.001: return INF
	var intersection := pos+heading*distance
	if absf((intersection-center).dot(axis.cross(Vector3.UP))) > width: return INF
	return maxf(0,gap)

func _central_clearance(pos: Vector3, heading: Vector3, half_length: float, red_only := false) -> float:
	var east_west := absf(heading.x)>=absf(heading.z)
	var green := 0 if east_west else 3
	if phase==green or (red_only and phase==green+1): return INF
	var setback := WEST_STOP_DISTANCE if east_west and heading.x>0 else JUNCTION_STOP_DISTANCE
	var axis := Vector3.RIGHT if east_west else Vector3.BACK
	var nearest := _line_clearance(pos,heading,half_length,Vector3.ZERO,axis,setback,4.85)
	if east_west:
		nearest = minf(nearest,_line_clearance(pos,heading,half_length,SHOP_CROSSING,axis,3,3.7))
		for center: Vector3 in EAST_CROSSINGS:
			nearest = minf(nearest,_line_clearance(pos,heading,half_length,center,axis,3,4.85))
	return nearest
