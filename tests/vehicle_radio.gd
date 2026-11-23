extends SceneTree

var game
var locale_index := 0
var slot := 0
var tracks := PackedStringArray()
var heard: Dictionary = {}
var previous := ""
var deadline := 0
var phase := "locale"
const LOCALES := ["sv", "fr", "de", "es", "fi", "nb", "en"]

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	TranslationServer.set_locale(LOCALES[0])
	game._start_game()

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_key_input(event)

func fail(message: String) -> void:
	printerr(message)
	phase = "done"
	quit(1)

func next_locale() -> void:
	locale_index += 1
	if locale_index == LOCALES.size():
		press(KEY_J)
		TranslationServer.set_locale("sv")
		phase = "controls"
		return
	TranslationServer.set_locale(LOCALES[locale_index])
	phase = "locale"

func _process(_delta: float) -> bool:
	if game == null or phase == "done": return false
	match phase:
		"locale":
			var locale: String = LOCALES[locale_index]
			tracks = game.L10n.radio_tracks(locale)
			if tracks.is_empty():
				if game.radio.playing or game.radio.stream != null or not game.radio_button.disabled or game.next_song_button.visible:
					fail("Radio retained a different language in " + locale)
				else:
					next_locale()
				return false
			if game.radio_button.disabled:
				fail("Radio disabled in " + locale)
				return false
			previous = ""
			heard.clear()
			slot = 0
			phase = "song"
		"song":
			var song: String = game.radio_track
			if song not in tracks or heard.has(song) or (tracks.size() > 1 and song == previous) or not game.radio.playing:
				fail("Unexpected radio rotation in %s at %s" % [LOCALES[locale_index], song])
				return false
			heard[song] = true
			previous = song
			slot += 1
			if slot == 2 * tracks.size():
				next_locale()
				return false
			if slot == tracks.size(): heard.clear()
			if slot % 2 == 1 and tracks.size() > 1:
				press(KEY_N)
			else:
				game.radio.seek(game.radio.stream.get_length() - .08)
				deadline = Time.get_ticks_msec() + 2000
				phase = "end"
		"end":
			if game.radio_track != previous or (tracks.size() == 1 and game.radio.get_playback_position() < 1.0):
				phase = "song"
			elif Time.get_ticks_msec() > deadline:
				fail("Song ended without advancing: " + previous)
		"controls":
			check_controls()
	return false

func check_controls() -> void:
	if game.radio_enabled or game.radio.playing:
		fail("Switching languages unexpectedly turned the radio back on")
		return
	game.mode = "menu"
	game.vehicle_selector.get_child(game.FOOD_TRUCK).pressed.emit()
	game.start_button.pressed.emit()
	if not game.radio.playing or not game.siren_player.playing:
		fail("Food truck must start with both radio and engine audio")
		return
	var song: String = game.radio_track
	game.radio.seek(8.0)
	press(KEY_P)
	if not game.paused or not game.radio.stream_paused or game.radio.get_playback_position() < 7.0:
		fail("Pausing lost the current position in the song")
		return
	press(KEY_P)
	if game.paused or game.radio.stream_paused or game.radio_track != song or game.radio.get_playback_position() < 7.0:
		fail("Resuming should continue the same recording")
		return
	game.siren_button.pressed.emit()
	if game.siren_player.playing or not game.radio.playing or game.radio_track != song:
		fail("Muting the engine interrupted its song")
		return
	game.radio_button.pressed.emit()
	game.siren_button.pressed.emit()
	if game.radio.playing or not game.siren_player.playing:
		fail("Unmuting the engine changed the radio setting")
		return
	print("Radio rotation, language changes, pause and vehicle audio verified.")
	phase = "done"
	game._finish_quit()
