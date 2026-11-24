extends Control

signal picked(index: int)
var player := Vector2.ZERO
var navigator
var stops := PackedVector3Array()

func plot(point: Vector2) -> Vector2:
	return Vector2(22,22) + (point + Vector2(520,85)) * (size - Vector2(44,44)) / Vector2(700,155)

func pin_number(index: int) -> int:
	return 0 if index == 9 else index+1

func configure(route, landmarks: PackedVector3Array, captions: Array) -> void:
	navigator = route
	stops = landmarks
	custom_minimum_size = Vector2(670,285)
	for i in stops.size():
		var pin := Button.new()
		pin.toggle_mode = true
		pin.text = str(pin_number(i))
		pin.tooltip_text = tr(captions[i])
		pin.accessibility_name = tr(captions[i])
		pin.custom_minimum_size = Vector2(34,34)
		pin.pressed.connect(func(): picked.emit(i))
		add_child(pin)
	resized.connect(_position_pins)
	_position_pins()

func _position_pins() -> void:
	var placed: Array[Rect2] = []
	for i in stops.size():
		var pin := get_child(i) as Button
		var desired := plot(Vector2(stops[i].x,stops[i].z)) - pin.size*.5
		var candidates := [desired]
		for rect in placed:
			candidates.append(Vector2(rect.position.x - pin.size.x - 3, desired.y))
			candidates.append(Vector2(rect.end.x + 3, desired.y))
			candidates.append(Vector2(desired.x, rect.position.y - pin.size.y - 3))
			candidates.append(Vector2(desired.x, rect.end.y + 3))
		var shortest := INF
		for candidate: Vector2 in candidates:
			var position_on_map := candidate.clamp(Vector2.ZERO, size - pin.size)
			var area := Rect2(position_on_map, pin.size)
			var distance := position_on_map.distance_squared_to(desired)
			if distance < shortest and not placed.any(func(rect: Rect2): return rect.grow(2).intersects(area)):
				shortest = distance
				pin.position = position_on_map
		placed.append(pin.get_rect())
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#243e39"))
	if not navigator: return
	for edge: Vector2i in navigator.edges:
		draw_line(plot(navigator.graph.get_point_position(edge.x)),plot(navigator.graph.get_point_position(edge.y)),Color("#b6ccbd"),3,true)
	draw_circle(plot(player),8,Color("#242831"),true,-1,true)
	draw_circle(plot(player),5,Color("#ffd369"),true,-1,true)
