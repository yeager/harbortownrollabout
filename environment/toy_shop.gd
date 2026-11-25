extends Node3D

const INK := Color("#253450")
const PAPER := Color("#fff2cf")
const PALETTE := [Color("#ed5c59"), Color("#f6bf44"), Color("#58bea8"), Color("#3697d1")]
var world: Node3D

func build(shop: Node3D, x: float, front_z: float) -> Node3D:
	name = "Toy Harbour shop"
	world = shop.get_parent()
	position = Vector3(x, 0, front_z)
	world._make_driving_surface("Toy shop floor", Vector3(8.36, .18, 6.9), Vector3(0, -.11, 3.45), PAPER, false, self)
	for side in [-1, 1]:
		_box("Insulated party wall", Vector3(side * 4.12, 1.72, 3.42), Vector3(.18, 3.44, 6.84), INK, true)
		_window(side)
	_box("Back wall", Vector3(0, 1.72, 6.86), Vector3(8.28, 3.44, .18), Color("#e6cdaa"), true)
	var roof := _box("Toy shop roof", Vector3(0, 3.53, 3.38), Vector3(8.48, .24, 7.13), INK)
	_box("Canopy shadow", Vector3(0, 2.78, -.36), Vector3(8.48, .15, .88), INK)
	for i in 16:
		_box("Coloured canopy tile", Vector3((i - 7.5) * .525, 2.88, -.39), Vector3(.52, .09, .84), PALETTE[i % 4])
	_box("Lettering fascia", Vector3(0, 3.18, -.25), Vector3(8.35, .50, .48), INK)
	var sign: Label3D = world._station_sign("Toy Harbour", Vector3(.32, 3.19, -.501), .0079, PAPER, PI, self)
	sign.double_sided = false
	world._size_world_sign(sign, 6.34)
	for i in 3:
		var badge := _box("Building block emblem", Vector3(-3.61 + i * .20, 3.15 + (i % 2) * .10, -.518), Vector3(.17, .17, .06), PALETTE[i])
		badge.rotation.z = (i - 1) * .22

	_box("Entrance threshold", Vector3(0, -.028, .12), Vector3(1.58, .049, .59), Color("#c17250"))
	_box("Welcome mat", Vector3(0, -.014, .64), Vector3(1.50, .020, .62), Color("#637e86"))
	var door := _glass("Open door glazing", Vector3(.86, 1.24, .57), Vector3(.04, 2.35, 1.14))
	for edge in [-1, 1]:
		_box("Door stile", door.position + Vector3(0, 0, edge * .55), Vector3(.075, 2.44, .07), INK)
		_box("Door rail", door.position + Vector3(0, edge * 1.18, 0), Vector3(.075, .075, 1.17), INK)
	_box("Door handle", door.position + Vector3(-.07, -.14, .43), Vector3(.055, .30, .05), Color("#e8ba66"))

	_box("Checkout counter", Vector3(1.88, .50, 4.97), Vector3(2.53, 1.02, .68), Color("#58bea8"), true)
	_box("Checkout worktop", Vector3(1.88, 1.03, 4.97), Vector3(2.66, .10, .77), PAPER)
	_box("Checkout register", Vector3(2.78, 1.16, 4.83), Vector3(.42, .19, .36), INK)
	_box("Checkout display", Vector3(2.78, 1.22, 4.643), Vector3(.25, .07, .026), Color("#b8e4b1"))
	_box("Play mat", Vector3(-1.73, -.017, 3.34), Vector3(2.67, .01, 2.27), Color("#2d6c89"))
	for side in [-1, 1]:
		_box("Play mat border", Vector3(-1.73 + side * 1.23, -.009, 3.34), Vector3(.065, .007, 2.09), PAPER)
		_box("Play mat border", Vector3(-1.73, -.009, 3.34 + side * 1.01), Vector3(2.46, .007, .065), PAPER)
	for shelf in [0.64, 1.39, 2.14]:
		_box("Back wall shelf", Vector3(0, shelf, 6.45), Vector3(7.52, .08, .62), PAPER, true)
		for item in 7:
			var tint: Color = PALETTE[(item + roundi(shelf * 3.0)) % PALETTE.size()]
			var height := [.32, .43, .36][item % 3] as float
			var width := [.73, .54, .65][item % 3] as float
			var at := Vector3((item - 3) * 1.04, shelf + .04 + height * .5, 6.43)
			_box("Boxed toy", at, Vector3(width, height, .39), tint)
			_box("Box illustration panel", at - Vector3(0, 0, .202), Vector3(width * .74, height * .60, .02), PAPER)
			if item % 2 == 0:
				for i in 3:
					_box("Box stacking blocks", at + Vector3((i - 1) * .105, .025 * (i % 2), -.214), Vector3(.086, .080, .009), tint)
			else:
				_box("Box racing car", at + Vector3(0, .017, -.214), Vector3(.24, .071, .01), tint)
				for side in [-1, 1]:
					_round("Box racing car wheel", at + Vector3(side * .071, -.028, -.221), .029, .008, INK, true)
	for i in 4:
		_box("Aisle ceiling strip", Vector3((i - 1.5) * 1.85, 3.28, 3.70), Vector3(.86, .056, .15), PAPER)
	for side in [-1, 1]:
		shop._shop_light(Vector3(x + side * 2.45, 2.57, front_z + 1.48), Color("#ffe8bc"), 1.30)
	shop._shop_light(Vector3(x, 2.63, front_z + 4.76), Color("#fff4db"), .75)
	_train(Vector3(-2.66, .73, .82))
	make_bear(self, Vector3(2.74, .75, .80))
	_blocks(Vector3(1.69, .74, .72))
	return roof

func _window(side: int) -> void:
	var x := side * 2.47
	_glass("Display glazing", Vector3(x, 1.57, .0), Vector3(3.24, 2.36, .055), true)
	_box("Display riser", Vector3(x, .21, .015), Vector3(3.28, .44, .26), PALETTE[1 if side < 0 else 2])
	_box("Window top rail", Vector3(x, 2.73, -.07), Vector3(3.32, .095, .14), INK)
	_box("Display window sill", Vector3(x, .46, -.03), Vector3(3.32, .078, .21), PAPER)
	for edge in [-1, 1]:
		_box("Window jamb", Vector3(x + edge * 1.62, 1.59, -.057), Vector3(.095, 2.31, .14), INK)
	_box("Window display plinth", Vector3(x, .61, .90), Vector3(2.90, .24, 1.39), Color("#c17250"), true)
	_box("Window display top", Vector3(x, .726, .90), Vector3(2.96, .055, 1.42), PAPER)

func _train(at: Vector3) -> void:
	for i in 19:
		_box("Wooden track sleeper", at + Vector3((i - 9) * .136, .015, .0), Vector3(.073, .027, .54), Color("#a97348"))
	for side in [-1, 1]:
		_box("Wooden track rail", at + Vector3(0, .045, side * .163), Vector3(2.55, .030, .044), Color("#ebc48a"))
	for i in 3:
		var car := at + Vector3((i - 1) * .76, .16, 0)
		var tint: Color = PALETTE[i]
		_box("Toy train chassis", car, Vector3(.63, .10, .36), tint)
		_box("Toy train carriage", car + Vector3(0, .15, 0), Vector3(.54, .24, .34), tint)
		for wheel in [-1, 1]:
			for side in [-1, 1]:
				_round("Toy train wheel", car + Vector3(wheel * .205, -.024, side * .185), .105, .053, INK, true)
		if i == 0:
			_box("Locomotive cab", car + Vector3(.15, .32, 0), Vector3(.25, .30, .37), PALETTE[0])
			_box("Locomotive window", car + Vector3(.15, .335, -.192), Vector3(.12, .12, .026), PAPER)
			_round("Locomotive chimney", car + Vector3(-.18, .335, 0), .055, .17, INK)
		else:
			for window in [-1, 1]:
				_box("Carriage window", car + Vector3(window * .13, .16, -.178), Vector3(.16, .12, .025), PAPER)

func make_bear(parent: Node3D, at: Vector3) -> Node3D:
	var bear := Node3D.new()
	bear.name = "TeddyBear"
	bear.position = at
	parent.add_child(bear)
	var fur := Color("#ad744c")
	var muzzle := Color("#f0d2ad")
	_sphere("Teddy body", Vector3(0, .29, 0), Vector3(.33, .34, .22), fur, bear)
	_sphere("Teddy head", Vector3(0, .68, -.025), Vector3(.285, .25, .23), fur, bear)
	_sphere("Teddy muzzle", Vector3(0, .61, -.217), Vector3(.16, .106, .080), muzzle, bear)
	_sphere("Teddy nose", Vector3(0, .65, -.28), Vector3(.053, .035, .027), INK, bear)
	for side in [-1, 1]:
		_sphere("Teddy ear", Vector3(side * .21, .86, -.02), Vector3(.123, .11, .078), fur, bear)
		_sphere("Teddy inner ear", Vector3(side * .21, .87, -.081), Vector3(.072, .069, .031), muzzle, bear)
		_sphere("Teddy eye", Vector3(side * .092, .72, -.228), Vector3(.022, .025, .014), INK, bear)
		_sphere("Teddy arm", Vector3(side * .31, .32, -.026), Vector3(.112, .20, .14), fur, bear)
		_sphere("Teddy paw", Vector3(side * .174, .12, -.135), Vector3(.14, .116, .17), muzzle, bear)
		var ribbon: MeshInstance3D = world._make_box("Teddy bow loop", Vector3(.15, .083, .05), Vector3(side * .09, .485, -.19), PALETTE[2], false, bear)
		ribbon.rotation.z = side * .24
	return bear

func _blocks(at: Vector3) -> void:
	for i in 6:
		var col := i % 3
		var tier := floori(i / 3.0)
		var block := _box("Painted wooden block", at + Vector3((col - 1) * .245, .112 + tier * .23, 0),
			Vector3(.219, .219, .22), PALETTE[i % 4])
		block.rotation.y = (col - 1) * .12
	_round("Wooden block tower top", at + Vector3(0, .55, 0), .106, .18, PALETTE[3])

func _box(label: String, at: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var part: MeshInstance3D = world._make_box(label, size, at, color, false, self)
	if solid:
		world.building_bounds.append(AABB(to_global(at) - size * .5, size))
	return part

func _glass(label: String, at: Vector3, size: Vector3, solid := false) -> MeshInstance3D:
	var pane := _box(label, at, size, Color.WHITE, solid)
	var glass := pane.material_override as StandardMaterial3D
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(.69, .87, .91, .13)
	glass.roughness = .16
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pane

func _round(label: String, at: Vector3, radius: float, height: float, color: Color, axle := false) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var item := _mesh(label, mesh, at, color, self)
	if axle:
		item.rotation.x = PI / 2

func _sphere(label: String, at: Vector3, radii: Vector3, color: Color, parent: Node3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_mesh(label, mesh, at, color, parent).scale = radii

func _mesh(label: String, mesh: Mesh, at: Vector3, color: Color, parent: Node3D) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	item.position = at
	item.mesh = mesh
	item.material_override = world._material(color)
	parent.add_child(item)
	return item
