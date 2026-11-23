extends Node3D

const LOADS := 6
const TOOTH_TIP := Vector3(0, -1.048, -.95)
var remaining := LOADS
var delivered := 0
var pile: MeshInstance3D
var cargo: MeshInstance3D
var deposit: MeshInstance3D
var bed := Node3D.new()

func setup(world: Node3D, joint: Node3D, yard: Vector3) -> void:
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color("#cfac70")
	sand.roughness = .98
	pile = mound(self, sand)
	pile.position = yard + Vector3(-1.1,.06,-4)
	cargo = mound(joint, sand)
	cargo.position = Vector3(0,-.55,-.15)
	cargo.scale = Vector3(.78,.40,.54)
	add_child(bed)
	bed.position = yard + Vector3(-7,.06,2)
	world._make_box("Sand loading deck",Vector3(3.6,.24,2.6),Vector3.UP*.48,Color("#635342"),false,bed)
	for side in [-1,1]:
		world._make_box("Flatbed runner",Vector3(3.25,.36,.24),Vector3(0,.18,side*.94),Color("#464c4f"),false,bed)
		world._make_box("Flatbed rail",Vector3(3.62,.25,.10),Vector3(0,.72,side*1.27),Color("#aa7847"),false,bed)
	deposit = mound(bed, sand)
	deposit.position.y = .60
	refresh()

func mound(parent: Node3D, material: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 1
	shape.height = 2
	shape.is_hemisphere = true
	shape.radial_segments = 17
	shape.rings = 6
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func refresh() -> void:
	pile.visible = remaining > 0
	pile.scale = Vector3(2.05,1.12,1.65) * pow(maxi(remaining,1)/float(LOADS),1.0/3.0)
	cargo.visible = remaining + delivered < LOADS
	deposit.visible = delivered > 0
	deposit.scale = Vector3(1.72,.94,1.20) * pow(maxi(delivered,1)/float(LOADS),1.0/3.0)

func move_bucket(joint: Node3D, curl: float) -> void:
	var tip := joint.to_global(TOOTH_TIP)
	if curl > 0 and remaining > 0 and not cargo.visible:
		var contact := pile.to_local(tip)
		if contact.y >= -.12 and contact.length_squared() <= 1:
			remaining -= 1
			refresh()
	elif curl < 0 and cargo.visible and joint.rotation.x < -.20:
		var over_bed := bed.to_local(tip)
		if absf(over_bed.x) < 1.80 and absf(over_bed.z) < 1.30 and over_bed.y >= .60:
			delivered += 1
			refresh()
