extends VBoxContainer

var open_button := Button.new()
var handset := PanelContainer.new()
var messages: Array[String] = []
var job_heading := Label.new()
var inbox := Label.new()
var history_scroll := ScrollContainer.new()
var unread := 0
var current_job := ""

const HISTORY_LIMIT := 32

const SOCIAL := [
	"Have you done your homework? — Mum",
	"A duck just beat me to the ferry. — Grandpa",
	"I saved you a bun. It only has one tiny bite missing! — Mum",
	"I said hello to someone on the tram. It was my reflection. — Grandpa",
	"Your missing sock turned up. The teddy bear was wearing it as a hat. — Mum",
	"I tried to wave at you from Lotten. I waved my sandwich. The gulls waved back! — Grandpa",
	"Could you pick up a cinnamon bun? Your dad bought cinnamon and a bun separately. — Mum",
]
var social_index := 0
var social_wait := 75.0

func reset_social() -> void:
	social_index = 0
	social_wait = 75.0

func advance(delta: float) -> void:
	if social_index >= SOCIAL.size(): return
	social_wait -= delta
	if social_wait <= 0:
		receive(SOCIAL[social_index])
		social_index += 1
		social_wait = 150.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position=Vector2(22,106)
	custom_minimum_size.x=200
	open_button.custom_minimum_size.y=44
	open_button.pressed.connect(toggle)
	add_child(open_button)
	handset.custom_minimum_size = Vector2(248, 350)
	handset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#162029")
	frame.border_color = Color("#82939d")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(24)
	for side in [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]:
		frame.set_content_margin(side, 9)
	handset.add_theme_stylebox_override("panel", frame)
	add_child(handset)
	var body := VBoxContainer.new()
	handset.add_child(body)
	_add_phone_detail(body, Vector2(38, 4))
	var screen := PanelContainer.new()
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color("#e6f3ef")
	glass.set_corner_radius_all(15)
	for side in [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]:
		glass.set_content_margin(side, 12)
	screen.add_theme_stylebox_override("panel", glass)
	body.add_child(screen)
	_add_phone_detail(body, Vector2(62, 3))
	var content := VBoxContainer.new()
	screen.add_child(content)
	var title := Label.new()
	title.text = "SMS"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#12594f"))
	content.add_child(title)
	for label in [job_heading, inbox]:
		label.add_theme_color_override("font_color", Color("#183a38"))
	inbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inbox.add_theme_font_size_override("font_size", 16)
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.follow_focus = true
	job_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job_heading.add_theme_font_size_override("font_size",18)
	content.add_child(job_heading)
	content.add_child(history_scroll)
	inbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_scroll.add_child(inbox)
	handset.hide()
	handset.visibility_changed.connect(_on_visibility_changed)
	refresh()

func _add_phone_detail(body: VBoxContainer, dimensions: Vector2) -> void:
	var detail := ColorRect.new()
	detail.custom_minimum_size = dimensions
	detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail.color = Color("#91a3ad")
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(detail)

func _on_visibility_changed() -> void:
	if handset.is_visible_in_tree():
		unread=0
		history_scroll.scroll_vertical = 0
		refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not handset.is_visible_in_tree() or not event is InputEventKey or not event.pressed: return
	var bar := history_scroll.get_v_scroll_bar()
	match event.keycode:
		KEY_PAGEUP: history_scroll.scroll_vertical -= int(bar.page)
		KEY_PAGEDOWN: history_scroll.scroll_vertical += int(bar.page)
		KEY_HOME: history_scroll.scroll_vertical = 0
		KEY_END: history_scroll.scroll_vertical = int(bar.max_value)
		_: return
	get_viewport().set_input_as_handled()

func receive(body: String) -> void:
	messages.push_front(body)
	if messages.size() > HISTORY_LIMIT: messages.pop_back()
	if not handset.is_visible_in_tree(): unread=mini(unread+1,messages.size())
	refresh()

func toggle() -> void:
	handset.visible=not handset.visible
	if handset.visible: unread=0
	refresh()

func refresh() -> void:
	open_button.text=tr("Close phone · T") if handset.visible else tr("Phone · T")
	if unread>0: open_button.text+="  (%d)" % unread
	var lines:=PackedStringArray()
	job_heading.visible = not current_job.is_empty()
	job_heading.text = tr("Current job") + "\n" + tr(current_job) if job_heading.visible else ""
	for body in messages:
		if body != current_job:
			lines.append(tr(body))
	history_scroll.visible = not lines.is_empty() or current_job.is_empty()
	inbox.text="\n\n".join(lines) if not lines.is_empty() else tr("No messages yet.")
