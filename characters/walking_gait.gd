extends RefCounted
## Distance-driven foot placement in a character's local space. Forward is -Z.

const THIGH := 0.37
const SHIN := 0.325
const HIP_HEIGHT := 0.77
const SOLE_HEIGHT := 0.054
const STANCE := 0.55
const UPPER_ARM := 0.34
const BALANCE_FREQUENCY := 18.0
static var trousers: ArrayMesh
static var sleeve_mesh: ArrayMesh

var actor: Node3D
var ground_height: Callable
var phase := 0.0
var weight := 0.0
var lateral_shift := 0.0
var lateral_speed := 0.0
var hip_centres := PackedFloat32Array()
var elbows: Array[Skeleton3D] = []
var palms: Array[Node3D] = []
var palm_rest: Array[Transform3D] = []
var jacket: Node3D
var legs: Array
var arms: Array
var upper_body: Dictionary = {}
var knees: Array[Skeleton3D] = []
var shoes: Array[Node3D] = []

func _init(person: Node3D, initial_phase: float, terrain := Callable()) -> void:
	actor = person
	ground_height = terrain
	phase = fposmod(initial_phase, 1.0)
	jacket = person.get_node("Jacket")
	legs = person.get_meta("legs")
	arms = person.get_meta("arms")
	for child in person.get_children():
		if child is Node3D and child.position.y > 0.6 and child not in legs:
			upper_body[child] = child.position
	for hip: Node3D in legs:
		var cloth: MeshInstance3D = hip.get_child(0)
		if not trousers:
			trousers = _weight_mesh(cloth.mesh, -(THIGH + cloth.position.y), .075)
		cloth.mesh = trousers
		knees.append(_create_joint(cloth, THIGH, "Thigh", "Shin"))
		hip_centres.append(hip.position.x)
		shoes.append(hip.get_child(1))
	for shoulder: Node3D in arms:
		var sleeve: MeshInstance3D = shoulder.get_child(0)
		var hand := shoulder.get_child(1) as Node3D
		if not sleeve_mesh:
			sleeve_mesh = _weight_mesh(sleeve.mesh, -(UPPER_ARM + sleeve.position.y), .07)
		sleeve.mesh = sleeve_mesh
		elbows.append(_create_joint(sleeve, UPPER_ARM, "UpperArm", "Forearm"))
		palms.append(hand)
		palm_rest.append(hand.transform)

func _create_joint(cloth: MeshInstance3D, length: float, upper: String, lower: String) -> Skeleton3D:
	var rig := Skeleton3D.new()
	cloth.add_child(rig)
	rig.add_bone(upper)
	rig.add_bone(lower)
	rig.set_bone_parent(1, 0)
	rig.set_bone_rest(1, Transform3D(Basis.IDENTITY, Vector3.DOWN * (length + cloth.position.y)))
	rig.reset_bone_poses()
	cloth.skeleton = cloth.get_path_to(rig)
	cloth.skin = rig.create_skin_from_rest_transforms()
	return rig

func _weight_mesh(source: Mesh, joint_y: float, blend: float) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(vertices.size() * 4)
		weights.resize(vertices.size() * 4)
		for i in vertices.size():
			var lower_weight := 1.0 - smoothstep(joint_y - blend, joint_y + blend, vertices[i].y)
			bones[i * 4 + 1] = 1
			weights[i * 4] = 1.0 - lower_weight
			weights[i * 4 + 1] = lower_weight
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func advance(distance: float, delta: float, pushing: bool) -> void:
	if delta <= 0.0:
		return
	var pace := distance / delta
	var stride := clampf(0.64 + pace * 0.41, 0.78, 1.57)
	phase = fposmod(phase + distance / stride, 1.0)
	weight = move_toward(weight, minf(1.0, pace / 0.55), delta * 7.0)
	# Critical damping gives the centre of mass inertia when a new foot takes the load.
	var target_shift := -sin(TAU * phase) * .037 * weight
	var error := lateral_shift - target_shift
	var slope := lateral_speed + BALANCE_FREQUENCY * error
	var decay := exp(-BALANCE_FREQUENCY * delta)
	lateral_shift = target_shift + (error + slope * delta) * decay
	lateral_speed = (lateral_speed - BALANCE_FREQUENCY * slope * delta) * decay
	var shoulder_yaw := -cos(TAU * phase) * .11 * weight
	if pushing:
		shoulder_yaw *= .2
	jacket.rotation.y = shoulder_yaw
	var reach := stride * STANCE * 0.5 * weight
	var feet: Array[Vector2] = []
	var shoe_angles := PackedFloat32Array()
	var hip_y := SOLE_HEIGHT + THIGH + SHIN - 0.002
	for i in 2:
		var cycle := fposmod(phase + 0.5 * i, 1.0)
		var foot := Vector2.ZERO # Forward distance and clearance above ground
		var shoe_angle: float
		if cycle < STANCE:
			var heel_lift := 1.0 - smoothstep(0.0, .13, cycle)
			var toe_off := smoothstep(.35, STANCE, cycle)
			shoe_angle = (.20 * heel_lift - .36 * toe_off) * weight
			foot.x = lerpf(reach, -reach, cycle / STANCE)
		else:
			var swing := (cycle - STANCE) / (1.0 - STANCE)
			foot.x = lerpf(-reach, reach, smoothstep(0.0, 1.0, swing))
			foot.y = sin(PI * swing) * (0.085 + 0.025 * pace) * weight
			shoe_angle = lerpf(-.36, .20, smoothstep(0.0, .78, swing)) * weight
		# Raise the ankle about the heel or forefoot while that end of the sole bears weight.
		var sole_pivot := Vector3(0, -SOLE_HEIGHT, .075 if shoe_angle >= 0.0 else -.155)
		var ankle_offset := sole_pivot - sole_pivot.rotated(Vector3.RIGHT, shoe_angle)
		foot += Vector2(-ankle_offset.z, ankle_offset.y)
		shoe_angles.append(shoe_angle)
		if ground_height.is_valid():
			# A shoe can straddle two treads. Check both ends of the pitched sole.
			var elevation := -INF
			for sole_z: float in [.075, -.155]:
				var sole := Vector3(0, -SOLE_HEIGHT, sole_z).rotated(Vector3.RIGHT, shoe_angle)
				var point := actor.to_global(Vector3(hip_centres[i], 0, -foot.x - .025 + sole.z))
				var ground := (float(ground_height.call(point.x, point.z)) - actor.global_position.y) / actor.scale.y
				elevation = maxf(elevation, ground - (SOLE_HEIGHT + ankle_offset.y + sole.y))
			foot.y += clampf(elevation, -0.22, 0.22)
		feet.append(foot)
		hip_y = minf(hip_y, SOLE_HEIGHT + foot.y + sqrt(maxf(0.0, (THIGH + SHIN) ** 2 - foot.x ** 2 - lateral_shift ** 2)) - 0.002)
	for child: Node3D in upper_body:
		var rest: Vector3 = upper_body[child]
		if child in arms:
			rest = rest.rotated(Vector3.UP, shoulder_yaw)
		child.position = rest + Vector3(lateral_shift, hip_y - HIP_HEIGHT, 0)
	for i in 2:
		var foot := feet[i]
		var down := hip_y - SOLE_HEIGHT - foot.y
		var lateral_angle := atan2(-lateral_shift, down)
		down = Vector2(down, lateral_shift).length()
		var length := Vector2(down, foot.x).length()
		var thigh_angle := atan2(foot.x, down) + acos(clampf((THIGH ** 2 + length ** 2 - SHIN ** 2) / (2.0 * THIGH * length), -1.0, 1.0))
		var bend := acos(clampf((length ** 2 - THIGH ** 2 - SHIN ** 2) / (2.0 * THIGH * SHIN), -1.0, 1.0))
		legs[i].position.x = hip_centres[i] + lateral_shift
		legs[i].position.y = hip_y
		legs[i].basis = Basis(Vector3.BACK, lateral_angle) * Basis(Vector3.RIGHT, thigh_angle)
		knees[i].set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, -bend))
		var shin := Vector3.DOWN * SHIN
		shoes[i].position = Vector3.DOWN * THIGH + shin.rotated(Vector3.RIGHT, -bend)
		shoes[i].position += legs[i].basis.inverse() * (Vector3.FORWARD * 0.025)
		shoes[i].basis = legs[i].basis.inverse() * Basis(Vector3.RIGHT, shoe_angles[i])
		if not pushing:
			arms[i].rotation.x = -foot.x * 1.05
			# Leave room for the resting thumb beside the jacket and thigh.
			arms[i].rotation.z = signf(hip_centres[i]) * .10
		var flex := .15 + weight * (.18 - foot.x * .52)
		if pushing:
			flex = .12
		var elbow_rotation := Basis(Vector3.RIGHT, flex)
		elbows[i].set_bone_pose_rotation(1, elbow_rotation.get_rotation_quaternion())
		var joint := Vector3.DOWN * UPPER_ARM
		var rest := palm_rest[i]
		palms[i].transform = Transform3D(elbow_rotation * rest.basis, joint + elbow_rotation * (rest.origin - joint))
