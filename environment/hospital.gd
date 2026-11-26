extends Node3D

# The ward footprint ends at the intake's rear wall. Only the intake is open.
const ORIGIN := Vector3(128, 0, -59)
const APRON_WIDTH := 9.6
const WALL := Color("#d7cfba")
const BRICK := Color("#b5a389")
const METAL := Color("#303e44")
const TRIM := Color("#e9e2d0")
const GLASS := Color("#45616a")

func build(world: Node3D) -> void:
	name = "Harbor Town hospital"
	position = ORIGIN
	var ward_height := 10.12
	world._make_box("Sealed hospital ward", Vector3(27, ward_height, 20),
		Vector3(0, ward_height * .5, -10), WALL, true, self)
	world.building_bounds.append(AABB(ORIGIN + Vector3(-13.5, -1, -20), Vector3(27, ward_height + 1, 20)))
	world._make_box("Dark roof flashing", Vector3(27.18, .22, 20.16),
		Vector3(0, 10.035, -10), METAL, false, self)
	for band in [3.82, 6.42, 9.02]:
		world._make_box("Precast concrete course", Vector3(27.04, .15, .19),
			Vector3(0, band, .035), TRIM, false, self)
		for side in [-1.0, 1.0]:
			world._make_box("Side concrete course", Vector3(.15, .15, 20),
				Vector3(side * 13.51, band, -10), TRIM, false, self)
	var glazing: StandardMaterial3D = world._material(GLASS, .22)
	glazing.metallic = .28
	var warm_glazing: StandardMaterial3D = world._material(Color("#9b8660"), .35, true)
	warm_glazing.emission = Color("#edc582")
	warm_glazing.emission_energy_multiplier = .36
	var windows: Array[Transform3D] = []
	var clear_panes: Array[Transform3D] = []
	var lit_panes: Array[Transform3D] = []
	for floor_index in 3:
		for column in 11:
			var x := (column - 5) * 2.34
			var y := 2.62 + floor_index * 2.60
			if floor_index == 0 and (absf(x) < 4.5 or x < -7):
				continue
			var pose := Transform3D(Basis.IDENTITY, Vector3(x, y, 0))
			windows.append(pose)
			_add_panes(pose, lit_panes if (column + 2 * floor_index) % 5 == 1 else clear_panes)
		for column in 8:
			var z := -1.9 - column * 2.34
			for side in [-1.0, 1.0]:
				var pose := Transform3D(Basis(Vector3.UP, side * PI / 2),
					Vector3(side * 13.5, 2.62 + floor_index * 2.60, z))
				windows.append(pose)
				_add_panes(pose, lit_panes if (column + floor_index) % 5 == 3 else clear_panes)
	_window_batch("Brick window panels", Vector3(1.93, 2.17, .10), Vector3.BACK * .055, world._material(BRICK), windows)
	_window_batch("Window frames", Vector3(1.62, 1.55, .12), Vector3.BACK * .114, world._material(METAL), windows)
	_window_batch("Cast window sills", Vector3(1.76, .10, .26), Vector3(0, -.78, .11), world._material(TRIM), windows)
	_window_batch("Ward glazing", Vector3(.71, 1.37, .035), Vector3.ZERO, glazing, clear_panes)
	_window_batch("Lit ward glazing", Vector3(.71, 1.37, .035), Vector3.ZERO, warm_glazing, lit_panes)
	_build_facade_sign(world)
	_build_closed_entrance(world, glazing)
	_build_intake(world)
	_build_helipad(world)

func _build_facade_sign(world: Node3D) -> void:
	var at := Vector3(0, 9.57, .13)
	var fascia: MeshInstance3D = world._make_box("Hospital illuminated sign", Vector3(10.6, .86, .23),
		at, METAL, false, self)
	var cross_finish: StandardMaterial3D = world._material(Color("#e02931"), .33, true)
	cross_finish.emission = Color("#ff1b2b")
	world.traffic_running_lenses.append(cross_finish)
	var horizontal: MeshInstance3D = world._make_box("Red hospital cross horizontal", Vector3(.59, .19, .074),
		Vector3(-4.46, 0, .15), Color.WHITE, false, fascia)
	horizontal.material_override = cross_finish
	for side in [-1, 1]:
		var upright: MeshInstance3D = world._make_box("Red hospital cross vertical %d" % side,
			Vector3(.19, .20, .074), Vector3(-4.46, side * .195, .15), Color.WHITE, false, fascia)
		upright.material_override = cross_finish
	var title: Label3D = world._station_sign("Harbor Town Hospital", Vector3(.44, 0, .153),
		.009, Color("#fff5df"), 0, fascia)
	title.name = "Hospital facade name"
	world._size_world_sign(title, 8.45)

func _add_panes(pose: Transform3D, panes: Array[Transform3D]) -> void:
	for side in [-1.0, 1.0]:
		panes.append(pose.translated_local(Vector3(side * .385, .025, .176)))

func _window_batch(label: String, size: Vector3, offset: Vector3, finish: Material, poses: Array[Transform3D]) -> void:
	var geometry := BoxMesh.new()
	geometry.size = size
	geometry.material = finish
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = geometry
	batch.instance_count = poses.size()
	for index in poses.size():
		batch.set_instance_transform(index, poses[index].translated_local(offset))
	var windows := MultiMeshInstance3D.new()
	windows.name = label
	windows.multimesh = batch
	add_child(windows)

func _build_closed_entrance(world: Node3D, glass: Material) -> void:
	var facade_x := -9.30
	world._make_driving_surface("Hospital entrance walk", Vector3(6.60, .14, 6.3),
		Vector3(facade_x, -.06, 3.20), Color("#a39c8d"), false, self)
	world._make_box("Entrance surround", Vector3(6.1, 3.05, .20), Vector3(facade_x, 1.525, .15), METAL, false, self)
	for column in 4:
		var pane: MeshInstance3D = world._make_box("Locked entrance glazing", Vector3(1.31, 2.42, .06),
			Vector3(facade_x + (column - 1.5) * 1.42, 1.28, .27), GLASS, false, self)
		pane.material_override = glass
		world._make_box("Entrance midrail", Vector3(1.35, .065, .035),
			pane.position + Vector3(0, -.18, .038), METAL, false, self)
	for side in [-1.0, 1.0]:
		world._make_box("Door pull", Vector3(.08, .42, .08),
			Vector3(facade_x + side * .27, 1.21, .36), TRIM, false, self)
		world._make_roadside_solid("Entrance canopy pier", Vector3(.18, 2.99, .18),
			Vector3(facade_x + side * 2.86, 1.48, 1.75), METAL, true, self)
	world._make_box("Public entrance canopy", Vector3(6.5, .50, 2.19),
		Vector3(facade_x, 3.21, 1.01), TRIM, false, self)
	var entrance: Label3D = world._station_sign("Harbor Town Hospital", Vector3(facade_x, 3.22, 2.12), .007, METAL, 0, self)
	world._size_world_sign(entrance, 6.15)

func _build_intake(world: Node3D) -> void:
	# Meet the north edge of Östra allén at the same grade without overlapping it.
	var apron_depth := -52.8 - ORIGIN.z
	world._make_driving_surface("Ambulance bay and apron", Vector3(APRON_WIDTH, .12, apron_depth),
		Vector3(0, -.08, apron_depth * .5), Color("#777c79"), true, self)
	var diffuser_finish: StandardMaterial3D = world._material(Color("#f4e5bd"), .38, true)
	for side in [-1.0, 1.0]:
		world._make_roadside_solid("Ambulance bay side wall", Vector3(.43, 4.15, 6.90),
			Vector3(side * 4.24, 2.075, 3.45), BRICK, true, self)
		world._make_roadside_solid("Portal column", Vector3(.49, 4.13, .30),
			Vector3(side * 4.21, 2.065, 6.75), METAL, true, self)
		var guard := Vector3(side * 3.88, .52, 5.98)
		world._make_roadside_solid("Intake column guard", Vector3(.20, 1.08, .20),
			guard, Color("#dfa936"), true, self)
		world._make_box("Guard base plate", Vector3(.31, .034, .31),
			guard - Vector3.UP * .52, METAL, false, self)
		for band in [.18, .37]:
			world._make_box("Guard contrast band", Vector3(.204, .082, .204),
				guard + Vector3.UP * band, METAL, false, self)
		world._make_box("Wall bumper rail", Vector3(.14, .18, 6.45),
			Vector3(side * 3.99, .77, 3.36), METAL, false, self)
		var line_start := .56
		var line_end := apron_depth - .14
		world._make_box("Ambulance bay lane line", Vector3(.105, .008, line_end - line_start),
			Vector3(side * 2.31, -.013, (line_start + line_end) * .5), Color("#e8bc43"), false, self)
		for z in [2.05, 5.55]:
			world._make_box("Intake luminaire housing", Vector3(1.26, .08, .23),
				Vector3(side * 2.1, 4.065, z), METAL, false, self)
			var diffuser: MeshInstance3D = world._make_box("Intake luminaire diffuser", Vector3(1.16, .025, .15),
				Vector3(side * 2.1, 4.017, z), Color("#f4e5bd"), false, self)
			diffuser.material_override = diffuser_finish
	var roof: MeshInstance3D = world._make_box("Ambulance intake roof", Vector3(9.12, .49, 7.06),
		Vector3(0, 4.34, 3.51), METAL, true, self)
	var roof_finish: ShaderMaterial = world._noise_material(METAL.darkened(.15), METAL.lightened(.08), 3.0, .18)
	roof_finish.set_shader_parameter("roof_surface", true)
	roof.material_override = roof_finish
	world.ground_finishes.append(roof_finish)
	world._make_box("Intake signage fascia", Vector3(9.13, .75, .14), Vector3(0, 4.27, 7.04), METAL, false, self)
	var intake: Label3D = world._station_sign("Ambulance intake", Vector3(.27, 4.30, 7.12), .0115, Color("#fff6e5"), 0, self)
	world._size_world_sign(intake, 6.65)
	for size in [Vector3(.49, .13, .055), Vector3(.13, .49, .055)]:
		world._make_box("Intake medical cross", size, Vector3(-3.24, 4.30, 7.13), Color("#72c6b3"), false, self)
	for section in 5:
		world._make_box("Raised door section", Vector3(7.98, .08, .206),
			Vector3(0, 3.99, 5.82 + section * .218), Color("#a5acab"), false, self)
	world._make_box("Door bottom seal", Vector3(8, .042, .065),
		Vector3(0, 3.938, 6.72), METAL, false, self)
	for side in [-1.0, 1.0]:
		world._make_box("Door vertical guide", Vector3(.074, 3.68, .10),
			Vector3(side * 4.035, 1.89, 6.66), METAL, false, self)
		world._make_box("Door overhead guide", Vector3(.083, .085, 1.85),
			Vector3(side * 4.035, 3.98, 5.84), METAL, false, self)
	world._make_box("Ambulance stop marking", Vector3(4.6, .008, .12),
		Vector3(0, -.012, 1.20), Color("#e8bc43"), false, self)
	world._make_box("Closed inner transfer doors", Vector3(2.0, 2.47, .14),
		Vector3(2.61, 1.235, .13), METAL, false, self)
	world._make_box("Staff door meeting rail", Vector3(.026, 2.31, .035),
		Vector3(2.61, 1.22, .218), TRIM, false, self)
	for z in [2.05, 5.55]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 3.76, z)
		light.light_color = Color("#ffe7bf")
		light.light_energy = 1.9
		light.omni_range = 5.8
		light.distance_fade_enabled = true
		light.distance_fade_begin = 28.0
		light.distance_fade_length = 12.0
		add_child(light)

func _build_helipad(world: Node3D) -> void:
	var center: Vector3 = world.HOSPITAL_HELIPAD - ORIGIN
	var deck := CylinderMesh.new()
	deck.top_radius = 8.4
	deck.bottom_radius = 8.4
	deck.height = .3
	deck.radial_segments = 48
	var platform := MeshInstance3D.new()
	platform.name = "Hospital rooftop helipad"
	platform.mesh = deck
	platform.material_override = world._material(Color("#364547"), .88)
	platform.position = center - Vector3.UP * .15
	add_child(platform)
	var stripe := TorusMesh.new()
	stripe.inner_radius = 7.71
	stripe.outer_radius = 7.84
	stripe.rings = 64
	stripe.ring_segments = 6
	var perimeter := MeshInstance3D.new()
	perimeter.name = "Helipad perimeter marking"
	perimeter.mesh = stripe
	perimeter.material_override = world._material(Color("#d9be55"), .78)
	perimeter.position = center + Vector3.UP * .008
	perimeter.scale.y = .09
	add_child(perimeter)
	for side in [-1.0, 1.0]:
		world._make_box("Helipad H upright", Vector3(.37, .012, 3.5),
			center + Vector3(side * .95, .012, 0), Color("#f5f2d8"), false, self)
	world._make_box("Helipad H crossbar", Vector3(1.70, .012, .36),
		center + Vector3(0, .012, 0), Color("#f5f2d8"), false, self)
	var lamp: StandardMaterial3D = world._material(Color("#61dca0"), .32, true)
	lamp.emission = Color("#27e282")
	lamp.emission_energy_multiplier = 1.5
	for index in 12:
		var angle := TAU * index / 12
		var pos := center + Vector3(cos(angle) * 8.11, .045, sin(angle) * 8.11)
		var marker: MeshInstance3D = world._make_box("Helipad green perimeter light", Vector3(.14, .09, .14), pos,
			Color("#61dca0"), false, self)
		marker.material_override = lamp
