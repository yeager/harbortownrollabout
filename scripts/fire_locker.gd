extends Node3D

var work_lights: Array[SpotLight3D] = []
var reflector_finish := StandardMaterial3D.new()
var panel: MeshInstance3D
var fittings: Array[MeshInstance3D] = []
var closed_height := 0.0
var dispatch := Label3D.new()
var speed_needle: Node3D
var lift := 0.0

func fit(model: Node3D) -> void:
	# Seat the complete optical assemblies back into the moulded cab corners.
	for pattern in ["Cab headlamp seal*", "Cab projector*", "Cab reflector*", "Cab amber signal*", "Swept transparent headlamp cover*"]:
		for part: MeshInstance3D in model.find_children(pattern, "MeshInstance3D", true, false):
			part.position.z -= .010
	var mirror_housing := StandardMaterial3D.new()
	mirror_housing.albedo_color = Color("#242628")
	mirror_housing.roughness = .76
	for pattern in ["Main mirror shell*", "Wide angle mirror shell*"]:
		for shell: MeshInstance3D in model.find_children(pattern, "MeshInstance3D", true, false):
			shell.material_override = mirror_housing
	var display: MeshInstance3D = model.find_child("Dispatch terminal display", true, false)
	var screen := display.get_aabb()
	display.add_child(dispatch)
	dispatch.position = screen.get_center()
	dispatch.position.z = screen.position.z - .002
	dispatch.rotation.y = PI
	dispatch.font_size = 48
	dispatch.pixel_size = .0007
	dispatch.modulate = Color("#122f37")
	dispatch.outline_size = 0
	dispatch.text = "711"
	speed_needle = model.find_child("Fire speed needle", true, false)
	panel = model.find_child("Roller shutter",true,false)
	var carrier := panel.get_parent()
	carrier.add_child(self)
	reflector_finish.albedo_color = Color("#e9edf0")
	reflector_finish.roughness = .23
	reflector_finish.emission = Color("#ffefd2")
	for reflector in model.find_children("Floodlight reflector*","MeshInstance3D",true,false):
		reflector.material_override = reflector_finish
	for lens: MeshInstance3D in model.find_children("Rear floodlight glazing*","MeshInstance3D",true,false):
		var lamp := SpotLight3D.new()
		carrier.add_child(lamp)
		lamp.position = lens.transform * lens.get_aabb().get_center() + Vector3.FORWARD*.04
		lamp.rotation_degrees.x = -35
		lamp.spot_angle = 40
		lamp.spot_range = 9
		lamp.light_energy = 3
		lamp.light_color = reflector_finish.emission
		lamp.hide()
		work_lights.append(lamp)
	var ribbed_glass := ShaderMaterial.new()
	ribbed_glass.shader = preload("res://environment/fire_lens_ribs.gdshader")
	for pattern in ["Rear indicator lens*", "Tail lamp*", "Reversing lens*"]:
		for lens: MeshInstance3D in model.find_children(pattern, "MeshInstance3D", true, false):
			lens.material_overlay = ribbed_glass
			lens.tree_entered.connect(func(): lens.material_overlay = ribbed_glass)
			lens.tree_exiting.connect(func(): lens.material_overlay = null)
	for blind: MeshInstance3D in model.find_children("Rear roller blind*", "MeshInstance3D", true, false):
		_fit_rear_reflector(blind)
		_fit_rear_pull_bar(blind)
	closed_height = -2.0*panel.get_aabb().position.y # The mesh origin is halfway up the closed blind.
	for part in carrier.get_children():
		if not part is MeshInstance3D: continue
		if absf(part.position.z-panel.position.z) > .56 or part.position.x > -1.14: continue
		if not (part.name.begins_with("Locker reflective") or part.name.begins_with("Shutter seam") or part.name.begins_with("Shutter lift") or part.name.begins_with("Shutter lock") or part.name.begins_with("Shutter keyway") or part.name.begins_with("Lift handle bracket")): continue
		part.set_meta("closed_y",part.position.y)
		fittings.append(part)
	panel.set_meta("closed_y",panel.position.y)
	# Show the wound supply hose against the dark liner as the panel retracts.
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("#bf9656")
	rubber.roughness = .86
	for i in 5:
		var coil := MeshInstance3D.new()
		var tube := TorusMesh.new()
		tube.outer_radius = .12+i*.065
		tube.inner_radius = tube.outer_radius-.061
		tube.rings = 32
		tube.ring_segments = 8
		coil.mesh = tube
		coil.material_override = rubber
		coil.rotation.z = PI*.5
		coil.scale.y = .26
		coil.position = Vector3(-1.151,1.64,panel.position.z)
		add_child(coil)

func _fit_rear_pull_bar(blind: MeshInstance3D) -> void:
	var bounds := blind.get_aabb()
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("#c8ccce")
	steel.metallic = .82
	steel.roughness = .32
	var half_span := bounds.size.x * .39
	var base := Vector3(0, bounds.position.y + .09, bounds.position.z)
	var tube := CylinderMesh.new()
	tube.top_radius = .016
	tube.bottom_radius = .016
	tube.height = half_span * 2
	tube.rings = 0
	tube.material = steel
	var bar := MeshInstance3D.new()
	bar.name = "Rear shutter pull bar"
	bar.mesh = tube
	bar.rotation.z = PI / 2
	bar.position = base + Vector3.FORWARD * .06
	blind.add_child(bar)
	var bracket := BoxMesh.new()
	bracket.size = Vector3(.034,.055,.078)
	bracket.material = steel
	for side in [-1,1]:
		var foot := MeshInstance3D.new()
		foot.mesh = bracket
		foot.position = base + Vector3(side * half_span,0,-.03)
		blind.add_child(foot)

func _fit_rear_reflector(blind: MeshInstance3D) -> void:
	var bounds := blind.get_aabb()
	var reflector := MeshInstance3D.new()
	reflector.name = "Rear circular reflector"
	var lens := CylinderMesh.new()
	lens.top_radius = .042
	lens.bottom_radius = .045
	lens.height = .014
	lens.rings = 0
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("#bb2024")
	finish.roughness = .25
	lens.material = finish
	reflector.mesh = lens
	reflector.rotation.x = -PI / 2
	var outside := signf(blind.position.x)
	reflector.position = Vector3(outside * (bounds.size.x * .5 + .045), bounds.position.y - .025, bounds.position.z - .008)
	blind.add_child(reflector)

func set_destination(destination: String) -> void:
	dispatch.text = "711" if destination.is_empty() else "711\n" + destination
	var width := ThemeDB.fallback_font.get_string_size(destination, HORIZONTAL_ALIGNMENT_LEFT, -1, dispatch.font_size).x
	dispatch.pixel_size = minf(.0007, .245 / maxf(1, width))

func set_road_speed(metres_per_second: float) -> void:
	speed_needle.rotation.z = deg_to_rad(-135.0 + 270.0 * clampf(absf(metres_per_second) * 3.6 / 120.0, 0.0, 1.0))

func advance(delta: float, opening: bool, reversing := false) -> void:
	var active := opening or reversing
	if reflector_finish.emission_enabled != active:
		reflector_finish.emission_enabled = active
		for lamp in work_lights: lamp.visible = active
	var next := move_toward(lift,closed_height-.055 if opening else 0.0,delta*1.6)
	if next == lift: return
	lift = next
	var centre := float(panel.get_meta("closed_y"))
	var top := centre + closed_height*.5
	panel.position.y = centre + lift*.5
	panel.scale.y = 1.0-lift/closed_height
	for part in fittings:
		part.position.y = float(part.get_meta("closed_y"))+lift
		part.visible = part.position.y < top
