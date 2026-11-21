extends RefCounted
## Distance-driven foot placement in a character's local space. Forward is -Z.

const THIGH := 0.37
const SHIN := 0.325
const HIP_HEIGHT := 0.77
const SOLE_HEIGHT := 0.054
const STANCE := 0.55
static var trousers: ArrayMesh

var actor: Node3D
var ground_height: Callable
var phase := 0.0
var weight := 0.0
var legs: Array
var arms: Array
var upper_body: Dictionary = {}
var knees: Array[Skeleton3D] = []
var shoes: Array[Node3D] = []

func _init(person: Node3D, initial_phase: float, terrain := Callable()) -> void:
	actor = person
	ground_height = terrain
	phase = fposmod(initial_phase, 1.0)
	legs = person.get_meta("legs")
	arms = person.get_meta("arms")
	for child in person.get_children():
		if child is Node3D and child.position.y > 0.6 and child not in legs:
			upper_body[child] = child.position
	for hip: Node3D in legs:
		var cloth: MeshInstance3D = hip.get_child(0)
		if not trousers:
			trousers = _weighted_trousers(cloth.mesh)
		cloth.mesh = trousers
		var rig := Skeleton3D.new()
		cloth.add_child(rig)
		rig.add_bone("Thigh")
		rig.add_bone("Shin")
		rig.set_bone_parent(1, 0)
		rig.set_bone_rest(1, Transform3D(Basis.IDENTITY, Vector3.DOWN * (THIGH + cloth.position.y)))
		rig.reset_bone_poses()
		cloth.skeleton = cloth.get_path_to(rig)
		cloth.skin = rig.create_skin_from_rest_transforms()
		knees.append(rig)
		shoes.append(hip.get_child(1))

func _weighted_trousers(source: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(vertices.size() * 4)
		weights.resize(vertices.size() * 4)
		for i in vertices.size():
			var shin_weight := 1.0 - smoothstep(-0.085, 0.065, vertices[i].y)
			bones[i * 4 + 1] = 1
			weights[i * 4] = 1.0 - shin_weight
			weights[i * 4 + 1] = shin_weight
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
	var reach := stride * STANCE * 0.5 * weight
	var feet: Array[Vector2] = []
	var hip_y := SOLE_HEIGHT + THIGH + SHIN - 0.002
	for i in 2:
		var cycle := fposmod(phase + 0.5 * i, 1.0)
		var foot := Vector2.ZERO # Forward distance and clearance above ground
		if cycle < STANCE:
			foot.x = lerpf(reach, -reach, cycle / STANCE)
		else:
			var swing := (cycle - STANCE) / (1.0 - STANCE)
			foot.x = lerpf(-reach, reach, smoothstep(0.0, 1.0, swing))
			foot.y = sin(PI * swing) * (0.085 + 0.025 * pace) * weight
		if ground_height.is_valid():
			var point := actor.to_global(Vector3(legs[i].position.x, 0, -foot.x))
			var elevation := (float(ground_height.call(point.x, point.z)) - actor.global_position.y) / actor.scale.y
			foot.y += clampf(elevation, -0.22, 0.22)
		feet.append(foot)
		hip_y = minf(hip_y, SOLE_HEIGHT + foot.y + sqrt(maxf(0.0, (THIGH + SHIN) ** 2 - foot.x ** 2)) - 0.002)
	for child: Node3D in upper_body:
		child.position = upper_body[child] + Vector3.UP * (hip_y - HIP_HEIGHT)
	for i in 2:
		var foot := feet[i]
		var down := hip_y - SOLE_HEIGHT - foot.y
		var length := Vector2(down, foot.x).length()
		var thigh_angle := atan2(foot.x, down) + acos(clampf((THIGH ** 2 + length ** 2 - SHIN ** 2) / (2.0 * THIGH * length), -1.0, 1.0))
		var bend := acos(clampf((length ** 2 - THIGH ** 2 - SHIN ** 2) / (2.0 * THIGH * SHIN), -1.0, 1.0))
		legs[i].position.y = hip_y
		legs[i].rotation.x = thigh_angle
		knees[i].set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, -bend))
		var shin := Vector3.DOWN * SHIN
		shoes[i].position = Vector3.DOWN * THIGH + shin.rotated(Vector3.RIGHT, -bend)
		shoes[i].position += Vector3.FORWARD.rotated(Vector3.RIGHT, -thigh_angle) * 0.025
		shoes[i].rotation.x = -thigh_angle
		if not pushing:
			arms[i].rotation.x = -foot.x * 1.05
