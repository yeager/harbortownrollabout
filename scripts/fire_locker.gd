extends Node3D

var panel: MeshInstance3D
var fittings: Array[MeshInstance3D] = []
var closed_height := 0.0
var lift := 0.0

func fit(model: Node3D) -> void:
	panel = model.find_child("Roller shutter",true,false)
	var carrier := panel.get_parent()
	carrier.add_child(self)
	closed_height = -2.0*panel.get_aabb().position.y # The mesh origin is halfway up the closed blind.
	for part in carrier.get_children():
		if not part is MeshInstance3D: continue
		if absf(part.position.z-panel.position.z) > .56 or part.position.x > -1.14: continue
		if not (part.name.begins_with("Locker reflective") or part.name.begins_with("Shutter seam") or part.name.begins_with("Shutter lift") or part.name.begins_with("Shutter lock") or part.name.begins_with("Shutter keyway") or part.name.begins_with("Lift handle bracket")): continue
		part.set_meta("closed_y",part.position.y)
		fittings.append(part)
	panel.set_meta("closed_y",panel.position.y)
	# Show the wound supply hose against the dark liner as the panel retracts.
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("#bf9656")
	rubber.roughness = .86
	for i in 5:
		var coil := MeshInstance3D.new()
		var tube := TorusMesh.new()
		tube.outer_radius = .12+i*.065
		tube.inner_radius = tube.outer_radius-.061
		tube.rings = 32
		tube.ring_segments = 8
		coil.mesh = tube
		coil.material_override = rubber
		coil.rotation.z = PI*.5
		coil.scale.y = .26
		coil.position = Vector3(-1.151,1.64,panel.position.z)
		add_child(coil)

func advance(delta: float, opening: bool) -> void:
	var next := move_toward(lift,closed_height-.055 if opening else 0.0,delta*1.6)
	if next == lift: return
	lift = next
	var centre := float(panel.get_meta("closed_y"))
	var top := centre + closed_height*.5
	panel.position.y = centre + lift*.5
	panel.scale.y = 1.0-lift/closed_height
	for part in fittings:
		part.position.y = float(part.get_meta("closed_y"))+lift
		part.visible = part.position.y < top
