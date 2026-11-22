extends Node3D
## Seated limbs in rider space, fitted to the Dakota saddle, grips and footrests.

var arms: Array[MeshInstance3D] = []
var legs: Array[MeshInstance3D] = []
var hands: Array[MeshInstance3D] = []
var shoes: Array[MeshInstance3D] = []

func _ready() -> void:
	var rider := get_parent() as Node3D
	for i in 2:
		var sleeve: MeshInstance3D = rider.get_meta("arms")[i].get_child(0)
		var trouser: MeshInstance3D = rider.get_meta("legs")[i].get_child(0)
		for radius in [.067, .052]:
			arms.append(_segment(radius, sleeve.material_override))
		for radius in [.086, .066]:
			legs.append(_segment(radius, trouser.material_override))
		var hand := MeshInstance3D.new()
		var palm := SphereMesh.new()
		palm.radius = .052
		palm.height = .112
		hand.mesh = palm
		hand.material_override = rider.get_node("Face").material_override
		add_child(hand)
		hands.append(hand)
		var shoe: MeshInstance3D = rider.get_meta("legs")[i].get_child(1).duplicate()
		add_child(shoe)
		shoes.append(shoe)
	var helmet := MeshInstance3D.new()
	var shell := SphereMesh.new()
	shell.radius = .148
	shell.height = .255
	shell.is_hemisphere = true
	helmet.mesh = shell
	helmet.name = "Helmet"
	helmet.position = Vector3(0, 1.675, .005)
	helmet.scale = Vector3(.94, 1, 1.09)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("#eee8d9")
	finish.roughness = .31
	helmet.material_override = finish
	add_child(helmet)

func _segment(radius: float, finish: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = .48
	part.mesh = mesh
	part.material_override = finish
	add_child(part)
	return part

func _fit(part: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	part.position = (start + end) * .5
	part.quaternion = Quaternion(Vector3.UP, start.direction_to(end))
	part.scale.y = (start.distance_to(end) + .045) / .48

func _joint(start: Vector3, end: Vector3, bend: Vector3, length: float) -> Vector3:
	var reach := end - start
	var offset := sqrt(maxf(0.0, length * length - reach.length_squared() * .25))
	return (start + end) * .5 + bend.slide(reach.normalized()).normalized() * offset

func fit_to(model: Node3D) -> void:
	var rider := get_parent() as Node3D
	var saddle := model.find_child("RiderSeat", true, false) as Node3D
	rider.global_position = saddle.global_position - rider.global_basis.y * .77
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Character left/right correspond to physical left/right relative to travel.
		var suffix := "Left" if i == 0 else "Right"
		var grip := model.find_child("Grip"+suffix, true, false) as Node3D
		var peg := model.find_child("Peg"+suffix, true, false) as Node3D
		var shoulder: Node3D = rider.get_meta("arms")[i]
		var hip: Node3D = rider.get_meta("legs")[i]
		var hand := to_local(grip.global_position)
		var ankle := to_local(peg.global_position) + Vector3(0,.057,.043)
		var elbow := _joint(shoulder.position, hand, Vector3(side*.38,-1,0), .345)
		var knee := _joint(hip.position, ankle, Vector3(side*.25,0,-1), .39)
		_fit(arms[i*2], shoulder.position, elbow)
		_fit(arms[i*2+1], elbow, hand)
		_fit(legs[i*2], hip.position, knee)
		_fit(legs[i*2+1], knee, ankle)
		hands[i].position = hand
		shoes[i].position = ankle - Vector3(0,.047,.043)
		for arm in [arms[i*2], arms[i*2+1]]:
			arm.material_override = shoulder.get_child(0).material_override
