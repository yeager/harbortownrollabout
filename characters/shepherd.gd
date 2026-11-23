extends "res://characters/walking_pet.gd"
## A walking German shepherd, in metres. Forward is local -Z.
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var tail := Node3D.new()
var phase := 0.0
var tan := coat("#b7783e")
var honey := coat("#d89a55")
var sable := coat("#302921")
var black := coat("#191a1b")
var leather := coat("#257876")

func ear(side: float) -> void:
	var base := Vector3(side*.078,.838,-.418)
	var tip := base+Vector3(side*.037,.174,.019)
	var left := base+Vector3(-.052,0,-.01)
	var right := base+Vector3(.052,0,-.01)
	var back := base+Vector3(0,.005,.071)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [left,tip,right,right,tip,back,back,tip,left,left,right,back]:
		surface.add_vertex(point)
	surface.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = surface.commit()
	var fur := tan.duplicate() as StandardMaterial3D
	fur.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = fur
	add_child(part)
	var inside := oval(self,base+Vector3(0,.05,.001),Vector3(.064,.12,.013),sable)
	inside.rotation.x = .09

const BODY_BOUNDS := AABB(Vector3(-.20,0,-.68), Vector3(.40,1.04,1.38))

func _ready() -> void:
	name = "GermanShepherd"
	position = Vector3(.69,0,-.30)
	var back_fur := ShaderMaterial.new()
	back_fur.shader = preload("res://characters/shepherd_coat.gdshader")
	oval(self,Vector3(0,.49,.035),Vector3(.315,.373,.84),back_fur).rotation.x = .10
	oval(self,Vector3(0,.56,-.235),Vector3(.288,.41,.30),honey).rotation.x = -.34
	oval(self,Vector3(0,.674,-.308),Vector3(.246,.34,.23),tan).rotation.x = -.40
	oval(self,Vector3(0,.791,-.403),Vector3(.237,.228,.265),tan)
	oval(self,Vector3(0,.755,-.526),Vector3(.154,.131,.245),sable).rotation.x = -.1
	oval(self,Vector3(0,.756,-.637),Vector3(.111,.071,.066),black)
	for side: float in [-1,1]:
		ear(side)
		oval(self,Vector3(.088*side,.808,-.479),Vector3(.04,.03,.04),black)
		oval(self,Vector3(.099*side,.813,-.491),Vector3(.009,.009,.009),honey)
	rod(self,Vector3(0,.655,-.298),Vector3(0,.685,-.312),.127,.127,leather)
	add_child(collar_ring)
	collar_ring.position = Vector3(-.106,.686,-.318)
	for hind in [false,true]:
		for side: float in [-1,1]:
			var hip := Node3D.new()
			add_child(hip)
			hip.position = Vector3(.105*side,.46,.29 if hind else -.215)
			var joint := Vector3(0,-.194,-.07 if hind else .018)
			rod(hip,Vector3.ZERO,joint,.069 if hind else .047,.043,tan)
			var knee := Node3D.new()
			hip.add_child(knee)
			knee.position = joint
			var hock := Vector3(0,-.123,.115 if hind else -.01)
			rod(knee,Vector3.ZERO,hock,.043,.031,tan)
			var ankle := Vector3(0,-.23,.075 if hind else -.01)
			rod(knee,hock,ankle,.033,.025,honey)
			oval(knee,ankle+Vector3(0,-.009,-.027),Vector3(.076,.057,.134),honey)
			hips.append(hip)
			knees.append(knee)
	add_child(tail)
	tail.position = Vector3(0,.51,.35)
	oval(tail,Vector3(0,-.133,.119),Vector3(.114,.39,.125),sable).rotation.x = -.65
	oval(tail,Vector3(0,-.269,.246),Vector3(.09,.23,.094),black).rotation.x = -.88
	for i in 8:
		lead.append(rod(self,Vector3.ZERO,Vector3.UP,.008,.008,leather))

func advance(distance: float) -> void:
	phase = fmod(phase+distance*9.2,TAU)
	for i in hips.size():
		var stride := sin(phase+(PI if i in [1,2] else 0.0)) if distance > 0 else 0.0
		hips[i].rotation.x = stride*.38
		knees[i].rotation.x = minf(stride,0)*-.27
	tail.rotation.z = sin(phase)*.16
	update_lead()
