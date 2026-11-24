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
	var english: PackedStringArray = game.L10n.radio_tracks("en")
	var swedish: PackedStringArray = game.L10n.radio_tracks("sv")
	if english.is_empty() or game.L10n.radio_tracks("it_IT") != english or game.L10n.radio_tracks("sv_FI") != swedish:
		fail("The radio did not resolve the regional language or fall back to English")
		return
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
	var same_playlist: bool = game.L10n.radio_tracks(LOCALES[locale_index]) == tracks
	var previous_song: String = game.radio_track
	var stream: AudioStream = game.radio.stream
	var playback: AudioStreamPlayback
	var position: float = game.radio.get_playback_position()
	if same_playlist and stream != null:
		playback = game.radio.get_stream_playback()
	TranslationServer.set_locale(LOCALES[locale_index])
	game._sync_radio()
	if same_playlist and stream != null:
		var same_playback: bool = playback != null and game.radio.get_stream_playback() == playback
		var stayed_on_track: bool = game.radio_track == previous_song and game.radio.stream == stream and game.radio.playing
		if not same_playback or not stayed_on_track or game.radio.get_playback_position() < position:
			fail("Changing between languages with the same playlist interrupted the song")
			return
		if game.radio_button.tooltip_text != game.tr("Now playing: %s") % game.song_title.text:
			fail("The uninterrupted song tooltip did not follow the selected language")
			return
		# Begin the independent rotation check at the start of the next shuffle bag.
		press(KEY_N)
	phase = "locale"

func _process(_delta: float) -> bool:
	if game == null or phase == "done": return false
	match phase:
		"locale":
			var locale: String = LOCALES[locale_index]
			tracks = game.L10n.radio_tracks(locale)
			var local_recordings := PackedStringArray()
			for file in ResourceLoader.list_directory("res://audio/radio"):
				if file.ends_with(" (%s).mp3" % locale.to_upper()) and file not in game.L10n.STATION_ANNOUNCEMENTS:
					local_recordings.append(file)
			if locale != "en" and local_recordings.is_empty() and tracks != game.L10n.radio_tracks("en"):
				fail("Missing English song fallback for " + locale)
				return false
			if not local_recordings.is_empty() and tracks != local_recordings:
				fail("Local songs lost priority for " + locale)
				return false
			if tracks.is_empty():
				if game.radio.playing or game.radio.stream != null or not game.radio_button.disabled or game.next_song_button.visible:
					fail("Radio retained a different language in " + locale)
				elif game.radio_button.tr(game.radio_button.text) != game.tr("No songs yet") or game.radio_button.tooltip_text != game.tr("No songs available in this language yet."):
					fail("Incorrect empty radio message in " + locale)
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
			var title := song.get_basename()
			for tag: String in [LOCALES[locale_index], "en"]:
				title = title.trim_suffix(" (%s)" % tag.to_upper())
			if not game.song_card.is_visible_in_tree() or game.song_cover.texture == null or game.song_title.text != title:
				fail("Missing cover or title for " + song)
				return false
			if game.radio_button.tooltip_text != game.tr("Now playing: %s") % title:
				fail("Radio tooltip does not identify " + song)
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
			phase = "checking_controls"
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
	game._request_quit()
	await process_frame
	if not game.quit_dialog.visible or not paused:
		fail("Quit confirmation did not open over the pause menu")
		return
	game.quit_dialog.get_cancel_button().pressed.emit()
	await process_frame
	if paused or game.quit_dialog.visible or not game.paused or not game.radio.stream_paused:
		fail("Cancelling quit must leave the pause menu and its radio paused")
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
	if game.radio_button.icon == null or not game.radio_button.is_visible_in_tree():
		fail("Parked radio must show its picture on the driver's radio button")
		return
	game.radio_button.pressed.emit()
	if not game.radio.playing or game.radio_button.icon != null:
		fail("The illustrated radio button must restart playback")
		return
	game._set_radio_ducking(100)
	game._say(game.walker_data[0].actor, "Which ice cream would you pick?", "chat_ice")
	song = game.radio_track
	press(KEY_N)
	if not game.greeting_voice.playing or game.radio_track == song or not is_equal_approx(game.radio.volume_db, game.radio_track_gain_db - 8.0):
		fail("Changing songs during a pedestrian line lost speech attenuation")
		return
	game.greeting_voice.stop()
	await create_timer(.75).timeout
	if not is_equal_approx(game.radio.volume_db, game.radio_track_gain_db):
		fail("Radio did not restore its track volume after speech")
		return
	print("Radio rotation, language changes, pause, vehicle audio and speech attenuation verified.")
	phase = "done"
	game._finish_quit()
