extends Node3D

var hand: Node3D
var collar_ring := Node3D.new()
var lead: Array[MeshInstance3D] = []

func coat(color: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = .86
	return material

func oval(parent: Node3D, center: Vector3, size: Vector3, finish: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 10
	part.mesh = mesh
	part.material_override = finish
	parent.add_child(part)
	part.position = center
	part.scale = size
	return part

func stick(part: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var axis := b-a
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD)
	if x.length_squared() < .001: x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	part.transform = Transform3D(Basis(x,y*axis.length(),x.cross(y)),(a+b)*.5)

func rod(parent: Node3D, a: Vector3, b: Vector3, r1: float, r2: float, finish: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 10
	mesh.height = 1
	mesh.bottom_radius = r1
	mesh.top_radius = r2
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = finish
	parent.add_child(part)
	stick(part,a,b)
	return part

func update_lead() -> void:
	var a := to_local(hand.global_position)
	var b := collar_ring.position
	var prev := a
	for i in lead.size():
		var t := float(i+1)/lead.size()
		var point := a.lerp(b,t) + Vector3.DOWN*(.15*4*t*(1-t))
		stick(lead[i],prev,point)
		prev = point
