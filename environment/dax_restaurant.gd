extends Node3D

const LOCATION := Vector3(-468, 0, 55)
const MAP_STOP := Vector3(-479, 0, 38)
const LANE_OFFSET := 11.0
const LANE_WIDTH := 5.5
const ORDER := Vector3(-11, 0, -.40)
const PICKUP := Vector3(-1, 0, 10)
const PRICE := 8
const DARK := Color("#263739")
const WOOD := Color("#a46943")
const TEAL := Color("#13635f")
const CREAM := Color("#fff0cb")
const PAINT := Color("#f0eee4")
const SIGN_LIGHT := Color("#ffad64")
var city: Node3D
var order_pending := false:
	set(value):
		order_pending = value
		if pickup_bag:
			pickup_bag.visible = value
var pickup_bag: Node3D
var pickup_light: OmniLight3D
var sign_glow: StandardMaterial3D
var ad_glow: StandardMaterial3D

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
	_box("Dining floor", Vector3(15.94, .22, 12.92), Vector3(0, .10, 0), CREAM)
	_box("Flat roof", Vector3(16.8, .38, 13.85), Vector3(0, 3.92, 0), DARK)
	_box("Timber fascia", Vector3(16.05, .82, 13.05), Vector3(0, 3.47, 0), WOOD)
	_box("Roof parapet", Vector3(11.2, .52, 8), Vector3(1, 4.16, 1.2), DARK)
	sign_glow = city._material(SIGN_LIGHT, .5, true)
	ad_glow = city._material(Color("#963f2b"), .55, true)
	_fit_timber_fascia()
	_roof_signs()
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
	_fit_pickup_window()
	for x in [-8, -6, -4, -2, 0, 2, 4, 6, 8]:
		_box("Window mullion", Vector3(.10, 3.20, .15), Vector3(x, 1.72, -6.48), DARK)
	for x in [-7, -5, -3, -1, 3, 5, 7]:
		_glass(Vector3(x, 1.78, -6.48), Vector3(1.90, 2.56, .055))
		_box("Timber window base", Vector3(1.9, .37, .13), Vector3(x, .32, -6.48), WOOD)
	_fit_entrance()
	_box("Entrance canopy", Vector3(4.4, .22, 1.7), Vector3(1.0, 3.03, -6.94), TEAL)
	_box("Dax sign panel", Vector3(3.8, .77, .20), Vector3(1, 3.49, -6.63), TEAL)
	_sign("Dax", Vector3(1, 3.50, -6.75), 3.45, PI)
	_sign("Dax", Vector3(-1, 3.48, 6.58), 2.4)
	for x in [-5.4, -2.7, 5.0]:
		_table(Vector3(x, .08, -9.6), true)
	for x in [-5.4, -1.9, 3.65, 6.1]:
		_table(Vector3(x, .21, -4.5), false)
	for x in [-7.0, 7.0]:
		_box("Terrace planter", Vector3(1.14, .56, .61), Vector3(x, .28, -11.68), DARK)
		for offset in [-.32, 0.0, .32]:
			_ball("Terrace shrub", Vector3(x + offset, .70, -11.68), Vector3(.48, .43, .46), Color("#59814c"))
	_burger_ad()
	_order_station()
	_obstacle(Vector3(16, 4.1, 13), Vector3(0, 2.0, 0))
	for x in [-5.4, -2.7, 5.0]:
		_obstacle(Vector3(1.6, 1.0, 1.65), Vector3(x, .5, -9.6))

func _fit_timber_fascia() -> void:
	var slat := BoxMesh.new()
	slat.size = Vector3(.16, .61, .045)
	slat.material = city._material(Color("#bc8258"), .88)
	slat.material.vertex_color_use_as_albedo = true
	var panels := MultiMesh.new()
	panels.mesh = slat
	panels.transform_format = MultiMesh.TRANSFORM_3D
	panels.use_colors = true
	panels.instance_count = 288
	var index := 0
	for side in [-1, 1]:
		for board in 80:
			panels.set_instance_transform(index, Transform3D(Basis.IDENTITY,
				Vector3(-7.90 + .20 * board, 3.41, side * 6.531)))
			panels.set_instance_color(index, Color.WHITE.lerp(Color("#d2b7a0"), (board * 7 % 11) / 16.0))
			index += 1
		for board in 64:
			panels.set_instance_transform(index, Transform3D(Basis(Vector3.UP, PI / 2),
				Vector3(side * 8.031, 3.41, -6.30 + .20 * board)))
			panels.set_instance_color(index, Color.WHITE.lerp(Color("#d2b7a0"), (board * 7 % 11) / 16.0))
			index += 1
	var cladding := MultiMeshInstance3D.new()
	cladding.name = "Vertical timber fascia boards"
	cladding.multimesh = panels
	add_child(cladding)

func _fit_entrance() -> void:
	_glass(Vector3(1.0, 2.77, -6.48), Vector3(1.89, .44, .055))
	_box("Entrance transom", Vector3(1.9, .11, .14), Vector3(1, 2.49, -6.49), DARK)
	_box("Entrance threshold", Vector3(1.91, .08, .32), Vector3(1, .20, -6.56), Color("#747b7a"))
	for side in [-1, 1]:
		var leaf_x: float = 1.0 + side * .47
		_box("Door frame rail", Vector3(.91, .16, .12), Vector3(leaf_x, .33, -6.51), DARK)
		_box("Door frame rail", Vector3(.91, .09, .12), Vector3(leaf_x, 2.40, -6.51), DARK)
		for edge in [-1, 1]:
			_box("Door frame stile", Vector3(.052, 2.10, .12), Vector3(leaf_x + edge * .428, 1.38, -6.51), DARK)
		_glass(Vector3(leaf_x, 1.40, -6.50), Vector3(.82, 1.98, .045))
		var handle_x: float = 1.0 + side * .12
		var steel := Color("#b9c0ba")
		for y in [1.03, 1.45]:
			_box("Door pull mount", Vector3(.042, .046, .10), Vector3(handle_x, y, -6.61), steel)
		_box("Door pull", Vector3(.047, .46, .055), Vector3(handle_x, 1.24, -6.68), steel)
	_box("Entrance mat", Vector3(1.56, .02, .86), Vector3(1, .062, -7.12), DARK)

func _fit_pickup_window() -> void:
	var metal := Color("#6b7978")
	for x in [-2.05, .055]:
		_box("Pickup jamb", Vector3(.09, 1.38, .123), Vector3(x, 1.86, 6.46), DARK)
	for y in [1.20, 2.49]:
		_box("Sliding window track", Vector3(2.15, .05, .16), Vector3(-1, y, 6.46), metal)
	_glass(Vector3(-.48, 1.84, 6.49), Vector3(.96, 1.24, .052))
	_box("Sliding sash stile", Vector3(.063, 1.28, .081), Vector3(-.99, 1.84, 6.50), metal)
	_box("Sliding sash pull", Vector3(.075, .21, .07), Vector3(-.87, 1.80, 6.55), DARK)
	_box("Kitchen worktop", Vector3(2.81, .10, .78), Vector3(-1, 1.08, 5.85), metal)
	var fixture := _box("Pickup canopy lamp", Vector3(.98, .042, .13), Vector3(-1, 2.445, 6.91), CREAM)
	fixture.material_override = sign_glow
	pickup_light = OmniLight3D.new()
	pickup_light.position = Vector3(-1, 2.30, 6.92)
	pickup_light.omni_range = 3.6
	pickup_light.light_color = Color("#ffe2ba")
	pickup_light.distance_fade_enabled = true
	pickup_light.distance_fade_begin = 25.0
	add_child(pickup_light)
	pickup_bag = _box("Takeaway bag", Vector3(.30, .36, .23), Vector3(-1.46, 1.36, 6.55), Color("#dbb682"))
	pickup_bag.visible = order_pending
	var handle := TorusMesh.new()
	handle.inner_radius = .058
	handle.outer_radius = .077
	handle.rings = 12
	handle.ring_segments = 8
	var grip := _mesh("Paper bag handle", handle, Vector3.ZERO, Color("#b98b59"))
	grip.reparent(pickup_bag, false)
	grip.position.y = .188
	grip.rotation.x = PI * .5

func update_lights(night: float) -> void:
	sign_glow.emission_energy_multiplier = lerpf(.22, 2.1, night)
	ad_glow.emission_energy_multiplier = lerpf(.12, .72, night)
	pickup_light.light_energy = 1.25 * night
	pickup_light.visible = night > .01

func _roof_signs() -> void:
	for side in [-1.0, 1.0]:
		var z: float = side * 3.8
		for x in [-1.95, 1.95]:
			_box("Roof sign support", Vector3(.16, .75, .22), Vector3(x, 4.42, z), DARK)
		_box("Roof lightbox housing", Vector3(5.40, 1.34, .32), Vector3(0, 5.25, z), DARK)
		var frame := _box("Illuminated roof sign trim", Vector3(5.26, 1.22, .055), Vector3(0, 5.25, z + side * .174), SIGN_LIGHT)
		frame.material_override = sign_glow
		_box("Roof sign face", Vector3(5.12, 1.08, .068), Vector3(0, 5.25, z + side * .207), TEAL)
		_sign("Dax", Vector3(0, 5.32, z + side * .25), 4.8, PI if side < 0 else 0.0, CREAM, .020)

func _burger_ad() -> void:
	var at := Vector3(5.90, 1.68, -6.58)
	_box("Burger advertisement frame", Vector3(2.36, 2.66, .17), at, DARK)
	var panel := _box("Backlit burger advertisement", Vector3(2.24, 2.54, .05), at + Vector3.FORWARD * .10, Color("#d1734c"))
	panel.material_override = ad_glow
	_sign("Dax burger", at + Vector3(0, .92, -.14), 1.98, PI)
	_food_photo(0, at + Vector3(0, .01, -.15), PI, 1.47)
	var price: Label3D = city._station_sign(str(PRICE), at + Vector3(0, -.92, -.147), .009, CREAM, PI, self)
	city._size_world_sign(price, 1.0)

func _order_menu() -> void:
	var screen := city._material(Color("#fff1d4"), .64, true) as StandardMaterial3D
	screen.emission_energy_multiplier = .64
	_box("Wall menu housing", Vector3(.22, 1.87, 5.53), Vector3(-8.08, 1.62, -3.49), DARK)
	var headings := ["BURGERS", "Milkshakes", "Snacks"]
	var listings := [
		["Dax burger", "Jam & Pickle Burger", "Popcorn Burger"],
		["Blueberry Cloud Shake", "Cinnamon Bun Shake"],
		["Curly Fries", "Crispy Pickles"]
	]
	for column in 3:
		var z := -5.25 + column * 1.76
		var face := _box("Backlit wall menu panel", Vector3(.035, 1.71, 1.67), Vector3(-8.20, 1.62, z), CREAM)
		face.material_override = screen
		_box("Menu colour band", Vector3(.045, .34, 1.67), Vector3(-8.22, 2.25, z), [TEAL, Color("#72547c"), Color("#9c482f")][column])
		_sign(headings[column], Vector3(-8.258, 2.25, z), 1.51, -PI / 2, CREAM, .0055)
		for row in listings[column].size():
			var y: float = 1.85 - row * .41
			var specials_tile: int = [[-1, 0, 1], [-1, 2], [-1, 3]][column][row]
			_food_photo(column if specials_tile < 0 else specials_tile,
				Vector3(-8.25, y, z - .57), -PI / 2, .37, specials_tile >= 0)
			_sign(listings[column][row], Vector3(-8.252, y, z + .19), 1.12, -PI / 2, DARK, .0042)
			if row < listings[column].size() - 1:
				_box("Menu row separator", Vector3(.025, .012, 1.56),
					Vector3(-8.222, y - .206, z), Color("#baa88c"))

func _food_photo(index: int, at: Vector3, yaw: float, width: float, special := false) -> void:
	var crop := AtlasTexture.new()
	crop.atlas = preload("res://art/dax/menu-specials.jpg") if special else preload("res://art/dax/menu-food.jpg")
	var tile := crop.atlas.get_height() / 2.0 if special else float(crop.atlas.get_height())
	var column := index % 2 if special else index
	var row := floori(index / 2.0) if special else 0
	crop.region = Rect2(column * tile, row * tile, tile, tile)
	crop.filter_clip = true
	var food := Sprite3D.new()
	food.name = "Food photograph"
	food.texture = crop
	food.pixel_size = width / tile
	food.position = at
	food.rotation.y = yaw
	add_child(food)

func _order_station() -> void:
	_order_menu()
	_box("Intercom pillar", Vector3(.31, 1.36, .36), Vector3(-8.67, .69, -.40), TEAL)
	for i in 4:
		_box("Speaker slot", Vector3(.024, .022, .21), Vector3(-8.83, 1.05 + .046 * i, -.40), DARK)
	_box("Intercom sign panel", Vector3(.14, .40, 1.35), Vector3(-8.78, 1.64, -.40), TEAL)
	_sign("1 · Order here", Vector3(-8.88, 1.66, -.40), 1.23, -PI / 2)
	_box("Ordering station header", Vector3(.32, .21, 2.92), Vector3(-8.18, 2.70, -3.49), TEAL)
	_sign("Drive-through", Vector3(-8.35, 2.72, -3.49), 2.55, -PI / 2, CREAM, .005)
	_box("Entrance sign post", Vector3(.20, 2.5, .20), Vector3(-8.15, 1.25, -15.4), DARK)
	_box("Entrance sign panel", Vector3(1.96, .89, .12), Vector3(-8.15, 2.46, -15.4), TEAL)
	_sign("Dax", Vector3(-8.15, 2.65, -15.48), 1.65, PI)
	_sign("Drive-through", Vector3(-8.15, 2.23, -15.48), 1.76, PI)
	_obstacle(Vector3(.40, 1.84, 1.35), Vector3(-8.67, .92, -.40))

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

func _sign(caption: String, at: Vector3, width: float, yaw := 0.0, tint := CREAM, text_size := .011) -> void:
	var label: Label3D = city._station_sign(caption, at, text_size, tint, yaw, self)
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
