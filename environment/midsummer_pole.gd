extends Node3D

var foliage := SurfaceTool.new()
var rng := RandomNumberGenerator.new()
var obstacle: AABB
var wreaths: Array[MeshInstance3D] = []

func _ready() -> void:
	hide()
	obstacle = AABB(position - Vector3(.19,0,.19), Vector3(.38,7.4,.38))
	rng.seed = 624
	foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3.UP * 7.4
	beam(Vector3.ZERO, top, .09)
	beam(Vector3(-2.35,5.6,0), Vector3(2.35,5.6,0), .07)
	for side: float in [-1,1]:
		var end := Vector3(side*2.15,5.6,0)
		beam(top,end,.036)
	# Narrow blue and yellow bindings wind through the birch leaves.
	for strand in 2:
		var tint := Color("#267bb6") if strand == 0 else Color("#f5c638")
		for step in 224:
			var a := float(step)/224
			var b := float(step+1)/224
			var start := Vector3(cos(a*TAU*14),0,sin(a*TAU*14))*.15 + Vector3.UP*(.14+a*7.08+strand*.035)
			var end := Vector3(cos(b*TAU*14),0,sin(b*TAU*14))*.15 + Vector3.UP*(.14+b*7.08+strand*.035)
			diamond(start,end,end+Vector3.UP*.028,start+Vector3.UP*.028,tint)
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.vertex_color_is_srgb = true
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_foliage(finish)
	for side: float in [-1, 1]:
		foliage.clear()
		foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
		var centre := Vector3.DOWN*.53
		for i in 40:
			var a := TAU*i/40
			var b := TAU*(i+1)/40
			sprigs(centre + Vector3(sin(a),cos(a),0)*.53,centre + Vector3(sin(b),cos(b),0)*.53,.075)
		var wreath := add_foliage(finish)
		wreath.position = Vector3(side*2.15,5.6,0)
		wreaths.append(wreath)

func add_foliage(finish: StandardMaterial3D) -> MeshInstance3D:
	foliage.generate_normals()
	foliage.index()
	var leaves := MeshInstance3D.new()
	leaves.mesh = foliage.commit()
	leaves.material_override = finish
	add_child(leaves)
	return leaves

func move_wreaths(time: float, wind_angle: float) -> void:
	if not visible: return
	for index in wreaths.size():
		var sway := .065 * sin(time*1.7 + index*.65)
		wreaths[index].rotation.x = sway * sin(wind_angle)
		wreaths[index].rotation.z = sway * cos(wind_angle)

func beam(a: Vector3,b: Vector3,radius: float) -> void:
	var core := CylinderMesh.new()
	core.height = a.distance_to(b)
	core.bottom_radius = radius
	core.top_radius = radius*.85
	var timber := MeshInstance3D.new()
	timber.mesh = core
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("#77644a")
	timber.material_override = finish
	timber.position = (a+b)*.5
	timber.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	add_child(timber)
	sprigs(a,b,radius)
	if not is_equal_approx(a.x,b.x):
		var bundles := ceili(a.distance_to(b)*6.5)
		for i in bundles:
			var origin := a.lerp(b,(i+.5)/bundles)
			var back := Vector3.BACK if i%2 == 0 else Vector3.FORWARD
			var end := origin + back*rng.randf_range(.045,.09) + Vector3.DOWN*rng.randf_range(.13,.28)
			end.x += rng.randf_range(-.10,.10)
			var stem_side := Vector3.RIGHT*.007
			diamond(origin-stem_side,origin+stem_side,end+stem_side*.25,end-stem_side*.25,Color("#66743a"))
			for pair in 4:
				var root := origin.lerp(end,.18+pair*.20)
				for direction in [-1,1]:
					var tip := root + Vector3(direction*(.10-.014*pair),-.075,.025*direction)
					var width := Vector3(direction*.018,.023,.017)
					var tint := Color("#436333").lerp(Color("#9ab84d"),rng.randf())
					birch_leaf(root,tip,width,tint)

func sprigs(a: Vector3,b: Vector3,radius: float) -> void:
	var axis := (b-a).normalized()
	var side := axis.cross(Vector3.BACK).normalized()
	var count := ceili(a.distance_to(b)*110)
	for i in count:
		var angle := i*2.4+rng.randf_range(-.4,.4)
		var out := side*cos(angle)+Vector3.BACK*sin(angle)
		var base := a.lerp(b,float(i)/count)+out*radius*.55
		var tip := base + out*rng.randf_range(.09,.16) + axis*rng.randf_range(-.13,.09) - Vector3.UP*.055
		var wing := axis.cross(out)*rng.randf_range(.036,.064)
		var colour := Color("#254c29").lerp(Color("#83ac40"),rng.randf())
		birch_leaf(base,tip,wing,colour)
		if rng.randf() < .035:
			var petal := Color("#fff7dc") if i%2 else Color("#d27dad")
			for j in 5:
				var turn := TAU*j/5
				var ray := axis*cos(turn)+axis.cross(out)*sin(turn)
				var edge := out.cross(ray)*.013
				diamond(tip,tip+ray*.027+edge,tip+ray*.046,tip+ray*.027-edge,petal)

# Each half folds toward the midrib. The shallow notches break up the edge.
const LEAF_EDGE := [Vector2(.16,.70), Vector2(.34,1.0), Vector2(.42,.80),
	Vector2(.49,.92), Vector2(.61,.64), Vector2(.67,.72), Vector2(.81,.35)]

func birch_leaf(base: Vector3, tip: Vector3, wing: Vector3, tint: Color) -> void:
	var fold := (tip-base).cross(wing).normalized() * wing.length()*.24
	var midrib := base.lerp(tip,.44) + fold
	for side: float in [-1,1]:
		var previous := base
		for point: Vector2 in LEAF_EDGE:
			var edge := base.lerp(tip,point.x) + wing*side*point.y
			leaf_facet(previous,edge,midrib,tint,side)
			previous = edge
		leaf_facet(previous,tip,midrib,tint,side)

func leaf_facet(a: Vector3,b: Vector3,ridge: Vector3,tint: Color,side: float) -> void:
	foliage.set_color(tint)
	foliage.add_vertex(a if side > 0 else b)
	foliage.add_vertex(b if side > 0 else a)
	foliage.set_color(tint.lightened(.10))
	foliage.add_vertex(ridge)

func diamond(a: Vector3,b: Vector3,c: Vector3,d: Vector3,tint: Color) -> void:
	for vertex in [a,b,c,a,c,d]:
		foliage.set_color(tint)
		foliage.add_vertex(vertex)

func set_summer(active: bool) -> void:
	if visible == active: return
	visible = active
	if active: get_parent().roadside_solids.append(obstacle)
	else: get_parent().roadside_solids.erase(obstacle)
