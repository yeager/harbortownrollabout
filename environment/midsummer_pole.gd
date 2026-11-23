extends Node3D

var foliage := SurfaceTool.new()
var rng := RandomNumberGenerator.new()
var obstacle: AABB

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
		var centre := end - Vector3.UP*.53
		for i in 40:
			var angle := TAU*i/40
			var next_angle := TAU*(i+1)/40
			var a := centre + Vector3(sin(angle),cos(angle),0)*.53
			var b := centre + Vector3(sin(next_angle),cos(next_angle),0)*.53
			sprigs(a,b,.075)
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
	foliage.generate_normals()
	var leaves := MeshInstance3D.new()
	leaves.mesh = foliage.commit()
	leaves.material_override = finish
	add_child(leaves)

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
		var mid := base.lerp(tip,.47)
		var colour := Color("#254c29").lerp(Color("#83ac40"),rng.randf())
		var ridge := mid + out*.018
		for vertex in [base,mid+wing,ridge,mid+wing,tip,ridge,tip,mid-wing,ridge,mid-wing,base,ridge]:
			foliage.set_color(colour)
			foliage.add_vertex(vertex)
		if rng.randf() < .035:
			var petal := Color("#fff7dc") if i%2 else Color("#d27dad")
			for j in 5:
				var turn := TAU*j/5
				var ray := axis*cos(turn)+axis.cross(out)*sin(turn)
				var edge := out.cross(ray)*.013
				diamond(tip,tip+ray*.027+edge,tip+ray*.046,tip+ray*.027-edge,petal)

func diamond(a: Vector3,b: Vector3,c: Vector3,d: Vector3,tint: Color) -> void:
	for vertex in [a,b,c,a,c,d]:
		foliage.set_color(tint)
		foliage.add_vertex(vertex)

func set_summer(active: bool) -> void:
	if visible == active: return
	visible = active
	if active: get_parent().roadside_solids.append(obstacle)
	else: get_parent().roadside_solids.erase(obstacle)
