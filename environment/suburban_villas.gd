extends Node3D

const LOTS := [-405.0, -386.0, -367.0, -348.0]
const FRONT_Z := -67.4
const CURB_Z := -56.3
const DRIVEWAY_OFFSET := 5.35
const MAP_STOP := Vector3(LOTS[1] + DRIVEWAY_OFFSET, .09, -62.0)
const SIDING := [Color("#a44738"), Color("#d9b26c"), Color("#647e78"), Color("#d7d7c4")]
const ROOFING := [Color("#4a4140"), Color("#9c5746"), Color("#484e55"), Color("#815448")]
const TRIM := Color("#eee6d6")
const TIMBER := Color("#957b60")
const BULBS := [Color("#ffde9e"), Color("#ffbc58"), Color("#ed4836"), Color("#57b993")]
const HOUSE_LIGHTS := [[0], [1, 0, 1], [3, 0], [0, 2, 1, 3]]
const PARKED_CARS := [preload("res://vehicles/volvo240.glb"), preload("res://vehicles/saab96.glb")]

var world: Node3D
var winter_trim := Node3D.new()
var flower_heads := Node3D.new()
var window_glass := StandardMaterial3D.new()
var bulb_finishes: Array[StandardMaterial3D] = []
var roof_finishes: Array[ShaderMaterial] = []
var bulb_positions: Array[PackedVector3Array] = [[], [], [], []]
var entry_lights: Array[OmniLight3D] = []
var plant_mesh := SphereMesh.new()

func build(city: Node3D) -> void:
	name = "SuburbanVillas"
	world = city
	winter_trim.name = "Winter decorations"
	flower_heads.name = "Flower heads"
	add_child(winter_trim)
	add_child(flower_heads)
	plant_mesh.radial_segments = 10
	plant_mesh.rings = 6
	window_glass.albedo_color = Color("#647c87")
	window_glass.roughness = .26
	window_glass.emission_enabled = true
	window_glass.emission = Color("#ffbf79")
	for index in LOTS.size():
		_build_lot(index)
	_build_residents()
	_batch_lights()
	update_lights(false, 0.0)

func _build_residents() -> void:
	for index in 2:
		var pavement := Vector3(LOTS[1 + index * 2] - 1.7, 0, -58.4)
		var coat: Color = [Color("#886761"), Color("#527787")][index]
		world._make_walker("Villa resident", pavement.x, pavement.z, 1 if index == 0 else -1, coat, Color("#3f424c"))
		var resident: Dictionary = world.walker_data.back()
		var actor: Node3D = resident.actor
		actor.add_to_group("villa_residents")
		actor.position.y = world._foot_height(pavement.x, pavement.z)
		resident.stretch = Vector2(pavement.x - 6.0, pavement.x + 6.0)
		resident.speed = 1.05 + .12 * index

func update_lights(winter: bool, night: float, snow_cover := 0.0) -> void:
	winter_trim.visible = winter
	flower_heads.visible = not winter
	for finish in roof_finishes:
		finish.set_shader_parameter("snow_cover", snow_cover)
	var dusk := smoothstep(.05, .82, night)
	window_glass.emission_energy_multiplier = dusk * .92
	for finish in bulb_finishes:
		finish.emission_energy_multiplier = .28 + 1.65 * dusk
	for lamp in entry_lights:
		lamp.visible = dusk > .015
		lamp.light_energy = .80 * dusk

func _build_lot(index: int) -> void:
	var lot := Node3D.new()
	var number := str(12 + index * 2)
	lot.name = "Villa " + number
	var setback: float = [0.0, -.8, .55, -1.15][index]
	lot.position = Vector3(LOTS[index], -.19, FRONT_Z + setback)
	add_child(lot)
	var width: float = [9.0, 8.5, 10.0, 8.8][index]
	var depth := 8.0 + .4 * (index % 3)
	var two_storeys := index % 2 == 1
	var wall_height := 5.55 if two_storeys else 3.17
	var pitch: float = [.49, .34, .19, .61][index]
	var siding: Color = SIDING[index]
	var roof: Color = ROOFING[index]
	var wall_center := Vector3(-1.65, wall_height * .5 + .25, -depth * .5)
	_box(lot, "Stone foundation", Vector3(width + .10, .33, depth + .10), wall_center * Vector3(1, 0, 1) + Vector3.UP * .165, Color("#90908b"))
	_box(lot, "Painted timber walls", Vector3(width, wall_height, depth), wall_center, siding)
	var house_bounds := AABB(lot.to_global(Vector3(-1.65 - width * .5, 0, -depth)), Vector3(width, wall_height + 2.2, depth))
	world.building_bounds.append(house_bounds)
	var eave := wall_height + .25
	var roof_finish := _roof(lot, index, width, depth, eave, pitch, siding, roof)
	for side in [-1, 1]:
		_box(lot, "Painted corner board", Vector3(.14, wall_height, .12), Vector3(-1.65 + side * (width * .5 - .05), wall_height * .5 + .25, .058), TRIM)
	if index != 2:
		var top := eave + tan(pitch) * width * .5
		_box(lot, "Brick chimney", Vector3(.71, 1.45, .62), Vector3(-.24, top - .15, -depth + 2.0), Color("#8c5141"))
		_box(lot, "Chimney cap", Vector3(.85, .13, .76), Vector3(-.24, top + .61, -depth + 2.0), Color("#615652"))
	# Battens on the side elevations follow the timber colour without crossing front openings.
	for side in [-1, 1]:
		for board in range(1, floori(depth / .36)):
			_box(lot, "Siding batten", Vector3(.034, wall_height - .06, .045), Vector3(-1.65 + side * width * .50, wall_height * .50 + .25, -.36 * board), siding.lightened(.10))
		_box(lot, "Side window frame", Vector3(.12, 1.16, 1.38), Vector3(-1.65 + side * (width * .5 + .023), 2.07, -depth * .73), TRIM)
		_box(lot, "Side glazing", Vector3(.13, .94, 1.15), Vector3(-1.65 + side * (width * .5 + .034), 2.07, -depth * .73), Color.WHITE).material_override = window_glass
	var front_windows := [
		[Vector4(-4.45, 1.94, 1.68, 1.52), Vector4(1.1, 1.94, 1.68, 1.52)],
		[Vector4(-4.30, 1.90, 1.36, 1.65), Vector4(.83, 1.90, 1.36, 1.65)],
		[Vector4(-4.56, 1.77, 2.64, 1.52), Vector4(.87, 2.04, 2.21, .99)],
		[Vector4(-4.35, 1.86, 2.08, 1.42), Vector4(.53, 2.07, .77, 1.36), Vector4(1.62, 2.07, .77, 1.36)]
	]
	for window: Vector4 in front_windows[index]:
		_window(lot, Vector3(window.x, window.y, .06), Vector2(window.z, window.w))
		if index == 0:
			for side in [-1, 1]:
				_box(lot, "Painted shutter", Vector3(.28, 1.30, .08), Vector3(window.x + side * .98, window.y, .091), Color("#77909a"))
	if two_storeys:
		_box(lot, "Storey band", Vector3(width, .085, .116), Vector3(-1.65, 3.13, .055), siding.darkened(.12))
		for window_x in ([-4.14, -1.65, 1.0] if index == 1 else [-4.18, .96]):
			var size := Vector2(1.32, 1.24) if index == 1 else Vector2(1.91, 1.38)
			_window(lot, Vector3(window_x, 4.34, .06), size)
	elif index == 0:
		_window(lot, Vector3(-1.65, eave + .55, .066), Vector2(.74, .67))
	var door_x := -1.65
	_box(lot, "Front door frame", Vector3(1.31, 2.26, .16), Vector3(door_x, 1.39, .06), TRIM)
	_box(lot, "Front door", Vector3(1.09, 2.10, .09), Vector3(door_x, 1.34, .17), roof.darkened(.22))
	_box(lot, "Door fanlight", Vector3(.70, .40, .035), Vector3(door_x, 2.03, .229), Color.WHITE).material_override = window_glass
	_box(lot, "Door handle", Vector3(.14, .05, .062), Vector3(door_x + .39, 1.35, .25), Color("#b39665"))
	var plate := _box(lot, "House number plate", Vector3(.31, .22, .047), Vector3(door_x - .88, 1.91, .067), Color("#303e4b"))
	var address: Label3D = world._station_sign(number, Vector3(0, 0, .026), .0030, Color("#fff4df"), 0, plate)
	address.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var canopy := _box(lot, "Entrance canopy", Vector3(2.56, .18, 1.82), Vector3(door_x, 2.74, .77), roof)
	canopy.rotation.x = .095
	canopy.material_override = roof_finish
	for x in [door_x - 1.06, door_x + 1.06]:
		_box(lot, "Porch post", Vector3(.13, 2.47, .13), Vector3(x, 1.42, 1.44), TRIM)
	for step in 3:
		_box(lot, "Entrance step", Vector3(2.18, .12, 1.66 - .26 * step), Vector3(door_x, .06 + .11 * step, .92 - .14 * step), Color("#a49d8f"))
	var sconce := _box(lot, "Porch lamp", Vector3(.15, .27, .16), Vector3(door_x + .83, 2.12, .19), Color("#ffdc95"))
	sconce.material_override = window_glass
	var light := OmniLight3D.new()
	light.position = Vector3(door_x + .77, 2.04, .42)
	light.light_color = Color("#ffd8a2")
	light.omni_range = 4.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 30.0
	light.distance_fade_length = 8.0
	lot.add_child(light)
	entry_lights.append(light)
	_grounds(lot, index)

func _roof(lot: Node3D, index: int, width: float, depth: float, eave: float, pitch: float, siding: Color, roof: Color) -> ShaderMaterial:
	var finish := ShaderMaterial.new()
	finish.shader = preload("res://environment/villa_roof.gdshader")
	finish.set_shader_parameter("roof_color", roof)
	roof_finishes.append(finish)
	var left := -1.65 - width * .5
	var right := -1.65 + width * .5
	var peak := tan(pitch) * width * .5
	if index == 1:
		# Hipped roof with a ridge running from the street toward the garden.
		var a := Vector3(left - .40, eave, .45)
		var b := Vector3(right + .40, eave, .45)
		var c := Vector3(right + .40, eave, -depth - .45)
		var d := Vector3(left - .40, eave, -depth - .45)
		var front_peak := Vector3(-1.65, eave + peak, -depth * .25)
		var rear_peak := Vector3(-1.65, eave + peak, -depth * .75)
		_triangles(lot, "Hipped tile roof", [a,front_peak,b, b,rear_peak,c, b,front_peak,rear_peak, c,rear_peak,d, d,front_peak,a, d,rear_peak,front_peak], roof).material_override = finish
		_box(lot, "Front gutter", Vector3(width + .83, .13, .15), Vector3(-1.65, eave - .06, .45), TRIM)
	elif index == 2:
		var step := tan(pitch) * width
		var panel := _box(lot, "Single-slope metal roof", Vector3((width + .86) / cos(pitch), .22, depth + 1.0), Vector3(-1.65, eave + step * .5 + .07, -depth * .5), roof)
		panel.material_override = finish
		panel.rotation.z = -pitch
		_box(lot, "Tall side wall", Vector3(.13, step, depth), Vector3(left, eave + step * .5, -depth * .5), siding)
		for z in [0.0, -depth]:
			_triangles(lot, "Sloping wall head", [Vector3(left,eave,z), Vector3(right,eave,z), Vector3(left,eave + step,z)], siding)
		for rib in range(1, 12):
			var x := lerpf(left - .28, right + .28, rib / 12.0)
			_box(lot, "Standing seam", Vector3(.033, .027, depth + .88), Vector3(x, eave + (right - x) * tan(pitch) + .19, -depth * .5), roof.lightened(.19))
	else:
		for z in [0.0, -depth]:
			_triangles(lot, "Timber gable", [Vector3(left,eave,z), Vector3(right,eave,z), Vector3(-1.65,eave+peak,z)], siding)
		for side in [-1, 1]:
			var run := width * .50 + .40
			var roof_at := Vector3(-1.65 + side * run * .50, eave + peak - tan(pitch) * run * .50, -depth * .50)
			var panel := _box(lot, "Roof tiles", Vector3(run / cos(pitch), .17, depth + .90), roof_at, roof)
			panel.material_override = finish
			panel.rotation.z = -side * pitch
			var fascia := _box(lot, "Painted verge", Vector3(run / cos(pitch), .15, .11), roof_at + Vector3.BACK * (depth * .50 + .42), TRIM)
			fascia.rotation.z = panel.rotation.z
			_box(lot, "Eave gutter", Vector3(.14, .13, depth + .8), Vector3(-1.65 + side * run, eave - .18, -depth * .5), Color("#575754"))
	for i in 29:
		var x := lerpf(left - .34, right + .34, i / 28.0)
		var y := eave + tan(pitch) * (width * .5 - absf(x + 1.65))
		if index == 1:
			y = eave
		elif index == 2:
			y = eave + tan(pitch) * (right - x)
		_bulb(lot.to_global(Vector3(x, y - .10, .53)), _house_light(index, i))
	return finish

func _triangles(lot: Node3D, label: String, vertices: Array[Vector3], color: Color) -> MeshInstance3D:
	var faces := SurfaceTool.new()
	faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		faces.add_vertex(vertex)
	faces.generate_normals()
	var panel := MeshInstance3D.new()
	panel.name = label
	panel.mesh = faces.commit()
	var material: StandardMaterial3D = world._material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = material
	lot.add_child(panel)
	return panel

func _window(lot: Node3D, at: Vector3, size: Vector2) -> void:
	_box(lot, "Window frame", Vector3(size.x, size.y, .12), at, TRIM)
	_box(lot, "Glazing", Vector3(size.x - .19, size.y - .18, .026), at + Vector3.BACK * .065, Color.WHITE).material_override = window_glass
	_box(lot, "Window mullion", Vector3(.062, size.y, .046), at + Vector3.BACK * .085, TRIM)
	_box(lot, "Window transom", Vector3(size.x, .062, .046), at + Vector3.BACK * .085 + Vector3.UP * .20, TRIM)
	_box(lot, "Stone sill", Vector3(size.x + .19, .088, .22), at + Vector3(0, -size.y * .50, .07), Color("#b2aaa0"))

func _grounds(lot: Node3D, index: int) -> void:
	var drive_x := DRIVEWAY_OFFSET
	var front := CURB_Z - lot.position.z
	var back := -5.6
	var slab := Vector3(3.65, .09, front - back)
	var driveway: MeshInstance3D = world._make_driving_surface("Villa driveway", slab, Vector3(drive_x, .232, (front + back) * .5), Color.WHITE, false, lot)
	driveway.material_override = world.sidewalk_finish
	driveway.add_to_group("villa_driveways")
	for x in [drive_x - 1.88, drive_x + 1.88]:
		_box(lot, "Granite driveway edging", Vector3(.13, .09, slab.z - .7), Vector3(x, .24, (front + back) * .5 - .35), Color("#a0998c"))
	var path: MeshInstance3D = world._make_driving_surface("Garden path", Vector3(1.28, .07, front - 1.42), Vector3(-1.65, .225, (front + 1.42) * .5), Color.WHITE, false, lot)
	path.material_override = world.sidewalk_finish
	var fence_paint: Color = [TRIM, Color("#b48d58"), Color("#66786a"), Color("#c4b5a6")][index]
	var picket_width: float = [.093, .115, .078, .135][index]
	var picket_height: float = [.73, .80, .87, .75][index]
	# Gaps in front of the driveway and path leave both open to the street.
	for span in [Vector2(-8.1, -2.60), Vector2(-.70, 3.30), Vector2(7.32, 8.45)]:
		var count := ceili((span.y - span.x) / .30)
		for i in count:
			var x := lerpf(span.x, span.y, float(i) / count)
			_box(lot, "Garden picket", Vector3(picket_width, picket_height + .035 * (i % 3), .06), Vector3(x, .53, 8.42), fence_paint)
		for y in [.36, .71]:
			_box(lot, "Garden fence rail", Vector3(span.y - span.x, .067, .076), Vector3(span.x + (span.y - span.x) * .5, y, 8.39), fence_paint)
		for i in ceili((span.y - span.x) / .37):
			var x: float = span.x + .16 + .37 * i
			_bulb(lot.to_global(Vector3(x, .70 - .06 * sin(i * .63), 8.48)), _house_light(index, i))
		world.roadside_solids.append(AABB(lot.to_global(Vector3(span.x, -.45, 8.34)), Vector3(span.y - span.x, 1.55, .16)))
	var bed_widths := [Vector2(2.60, 1.87), Vector2(2.17, 2.80), Vector2(2.98, 2.44), Vector2(2.28, 1.66)][index] as Vector2
	var flowers: Array = [
		[Color("#e4a0b9"), Color("#fff1da")],
		[Color("#ffd574"), Color("#e59a4b")],
		[Color("#9c8ad2"), Color("#d6b7e9")],
		[Color("#e89978"), Color("#f8edce")]
	][index]
	for side in 2:
		var bed_x := -4.6 if side == 0 else 1.0
		var width := bed_widths[side]
		var depth := .80 + .12 * ((index + side) % 3)
		var bed_z := .55 + depth * .5
		_box(lot, "Flower bed mulch", Vector3(width, .16, depth), Vector3(bed_x, .09, bed_z), Color("#503b2c"))
		_box(lot, "Bed edging", Vector3(width + .06, .13, .10), Vector3(bed_x, .115, bed_z + depth * .5), TIMBER)
		var count := roundi(width / .31)
		for plant_index in count:
			var x := bed_x + ((plant_index + .5) / count - .5) * width
			var z := bed_z + .16 * sin(plant_index * 2.46)
			_plant(lot, Vector3(x, .34, z), Vector3(.32, .40, .32), Color("#4d7047"))
			var petal: Color = flowers[(plant_index / 2) % 2]
			_plant(flower_heads, lot.to_global(Vector3(x, .58, z)), Vector3(.20, .13, .21), petal)
	for i in 5:
		_plant(lot, Vector3(-6.6 + i * .54, .40, 7.72), Vector3(1.0, .80 + .15 * sin(i), .83), Color("#50704b"))
	world._make_tree(lot.to_global(Vector3(-6.95, 0, (4.65 if index % 2 == 0 else -7.7))), .68 + .055 * index)
	var spruce_site: Vector3 = [Vector3(1.87, .04, 5.40), Vector3(-5.75, .04, 5.90),
		Vector3(1.85, .04, 7.15), Vector3(2.15, .04, 4.35)][index]
	_yard_spruce(lot.to_global(spruce_site), index)
	if index == 1:
		_garden_bench(lot, Vector3(1.68, .03, 3.1))
	elif index == 3:
		_box(lot, "Raised herb bed", Vector3(2.1, .36, .85), Vector3(-4.8, .18, 4.6), TIMBER)
		for i in 7:
			_plant(lot, Vector3(-5.65 + .27 * i, .44, 4.6), Vector3(.29, .25, .38), Color("#6d7850"))
	if index % 2 == 0:
		_park_car(lot, PARKED_CARS[index / 2], Vector3(drive_x, .278, -1.85))
	# A wreath with a red bow hangs above each porch.
	var wreath_at := lot.to_global(Vector3(-1.65, 2.70, 1.64))
	for i in 18:
		var angle := i * TAU / 18.0
		var point := wreath_at + Vector3(cos(angle), sin(angle), 0) * .32
		_plant(winter_trim, point, Vector3(.19, .19, .113), Color("#315738"))
		if i % 3 == 0:
			_bulb(point + Vector3.BACK * .072, 0)
	_box(winter_trim, "Wreath ribbon", Vector3(.35, .13, .085), wreath_at + Vector3(0, -.33, .09), Color("#b64739")).rotation.z = .13

func _garden_bench(lot: Node3D, at: Vector3) -> void:
	for end in [-1, 1]:
		_box(lot, "Garden bench leg", Vector3(.10, .43, .39), at + Vector3(end * .65, .225, 0), Color("#4f5d58"))
	_box(lot, "Garden bench seat", Vector3(1.6, .08, .44), at + Vector3.UP * .45, TIMBER)
	_box(lot, "Garden bench back", Vector3(1.6, .28, .07), at + Vector3(0, .73, -.23), TIMBER)

func _yard_spruce(at: Vector3, index: int) -> void:
	var tree := Node3D.new()
	tree.name = "Garden spruce"
	tree.position = at
	add_child(tree)
	_box(tree, "Trunk", Vector3(.18, 1.0, .18), Vector3.UP * .47, Color("#74513a"))
	var height := 2.45 + .18 * index
	for i in 4:
		var tier := CylinderMesh.new()
		tier.top_radius = 0
		tier.bottom_radius = 1.03 - i * .19
		tier.height = height * .53
		tier.radial_segments = 16
		var bough := MeshInstance3D.new()
		bough.mesh = tier
		bough.position.y = .90 + i * height * .178
		bough.material_override = world._material(Color("#315745").lightened(i * .024))
		tree.add_child(bough)
		for bulb in 8:
			var angle := bulb * TAU / 8.0 + i * .36
			var radius := tier.bottom_radius * .96
			_bulb(at + Vector3(radius * cos(angle), bough.position.y - tier.height * .43, radius * sin(angle)), _house_light(index, i + bulb))

func _park_car(lot: Node3D, scene: PackedScene, at: Vector3) -> void:
	var car := scene.instantiate() as Node3D
	car.name = "Driveway resident car"
	car.position = at
	car.rotation.y = PI if lot.get_index() % 2 == 0 else 0.0
	lot.add_child(car)
	car.add_to_group("villa_resident_cars")
	var model_bounds: AABB = world._model_bounds(car, car)
	car.position.y -= model_bounds.position.y
	var bounds := car.global_transform * model_bounds
	world.roadside_solids.append(bounds.expand(Vector3(bounds.get_center().x, -.55, bounds.get_center().z)))

func _plant(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var plant := MeshInstance3D.new()
	plant.mesh = plant_mesh
	plant.position = at
	plant.scale = size
	plant.material_override = world._material(color, .92)
	parent.add_child(plant)

func _house_light(lot_index: int, bulb_index: int) -> int:
	var palette: Array = HOUSE_LIGHTS[lot_index]
	return palette[bulb_index % palette.size()]

func _bulb(at: Vector3, color: int) -> void:
	bulb_positions[color].append(at)

func _batch_lights() -> void:
	for index in BULBS.size():
		var finish: StandardMaterial3D = world._material(BULBS[index], .43, true)
		bulb_finishes.append(finish)
		var mesh := SphereMesh.new()
		mesh.radius = .050
		mesh.height = .100
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = finish
		var bulbs := MultiMeshInstance3D.new()
		bulbs.name = "Winter bulbs %d" % index
		bulbs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bulbs.multimesh = MultiMesh.new()
		bulbs.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		bulbs.multimesh.mesh = mesh
		bulbs.multimesh.instance_count = bulb_positions[index].size()
		for i in bulb_positions[index].size():
			bulbs.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, bulb_positions[index][i]))
		winter_trim.add_child(bulbs)

func _box(parent: Node3D, title: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	return world._make_box(title, size, at, color, false, parent)
