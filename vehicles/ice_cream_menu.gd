extends Node3D

const FLAVOURS := ["Berry Boing", "Minty Moo", "Purple Hiccup", "Lemon Comet", "Melon Wiggle", "Blue Blizzard"]

var captions: Array[Label3D] = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		for label in captions: fit_caption(label)

func _ready() -> void:
	add_caption("Ice cream", Vector3(0, 2.67, 1.035), .004, .92, 0)
	for side in [-1.0, 1.0]:
		add_caption("Harbor Town Ice Cream", Vector3(side * 1.08, 2.36, -1.25), .005, 2.9, side * PI / 2)
	add_caption("Our ice creams", Vector3(0,2.32,-3.06), .0034, 1.55)
	for i in FLAVOURS.size():
		var center := Vector3(.55 - (i % 3)*.55, 1.78 - floori(i/3.0)*.47, -3.06)
		add_caption(FLAVOURS[i], center, .00145, .49)

func add_caption(words: String, center: Vector3, scale_per_pixel: float, width: float, facing: float = PI) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = center
	label.rotation.y = facing
	label.font_size = 48
	label.outline_size = 0
	label.modulate = Color("#12284a")
	add_child(label)
	label.set_meta("design_scale",scale_per_pixel)
	label.set_meta("width",width)
	captions.append(label)
	fit_caption(label)

func fit_caption(label: Label3D) -> void:
	var length := ThemeDB.fallback_font.get_string_size(label.tr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
	label.pixel_size = minf(label.get_meta("design_scale"), float(label.get_meta("width")) / maxf(length,1.0))
