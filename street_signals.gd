extends Node3D

# The main junction clears before the north/south traffic and pedestrians get green.
var elapsed := 0.0
var heads: Array[Dictionary] = []
var phase := -1
# Boulevard and tram share a phase. Crossing traffic and pedestrians each have
# their own green, separated by amber and all-red clearance intervals.
enum Stage { BOULEVARD, BOULEVARD_AMBER, CLEAR_BOULEVARD, SIDE_STREET, SIDE_AMBER, CLEAR_SIDE, WALK, CLEAR_WALK }
const STAGE_SECONDS := [3.0,0.8,0.4,3.0,0.8,0.4,3.0,0.4]
const BOULEVARD_LINE := 10.0
const SIDE_LINE := 10.5
const ZEBRA_OFFSET := 6.3
var tram_crossings: Array[Dictionary] = []
const SHOP_CROSSING := Vector3(-39,0,35)
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
			mast.position.x=-14.7
		heads.append(_vehicle_head(mast,i%2==1))
	for approach in [Vector3.RIGHT,Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
		var forward: Vector3 = approach
		var setback := WEST_STOP_DISTANCE if forward == Vector3.RIGHT else JUNCTION_STOP_DISTANCE
		var center := -forward*setback + forward.cross(Vector3.UP)*1.85
		center.y = get_parent()._surface_height(center.x,center.z)+.016
		var size := Vector3(.22,.018,3.3) if forward.x != 0 else Vector3(3.3,.018,.22)
		get_parent()._make_box("Junction stop line",size,center,Color("#eee9d9"),false,self)
	heads.append_array(_add_crossing(SHOP_CROSSING,false))
	for direction in [-1,1]:
		var mast := Node3D.new()
		add_child(mast)
		mast.position = SHOP_CROSSING + Vector3(-3*direction,0,4.1*direction)
		mast.rotation.y = -direction*PI/2
		heads.append(_vehicle_head(mast,true))
		get_parent()._make_box("Shop crossing stop line",Vector3(.21,.016,3.25),
			SHOP_CROSSING+Vector3(-3*direction,-.028,1.85*direction),Color("#eee9d9"),false,self)
	heads.append_array(_add_crossing(Vector3(CROSSING_X,0,0),false))
	for z in [-6.35,6.35]:
		heads.append_array(_add_crossing(Vector3(0,0,z),true))
	_build_tram_crossings()
	advance(0)

func _vehicle_head(mast: Node3D, east_west: bool) -> Dictionary:
	get_parent()._make_roadside_solid("Signal mast",Vector3(.12,3.7,.12),Vector3.UP*1.85,Color("#777e78"),false,mast)
	get_parent()._make_box("Signal head",Vector3(.44,1.04,.26),Vector3(0,3.54,.1),Color("#242d2b"),false,mast)
	var lamps: Array = []
	for j in 3:
		lamps.append(lens(mast,Vector3(0,3.85-.31*j,.25),[Color.RED,Color.ORANGE,Color.LIME_GREEN][j]))
	return {"lamps":lamps,"east_west":east_west}

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
		head.figures[0].visible = stage!=Stage.WALK
		head.figures[1].visible = stage==Stage.WALK

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
	if world.ambulance.visible:
		var ext: Vector2 = world._player_extent()
		var player_car := AABB(world.ambulance.position-Vector3(ext.x,.2,ext.y),Vector3(ext.x*2,3,ext.y*2))
		if zone.intersects(player_car): return true
	if world.walker.visible and zone.has_point(world.walker.position): return true
	for item in world.walker_data:
		if zone.has_point(item.actor.position): return true
	return false

func advance_tram_crossings(delta: float) -> void:
	for crossing in tram_crossings:
		crossing.timer += delta
		var duration: float = STAGE_SECONDS[crossing.stage]
		if crossing.timer < duration: continue
		if crossing.stage in [Stage.CLEAR_BOULEVARD, Stage.CLEAR_SIDE, Stage.CLEAR_WALK] and _junction_occupied(crossing):
			crossing.timer = duration
			continue
		crossing.timer = minf(crossing.timer - duration, delta)
		crossing.stage = (int(crossing.stage)+1)%STAGE_SECONDS.size()
		_show_crossing(crossing)

func tram_clearance(distance: float, length: float) -> float:
	var nearest := INF
	for crossing in tram_crossings:
		if crossing.stage==Stage.BOULEVARD: continue
		# Once the cab passes its line, let the whole articulated train clear it.
		var gap: float = fposmod(float(crossing.offset)-distance,length)-BOULEVARD_LINE-get_parent().tram.CAB_REACH
		if gap >= -.001: nearest = minf(nearest,maxf(0,gap))
	return nearest

func pedestrian_may_enter(from: Vector3, to: Vector3) -> bool:
	for c in tram_crossings:
		if c.stage==Stage.WALK: continue
		var dest := to-Vector3(c.center)
		if absf(dest.dot(c.tangent)-ZEBRA_OFFSET)>1.45: continue
		var start := (from-Vector3(c.center)).dot(c.across)
		if absf(start)>=8.7 and absf(dest.dot(c.across))<8.7: return false
	return true

func red_clearance(pos: Vector3, heading: Vector3, half_length: float, red_only := false) -> float:
	var nearest := _central_clearance(pos,heading,half_length,red_only)
	for crossing in tram_crossings:
		var tangent: Vector3 = crossing.tangent
		var across: Vector3 = crossing.across
		var along := absf(heading.dot(tangent)) >= absf(heading.dot(across))
		var green := Stage.BOULEVARD if along else Stage.SIDE_STREET
		if crossing.stage==green or (red_only and crossing.stage==green+1): continue
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
	return nearest
