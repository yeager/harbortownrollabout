extends RefCounted
## Small features that attach to the existing portrait and articulated shoe.

static func add_trainer_details(shoe: MeshInstance3D, accent: Color) -> void:
	var liner := _finish(Color("#302c2b"))
	var lace := _finish(Color("#cfc4ae"))
	var rubber := _finish(Color("#999188"))
	var panel := _finish(accent)
	var eyelet := _finish(Color("#3a3532"))
	var upper := Vector3(0, .047, -.058)
	_oval(shoe, "Lace panel", upper, Vector3(.042, .005, .047), liner).rotation.x = -.41
	for row in 4:
		var z := -.043 - row * .017
		var y: float = [.062, .058, .048, .032][row]
		for side in [-1, 1]:
			_oval(shoe, "Lace eyelet", Vector3(side * .032, y - .005, z), Vector3(.005, .003, .005), eyelet)
		var crossing := _oval(shoe, "Woven lace", Vector3(0, y + .001, z), Vector3(.036, .0027, .0031), lace)
		crossing.rotation.y = .12 if row % 2 == 0 else -.12
	for side in [-1, 1]:
		var stripe := _oval(shoe, "Side panel", Vector3(side * .073, -.009, -.027), Vector3(.006, .008, .040), panel)
		stripe.rotation.x = -.18
	_oval(shoe, "Heel patch", Vector3(0, .014, .074), Vector3(.043, .018, .005), panel)
	_oval(shoe, "Toe bumper", Vector3(0, -.031, -.128), Vector3(.064, .007, .019), rubber)

static func add_jacket_details(torso: MeshInstance3D) -> void:
	var welt := _finish(Color("#39454b"))
	for side in [-1, 1]:
		var pocket := _oval(torso, "Pocket welt", Vector3(side * .097, -.168, -.110), Vector3(.007, .058, .009), welt)
		pocket.rotation.z = side * .31
		pocket.rotation.x = .17

static func add_ear_details(ear: MeshInstance3D, side: int, skin: Color) -> void:
	# Local dimensions are expressed relative to the scaled outer ear.
	_oval(ear, "Concha", Vector3(side * .150, -.012, -.032), Vector3(.026, .091, .102), _finish(skin.darkened(.22)))
	var fold := _oval(ear, "Ear fold", Vector3(side * .158, .014, -.017), Vector3(.022, .069, .053), _finish(skin.darkened(.055)))
	fold.rotation.x = -.30
	_oval(ear, "Tragus", Vector3(side * .091, -.036, -.103), Vector3(.027, .038, .034), _finish(skin))

static func _finish(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .87
	return material

static func _oval(parent: Node3D, title: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 12
	mesh.rings = 6
	var part := MeshInstance3D.new()
	part.name = title
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.scale = radii
	parent.add_child(part)
	return part
