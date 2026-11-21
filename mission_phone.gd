extends VBoxContainer

var open_button := Button.new()
var handset := PanelContainer.new()
var messages: Array[String] = []
var inbox := Label.new()
var unread := 0
var current_job := ""

const SOCIAL := ["Have you done your homework? — Mum", "A duck just beat me to the ferry. — Grandpa", "I saved you a bun. It only has one tiny bite missing! — Mum"]
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
	var finish := StyleBoxFlat.new()
	finish.bg_color=Color("#152b33")
	finish.set_corner_radius_all(16)
	for side in [SIDE_TOP,SIDE_BOTTOM,SIDE_LEFT,SIDE_RIGHT]:
		finish.set_content_margin(side,16)
	handset.add_theme_stylebox_override("panel",finish)
	add_child(handset)
	inbox.custom_minimum_size.x=280
	inbox.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	inbox.add_theme_font_size_override("font_size",18)
	handset.add_child(inbox)
	handset.hide()
	handset.visibility_changed.connect(_on_visibility_changed)
	refresh()

func _on_visibility_changed() -> void:
	if handset.is_visible_in_tree():
		unread=0
		refresh()

func receive(body: String) -> void:
	messages.push_front(body)
	if messages.size()>4: messages.pop_back()
	if not handset.is_visible_in_tree(): unread=mini(unread+1,messages.size())
	refresh()

func toggle() -> void:
	handset.visible=not handset.visible
	if handset.visible: unread=0
	refresh()

func refresh() -> void:
	open_button.text=tr("Phone · T")
	if unread>0: open_button.text+="  (%d)" % unread
	var lines:=PackedStringArray()
	if not current_job.is_empty():
		lines.append(tr("Current job") + "\n" + tr(current_job))
	for body in messages:
		if body != current_job:
			lines.append(tr(body))
	inbox.text="\n\n".join(lines) if not lines.is_empty() else tr("No messages yet.")
