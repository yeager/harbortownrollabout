extends RefCounted
## One texel per quarter metre. Both tools stamp in world coordinates.
const DENSITY := 4
var area: Rect2
var image: Image
var texture: ImageTexture
var has_ploughed := false
var dirty := false
var upload_time := 0.0

func _init(bounds: Rect2) -> void:
	area = bounds
	image = Image.create_empty(int(bounds.size.x)*DENSITY, int(bounds.size.y)*DENSITY, false, Image.FORMAT_RG8)
	texture = ImageTexture.create_from_image(image)

func attach(surface: ShaderMaterial) -> void:
	surface.set_shader_parameter("work_map", texture)
	surface.set_shader_parameter("work_bounds", Vector4(area.position.x,area.position.y,area.size.x,area.size.y))

func sweep(start: Transform3D, finish: Transform3D, left: Vector3, right: Vector3, mowing: bool) -> void:
	var travel := maxf((start * left).distance_to(finish * left), (start * right).distance_to(finish * right))
	var steps := maxi(1, ceili(travel*DENSITY*2))
	var samples := maxi(1, ceili(left.distance_to(right)*DENSITY*2))
	for i in range(steps+1):
		var pose := start.interpolate_with(finish,float(i)/steps)
		for j in range(samples+1):
			var point := pose * left.lerp(right,float(j)/samples)
			var flat := Vector2(point.x,point.z)
			if not area.has_point(flat):
				continue
			var p := Vector2i((flat-area.position)*DENSITY)
			var colour := image.get_pixelv(p)
			if mowing:
				if colour.g == 1.0: continue
				colour.g = 1.0
			else:
				if colour.r == 1.0: continue
				colour.r = 1.0
				has_ploughed = true
			image.set_pixelv(p,colour)
			dirty = true

func cleared_at(point: Vector3) -> bool:
	var flat := Vector2(point.x,point.z)
	return has_ploughed and area.has_point(flat) and image.get_pixelv(Vector2i((flat-area.position)*DENSITY)).r > .5

func update(delta: float, snow: float) -> void:
	if snow <= .01 and has_ploughed:
		# Preserve the green mowing channel when the snow melts.
		var data := image.get_data()
		for i in range(0,data.size(),2): data[i] = 0
		image.set_data(image.get_width(),image.get_height(),false,Image.FORMAT_RG8,data)
		has_ploughed = false
		dirty = true
	upload_time -= delta
	if dirty and upload_time <= 0:
		texture.update(image)
		dirty = false
		upload_time = .10
