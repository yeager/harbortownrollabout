extends Control

signal picked(index: int)
var player := Vector2.ZERO
var navigator
var stops := PackedVector3Array()

func plot(point: Vector2) -> Vector2:
	return Vector2(22,22) + (point + Vector2(520,85)) * (size - Vector2(44,44)) / Vector2(700,155)

func configure(route, landmarks: PackedVector3Array, captions: Array) -> void:
	navigator = route
	stops = landmarks
	custom_minimum_size = Vector2(670,285)
	for i in stops.size():
		var pin := Button.new()
		pin.text = str(i+1)
		pin.tooltip_text = tr(captions[i])
		pin.accessibility_name = tr(captions[i])
		pin.custom_minimum_size = Vector2(34,34)
		pin.pressed.connect(func(): picked.emit(i))
		add_child(pin)
	resized.connect(_position_pins)
	_position_pins()

func _position_pins() -> void:
	for i in stops.size():
		var pin := get_child(i) as Button
		pin.position = plot(Vector2(stops[i].x,stops[i].z)) - pin.size*.5

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#243e39"))
	if not navigator: return
	for edge: Vector2i in navigator.edges:
		draw_line(plot(navigator.graph.get_point_position(edge.x)),plot(navigator.graph.get_point_position(edge.y)),Color("#b6ccbd"),3,true)
	draw_circle(plot(player),8,Color("#242831"),true,-1,true)
	draw_circle(plot(player),5,Color("#ffd369"),true,-1,true)
