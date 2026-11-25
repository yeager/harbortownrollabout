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

func press(key: Key, ctrl := false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.ctrl_pressed = ctrl
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
			if tracks.size() == 1:
				var playback: AudioStreamPlayback = game.radio.get_stream_playback()
				press(KEY_N)
				if game.next_song_button.is_visible_in_tree() or game.radio.get_stream_playback() != playback:
					fail("The next-song shortcut restarted a one-song station")
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
	TranslationServer.set_locale("de")
	await process_frame
	var german: PackedStringArray = game.L10n.radio_tracks("de")
	if not game.radio.playing or game.radio_track not in german or game.next_song_button.is_visible_in_tree() != (german.size() > 1):
		print("German radio state: ", game.radio_track, " ", game.radio_language, " ", game.radio.playing, " ", game.next_song_button.is_visible_in_tree())
		fail("Changing to German did not update the song and next-song control")
		return
	TranslationServer.set_locale("sv")
	await process_frame
	if not game.next_song_button.is_visible_in_tree():
		fail("Changing back to Swedish did not restore the next-song control")
		return
	var song: String = game.radio_track
	press(KEY_J, true)
	press(KEY_N, true)
	if not game.radio.playing or game.radio_track != song:
		fail("A modified shortcut changed the radio")
		return
	press(KEY_N)
	if game.radio_track == song:
		fail("Changing back to Swedish did not restore the next-song shortcut")
		return
	song = game.radio_track
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
	TranslationServer.set_locale("sv")
	game.phone.current_job = game.FLOUR_ROUTE
	game.phone.handset.show()
	game._say(game.walker_data[0].actor, "Which ice cream would you pick?", "chat_ice")
	game.phone._repeat_instruction()
	var traffic_bus := AudioServer.get_bus_index("Traffic and radio")
	if not game.phone.job_voice.playing or game.greeting_voice.playing or AudioServer.get_bus_volume_db(traffic_bus) > -9.0:
		fail("Phone instruction did not immediately take priority over street audio")
		return
	if not game.radio.playing or not is_equal_approx(game.radio.volume_db, game.radio_track_gain_db - 8.0):
		fail("Starting a phone instruction must immediately lower the radio without stopping it")
		return
	game._say(game.walker_data[0].actor, "Which ice cream would you pick?", "chat_ice")
	if game.greeting_voice.playing or not game.greeting.visible:
		fail("A street greeting interrupted the phone or lost its speech bubble")
		return
	game.phone.handset.hide()
	game._say(game.walker_data[0].actor, "Which ice cream would you pick?", "chat_ice")
	if not game.greeting_voice.playing:
		fail("Street greetings did not return after closing the phone")
		return
	game.greeting_voice.stop()
	await create_timer(.75).timeout
	if not is_zero_approx(AudioServer.get_bus_volume_db(traffic_bus)) or not is_equal_approx(game.radio.volume_db, game.radio_track_gain_db):
		fail("Traffic or radio volume did not recover after closing the phone")
		return
	game._apply_calm_mode(true)
	game.phone.handset.show()
	game.phone._repeat_instruction()
	if not is_equal_approx(AudioServer.get_bus_volume_db(traffic_bus), -19.0):
		fail("Phone ducking must preserve the calm-mode volume reduction")
		return
	for i in range(60):
		if not game.phone.job_voice.playing:
			break
		await create_timer(.1).timeout
	await create_timer(.75).timeout
	if game.phone.job_voice.playing or not is_equal_approx(AudioServer.get_bus_volume_db(traffic_bus), -10.0) or not is_equal_approx(game.radio.volume_db, game.radio_track_gain_db):
		fail("Traffic or radio did not recover when the phone instruction finished")
		return
	game.phone.handset.hide()
	var toggle_keys: HBoxContainer = game.find_child("RadioToggleKeys", true, false)
	var next_keys: HBoxContainer = game.find_child("RadioNextTrackKeys", true, false)
	toggle_keys.get_child(2).pressed.emit()
	next_keys.get_child(2).pressed.emit()
	phase = "done"
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	if game.radio_keys != [KEY_B, KEY_M] or not game.radio_button.text.ends_with(" · B") or not game.next_song_button.text.ends_with(" · M"):
		fail("Saved radio choices and button labels did not restore")
		return
	var restored_song: String = game.radio_track
	press(KEY_J)
	press(KEY_N)
	if not game.radio.playing or game.radio_track != restored_song:
		fail("An old radio key remained active after rebinding")
		return
	press(KEY_M)
	if game.radio_track == restored_song:
		fail("The saved next-song key did not change tracks")
		return
	restored_song = game.radio_track
	var remaining_tracks: Array[String] = game.radio_bag.duplicate()
	game.radio.seek(8.0)
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if not game.radio.playing or game.radio_track != restored_song or game.radio.get_playback_position() < 7.0:
		fail("The saved song did not resume near its playback position")
		return
	if remaining_tracks.is_empty() or game.radio_bag != remaining_tracks:
		fail("The saved shuffle order did not resume")
		return
	press(KEY_M)
	if game.radio_track != remaining_tracks.back():
		fail("Next song did not follow the saved shuffle order")
		return
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	TranslationServer.set_locale("de")
	game._resume_road_checkpoint()
	var expected_tracks: PackedStringArray = game.L10n.radio_tracks("en")
	if not game.radio.playing or game.radio_track not in expected_tracks or game.radio_track == restored_song or game.radio.get_playback_position() >= 7.0:
		fail("Resuming in German did not start a fresh track from the English fallback playlist")
		return
	if game.radio_bag.size() != expected_tracks.size() - 1:
		fail("Restoring the trip consumed an unplayed track from the fallback playlist")
		return
	var expected_next: String = game.radio_bag.back()
	press(KEY_B)
	if game.radio.playing:
		fail("The saved radio key did not turn off the radio")
		return
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	TranslationServer.set_locale("de")
	game._resume_road_checkpoint()
	if game.radio_enabled or game.radio.playing or game.radio.stream != null or game.next_song_button.visible:
		fail("A radio switched off before saving came back on")
		return
	press(KEY_B)
	if not game.radio.playing or game.radio_track != expected_next:
		fail("Turning the radio back on did not follow the saved shuffle order")
		return
	var song_before_exit: String = game.radio_track
	game.radio.seek(8.0)
	game._change_seat()
	if not game.walker.visible or not game.radio.stream_paused or game.radio_button.visible:
		fail("Leaving the vehicle did not pause its radio")
		return
	game._change_seat()
	if game.walker.visible or not game.radio.playing or game.radio.stream_paused or game.radio_track != song_before_exit or game.radio.get_playback_position() < 7.0:
		fail("Re-entering the same vehicle did not resume the song")
		return
	print("Radio rotation, language changes, pause, vehicle audio and speech attenuation verified.")
	phase = "done"
	game._finish_quit()
