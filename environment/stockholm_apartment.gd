extends Node3D

# All measurements are local metres. Front faces +Z; the ground footprint is 14 × 10 m.
var batches := {}
var unit_box := BoxMesh.new()

func _add(finish: Material, mesh: Mesh, placement: Transform3D) -> void:
	if not batches.has(finish):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(finish)
		batches[finish] = surface
	batches[finish].append_from(mesh, 0, placement)

func _box(finish: Material, center: Vector3, size: Vector3, angle := 0.0) -> void:
	_add(finish, unit_box, Transform3D(Basis(Vector3.FORWARD,angle).scaled_local(size),center))

func _gable(finish: Material, center: Vector3, width: float, rise: float, depth: float) -> void:
	# A shallow pediment with a triangular face on each end.
	var shape := PrismMesh.new()
	shape.size = Vector3(width,rise,depth)
	_add(finish,shape,Transform3D(Basis.IDENTITY,center))

func _finish(color: String, roughness := .84, surface := "mineral") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = roughness
	if not surface.is_empty():
		preload("res://art/surfaces/model_finish.gd").apply(mat, surface)
	return mat

func _window(at: Vector3, frame: Material, stone: Material, glass: Material, elaborate: bool) -> void:
	_box(stone,at,Vector3(1.46,1.91,.16))
	_box(frame,at+Vector3(0,0,.095),Vector3(1.26,1.72,.075))
	_box(glass,at+Vector3(0,0,.14),Vector3(1.11,1.55,.047))
	_box(frame,at+Vector3(0,0,.177),Vector3(.066,1.57,.043))
	for h in [-.25,.29]:
		_box(frame,at+Vector3(0,h,.177),Vector3(1.12,.049,.043))
	_box(stone,at+Vector3(0,-.97,.038),Vector3(1.61,.12,.30))
	if elaborate:
		_box(stone,at+Vector3(0,.97,.032),Vector3(1.65,.11,.28))
		_gable(stone,at+Vector3(0,1.12,.055),1.58,.23,.24)

func _oriel(floors: int, stone: Material, plaster: Material, wood: Material, glass: Material, roof: Material) -> void:
	# A three-sided bay starts above the portal, leaving the pavement clear.
	var bottom := 2.98
	var height := floors*2.8-bottom-.19
	_box(plaster,Vector3(0,bottom+height*.5,.42),Vector3(1.85,height,.88))
	for side in [-1,1]:
		var orientation := Basis(Vector3.UP,side*.90)
		var face := Transform3D(orientation,Vector3(side*1.18,0,.44))
		var side_batches := {}
		var outer := batches
		batches = side_batches
		_box(plaster,Vector3(0,bottom+height*.5,0),Vector3(1.03,height,.14))
		for level in range(1,floors):
			var h := 1.55+level*2.8
			_box(wood,Vector3(0,h,.095),Vector3(.68,1.63,.08))
			_box(glass,Vector3(0,h,.155),Vector3(.56,1.48,.06))
			_box(wood,Vector3(0,h+.29,.202),Vector3(.57,.054,.04))
		batches = outer
		for mat in side_batches:
			_add(mat,side_batches[mat].commit(),face)
	for level in range(1,floors):
		_window(Vector3(0,1.56+level*2.8,.85),wood,stone,glass,false)
	_box(stone,Vector3(0,bottom,.42),Vector3(2.03,.17,.98))
	_box(roof,Vector3(0,bottom+height+.08,.43),Vector3(2.0,.18,1.03))

func build(floors: int, atlas: bool, facade: Color, night_glass: Material) -> void:
	unit_box.size = Vector3.ONE
	name = "Atlasgården" if atlas else "Birkahuset"
	var plaster := _finish("#ffffff")
	plaster.albedo_color = facade
	var stone := _finish("#d4c6a7" if atlas else "#d6b997")
	var plinth := _finish("#847c70")
	var wood := _finish("#59443a" if atlas else "#485249", .61, "wood")
	var door := _finish("#384f47" if atlas else "#704335", .50, "wood")
	var brass := _finish("#a18a55", .39, "brushed")
	brass.metallic = .62
	var slate := _finish("#42494a" if atlas else "#643f37",.52)
	var pane := _finish("#526770", .20, "")
	pane.metallic = .35
	var brick := _finish("#8e5644")
	var cornice := floors*2.8
	_box(plaster,Vector3(0,cornice*.5-.13,0),Vector3(14,cornice,10))
	_box(plinth,Vector3(0,.29,0),Vector3(14.07,.58,10.06))
	if atlas:
		# Slightly proud stone-coloured render ties the ground floor around the corners.
		_box(stone,Vector3(0,1.64,0),Vector3(14.04,2.12,10.035))
		for side in [-1,1]:
			for course in 5:
				var y := .78+course*.40
				_box(plinth,Vector3(side*7.022,y,0),Vector3(.012,.022,10.03))
				_box(plinth,Vector3(0,y,side*5.020),Vector3(14.04,.022,.012))
	_box(stone,Vector3(0,2.76,0),Vector3(14.10,.17,10.13))
	_box(stone,Vector3(0,cornice-.20,0),Vector3(14.16,.16,10.14))
	_box(stone,Vector3(0,cornice+.01,0),Vector3(14.35,.19,10.32))
	# Rusticated joints at street level, scribed into a darker base course.
	if not atlas:
		for i in 5:
			_box(plinth,Vector3(0,.70+i*.40,4.99),Vector3(13.96,.024,.051))
	for front in [1,-1]:
		var offset := Vector3(0,0,front*4.99)
		var first_surface: Dictionary = {}
		# Build each facade facing forward; rotate the completed rear section as one batch.
		var exterior_batches := batches
		batches = first_surface
		for level in floors:
			for bay in range(-2,3):
				if bay==0 and (level==0 or (not atlas and front==1)):
					continue
				var at := Vector3(2.74*bay,1.56+level*2.8,0)
				var glass: Material = night_glass if posmod(level*7+bay+front,4)==0 else pane
				_window(at,wood,stone,glass,not atlas and level==1)
		_box(stone,Vector3(0,1.23,0),Vector3(1.76,2.56,.18))
		_box(door,Vector3(0,1.19,.11),Vector3(1.42,2.38,.10))
		for side in [-1,1]:
			_box(wood,Vector3(side*.36,1.09,.185),Vector3(.55,1.59,.045))
			_box(door,Vector3(side*.36,.70,.216),Vector3(.43,.66,.04))
			_box(night_glass,Vector3(side*.36,1.48,.216),Vector3(.43,.64,.04))
		_box(wood,Vector3(0,2.11,.182),Vector3(1.27,.37,.058))
		_box(night_glass,Vector3(0,2.11,.219),Vector3(1.17,.273,.034))
		for divider in [-.20,.20]:
			_box(wood,Vector3(divider,2.11,.245),Vector3(.035,.28,.028))
		# Mount the latch on the stile between the glazed panels.
		_box(brass,Vector3(.072,1.035,.185),Vector3(.079,.23,.045))
		_box(brass,Vector3(.072,1.08,.227),Vector3(.036,.035,.063))
		_box(brass,Vector3(.134,1.08,.263),Vector3(.15,.033,.027))
		_box(brass,Vector3(-.36,.83,.246),Vector3(.29,.071,.025))
		_box(wood,Vector3(-.36,.833,.262),Vector3(.238,.021,.009))
		_box(stone,Vector3(0,2.54,.035),Vector3(1.96,.16,.29))
		if not atlas:
			if front==1:
				_oriel(floors,stone,plaster,wood,pane,slate)
			_gable(stone,Vector3(0,2.73,.04),2.06,.28,.30)
			for side in [-1,1]:
				for i in range(floors*4):
					_box(stone,Vector3(side*6.71,.63+i*.68,.01),Vector3(.52 if i%2==0 else .37,.64,.115))
		batches = exterior_batches
		var rotation_basis := Basis(Vector3.UP, PI if front<0 else 0.0)
		for mat in first_surface:
			var section: ArrayMesh = first_surface[mat].commit()
			_add(mat,section,Transform3D(rotation_basis,offset))
	# The roof projects past the cornice. Offset the downpipes back to the masonry.
	var pipe := CylinderMesh.new()
	pipe.radial_segments = 12
	pipe.rings = 0
	pipe.height = 1.0
	pipe.top_radius = .065
	pipe.bottom_radius = .065
	var metal := _finish("#575953", .44, "brushed")
	metal.metallic = .56
	for side in [-1,1]:
		var eave: float = side*5.19
		_box(metal,Vector3(0,cornice-.04,eave),Vector3(14.34,.115,.15))
		for x in [-6.35,6.35]:
			var run := PackedVector3Array([
				Vector3(x,cornice-.04,eave),Vector3(x,cornice-.31,eave),
				Vector3(x,cornice-.51,side*5.11),Vector3(x,.35,side*5.11),
				Vector3(x,.22,side*5.26)])
			for i in range(run.size()-1):
				var delta := run[i+1]-run[i]
				var axes := Basis(Quaternion(Vector3.UP,delta.normalized())).scaled_local(Vector3(1,delta.length(),1))
				_add(metal,pipe,Transform3D(axes,(run[i]+run[i+1])*.5))
			for floor_index in floors:
				_box(metal,Vector3(x,.65+floor_index*2.8,side*5.10),Vector3(.17,.055,.17))
	# Windows on both gable walls are visible from the quay approaches.
	for side in [-1,1]:
		for level in floors:
			for bay in [-2.6,0.0,2.6]:
				var at := Vector3(side*7.01,1.51+2.8*level,bay)
				_box(stone,at,Vector3(.13,1.83,1.40))
				_box(pane,at+Vector3.RIGHT*(side*.09),Vector3(.09,1.59,1.14))
				_box(wood,at+Vector3.RIGHT*(side*.155),Vector3(.035,1.63,.061))
				_box(wood,at+Vector3(side*.155,.21,0),Vector3(.035,.056,1.16))
	# The twin pitched roof planes meet at the ridge; dormers face the street.
	for side in [-1,1]:
		var roof_basis := Basis(Vector3.RIGHT,side*.39).scaled_local(Vector3(14.28,.19,5.64))
		_add(slate,unit_box,Transform3D(roof_basis,Vector3(0,cornice+1.06,side*2.55)))
	var end_gable := PrismMesh.new()
	end_gable.size = Vector3(10.01,2.10,14.0)
	_add(plaster,end_gable,Transform3D(Basis(Vector3.UP,PI/2),Vector3(0,cornice+1.02,0)))
	for x in [-3.7,0.0,3.7]:
		_box(slate,Vector3(x,cornice+.80,3.95),Vector3(1.65,1.18,1.43))
		_box(stone,Vector3(x,cornice+.85,4.68),Vector3(1.32,.92,.09))
		_box(pane,Vector3(x,cornice+.85,4.74),Vector3(1.07,.71,.065))
		_box(wood,Vector3(x,cornice+.85,4.79),Vector3(.058,.73,.05))
		_gable(slate,Vector3(x,cornice+1.62,3.94),1.98,.51,1.62)
	for x in [-4.2,3.1]:
		_box(brick,Vector3(x,cornice+2.07,-.83),Vector3(.72,1.46,.73))
		_box(slate,Vector3(x,cornice+2.79,-.83),Vector3(.85,.13,.84))
	for mat in batches:
		var part := MeshInstance3D.new()
		part.mesh = batches[mat].commit()
		add_child(part)
	batches.clear()
