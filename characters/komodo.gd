extends "res://characters/walking_pet.gd"

var legs: Array[Node3D] = []
var tail_skin: ShaderMaterial
var tongue := Node3D.new()
var phase := 0.0

const BODY_BOUNDS := AABB(Vector3(-.38,0,-1.08), Vector3(.76,.65,2.70))

func _ready() -> void:
	name = "KomodoDragon"
	position = Vector3(.83,0,-.34)
	var scales := ShaderMaterial.new()
	scales.shader = preload("res://characters/komodo_scales.gdshader")
	var throat := coat("#9d926f")
	var claw := coat("#595342")
	var pupil := coat("#201d18")
	var iris := coat("#b69d5a")
	var strap := coat("#ae6440")
	oval(self,Vector3(0,.34,.03),Vector3(.46,.42,1.04),scales)
	oval(self,Vector3(0,.414,-.48),Vector3(.31,.30,.55),scales).rotation.x = .27
	oval(self,Vector3(0,.455,-.64),Vector3(.245,.18,.32),throat)
	oval(self,Vector3(0,.533,-.72),Vector3(.262,.184,.38),scales)
	oval(self,Vector3(0,.508,-.846),Vector3(.203,.102,.219),throat)
	oval(self,Vector3(0,.54,-.847),Vector3(.207,.096,.226),scales)
	for side: float in [-1,1]:
		oval(self,Vector3(side*.115,.564,-.759),Vector3(.029,.029,.037),iris)
		oval(self,Vector3(side*.126,.566,-.767),Vector3(.014,.018,.018),pupil)
		oval(self,Vector3(side*.068,.559,-.924),Vector3(.014,.009,.02),pupil)
	for rear in [false,true]:
		for side: float in [-1,1]:
			var hip := Node3D.new()
			add_child(hip)
			hip.position = Vector3(side*.14,.325,.315 if rear else -.292)
			var elbow := Vector3(side*.13,-.11,.086)
			var wrist := Vector3(side*.152,-.273,-.034)
			rod(hip,Vector3.ZERO,elbow,.08,.058,scales)
			oval(hip,elbow,Vector3(.117,.115,.116),scales)
			rod(hip,elbow,wrist,.058,.034,scales)
			oval(hip,wrist,Vector3(.098,.065,.13),scales)
			for toe in 5:
				var base := wrist+Vector3((toe-2)*.012,-.018,-.036)
				var tip := base+Vector3((toe-2)*.017,-.012,-.077+.011*absf(toe-2))
				rod(hip,base,tip,.009,.002,claw)
			legs.append(hip)
	_build_tail(scales)
	add_child(tongue)
	tongue.position = Vector3(0,.518,-.938)
	var pink := coat("#b98782")
	rod(tongue,Vector3.ZERO,Vector3(0,0,-.085),.008,.005,pink)
	for side: float in [-1,1]:
		rod(tongue,Vector3(0,0,-.085),Vector3(.024*side,-.006,-.135),.005,.001,pink)
	# A chest harness carries the lead above the shoulders.
	var band := MeshInstance3D.new()
	var loop := TorusMesh.new()
	loop.inner_radius = .196
	loop.outer_radius = .218
	band.mesh = loop
	band.material_override = strap
	add_child(band)
	band.position = Vector3(0,.355,-.247)
	band.rotation.x = PI*.5
	band.scale = Vector3(.99,1,.91)
	add_child(collar_ring)
	collar_ring.position = Vector3(-.07,.53,-.25)
	for i in 8:
		lead.append(rod(self,Vector3.ZERO,Vector3.UP,.007,.007,strap))

func _build_tail(scales: ShaderMaterial) -> void:
	const RINGS := 24
	const SIDES := 16
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(RINGS+1):
		var t := float(ring)/RINGS
		var radius := .16*pow(1.0-t,1.12)+.002
		var centre := Vector3(0,-.245*sin(t*PI*.5),1.23*t)
		var slope := -.245*PI*.5*cos(t*PI*.5)/1.23
		var up := Vector3(0,1,-slope).normalized()
		for side in range(SIDES+1):
			var u := float(side)/SIDES
			var radial := Vector3.RIGHT*cos(TAU*u)+up*sin(TAU*u)
			surface.set_normal((radial+Vector3.BACK*.13).normalized())
			surface.set_uv(Vector2(u,t))
			surface.add_vertex(centre+radial*radius)
			if ring < RINGS and side < SIDES:
				var a := ring*(SIDES+1)+side
				var b := a+SIDES+1
				for index in [a,b,a+1,a+1,b,b+1]:
					surface.add_index(index)
	var tail := MeshInstance3D.new()
	tail.name = "TaperedTail"
	tail.mesh = surface.commit()
	tail.custom_aabb = tail.mesh.get_aabb().grow(.32)
	tail_skin = scales.duplicate() as ShaderMaterial
	tail_skin.set_shader_parameter("tail_sway",true)
	tail.material_override = tail_skin
	add_child(tail)
	tail.position = Vector3(0,.31,.37)

func advance(distance: float) -> void:
	phase = fmod(phase + distance*7.4,TAU*4)
	for i in legs.size():
		var step := sin(phase+(PI if i in [1,2] else 0.0)) if distance > 0 else 0.0
		legs[i].rotation.x = step*.23
		legs[i].rotation.y = step*.16
	tail_skin.set_shader_parameter("phase",phase*.5)
	tongue.visible = fmod(phase,TAU*2) < 1.7 and distance > 0
	update_lead()
