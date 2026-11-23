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
			if not history.begins_with(game.tr(receipt)) or not phone.handset.is_visible_in_tree() or inbox.get_theme_font_size("font_size") != 22 or inbox.size.x > view.size.x or root.size != Vector2i(800, 600) or receipt_height > view.size.y or not root.get_visible_rect().encloses(view):
				printerr(locale, " leg ", leg, " receipt height ", receipt_height, " viewport ", view)
				quit(1)
				return
	print("All 21 parcel receipt layouts fit at 800 × 600 with large text.")
	game._finish_quit()
