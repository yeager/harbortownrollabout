extends Node3D

const HEIGHT := 12.0
const COLORS := ["#fa1532", "#ffb312", "#12d56b", "#265dff", "#cd22eb"]
var bulbs: Array[StandardMaterial3D] = []
var glow := OmniLight3D.new()
var obstacle: AABB

func _ready() -> void:
	var spruce := preload("res://environment/gran.glb").instantiate() as Node3D
	add_child(spruce)
	var bounds: AABB = get_parent()._model_bounds(spruce, spruce)
	var factor := HEIGHT / bounds.size.y
	spruce.scale *= factor
	spruce.position.y = -bounds.position.y * factor
	var radius := maxf(bounds.size.x, bounds.size.z) * factor * .5
	var ornament := SphereMesh.new()
	ornament.radius = .083
	ornament.height = .166
	ornament.radial_segments = 10
	ornament.rings = 5
	for color in COLORS:
		var finish := StandardMaterial3D.new()
		finish.albedo_color = Color(color)
		finish.emission = Color(color)
		finish.emission_enabled = true
		bulbs.append(finish)
	# Hang each bulb just outside the outermost branch in its height and angle band.
	var reaches := PackedFloat32Array()
	reaches.resize(160)
	for part: MeshInstance3D in spruce.find_children("*", "MeshInstance3D", true, false):
		var pose := global_transform.affine_inverse() * part.global_transform
		for surface in part.mesh.get_surface_count():
			for vertex: Vector3 in part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var tip := pose * vertex
				var layer := (tip.y - 1.0) * 159.0 / (HEIGHT - 1.5)
				for index in range(maxi(0, ceili(layer - 6)), mini(160, floori(layer + 6) + 1)):
					var axis := Vector3(cos(index*.32), 0, sin(index*.32))
					if absf(axis.cross(tip).y) < .48:
						reaches[index] = maxf(reaches[index], tip.dot(axis))
	for i in 160:
		var progress := i / 159.0
		var y := lerpf(1.0, HEIGHT - .5, progress)
		var direction := Vector3(cos(i*.32), 0, sin(i*.32))
		var reach := reaches[i]
		if reach == 0: reach = radius * (1.0 - progress)
		var lamp := MeshInstance3D.new()
		lamp.mesh = ornament
		lamp.material_override = bulbs[i % bulbs.size()]
		lamp.position = direction * (reach + .08) + Vector3.UP*y
		add_child(lamp)
	add_child(glow)
	glow.position.y = 2
	glow.light_color = Color("#ffd995")
	glow.omni_range = 7
	obstacle = AABB(position - Vector3(.65,.6,.65), Vector3(1.3,3,1.3))
	hide()

func update_lights(snowy_winter: bool, darkness: float) -> void:
	if visible != snowy_winter:
		visible = snowy_winter
		if visible: get_parent().roadside_solids.append(obstacle)
		else: get_parent().roadside_solids.erase(obstacle)
	if not visible: return
	var strength := smoothstep(.12,.72,darkness)
	for finish in bulbs:
		finish.emission_energy_multiplier = strength * 1.25
	glow.light_energy = strength * .85
	glow.visible = strength > 0
