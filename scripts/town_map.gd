extends Control

signal picked(index: int)

const MAP_BOUNDS := Rect2(-520,-85,700,155)
var player := Vector2.ZERO
var player_heading := Vector2.ZERO
var player_layer := Control.new()
var navigator
var stops := PackedVector3Array()
var route_preview := PackedVector2Array()
var water_bounds := Rect2()

func plot(point: Vector2) -> Vector2:
	return Vector2(22,22) + (point-MAP_BOUNDS.position) * (size-Vector2(44,44)) / MAP_BOUNDS.size

func pin_number(index: int) -> int:
	return 0 if index == 9 else index+1

func configure(route, landmarks: PackedVector3Array, captions: Array) -> void:
	navigator = route
	stops = landmarks
	custom_minimum_size = Vector2(670,285)
	for i in stops.size():
		var pin := Button.new()
		pin.toggle_mode = true
		pin.focus_mode = Control.FOCUS_CLICK
		pin.text = str(pin_number(i))
		pin.tooltip_text = tr(captions[i])
		pin.accessibility_name = tr(captions[i])
		pin.custom_minimum_size = Vector2(34,34)
		pin.pressed.connect(func(): picked.emit(i))
		add_child(pin)
	player_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_layer)
	player_layer.draw.connect(_draw_player)
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
	var water := MAP_BOUNDS.intersection(water_bounds)
	if water.has_area():
		var top_left := plot(water.position)
		var bottom_right := plot(water.end)
		var banks := Rect2(Vector2(top_left.x,0),Vector2(bottom_right.x-top_left.x,size.y))
		draw_rect(banks,Color("#285a6a"))
		for bank_x in [banks.position.x,banks.end.x]:
			draw_line(Vector2(bank_x,0),Vector2(bank_x,size.y),Color("#81aab2"),1.5,true)
	for edge: Vector2i in navigator.edges:
		draw_line(plot(navigator.graph.get_point_position(edge.x)),plot(navigator.graph.get_point_position(edge.y)),Color("#b6ccbd"),3,true)
	if route_preview.size() >= 2:
		var points := PackedVector2Array()
		for point in route_preview:
			points.append(plot(point))
		draw_polyline(points,Color("#162e2c"),7.0,true)
		draw_polyline(points,Color("#ffd369"),3.5,true)
	for i in stops.size():
		var pin := get_child(i) as Button
		var anchor := plot(Vector2(stops[i].x,stops[i].z))
		if not pin.get_rect().has_point(anchor):
			var tint := Color("#ffd369") if pin.button_pressed else Color("#90ada5")
			draw_line(anchor,pin.get_rect().get_center(),tint,1.5,true)
			draw_circle(anchor,3.0,tint,true,-1,true)
	player_layer.queue_redraw()

func _draw_player() -> void:
	var position_on_map := plot(player)
	player_layer.draw_circle(position_on_map,8,Color("#242831"),true,-1,true)
	player_layer.draw_circle(position_on_map,5,Color("#ffd369"),true,-1,true)
	var direction := (plot(player+player_heading)-position_on_map).normalized()
	if not direction.is_zero_approx():
		var across := direction.orthogonal()
		var arrow := PackedVector2Array([
			position_on_map+direction*17.0,
			position_on_map+direction*6.0+across*5.0,
			position_on_map+direction*6.0-across*5.0,
		])
		player_layer.draw_colored_polygon(arrow,Color("#ffd369"))
		arrow.append(arrow[0])
		player_layer.draw_polyline(arrow,Color("#242831"),1.5,true)
