extends RefCounted

const FLASH_PERIOD := .8
const OFF_COLOR := Color("#825026")
const ON_COLOR := Color("#ff9f20")

var left: Array[MeshInstance3D] = []
var right: Array[MeshInstance3D] = []
var direction := 0
var phase := 0.0
var housing := StandardMaterial3D.new()
var amber := StandardMaterial3D.new()

func _init() -> void:
	housing.albedo_color = OFF_COLOR
	housing.roughness = .31
	amber.albedo_color = ON_COLOR
	amber.roughness = .31
	amber.emission_enabled = true
	amber.emission = ON_COLOR
	amber.emission_energy_multiplier = 1.35

func fit_anchors(actor: Node3D, left_points: Array[Vector3], right_points: Array[Vector3], size: Vector3) -> void:
	for point in left_points:
		_add_lamp(actor, point, size, -1)
	for point in right_points:
		_add_lamp(actor, point, size, 1)

func fit(actor: Node3D, model: Node3D, bounds: AABB) -> void:
	var frame := Node3D.new()
	frame.name = "Turn indicators"
	model.add_child(frame)
	frame.global_transform = actor.global_transform
	if model.scene_file_path.ends_with("/city_bus.glb"):
		for side in [-1, 1]:
			# The imported bus faces +Z, opposite the driving actor.
			var front := Vector3(side * 1.015, .892, 5.363)
			_add_lamp(frame, actor.to_local(model.to_global(front)),
				Vector3(.155, .041, .016), -side, side * .13)
			for contact in [
				[Vector3(side * 1.01, 1.11, -5.302), Vector3(.19, .085, .027)],
				[Vector3(side * 1.298, 1.16, 3.91), Vector3(.009, .043, .115)],
			]:
				_add_lamp(frame, actor.to_local(model.to_global(contact[0])), contact[1], -side)
		return
	var panels: Array[AABB] = []
	var existing: Array[MeshInstance3D] = [null, null, null, null]
	var to_actor := actor.global_transform.affine_inverse()
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if not part.mesh or not part.visible:
			continue
		var label := String(part.name).to_lower()
		if "wheel" in label or "tyre" in label or "tire" in label or "bucket" in label or "blade" in label or "mirror" in label:
			continue
		var panel := (to_actor * part.global_transform) * part.get_aabb()
		if _is_indicator_lens(label):
			var offset := panel.get_center() - bounds.get_center()
			if absf(offset.x) > bounds.size.x * .13 and absf(offset.z) > bounds.size.z * .2:
				var slot := (2 if offset.x > 0 else 0) + (1 if offset.z > 0 else 0)
				if existing[slot] == null:
					existing[slot] = part
		if panel.size.y >= .035 and panel.size.x >= .035:
			panels.append(panel)
	var width := bounds.size.x
	var height := bounds.size.y
	var size := Vector3(clampf(width * .09, .065, .19), clampf(height * .034, .038, .105), .035)
	for side in [-1, 1]:
		for end in [-1, 1]:
			var slot := (2 if side > 0 else 0) + (1 if end > 0 else 0)
			if existing[slot]:
				_use_existing_lens(existing[slot], side)
				continue
			var at := _attachment(panels, bounds, side, end)
			_add_lamp(frame, at, size, side)

func _is_indicator_lens(label: String) -> bool:
	for name in ["blinkersglas", "corner indicator", "front amber marker", "front amber indicator",
			"rear indicator lens", "turn signal", "cab amber signal"]:
		if name in label:
			return true
	return false

func _use_existing_lens(lens: MeshInstance3D, side: int) -> void:
	var lit := MeshInstance3D.new()
	lit.name = "Amber flash"
	lit.mesh = lens.mesh
	lit.material_override = amber
	lit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lit.scale = Vector3.ONE * 1.005
	lens.material_override = housing
	lens.add_child(lit)
	_track(lit, side)

func _attachment(panels: Array[AABB], bounds: AABB, side: int, end: int) -> Vector3:
	var best := INF
	var center := bounds.get_center()
	var ideal_x := center.x + side * bounds.size.x * .36
	var ideal_y := bounds.position.y + clampf(bounds.size.y * .38, .47, 1.3)
	var at := Vector3(ideal_x, ideal_y, bounds.position.z if end < 0 else bounds.end.z)
	for panel in panels:
		var face := panel.position.z if end < 0 else panel.end.z
		if (face - center.z) * end < bounds.size.z * .21:
			continue
		# Small parts still make useful anchors on narrow bikes and mowers.
		var x := clampf(ideal_x, panel.position.x, panel.end.x)
		var y := clampf(ideal_y, panel.position.y + .02, maxf(panel.position.y + .02, panel.end.y - .02))
		var score := absf(x - ideal_x) + absf(y - ideal_y) * .8
		score += absf(face - (bounds.position.z if end < 0 else bounds.end.z)) * .22
		if score < best and (x - center.x) * side >= bounds.size.x * .09:
			best = score
			at = Vector3(x, y, face)
	at.z += end * .006
	return at

func _add_lamp(frame: Node3D, at: Vector3, size: Vector3, side: int, yaw := 0.0) -> void:
	var lens := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = housing
	lens.mesh = mesh
	lens.name = "Left indicator lens" if side < 0 else "Right indicator lens"
	lens.position = at
	lens.rotation.y = yaw
	frame.add_child(lens, true)
	var lit := MeshInstance3D.new()
	var glow := BoxMesh.new()
	glow.size = size + Vector3.ONE * .003
	glow.material = amber
	lit.mesh = glow
	lit.name = "Amber flash"
	lens.add_child(lit)
	_track(lit, side)

func _track(lit: MeshInstance3D, side: int) -> void:
	lit.hide()
	if side < 0:
		left.append(lit)
	else:
		right.append(lit)

func advance(turn: float, delta: float, steady: bool) -> void:
	var next := int(signf(turn)) if absf(turn) >= .12 else 0
	if next != direction:
		phase = 0.0
		direction = next
	phase = fposmod(phase + delta, FLASH_PERIOD)
	var lit := steady or phase < FLASH_PERIOD * .5
	for lamp in left:
		lamp.visible = lit and direction < 0
	for lamp in right:
		lamp.visible = lit and direction > 0
