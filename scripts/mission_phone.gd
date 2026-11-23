extends VBoxContainer

var toggle_key := KEY_T
var open_button := Button.new()
var title := Label.new()
var large_text := false
var recovery_hint := Label.new()
var handset := PanelContainer.new()
var messages: Array[String] = []
var job_heading := Label.new()
const FOOT_PICTURES := {
	"Find the red shoe on the pavement.": 0,
	"Bring the red shoe back to the neighbour.": 1,
	"Find the cat with white paws.": 2,
	"Walk back to the neighbour with the cat.": 3,
}
enum Action { COLLECT, DELIVER, BOARD, ALIGHT, INSPECT, AID, ICE_CREAM, SOUP, BIN, TOW }
var vehicle_action := Action.COLLECT
var action_rows := VBoxContainer.new()
var pictured_jobs := PackedStringArray()
var star_progress := Label.new()
var memory_scroll := ScrollContainer.new()
var memory_strip := HBoxContainer.new()
var star_album := HBoxContainer.new()
var inbox := Label.new()
var history_scroll := ScrollContainer.new()
var message_tone := AudioStreamPlayer.new()
var unread := 0
var current_job := ""
var foot_jobs := PackedStringArray()
var repeat_job := Button.new()
var job_voice := AudioStreamPlayer.new()
var spoken_locale := ""
var spoken_jobs := PackedStringArray()
var take_job := Button.new()

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
	message_tone.stream = preload("res://audio/sms.wav")
	message_tone.volume_db = -9
	add_child(message_tone)
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
	title.text = "Messages"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#12594f"))
	content.add_child(title)
	recovery_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recovery_hint.add_theme_color_override("font_color", Color("#183a38"))
	content.add_child(recovery_hint)
	for label in [job_heading, inbox, star_progress]:
		label.add_theme_color_override("font_color", Color("#183a38"))
	inbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inbox.add_theme_font_size_override("font_size", 16)
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.follow_focus = true
	job_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job_heading.add_theme_font_size_override("font_size",18)
	take_job.text = "Take a job"
	content.add_child(star_progress)
	content.add_child(star_album)
	memory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	memory_scroll.custom_minimum_size.y = 55
	content.add_child(memory_scroll)
	memory_scroll.add_child(memory_strip)
	content.add_child(take_job)
	content.add_child(job_heading)
	content.add_child(action_rows)
	repeat_job.text = "Say again"
	repeat_job.icon = preload("res://branding/repeat-job.svg")
	repeat_job.custom_minimum_size.y = 44
	repeat_job.pressed.connect(_repeat_instruction)
	content.add_child(repeat_job)
	job_voice.bus = &"Speech"
	add_child(job_voice)
	content.add_child(history_scroll)
	inbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_scroll.add_child(inbox)
	set_large_text(large_text)
	handset.hide()
	handset.visibility_changed.connect(_on_visibility_changed)
	refresh()

func set_large_text(enabled: bool) -> void:
	large_text = enabled
	var reading_theme := Theme.new()
	if enabled:
		for control in ["Label", "Button"]:
			reading_theme.set_font_size("font_size", control, 22)
	theme = reading_theme
	title.add_theme_font_size_override("font_size", 30 if enabled else 22)
	job_heading.add_theme_font_size_override("font_size", 25 if enabled else 18)
	inbox.add_theme_font_size_override("font_size", 22 if enabled else 16)
	handset.custom_minimum_size = Vector2(370, 550) if enabled else Vector2(248, 350)
	reset_size()

func _add_phone_detail(body: VBoxContainer, dimensions: Vector2) -> void:
	var detail := ColorRect.new()
	detail.custom_minimum_size = dimensions
	detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail.color = Color("#91a3ad")
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(detail)

func _repeat_instruction() -> void:
	var playlist := AudioStreamPlaylist.new()
	playlist.loop = false
	spoken_locale = TranslationServer.get_locale()
	var jobs := _active_jobs()
	spoken_jobs = jobs.duplicate()
	playlist.stream_count = jobs.size()
	for i in jobs.size():
		var path := "res://audio/dispatch/%s_%s.ogg" % [spoken_locale.get_slice("_", 0), jobs[i].md5_text()]
		if not ResourceLoader.exists(path): return
		playlist.set_list_stream(i, load(path))
	job_voice.stream = playlist
	job_voice.play()

func _on_visibility_changed() -> void:
	if not handset.is_visible_in_tree(): job_voice.stop()
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

func _active_jobs() -> PackedStringArray:
	if not foot_jobs.is_empty(): return foot_jobs
	if not current_job.is_empty(): return PackedStringArray([current_job])
	return PackedStringArray()

func receive(body: String) -> void:
	# Preserve the line being read when new SMS push older ones down the screen.
	var offset := history_scroll.scroll_vertical
	var added_height := 0
	if handset.is_visible_in_tree() and offset > 0 and body not in _active_jobs():
		var old_text := inbox.text
		var old_height := inbox.get_minimum_size().y
		inbox.text = tr(body) + "\n\n" + old_text
		added_height = roundi(inbox.get_minimum_size().y - old_height)
		history_scroll.get_v_scroll_bar().max_value += added_height
	messages.push_front(body)
	if is_visible_in_tree(): message_tone.play()
	if messages.size() > HISTORY_LIMIT: messages.pop_back()
	if not handset.is_visible_in_tree(): unread=mini(unread+1,messages.size())
	refresh()
	if added_height > 0:
		history_scroll.scroll_vertical = offset + added_height

func toggle() -> void:
	handset.visible=not handset.visible
	if handset.visible: unread=0
	refresh()

func _show_action_rows(jobs: PackedStringArray) -> void:
	if jobs == pictured_jobs: return
	pictured_jobs = jobs.duplicate()
	for row in action_rows.get_children():
		action_rows.remove_child(row)
		row.queue_free()
	for job in jobs:
		var row := HBoxContainer.new()
		var atlas := AtlasTexture.new()
		var cell := int(vehicle_action)
		if FOOT_PICTURES.has(job):
			atlas.atlas = preload("res://branding/foot-job-actions.svg")
			cell = FOOT_PICTURES[job]
		else:
			atlas.atlas = preload("res://branding/vehicle-job-actions.svg")
		atlas.region = Rect2(cell * 48, 0, 48, 48)
		var picture := TextureRect.new()
		picture.texture = atlas
		picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(picture)
		var label := Label.new()
		label.text = job
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color("#183a38"))
		row.add_child(label)
		action_rows.add_child(row)

func refresh() -> void:
	open_button.text = tr("Close phone · %s" if handset.visible else "Phone · %s") % OS.get_keycode_string(toggle_key)
	if unread>0: open_button.text+="  (%d)" % unread
	var lines:=PackedStringArray()
	var active := _active_jobs()
	job_heading.visible = not active.is_empty()
	repeat_job.visible = job_heading.visible
	if job_voice.playing and (active != spoken_jobs or spoken_locale != TranslationServer.get_locale()):
		job_voice.stop()
	job_heading.text = tr("Current jobs") if active.size() > 1 else tr("Current job")
	_show_action_rows(active)
	action_rows.visible = not active.is_empty()
	for body in messages:
		if body not in active:
			lines.append(tr(body))
	history_scroll.visible = not lines.is_empty() or active.is_empty()
	inbox.text="\n\n".join(lines) if not lines.is_empty() else tr("No messages yet.")

func update_star_album(sites: Dictionary, collected: PackedStringArray) -> void:
	if star_album.get_child_count() == 0:
		for site in sites:
			var stamp := Label.new()
			stamp.name = site
			stamp.add_theme_font_size_override("font_size", 21)
			star_album.add_child(stamp)
	for stamp: Label in star_album.get_children():
		var found := collected.has(str(stamp.name))
		stamp.text = "★" if found else "☆"
		stamp.add_theme_color_override("font_color", Color("#87520c") if found else Color("#516963"))

func update_mission_album(sheets: Dictionary, memories: PackedStringArray, shops, purchases: Dictionary) -> void:
	for id in memories:
		var parts := id.split("/")
		if parts.size() != 2 or not sheets.has(parts[0]) or not parts[1].is_valid_int(): continue
		var cell := parts[1].to_int()
		var sheet: Texture2D = sheets[parts[0]]
		if cell < 0 or (cell+1)*48 > sheet.get_width(): continue
		var stamp_name := "%s_%d" % [parts[0],cell]
		if memory_strip.has_node(stamp_name): continue
		var picture := AtlasTexture.new()
		picture.atlas = sheet
		picture.region = Rect2(cell*48,0,48,48)
		var stamp := TextureRect.new()
		stamp.name = stamp_name
		stamp.texture = picture
		memory_strip.add_child(stamp)
	# Purchased snacks keep their entry after the last serving is eaten.
	for product: String in purchases:
		var stamp_name := "Purchase_" + product.validate_node_name()
		var stamp := memory_strip.get_node_or_null(stamp_name) as TextureRect
		if not stamp:
			for shop in shops.MENUS.size():
				var item: int = shops.MENUS[shop].find(product)
				if item < 0: continue
				stamp = TextureRect.new()
				stamp.name = stamp_name
				stamp.texture = shops._product_icon(shop,item)
				stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				stamp.custom_minimum_size = Vector2(48,48)
				memory_strip.add_child(stamp)
				break
		if stamp:
			stamp.tooltip_text = tr(product)
			stamp.accessibility_name = tr(product)
	memory_scroll.visible = memory_strip.get_child_count() > 0
