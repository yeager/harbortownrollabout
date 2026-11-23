extends Node3D

const SHOES := 52
const STRAIGHT := 4.26
const RADIUS := .57
const LENGTH := 2 * STRAIGHT + TAU * RADIUS

var plates: MultiMesh
var ribs: MultiMesh
var pins: MultiMesh
var edges: MultiMesh
var phase := 0.0

func configure(original: MeshInstance3D) -> void:
	plates = _strip(Vector3(.88,.116,.224), original.get_active_material(0))
	ribs = _strip(Vector3(.88,.05,.052), original.get_active_material(1))
	var edge_finish := original.get_active_material(2)
	edges = _strip(Vector3(.88,.009,.036), edge_finish)
	var pin := CylinderMesh.new()
	pin.top_radius = .044
	pin.bottom_radius = .044
	pin.height = .91
	pin.radial_segments = 12
	pin.rings = 0
	pin.material = original.get_active_material(0)
	pins = _batch(pin)
	advance(0)
	original.hide()

func _strip(size: Vector3, finish: Material) -> MultiMesh:
	var box := BoxMesh.new()
	box.size = size
	box.material = finish
	return _batch(box)

func _batch(mesh: Mesh) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = SHOES
	var strip := MultiMeshInstance3D.new()
	strip.multimesh = batch
	add_child(strip)
	return batch

func advance(distance: float) -> void:
	phase = fposmod(phase + distance,LENGTH)
	for sample in 2 * SHOES:
		var t := fposmod(phase + LENGTH * sample / (2 * SHOES), LENGTH)
		var angle := 0.0
		var z := -STRAIGHT*.5 + t
		var y := .68 + RADIUS
		if t >= 2*STRAIGHT + PI*RADIUS:
			angle = PI + (t - 2*STRAIGHT - PI*RADIUS)/RADIUS
			z = -STRAIGHT*.5 + RADIUS*sin(angle)
			y = .68 + RADIUS*cos(angle)
		elif t >= STRAIGHT + PI*RADIUS:
			angle = PI
			z = STRAIGHT*.5 - (t - STRAIGHT - PI*RADIUS)
			y = .68 - RADIUS
		elif t >= STRAIGHT:
			angle = (t - STRAIGHT)/RADIUS
			z = STRAIGHT*.5 + RADIUS*sin(angle)
			y = .68 + RADIUS*cos(angle)
		var shoe := Transform3D(Basis(Vector3.RIGHT,angle),Vector3(0,y,z))
		var i := sample >> 1
		if sample % 2 == 1:
			pins.set_instance_transform(i, shoe.rotated_local(Vector3.BACK, PI*.5))
			continue
		edges.set_instance_transform(i, shoe.translated_local(Vector3.UP*.096))
		plates.set_instance_transform(i,shoe)
		ribs.set_instance_transform(i,shoe.translated_local(Vector3.UP*.07))
