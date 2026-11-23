extends Control

var show_wheel := true:
	set(value):
		if value != show_wheel:
			show_wheel = value
			queue_redraw()
var reverse_pedal := false:
	set(value):
		if value != reverse_pedal:
			reverse_pedal = value
			queue_redraw()
var steering := 0.0
var gas := false
var brake := false
var reverse := false
var ink := Color("#e8eff1")
var backing := Color("#172b32")

func set_controls(turn: float, accelerating: bool, braking: bool, reversing := false) -> void:
	if steering != turn or gas != accelerating or brake != braking or reverse != reversing:
		steering = turn
		gas = accelerating
		brake = braking
		reverse = reversing
		queue_redraw()

func over_brake_pedal(point: Vector2) -> bool:
	var base := Vector2(size.x-216,size.y-132)
	return Rect2(base+Vector2(98,0),Vector2(98,106)).has_point(point)

func _draw() -> void:
	if show_wheel:
		var center := Vector2(76,size.y-80)
		draw_circle(center,53,backing,true,-1,true)
		draw_set_transform(center,steering*1.2)
		draw_arc(Vector2.ZERO,39,0,TAU,64,ink,6,true)
		for angle in [-0.18, PI+0.18, PI/2]:
			draw_line(Vector2.ZERO,Vector2.from_angle(angle)*37,ink,5,true)
		draw_circle(Vector2.ZERO,10,ink,true,-1,true)
		draw_line(Vector2(0,-42),Vector2(0,-34),Color("#42dcb1"),5,true)
		draw_set_transform(Vector2.ZERO)
	var base := Vector2(size.x-216,size.y-132)
	draw_style_box(_panel,Rect2(base,Vector2(196,106)))
	_draw_pedal(base+Vector2(48,39),true,gas,tr("Gas"),tr("Left"))
	_draw_pedal(base+Vector2(148,39),false,brake or reverse,tr("Reverse") if reverse_pedal or reverse else tr("Brake"),"S / ↓" if reverse and not brake else tr("Right"))

var _panel := StyleBoxFlat.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.bg_color = backing
	_panel.set_corner_radius_all(14)

func _draw_pedal(center: Vector2, narrow: bool, pressed: bool, label: String, button: String) -> void:
	var accent := Color("#64dcab") if narrow else Color("#ffb18e")
	var w := 21.0 if narrow else 40.0
	var h := 40.0 if narrow else 27.0
	var foot := center + Vector2.DOWN * (4 if pressed else 0)
	var pedal := Rect2(foot-Vector2(w,h)/2,Vector2(w,h))
	draw_rect(pedal, accent)
	if pressed:
		draw_rect(pedal.grow(3), ink, false, 2)
	for groove in [-1,0,1]:
		var p := foot + Vector2(0,groove*h*.23)
		draw_line(p-Vector2(w*.33,0),p+Vector2(w*.33,0),backing,2,true)
	draw_string(ThemeDB.fallback_font,center+Vector2(-46,38),label,HORIZONTAL_ALIGNMENT_CENTER,92,17,ink)
	draw_string(ThemeDB.fallback_font,center+Vector2(-13,57),button,HORIZONTAL_ALIGNMENT_LEFT,61,13,ink)

	if reverse and not brake and not narrow:
		return
	var mouse := center + Vector2(-24,52)
	draw_arc(mouse,8,0,TAU,32,ink,1.5,true)
	draw_line(mouse-Vector2(8,0),mouse+Vector2(8,0),ink,1,true)
	draw_line(mouse,mouse-Vector2(0,8),ink,1,true)
	var start := PI if narrow else 1.5*PI
	var sector := PackedVector2Array([mouse])
	for i in range(9):
		sector.append(mouse+Vector2.from_angle(start+i*PI/16)*7)
	draw_colored_polygon(sector,accent)
