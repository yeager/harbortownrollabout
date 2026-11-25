extends Node3D

const BAY_LENGTH := 6.4
const BAY_WIDTH := 2.65
const STRIPE := .10
const ROAD_EDGE := 3.7
const ASPHALT_TOP := -.038
var bay_finish: ShaderMaterial

func build(world: Node3D) -> void:
	name = "Street parking"
	bay_finish = world.road_finish.duplicate() as ShaderMaterial
	bay_finish.set_shader_parameter("snow_retention", .60)
	world.ground_finishes.append(bay_finish)
	_build_row(world, "Stationsallén", 21.5, 35.0, -1.0, 2)
	_build_row(world, "Norra kajgatan", 120.0, -82.0, -1.0, 2)
	_build_row(world, "Södra kajgatan", 121.0, 60.0, 1.0, 3)

func _build_row(world: Node3D, street: String, start_x: float, street_z: float, side: float, count: int) -> void:
	var row := Node3D.new()
	row.name = street
	add_child(row)
	var length := count * BAY_LENGTH
	var lane_edge := street_z + side * ROAD_EDGE
	var bays_z := lane_edge + side * BAY_WIDTH * .5
	var midpoint := start_x + length * .5
	var asphalt: MeshInstance3D = world._make_driving_surface("Parallel parking asphalt",
		Vector3(length + 1.6, .10, BAY_WIDTH + .12), Vector3(midpoint, ASPHALT_TOP - .05, bays_z), Color.WHITE, true, row)
	asphalt.material_override = bay_finish

	var kerb_z := lane_edge + side * (BAY_WIDTH + .11)
	world._make_roadside_solid("Parking kerb", Vector3(length + 1.6, .19, .18),
		Vector3(midpoint, -.005, kerb_z), Color("#aaa79e"), true, row)
	var path: MeshInstance3D = world._make_driving_surface("Parking pavement",
		Vector3(length + 1.6, .16, 1.65), Vector3(midpoint, .01, kerb_z + side * .86), Color.WHITE, true, row)
	path.material_override = world.sidewalk_finish

	for edge in [-1.0, 1.0]:
		_stripe(world, row, Vector3(length + STRIPE, .012, STRIPE),
			Vector3(midpoint, ASPHALT_TOP + .012, bays_z + edge * (BAY_WIDTH - STRIPE) * .5))
	for edge in range(count + 1):
		_stripe(world, row, Vector3(STRIPE, .012, BAY_WIDTH),
			Vector3(start_x + edge * BAY_LENGTH, ASPHALT_TOP + .012, bays_z))
	for bay in count:
		var mark := Marker3D.new()
		mark.name = "Parking bay %d" % (bay + 1)
		mark.position = Vector3(start_x + (bay + .5) * BAY_LENGTH, ASPHALT_TOP, bays_z)
		row.add_child(mark)
		mark.add_to_group("street_parking_bays")

	var pole_at := Vector3(start_x - .35 if side > 0 else start_x + length + .35, .09, kerb_z + side * .25)
	_add_parking_sign(world, row, pole_at)

func _stripe(world: Node3D, row: Node3D, size: Vector3, at: Vector3) -> void:
	var paint: MeshInstance3D = world._make_box("White parking line", size, at, Color.WHITE, false, row)
	paint.material_override = world.marking_finish
	paint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_parking_sign(world: Node3D, row: Node3D, at: Vector3) -> void:
	var stem: MeshInstance3D = world._make_roadside_solid("Parking sign pole", Vector3(.065, 1.92, .065),
		at + Vector3.UP * .96, Color("#788286"), true, row)
	var plate := Node3D.new()
	plate.name = "Parking sign"
	plate.position = Vector3.UP * 1.21
	plate.rotation.y = PI * .5
	stem.add_child(plate)
	world._make_box("White sign rim", Vector3(.54, .54, .032), Vector3.ZERO, Color("#f5f5ed"), false, plate)
	for face in [-1.0, 1.0]:
		world._make_box("Blue parking sign face", Vector3(.498, .498, .012),
			Vector3.BACK * face * .022, Color("#175499"), false, plate)
		var label: Label3D = world._station_sign("P", Vector3.BACK * face * .031, .0075, Color.WHITE,
			0.0 if face > 0 else PI, plate)
		label.double_sided = false
