extends Node3D

const LOCATION := Vector3(-468, 0, 55)
const MAP_STOP := Vector3(-479, 0, 38)
const LANE_OFFSET := 11.0
const LANE_WIDTH := 5.5
const ORDER := Vector3(-11, 0, -1)
const PICKUP := Vector3(-1, 0, 10)
const PRICE := 8
const DARK := Color("#263739")
const WOOD := Color("#a46943")
const TEAL := Color("#13635f")
const CREAM := Color("#fff0cb")
const PAINT := Color("#f0eee4")
var city: Node3D
var order_pending := false

func build(world: Node3D) -> void:
	city = world
	name = "Dax restaurant"
	position = LOCATION
	for x in [-LANE_OFFSET, LANE_OFFSET]:
		_asphalt(Vector2(LANE_WIDTH, 28), Vector2(x, -1.25))
	_asphalt(Vector2(2 * LANE_OFFSET - LANE_WIDTH, 5.5), Vector2(0, 10))
	_asphalt(Vector2(14.5, 11), Vector2(21.0, -7.25))
	for x in [14.3, 17.1, 19.9, 22.7, 25.5]:
		_box("Parking division", Vector3(.09, .012, 4.8), Vector3(x, .019, -9.9), PAINT)
	for x in [-LANE_OFFSET, LANE_OFFSET]:
		for z in [-11.4, 4.0]:
			_arrow(Vector3(x, .024, z), PI if x < 0 else 0.0)
	_arrow(Vector3(5, .024, 10), -PI / 2)
	for stop in [ORDER, PICKUP]:
		var stripe := _box("Drive-through stop line", Vector3(3.4, .014, .22), stop + Vector3(0, .023, 0), PAINT)
		stripe.rotation.y = PI / 2 if stop == PICKUP else 0.0

	var terrace: MeshInstance3D = city._make_driving_surface("Dax terrace", Vector3(16, .13, 5.6), Vector3(0, -.018, -9.4), Color.WHITE, false, self)
	terrace.material_override = city.sidewalk_finish
	_box("Dining floor", Vector3(16, .22, 13), Vector3(0, .10, 0), CREAM)
	_box("Flat roof", Vector3(16.8, .38, 13.85), Vector3(0, 3.92, 0), DARK)
	_box("Timber fascia", Vector3(16.05, .82, 13.05), Vector3(0, 3.47, 0), WOOD)
	_box("Roof parapet", Vector3(11.2, .52, 8), Vector3(1, 4.16, 1.2), DARK)
	for x in [-2.0, 4.0]:
		_box("Roof ventilation", Vector3(1.6, .45, 1.13), Vector3(x, 4.62, 2), Color("#6b7471"))
	for wall_x in [-7.92, 7.92]:
		_box("Side wall", Vector3(.16, 3.18, 13), Vector3(wall_x, 1.68, 0), TEAL)
	for x in [-5.02, 4.03]:
		_box("Kitchen rear wall", Vector3(6.0 if x < 0 else 7.95, 3.18, .16), Vector3(x, 1.68, 6.42), TEAL)
	_box("Kitchen partition", Vector3(15.8, 3.12, .14), Vector3(0, 1.68, 2.2), Color("#d4b99b"))
	_box("Pickup counter", Vector3(2.17, .91, .67), Vector3(-1, .63, 6.35), WOOD)
	_box("Pickup sill", Vector3(2.34, .09, .70), Vector3(-1, 1.13, 6.49), CREAM)
	_box("Pickup header", Vector3(2.2, .76, .16), Vector3(-1, 2.88, 6.42), DARK)
	_box("Pickup canopy", Vector3(3.65, .19, 1.40), Vector3(-1, 2.56, 6.80), TEAL)
	_sign("2 · Pick up here", Vector3(-1, 2.83, 6.53), 2.0)
	_glass(Vector3(-.42, 1.79, 6.44), Vector3(.93, 1.25, .05))
	_box("Takeaway bag", Vector3(.30, .36, .23), Vector3(-1.46, 1.36, 6.46), Color("#dbb682"))
	for x in [-8, -6, -4, -2, 0, 2, 4, 6, 8]:
		_box("Window mullion", Vector3(.10, 3.20, .15), Vector3(x, 1.72, -6.48), DARK)
	for x in [-7, -5, -3, -1, 1, 3, 5, 7]:
		_glass(Vector3(x, 1.78, -6.48), Vector3(1.90, 2.56, .055))
		_box("Timber window base", Vector3(1.9, .37, .13), Vector3(x, .32, -6.48), WOOD)
	_box("Entrance handle", Vector3(.055, .45, .07), Vector3(1.8, 1.28, -6.56), CREAM)
	_box("Entrance canopy", Vector3(4.4, .22, 1.7), Vector3(1.0, 3.03, -6.94), TEAL)
	_box("Dax sign panel", Vector3(3.8, .77, .20), Vector3(1, 3.57, -6.63), TEAL)
	_sign("Dax", Vector3(1, 3.59, -6.75), 3.45, PI)
	_sign("Dax", Vector3(-1, 3.48, 6.58), 2.4)
	for x in [-5.4, -2.7, 5.0]:
		_table(Vector3(x, .08, -9.6), true)
	for x in [-5.4, -1.9, 3.65, 6.1]:
		_table(Vector3(x, .21, -4.5), false)
	for x in [-7.0, 7.0]:
		_box("Terrace planter", Vector3(1.14, .56, .61), Vector3(x, .28, -11.68), DARK)
		for offset in [-.32, 0.0, .32]:
			_ball("Terrace shrub", Vector3(x + offset, .70, -11.68), Vector3(.48, .43, .46), Color("#59814c"))
	_order_station()
	_obstacle(Vector3(16, 4.1, 13), Vector3(0, 2.0, 0))
	for x in [-5.4, -2.7, 5.0]:
		_obstacle(Vector3(1.6, 1.0, 1.65), Vector3(x, .5, -9.6))

func _order_station() -> void:
	_box("Menu pedestal", Vector3(.28, 1.04, 1.36), Vector3(-8.46, .54, -3), DARK)
	_box("Backlit menu", Vector3(.13, 1.26, 1.61), Vector3(-8.62, 1.55, -3), CREAM)
	_sign("Dax burger", Vector3(-8.70, 1.87, -3), 1.45, -PI / 2, DARK)
	_sign("%d" % PRICE, Vector3(-8.70, 1.12, -3), 1.0, -PI / 2, DARK)
	for layer in [[1.48, .13, WOOD], [1.54, .05, Color("#678d32")], [1.60, .10, Color("#633b26")], [1.71, .16, Color("#d88b3e")]]:
		_ball("Burger illustration", Vector3(-8.71, layer[0], -3), Vector3(.035, layer[1], .57), layer[2])
	_box("Intercom pillar", Vector3(.31, 1.36, .36), Vector3(-8.67, .69, -1), TEAL)
	for i in 4:
		_box("Speaker slot", Vector3(.024, .022, .21), Vector3(-8.83, 1.05 + .046 * i, -1), DARK)
	_box("Intercom sign panel", Vector3(.14, .40, 1.35), Vector3(-8.78, 1.64, -1), TEAL)
	_sign("1 · Order here", Vector3(-8.88, 1.66, -1), 1.23, -PI / 2)
	_box("Ordering station header", Vector3(.32, .21, 2.92), Vector3(-8.61, 2.31, -2.27), TEAL)
	_sign("Drive-through", Vector3(-8.78, 2.33, -2.27), 2.55, -PI / 2)
	_box("Entrance sign post", Vector3(.20, 2.5, .20), Vector3(-8.15, 1.25, -15.4), DARK)
	_box("Entrance sign panel", Vector3(1.96, .89, .12), Vector3(-8.15, 2.46, -15.4), TEAL)
	_sign("Dax", Vector3(-8.15, 2.65, -15.48), 1.65, PI)
	_sign("Drive-through", Vector3(-8.15, 2.23, -15.48), 1.76, PI)
	_obstacle(Vector3(.55, 2.5, 3.14), Vector3(-8.57, 1.18, -2.35))

func action_at(point: Vector3) -> String:
	var local := to_local(point)
	if Vector2(local.x - ORDER.x, local.z - ORDER.z).length() <= 1.8 and not order_pending:
		return "Order Dax burger"
	if Vector2(local.x - PICKUP.x, local.z - PICKUP.z).length() <= 1.8 and order_pending:
		return "Pick up Dax burger"
	return ""

func _table(at: Vector3, outside: bool) -> void:
	_box("Tabletop", Vector3(1.48, .11, .70), at + Vector3.UP * .78, WOOD)
	_box("Table support", Vector3(.11, .75, .11), at + Vector3.UP * .38, DARK)
	for side in [-1, 1]:
		_box("Bench seat", Vector3(1.45, .13, .30), at + Vector3(0, .43, side * .66), WOOD)
		_box("Bench base", Vector3(1.15, .40, .15), at + Vector3(0, .20, side * .66), DARK)
	if outside:
		_box("Parasol pole", Vector3(.065, 2.25, .065), at + Vector3.UP * 1.13, DARK)
		var canopy := CylinderMesh.new()
		canopy.top_radius = .08
		canopy.bottom_radius = 1.10
		canopy.height = .38
		canopy.radial_segments = 8
		_mesh("Parasol", canopy, at + Vector3.UP * 2.19, Color("#cf7150"))

func _arrow(at: Vector3, heading: float) -> void:
	var arrow := Node3D.new()
	add_child(arrow)
	arrow.position = at
	arrow.rotation.y = heading
	city._make_box("Arrow stem", Vector3(.17, .012, 1.02), Vector3.ZERO, PAINT, false, arrow)
	for side in [-1, 1]:
		var edge: MeshInstance3D = city._make_box("Arrow tip", Vector3(.13, .012, .61), Vector3(side * .19, 0, -.49), PAINT, false, arrow)
		edge.rotation.y = side * .72

func _asphalt(size: Vector2, at: Vector2) -> void:
	city._make_driving_surface("Dax drive-through asphalt", Vector3(size.x, .10, size.y), Vector3(at.x, -.043, at.y), Color.WHITE, false, self).material_override = city.road_finish

func _obstacle(size: Vector3, at: Vector3) -> void:
	city.building_bounds.append(AABB(to_global(at - size * .5) - Vector3.UP, size + Vector3.UP))

func _sign(caption: String, at: Vector3, width: float, yaw := 0.0, tint := CREAM) -> void:
	var label: Label3D = city._station_sign(caption, at, .011, tint, yaw, self)
	city._size_world_sign(label, width)

func _glass(at: Vector3, size: Vector3) -> void:
	var pane := _box("Glazing", size, at, Color.WHITE)
	var finish := StandardMaterial3D.new()
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	finish.albedo_color = Color(.33, .60, .60, .28)
	finish.roughness = .25
	pane.material_override = finish

func _ball(label: String, at: Vector3, size: Vector3, tint: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 12
	sphere.rings = 6
	_mesh(label, sphere, at, tint).scale = size

func _mesh(label: String, mesh: Mesh, at: Vector3, tint: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = city._material(tint)
	part.position = at
	add_child(part)
	return part

func _box(label: String, size: Vector3, at: Vector3, tint: Color) -> MeshInstance3D:
	return city._make_box(label, size, at, tint, false, self)
