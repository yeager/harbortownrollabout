extends RefCounted

static func dress(person: Node3D, wool: Material, fur: Material, leather: Material, brass: Material) -> void:
	var face := person.get_node("Face") as Node3D
	person.get_node("Hair").hide()
	var jacket := person.get_node("Jacket") as Node3D
	oval(jacket, Vector3.ZERO, Vector3(.53,.70,.39), wool)
	oval(jacket, Vector3(0,-.21,0), Vector3(.51,.095,.38), leather)
	oval(jacket, Vector3(0,-.21,-.19), Vector3(.09,.07,.025), brass)
	oval(jacket, Vector3(0,-.29,0), Vector3(.45,.095,.34), fur)
	oval(jacket, Vector3(0,.24,0), Vector3(.41,.14,.28), fur)
	oval(face, Vector3(0,.105,0), Vector3(.267,.095,.26), fur)
	oval(face, Vector3(.014,.17,.005), Vector3(.24,.17,.23), wool)
	oval(face, Vector3(.11,.17,.012), Vector3(.20,.105,.135), wool).rotation.z = -.68
	oval(face, Vector3(.192,.103,.015), Vector3.ONE*.09, fur)
	for i in range(-4,5):
		var x := i*.024
		oval(face, Vector3(x,-.105+absf(x)*.63,-.10+absf(x)*.40), Vector3(.072,.16-absf(x)*.38,.09),fur)
	for side in [-1,1]:
		oval(face,Vector3(side*.041,-.045,-.131),Vector3(.095,.035,.036),fur).rotation.z = side*.20

static func oval(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = SphereMesh.new()
	part.material_override = material
	part.position = at
	part.scale = size
	parent.add_child(part)
	return part
