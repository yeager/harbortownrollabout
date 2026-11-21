extends Node3D

const STATION_NAMES := ["Sjöstads kaj", "Kanalparken", "Brotorget"]

const SERVICE_BRAKE := 1.8

var track := Curve3D.new()
var sections: Array[Node3D] = []
var gangways: Array[MeshInstance3D] = []
var bellows_finish := StandardMaterial3D.new()
var platform_door_leaves: Array[Node3D] = []
var interior_displays: Array[Label3D] = []
var next_stop_display: Label3D
var stops: Array[float] = []
var next_stop := 1
var distance := 0.0
var velocity := 0.0
var dwell := 6.0

func beam(a: Vector3, b: Vector3, width: float, height: float, color: Color, mount: Node3D = self) -> void:
	var piece = get_parent()._make_box("Track", Vector3(width,height,a.distance_to(b)+.015), (a+b)/2, color,false,mount)
	piece.look_at(mount.to_global(b))

func sign_at(parent: Node3D, words: String, at: Vector3, angle: float, scale_factor: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.rotation.y = angle
	label.pixel_size = scale_factor
	label.font_size = 42
	label.outline_size = 4
	parent.add_child(label)
	return label

func _door_window(side: int, direction: int, leaf: Node3D) -> void:
	# The two leaves form a split oval when the doors meet.
	var vertices := PackedVector3Array()
	var centre := Vector3(side*.048,.28,-direction*.225)
	for point in 16:
		var a := PI*point/16.0
		var b := PI*(point+1)/16.0
		vertices.append(centre)
		vertices.append(centre+Vector3(0,.64*cos(a),direction*.405*sin(a)))
		vertices.append(centre+Vector3(0,.64*cos(b),direction*.405*sin(b)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.RIGHT*side)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var window := MeshInstance3D.new()
	window.mesh = mesh
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color("#29404a")
	tint.roughness = .21
	tint.metallic = .24
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	window.material_override = tint
	leaf.add_child(window)

func _ready() -> void:
	var world := get_parent()
	for i in 97:
		var a := TAU*i/96
		track.add_point(Vector3(71+11*cos(a),5,-24+41*sin(a)))
	var length := track.get_baked_length()
	for i in 120:
		var a := track.sample_baked(length*i/120)
		var b := track.sample_baked(length*(i+1)/120)
		var side := (b-a).normalized().cross(Vector3.UP)
		beam(a-Vector3.UP*.25,b-Vector3.UP*.25,3.4,.46,Color("#888983"))
		for s in [-1,1]:
			beam(a+side*.72*s,b+side*.72*s,.07,.12,Color("#939c9c"))
		beam(a+Vector3.UP*4.2,b+Vector3.UP*4.2,.028,.032,Color("#60594e"))
		if i%8==0:
			var pole := a+side*1.95
			world._make_box("Overhead mast",Vector3(.14,4.7,.14),pole+Vector3.UP*2.12,Color("#758083"),false,self)
			beam(pole+Vector3.UP*4.42,a+Vector3.UP*4.42,.075,.075,Color("#717c7d"))
			world._make_box("Wire suspension",Vector3(.045,.23,.045),a+Vector3.UP*4.31,Color("#554f46"),false,self)
		if i%10==0 and absf(a.z)>6 and absf(a.z+48)>6:
			world._make_box("Viaduct pier",Vector3(1.1,6.3,1.4),a-Vector3.UP*3.45,Color("#a9aaa5"),false,self)
	for i in 3:
		var offset := length*i/3
		stops.append(offset)
		var station := Node3D.new()
		add_child(station)
		station.position = track.sample_baked(offset)
		station.look_at(track.sample_baked(offset+.2))
		# Follow the curve so each door opens alongside a platform edge.
		for segment in range(-12, 4):
			var start := track.sample_baked(fposmod(offset + segment, length))
			var end := track.sample_baked(fposmod(offset + segment + 1, length))
			var outward := (end - start).normalized().cross(Vector3.UP)
			var platform := outward * 2.8 + Vector3.UP * .05
			beam(start + platform, end + platform, 2.6, .55, Color("#c4bbaa"))
			var marking := outward * 1.69 + Vector3.UP * .332
			beam(start + marking, end + marking, .14, .012, Color("#f3da85"))
		world._make_box("Shelter roof",Vector3(2.1,.12,5.2),Vector3(3,2.7,0),Color("#475963"),false,station)
		for z in [-2,2]:
			world._make_box("Shelter post",Vector3(.1,2.4,.1),Vector3(3.8,1.5,z),Color("#697778"),false,station)
		world._make_box("Bench seat",Vector3(.43,.085,2.5),Vector3(3.53,.80,0),Color("#a87547"),false,station)
		world._make_box("Bench back",Vector3(.07,.29,2.5),Vector3(3.72,1.06,0),Color("#a87547"),false,station)
		for z in [-.9,.9]:
			world._make_box("Bench leg",Vector3(.25,.44,.08),Vector3(3.53,.55,z),Color("#49565c"),false,station)
		world._make_box("Station name board",Vector3(.08,.43,3.8),Vector3(2.15,2.45,0),Color("#16496a"),false,station)
		for side in [-1,1]:
			sign_at(station,STATION_NAMES[i],Vector3(2.15+side*.045,2.45,0),side*PI/2,.0068)
	for i in 3:
		var car := Node3D.new()
		add_child(car)
		sections.append(car)
		var display := sign_at(car, STATION_NAMES[next_stop], Vector3(0,2.145,-2.085), 0, .0019)
		display.modulate = Color("#ffbd58")
		display.outline_size = 0
		interior_displays.append(display)
		car.add_child(preload("res://vehicles/tram_saloon.glb").instantiate())
		for s in [-1,1]:
			for opening_direction in [-1,1]:
				var leaf := Node3D.new()
				car.add_child(leaf)
				leaf.position = Vector3(s*1.21,1.49,.13+opening_direction*.26)
				world._make_box("Door panel",Vector3(.08,2.22,.51),Vector3.ZERO,Color("#147db0"),false,leaf)
				world._make_box("Interior door lining", Vector3(.008,2.21,.50), Vector3(-s*.043,0,0), Color("#dbd1b4"),false,leaf)
				_door_window(s, opening_direction, leaf)
				_door_window(-s, opening_direction, leaf)
				if s==1:
					platform_door_leaves.append(leaf)
		if i==1:
			var steel := Color("#384448")
			world._make_box("Pantograph base",Vector3(1.05,.18,1.26),Vector3(0,2.78,.25),steel,false,car)
			for side in [-1,1]:
				var heel := Vector3(side*.33,2.87,.67)
				var elbow := Vector3(side*.28,3.53,-.54)
				var crown := Vector3(side*.39,4.13,0)
				beam(heel,elbow,.065,.083,steel,car)
				beam(elbow,crown,.048,.065,steel,car)
			world._make_box("Contact shoe",Vector3(1.22,.065,.13),Vector3(0,4.16,0),steel,false,car)
		if i in [0, 2]:
			var cab := preload("res://vehicles/tram_cab.glb").instantiate() as Node3D
			var end := -1 if i == 0 else 1
			cab.rotation.y = 0 if i == 0 else PI
			car.add_child(cab)
			world._make_box("Cab bulkhead", Vector3(2.23,2.26,.15), Vector3(0,1.49,end*2.25), Color("#374b58"),false,car)
		if i==0:
			sign_at(car,"Sjöstaden",Vector3(0,2.32,-2.528),PI,.0036)
			world._make_box("Next stop display",Vector3(.04,.32,1.74),Vector3(1.20,2.48,-1.32),Color("#192426"),false,car)
			next_stop_display = sign_at(car,STATION_NAMES[next_stop],Vector3(1.23,2.48,-1.32),PI/2,.0044)
			next_stop_display.modulate = Color("#ffbd58")
			next_stop_display.outline_size = 0
			world._make_box("Door notice",Vector3(.035,.32,1.4),Vector3(1.21,1.04,1.46),Color("#174460"),false,car)
			sign_at(car,"Vi åker inte till Ekerö",Vector3(1.24,1.04,1.46),PI/2,.003)
	bellows_finish.albedo_color = Color("#41494b")
	bellows_finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	for joint in sections.size()-1:
		var gangway := MeshInstance3D.new()
		gangway.mesh = ImmediateMesh.new()
		gangway.material_override = bellows_finish
		add_child(gangway)
		gangways.append(gangway)
	place_sections()

func distance_to_next_stop() -> float:
	return fposmod(stops[next_stop]-distance,track.get_baked_length())

func advance(delta: float, manual: bool, gas: bool, brake: bool) -> void:
	if dwell>0:
		dwell=maxf(0,dwell-delta)
		var opening := smoothstep(0,.85,minf(6-dwell,dwell))
		for i in platform_door_leaves.size():
			var direction := -1 if i%2==0 else 1
			platform_door_leaves[i].position.z = .13+direction*(.26+.51*opening)
		return
	var length := track.get_baked_length()
	var remaining := distance_to_next_stop()
	var target := 7.0
	if manual:
		target = 0 if brake else (7 if gas else velocity)
	# Reserve the distance travelled this frame as well as the braking distance afterwards.
	var initial := velocity
	var half_change := SERVICE_BRAKE * delta * .5
	var approach_speed := sqrt(maxf(0,half_change*half_change + SERVICE_BRAKE*(2*remaining-initial*delta))) - half_change
	velocity = move_toward(initial,clampf(approach_speed,0,target),delta*(3.0 if brake else SERVICE_BRAKE))
	var step := (initial + velocity) * .5 * delta
	if step <= 0.0 and remaining > .0001:
		return
	if remaining <= step + .0001:
		distance=stops[next_stop]
		next_stop=(next_stop+1)%stops.size()
		next_stop_display.text = STATION_NAMES[next_stop]
		for display in interior_displays:
			display.text = next_stop_display.text
		velocity=0
		dwell=6
	else:
		distance=fposmod(distance+step,length)
	place_sections()

func place_sections() -> void:
	var length := track.get_baked_length()
	for i in sections.size():
		var p := fposmod(distance-4.83*i,length)
		sections[i].position=track.sample_baked(p)
		sections[i].look_at(track.sample_baked(fposmod(p+.2,length)))
	for i in gangways.size():
		_shape_gangway(gangways[i].mesh, sections[i].transform, sections[i+1].transform)

func _shape_gangway(mesh: ImmediateMesh, leading: Transform3D, trailing: Transform3D) -> void:
	# Each fold spans matching points on the two moving saloon end frames.
	var contour := PackedVector2Array([
		Vector2(-1.05,.43), Vector2(1.05,.43), Vector2(1.14,.59), Vector2(1.14,2.40),
		Vector2(1.01,2.59), Vector2(-1.01,2.59), Vector2(-1.14,2.40), Vector2(-1.14,.59)
	])
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := PackedVector3Array()
	for ridge in 9:
		var ring := PackedVector3Array()
		for point in contour:
			var inset := 1.0 if ridge % 2 == 0 else .93
			var x := point.x*inset
			var y := 1.5+(point.y-1.5)*inset
			var start := leading * Vector3(x,y,2.19)
			var end := trailing * Vector3(x,y,-2.19)
			ring.append(start.lerp(end,float(ridge)/8.0))
		if ridge > 0:
			for k in contour.size():
				var j := (k+1)%contour.size()
				var normal := (previous[j]-previous[k]).cross(ring[k]-previous[k]).normalized()
				for vertex in [previous[k],ring[k],previous[j],previous[j],ring[k],ring[j]]:
					mesh.surface_set_normal(normal)
					mesh.surface_add_vertex(vertex)
		previous = ring
	mesh.surface_end()
