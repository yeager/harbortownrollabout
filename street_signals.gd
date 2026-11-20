extends Node3D

# The main junction clears before the north/south traffic and pedestrians get green.
var elapsed := 0.0
var heads: Array[Dictionary] = []
var phase := -1
const CROSSING_X := -12.0

func _ready() -> void:
	for i in 4:
		var mast := Node3D.new()
		add_child(mast)
		mast.rotation.y = i*PI/2
		mast.position = mast.basis*Vector3(5.4,0,6)
		if i==3:
			mast.position.x=-14.7
		get_parent()._make_box("Signal mast",Vector3(.12,3.7,.12),Vector3.UP*1.85,Color("#777e78"),false,mast)
		get_parent()._make_box("Signal head",Vector3(.44,1.04,.26),Vector3(0,3.54,.1),Color("#242d2b"),false,mast)
		var lamps: Array = []
		for j in 3:
			lamps.append(lens(mast,Vector3(0,3.85-.31*j,.25),[Color.RED,Color.ORANGE,Color.LIME_GREEN][j]))
		heads.append({"lamps":lamps,"east_west":i%2==1})
	_add_crossing(Vector3(CROSSING_X,0,0),false)
	for z in [-6.35,6.35]:
		_add_crossing(Vector3(0,0,z),true)
	advance(0)

func _add_crossing(center: Vector3, east_west: bool) -> void:
	for side in [-1,1]:
		var mast := Node3D.new()
		add_child(mast)
		mast.position = center + Vector3(5.45*side,0,-1.55*side) if east_west else center + Vector3(-1.55*side,0,5.45*side)
		mast.rotation.y = (-PI/2 if side==1 else PI/2) if east_west else (PI if side==1 else 0.)
		get_parent()._make_box("Crossing pole",Vector3(.09,2.45,.09),Vector3.UP*1.22,Color("#737d7a"),false,mast)
		get_parent()._make_box("Pedestrian signal",Vector3(.52,.9,.18),Vector3.UP*2.2,Color("#202927"),false,mast)
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
		heads.append({"figures":signs,"walk_phase":0 if east_west else 3})

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
	elapsed=fmod(elapsed+delta,42)
	var current := 0 if elapsed<18 else 1 if elapsed<21 else 2 if elapsed<23 else 3 if elapsed<37 else 4 if elapsed<40 else 5
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

func red_clearance(pos: Vector3, heading: Vector3, half_length: float) -> float:
	var east_west := absf(heading.x)>.95
	if not east_west and absf(heading.z)<.95: return INF
	var green := 0 if east_west else 3
	if phase==green: return INF
	var along := pos.x if east_west else pos.z
	var across := pos.z if east_west else pos.x
	var direction := signf(heading.x if east_west else heading.z)
	if absf(across)>4.85: return INF
	var gap := -along*direction - (15 if east_west and direction>0 else 8) - half_length
	return gap if gap>=-.05 else INF
