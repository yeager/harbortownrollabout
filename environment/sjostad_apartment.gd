extends Node3D

# Local X points inland; the promenade faces the negative X facade.
const STAIR_Z := -2.9
const STAIR_WIDTH := 2.2
var batches := {}
var unit_box := BoxMesh.new()

func _box(finish: Material, pos: Vector3, size: Vector3, angle := 0.0) -> void:
	if not batches.has(finish):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(finish)
		batches[finish] = surface
	var transform := Transform3D(Basis(Vector3.RIGHT,angle).scaled_local(size),pos)
	batches[finish].append_from(unit_box,0,transform)

func _finish(color: String, surface := "mineral", roughness := .80) -> StandardMaterial3D:
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(color)
	finish.roughness = roughness
	preload("res://art/surfaces/model_finish.gd").apply(finish, surface)
	return finish

func _glaze(glazing: BaseMaterial3D, pos: Vector3, size: Vector3) -> void:
	# Keep transparent surfaces separate so Godot can sort floors by camera distance.
	var panel := MeshInstance3D.new()
	panel.name = "Glass panel"
	panel.mesh = unit_box
	panel.position = pos
	panel.scale = size
	panel.material_override = glazing
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(panel)

func _stair(floors: int, glow: Material, rail: Material, glazing: BaseMaterial3D) -> void:
	var floor_finish := _finish("#a99c84")
	for level in floors:
		var base := level*2.8
		_box(floor_finish,Vector3(-6.20,base+.08,STAIR_Z),Vector3(1.62,.16,STAIR_WIDTH))
		# Switchback flights sit behind a transparent curtain wall in a real recess.
		for flight in 2:
			var direction := 1.0 if flight==0 else -1.0
			var flight_x := -6.63+.70*flight
			for step in 8:
				var t := (step+.5)/8.0
				var z := STAIR_Z+direction*(-.90+1.80*t)
				_box(floor_finish,Vector3(flight_x,base+1.40*(flight+t),z),Vector3(.67,.13,.24))
			var rise_angle := -direction*atan2(1.4,1.8)
			_box(rail,Vector3(flight_x-.31,base+1.40*flight+1.42,STAIR_Z),
				Vector3(.031,.038,2.28),rise_angle)
		_box(glow,Vector3(-5.53,base+1.41,STAIR_Z),Vector3(.07,2.51,STAIR_WIDTH-.12))
		_box(glow,Vector3(-6.06,base+2.62,STAIR_Z),Vector3(.96,.045,.085))
		for dz in [-.55,.55]:
			_glaze(glazing,Vector3(-6.99,base+1.42,STAIR_Z+dz),Vector3(.025,2.72,1.08))
		_box(rail,Vector3(-7.005,base+.07,STAIR_Z),Vector3(.073,.085,STAIR_WIDTH))
	_box(rail,Vector3(-7.005,floors*1.4,STAIR_Z),Vector3(.072,floors*2.8,.065))

func _balcony(y: float, bay_z: float, width: float, slab: Material, metal: Material, glazing: BaseMaterial3D) -> void:
	_box(slab,Vector3(-7.59,y,bay_z),Vector3(1.33,.17,width+.14))
	_glaze(glazing,Vector3(-8.21,y+.57,bay_z),Vector3(.035,.96,width))
	_box(metal,Vector3(-8.22,y+1.07,bay_z),Vector3(.065,.046,width+.06))
	for edge in [-1,1]:
		var z: float = bay_z+edge*width*.5
		_glaze(glazing,Vector3(-7.62,y+.57,z),Vector3(1.19,.96,.035))
		_box(metal,Vector3(-7.62,y+1.07,z),Vector3(1.25,.046,.05))
		_box(metal,Vector3(-8.19,y+.56,z),Vector3(.055,.96,.055))

func build(floors: int, variant: int, window_batches: Array, glazing: BaseMaterial3D, stair_glow: Material) -> void:
	name = "Sjöstadsfasad"
	unit_box.size = Vector3.ONE
	var height := floors*2.8
	var ivory := _finish("#f0eadd")
	var surround := _finish("#c9975b", "wood", .56)
	var accent := _finish(["#bb6549","#4b5355","#cdac77"][variant%3])
	var end_volume := accent if variant%3<2 else ivory
	var rail := _finish("#5c6665", "brushed", .31)
	rail.metallic = .72
	var slab := _finish("#d6d4bf")
	var parapet := _finish("#afb2a9", "brushed", .46)
	parapet.metallic = .55
	# Rear mass and two wings leave a full-height glazed slot at the canal face.
	_box(ivory,Vector3(.76,height*.5-.16,0),Vector3(12.48,height,10))
	# Projecting coloured end wing continues around the corner onto the inland face.
	_box(end_volume,Vector3(4.60,height*.5-.16,0),Vector3(4.77,height,10.03))
	for span in [Vector2(-5,STAIR_Z-STAIR_WIDTH*.5),Vector2(STAIR_Z+STAIR_WIDTH*.5,5)]:
		var width: float = span.y-span.x
		_box(ivory,Vector3(-6.22,height*.5-.16,(span.x+span.y)*.5),Vector3(1.56,height,width))
	_box(accent,Vector3(-6.97,height*.5,-4.48),Vector3(.12,height,1.02))
	for jamb in [-1,1]:
		_box(accent,Vector3(-7.08,height*.5,STAIR_Z+jamb*(STAIR_WIDTH*.5+.105)),Vector3(.22,height,.21))
	_stair(floors,stair_glow,rail,glazing)
	# Upper glazed bays and their honey-coloured picture frame alternate with a loggia.
	var bay_z := 2.72
	var bay_width := 3.95
	for side in [-1,1]:
		_box(surround,Vector3(-7.11,height*.5+.04,bay_z+side*bay_width*.5),
			Vector3(.32,height,.26))
	for level in floors:
		var y := level*2.8
		if level>0:
			_box(surround,Vector3(-7.11,y,bay_z),Vector3(.32,.18,bay_width+.24))
		for column in 3:
			var z := bay_z+(column-1)*1.22
			var finish := posmod(level+column+variant,4)
			window_batches[finish].append(Transform3D(Basis.from_scale(Vector3(.065,2.34,1.17)),
				position+Vector3(-7.035,y+1.36,z)))
			if column<2:
				_box(rail,Vector3(-7.09,y+1.36,z+.612),Vector3(.10,2.38,.052))
		_box(rail,Vector3(-7.08,y+1.88,bay_z),Vector3(.085,.052,3.73))
		if level>0:
			window_batches[(level+variant)%4].append(Transform3D(Basis.from_scale(Vector3(.06,2.24,1.65)),
				position+Vector3(-7.035,y+1.27,-.7)))
			_balcony(y,-.58,2.18,slab,rail,glazing)
			if level%3==1:
				var shade_pos := Vector3(-7.60,y+2.28,-.58)
				var shade_basis := Basis(Vector3.BACK,.16).scaled_local(Vector3(1.39,.055,2.19))
				batches[accent].append_from(unit_box,0,Transform3D(shade_basis,shade_pos))
				_box(accent,shade_pos+Vector3(-.65,-.15,0),Vector3(.05,.13,2.19))
		for face in [-1,1]:
			for bay in [-4.75,-.20,4.24]:
				var wx: float = bay
				for half in [-1,1]:
					var center := position+Vector3(wx+half*.58,y+1.45,face*5.035)
					window_batches[posmod(variant+level+half+roundi(wx),4)].append(
						Transform3D(Basis.from_scale(Vector3(1.10,1.74,.06)),center))
			if level>0:
				_box(accent,Vector3(.02,y+.42,face*5.52),Vector3(2.94,.72,.10))
				_box(slab,Vector3(.02,y,face*5.27),Vector3(3,.14,.62))
		for bay in [-3.3,0,3.3]:
			window_batches[posmod(level+int(bay)+variant,4)].append(Transform3D(
				Basis.from_scale(Vector3(.065,1.75,1.82)),position+Vector3(7.035,y+1.39,bay)))
	_box(surround,Vector3(-7.11,height-.1,bay_z),Vector3(.32,.24,bay_width+.24))
	_box(parapet,Vector3(0,height-.08,0),Vector3(14.35,.17,10.32))
	_box(ivory,Vector3(.95,height+1.04,.20),Vector3(9.5,2.26,6.20))
	_box(parapet,Vector3(.95,height+2.23,.20),Vector3(10.13,.15,6.64))
	for z in [-1.91,.03,1.97]:
		window_batches[posmod(variant+roundi(z),4)].append(Transform3D(Basis.from_scale(Vector3(.07,1.85,1.73)),
			position+Vector3(-3.84,height+.99,z)))
	# A glazed door and fixed sidelight occupy the centre opening.
	for jamb_z in [-.84,.14,.90]:
		_box(surround,Vector3(-3.90,height+1.0,jamb_z),Vector3(.085,1.97,.068))
	for lintel_y in [.086,1.94]:
		_box(surround,Vector3(-3.90,height+lintel_y,.03),Vector3(.085,.085,1.81))
	_box(rail,Vector3(-3.98,height+.045,-.35),Vector3(.25,.07,1.04))
	_box(rail,Vector3(-3.97,height+1.03,.12),Vector3(.12,.07,.07))
	_box(rail,Vector3(-4.03,height+1.03,.055),Vector3(.04,.04,.17))
	if variant % 2 == 0:
		# Keep the route from the glazed door clear, with seating at one end.
		var tabletop := CylinderMesh.new()
		tabletop.radial_segments = 24
		tabletop.rings = 0
		tabletop.top_radius = .36
		tabletop.bottom_radius = .36
		tabletop.height = .045
		batches[surround].append_from(tabletop,0,Transform3D(Basis.IDENTITY,Vector3(-5.42,height+.74,2.62)))
		_box(rail,Vector3(-5.42,height+.37,2.62),Vector3(.055,.74,.055))
		_box(rail,Vector3(-5.42,height+.03,2.62),Vector3(.40,.045,.40))
		for facing in [-1,1]:
			var seat_z: float = 2.62 + facing*.70
			_box(surround,Vector3(-5.42,height+.45,seat_z),Vector3(.43,.055,.40))
			for across in [-1,1]:
				for along in [-1,1]:
					var back: bool = along == facing
					var leg_height := .85 if back else .44
					_box(rail,Vector3(-5.42+across*.18,height+leg_height*.5,seat_z+along*.17),Vector3(.031,leg_height,.031))
			for back_y in [.66,.79]:
				_box(surround,Vector3(-5.42,height+back_y,seat_z+facing*.17),Vector3(.43,.09,.032))
	# Glazing bays share the existing transparent surface, with posts at each joint.
	for joint in range(-4,5):
		_box(rail,Vector3(-6.87,height+.49,joint*1.20),Vector3(.055,.96,.045))
		_box(rail,Vector3(-6.87,height+.025,joint*1.20),Vector3(.14,.055,.15))
	_glaze(glazing,Vector3(-6.87,height+.49,0),Vector3(.035,.94,9.61))
	_box(rail,Vector3(-6.87,height+.99,0),Vector3(.055,.04,9.68))
	for side in [-1,1]:
		for joint in range(1,5):
			var post_x := -6.87 + joint*1.09
			_box(rail,Vector3(post_x,height+.49,side*4.80),Vector3(.045,.96,.055))
			_box(rail,Vector3(post_x,height+.025,side*4.80),Vector3(.15,.055,.14))
		_glaze(glazing,Vector3(-4.68,height+.49,side*4.80),Vector3(4.35,.94,.035))
		_box(rail,Vector3(-4.68,height+.99,side*4.80),Vector3(4.39,.04,.055))
	for finish in batches:
		var part := MeshInstance3D.new()
		part.mesh = batches[finish].commit()
		add_child(part)
	batches.clear()
