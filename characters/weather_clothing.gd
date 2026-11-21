extends RefCounted
## Outdoor layers follow each figure's jacket, including on a moving boat or in a cab.

enum Outfit { LIGHT, SCARF, RAIN, WINTER, SLUSH }

var current := -1
var garments: Array[Node3D] = []
var hat_mesh: ArrayMesh
var scarf_mesh: ArrayMesh
var rain_mesh: ArrayMesh
var rain_collar: ArrayMesh
var fabrics: Dictionary = {}

func _init() -> void:
	# Successive rows describe the cross section (height, half-width, half-depth).
	hat_mesh = _sew([
		Vector3(.077,.117,.146), Vector3(.083,.123,.149), Vector3(.113,.124,.150),
		Vector3(.117,.120,.148), Vector3(.125,.122,.147), Vector3(.157,.112,.130),
		Vector3(.184,.087,.102), Vector3(.201,.052,.062), Vector3(.211,.003,.003)
	], true)
	scarf_mesh = _sew([
		Vector3(-.199,.108,.100), Vector3(-.192,.116,.104),
		Vector3(-.178,.106,.094), Vector3(-.169,.114,.103),
		Vector3(-.151,.108,.101), Vector3(-.139,.088,.081)
	], false, .009)
	rain_mesh = _sew([
		Vector3(.066,.161,.192), Vector3(.070,.162,.194),
		Vector3(.102,.123,.148), Vector3(.143,.117,.141),
		Vector3(.174,.091,.109), Vector3(.193,.049,.063), Vector3(.199,.003,.003)
	], false, .028)
	rain_collar = _sew([
		Vector3(-.212,.133,.121), Vector3(-.198,.130,.117),
		Vector3(-.143,.109,.107), Vector3(-.141,.103,.099)
	], false, -.019)

func add_person(torso: MeshInstance3D, shirt: Color) -> void:
	var layers := Node3D.new()
	layers.name = "WeatherClothing"
	# The clothing meshes use the face centre as their tailoring origin.
	layers.position = Vector3(0,.505,-.003)
	torso.add_child(layers)
	var wool := _fabric(shirt.darkened(.35), .96)
	var shell := _fabric(shirt.lerp(Color("#ddb460"), .5), .57)
	_piece(layers, "Scarf", scarf_mesh, wool)
	_piece(layers, "Knit cap", hat_mesh, wool)
	_piece(layers, "Rain hat", rain_mesh, shell)
	_piece(layers, "Storm collar", rain_collar, shell)
	garments.append(layers)
	_dress(layers, current)

func update(season: int, intensity: Vector2) -> void:
	var next := Outfit.LIGHT
	if intensity.y >= .16 or season == 4:
		next = Outfit.WINTER
	if intensity.x >= .22:
		next = Outfit.SLUSH if intensity.y >= .16 else Outfit.RAIN
	elif next == Outfit.LIGHT and season in [1,3]:
		next = Outfit.SCARF
	if current == next:
		return
	current = next
	for layers in garments:
		_dress(layers, current)

func _dress(layers: Node3D, outfit: int) -> void:
	layers.get_node("Scarf").visible = outfit in [Outfit.SCARF, Outfit.WINTER, Outfit.SLUSH]
	layers.get_node("Knit cap").visible = outfit == Outfit.WINTER
	layers.get_node("Rain hat").visible = outfit in [Outfit.RAIN, Outfit.SLUSH]
	layers.get_node("Storm collar").visible = outfit in [Outfit.RAIN, Outfit.SLUSH]

func _fabric(colour: Color, roughness: float) -> StandardMaterial3D:
	var key := Vector2i(colour.to_rgba32(), roundi(roughness*100))
	if not fabrics.has(key):
		var finish := StandardMaterial3D.new()
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		finish.albedo_color = colour
		finish.roughness = roughness
		fabrics[key] = finish
	return fabrics[key]

func _piece(parent: Node3D, label: String, mesh: Mesh, finish: Material) -> void:
	var piece := MeshInstance3D.new()
	piece.name = label
	piece.mesh = mesh
	piece.material_override = finish
	parent.add_child(piece)

func _sew(profile: Array, ribbed := false, slope := 0.0) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 96 if ribbed else 40
	for row in profile.size():
		var ring: Vector3 = profile[row]
		for i in segments:
			var angle := TAU*i/segments
			var rib := 1.0 + (.012*cos(24.0*angle) if ribbed else 0.0)
			var h := ring.x - sin(angle)*slope*(1.0-float(row)/(profile.size()-1))
			surface.add_vertex(Vector3(cos(angle)*ring.y*rib,h,sin(angle)*ring.z*rib))
			if row < profile.size()-1:
				var a := row*segments+i
				var b := row*segments+(i+1)%segments
				for vertex in [a,b,a+segments,b,b+segments,a+segments]:
					surface.add_index(vertex)
	surface.generate_normals()
	return surface.commit()
