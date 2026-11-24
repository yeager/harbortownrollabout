extends SceneTree

func _initialize() -> void:
	call_deferred("check_layout")

func check_layout() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(800, 600)
	root.disable_3d = true
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(3)
	game.start_button.pressed.emit()
	game.large_text = true
	game._apply_reading_size()
	var phone = game.phone
	phone.open_button.pressed.emit()
	phone.take_job.pressed.emit()
	if not phone.handset.visible: phone.open_button.pressed.emit()
	for locale in ["sv", "en", "de", "es", "fr", "fi", "nb"]:
		TranslationServer.set_locale(locale)
		for leg in range(1, 4):
			game.mission_index = leg
			var receipt: String = game._delivery_receipt()
			phone.receive(receipt)
			phone.history_scroll.scroll_vertical = 0
			for frame in 3: await process_frame
			var inbox: Label = phone.inbox
			# Measure just the newest receipt at the actual wrapped width.
			var history := inbox.text
			inbox.text = game.tr(receipt)
			var receipt_height := inbox.get_minimum_size().y
			inbox.text = history
			var view: Rect2 = phone.history_scroll.get_global_rect()
			var screen_view: Rect2 = phone.history_scroll.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, view.size)
			if not history.begins_with(game.tr(receipt)) or not phone.handset.is_visible_in_tree() or inbox.get_theme_font_size("font_size") != 22 or inbox.size.x > view.size.x or root.size.x > 800 or root.size.y > 600 or receipt_height > view.size.y or not root.get_visible_rect().encloses(screen_view):
				printerr(locale, " leg ", leg, " receipt height ", receipt_height, " viewport ", view)
				quit(1)
				return
	print("All 21 parcel receipt layouts fit in %s pixels with large text." % str(root.size))
	var recorded_job := "Stop the flatbed at the square in the morning to collect flour."
	var missing_job := "Unrecorded job fixture"
	for locale in ["sv", "en", "de", "es", "fr", "fi", "nb"]:
		TranslationServer.set_locale(locale)
		phone.foot_jobs = PackedStringArray([missing_job, recorded_job])
		phone.refresh()
		phone.repeat_job.pressed.emit()
		var playlist := phone.job_voice.stream as AudioStreamPlaylist
		if not phone.repeat_job.is_visible_in_tree() or not phone.job_voice.playing or playlist == null or playlist.stream_count != 1 or not playlist.get_list_stream(0).resource_path.begins_with("res://audio/dispatch/%s_" % locale):
			printerr(locale, " did not read the available recording")
			quit(1)
			return
		phone.foot_jobs = PackedStringArray([missing_job])
		phone.refresh()
		if phone.repeat_job.visible or phone.job_voice.playing or not phone.action_rows.visible:
			printerr(locale, " did not keep the unrecorded job as text only")
			quit(1)
			return
	print("Mission read-aloud availability and language verified in all seven locales.")
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.RECOVERY)
	game.start_button.pressed.emit()
	game.free_drive = true
	game.time_mode = 2
	game.day_phase = .8
	game.ambulance.position = game.TARGETS[0]
	game._update_flour_delivery()
	game.ambulance.position = game.FLOUR_CURB
	game._update_flour_delivery()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_button.pressed.emit()
	phone = game.phone
	phone.open_button.pressed.emit()
	if phone.delivery_receipts.count(phone.FLOUR_RECEIPT) != 1:
		printerr("Bakery receipt was not saved exactly once")
		quit(1)
		return
	for locale in ["sv", "en", "de", "es", "fr", "fi", "nb"]:
		TranslationServer.set_locale(locale)
		phone.receipt_menu.about_to_popup.emit()
		var menu: PopupMenu = phone.receipt_menu.get_popup()
		var bakery_index := -1
		for index in menu.item_count:
			if menu.get_item_text(index).ends_with(game.tr("Bakery")):
				bakery_index = index
				break
		if bakery_index >= 0:
			menu.id_pressed.emit(menu.get_item_id(bakery_index))
		if bakery_index < 0 or not phone.receipt_dialog.visible or phone.receipt_dialog.dialog_text != game.tr(phone.FLOUR_RECEIPT):
			printerr(locale, " could not open the saved bakery receipt")
			quit(1)
			return
		phone.receipt_dialog.hide()
	print("Bakery receipt persisted and opened in all seven locales.")
	game._finish_quit()
