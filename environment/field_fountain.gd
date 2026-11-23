extends Node3D

# Fält, Thomas Nordström (2003). https://sv.wikipedia.org/wiki/Fält_(fontän)
var jets: Array[CPUParticles3D] = []
var covers := Node3D.new()
var season := -1
var elapsed := 0.0

func finish(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func place(parent: Node3D, mesh: Mesh, position_local: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = position_local
	parent.add_child(part)

func _ready() -> void:
	add_child(covers)
	var slab := BoxMesh.new()
	slab.size = Vector3(2.47,.06,2.47)
	slab.material = finish(Color("#8baf95"),.82)
	var dome := SphereMesh.new()
	dome.is_hemisphere = true
	dome.radius = .46
	dome.height = .46
	dome.material = finish(Color("#272c2a"),.19)
	var lid := SphereMesh.new()
	lid.is_hemisphere = true
	lid.radius = .50
	lid.height = .54
	var glass := finish(Color(.68,.9,.96,.36),.15)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lid.material = glass
	var drop := SphereMesh.new()
	drop.radius = .034
	drop.height = .13
	drop.radial_segments = 6
	drop.rings = 2
	drop.material = finish(Color("#b6e7ef"),.13)
	for row in 4:
		for column in 4:
			var base := Vector3((column-1.5)*2.5,.045,(row-1.5)*2.5)
			place(self,slab,base)
			place(self,dome,base+Vector3.UP*.03)
			place(covers,lid,base+Vector3.UP*.03)
			var jet := CPUParticles3D.new()
			jet.emitting = false
			jet.mesh = drop
			jet.amount = 100
			jet.lifetime = 1.15
			jet.direction = Vector3.UP
			jet.spread = 6
			jet.gravity = Vector3.DOWN*9.8
			jet.position = base+Vector3.UP*.49
			add_child(jet)
			jets.append(jet)
	set_season(0)

func set_season(value: int) -> void:
	if season == value:
		return
	season = value
	covers.visible = value == 4
	set_process(value == 2)
	for jet in jets:
		jet.visible = value == 2
		jet.emitting = value == 2

func _process(delta: float) -> void:
	elapsed += delta
	for index in jets.size():
		var speed := 3.5 + 2.2*sin(elapsed*1.2 + index*.85)
		jets[index].initial_velocity_min = speed*.93
		jets[index].initial_velocity_max = speed
