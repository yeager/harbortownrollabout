extends SceneTree
## Run from the imported project with godot --headless --script res://tests/ferry_passenger.gd

func _initialize() -> void:
	call_deferred("check_crossings")

func check_crossings() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.play_as_alma = true
	game._apply_player_appearance()
	game._start_game()
	game._change_seat()
	var original_scale: Vector3 = game.walker.scale
	for departure in game.FERRY_LANDINGS.size():
		var quay_z: float = game.FERRY_LANDINGS[departure]
		game.walker.position = Vector3(64.9, game._foot_height(64.9, quay_z), quay_z)
		game.wave_time = departure * 29.0 + 1.0
		game._update_moorings(0.0)
		if not check_localized_button(game, "Board Lotten · F"):
			return
		game._change_seat()
		if not check_localized_button(game, "Step ashore · F"):
			return
		game._update_moorings(10.0)
		if not check_localized_button(game, "Get off at next landing · F"):
			return
		game._change_seat()
		if not check_localized_button(game, "Stay on board · F"):
			return
		if not game.ferry_passenger:
			printerr("Passenger stepped off over open water from landing ", departure)
			quit(1)
			return
		game._update_moorings(19.0)
		if game.ferry_passenger or game._near_ferry_landing() != 1 - departure:
			printerr("Requested exit did not reach the opposite pier")
			quit(1)
			return
		if not game._feet_supported(game.walker.position) or not game.walker.scale.is_equal_approx(original_scale):
			printerr("Disembarkation changed Alma's scale or left her without footing")
			quit(1)
			return
	var hull: AABB = game._model_bounds(game.ferry, game.ferry)
	var bridge := []
	for part in game.get_children():
		if part is MeshInstance3D and part.mesh is BoxMesh and absf(part.position.z + 48) < 5 and part.position.x > 50 and part.position.x < 99:
			bridge.append(part)
	var clearance := INF
	for frame in range(580):
		game.wave_time = frame * .1
		game._update_moorings(0)
		var occupied: AABB = game.ferry.global_transform * hull
		for part: MeshInstance3D in bridge:
			var span := part.global_transform * part.get_aabb()
			if occupied.position.x < span.end.x and span.position.x < occupied.end.x and occupied.position.z < span.end.z and span.position.z < occupied.end.z:
				clearance = minf(clearance, span.position.y - occupied.end.y)
	if clearance < .5 or not is_finite(clearance):
		printerr("Unexpected clearance along ferry route: ", clearance)
		quit(1)
		return
	print("Minimum overhead clearance on both crossings: %.2f m" % clearance)
	print("Both Lotten crossings preserved passenger scale and pier footing.")
	quit()

func check_localized_button(game: Node, key: String) -> bool:
	var original := TranslationServer.get_locale()
	for locale in ["de", "es", "fi", "fr", "nb", "sv", "en"]:
		TranslationServer.set_locale(locale)
		game._update_entry_button()
		var expected := String(TranslationServer.translate(key))
		if game.seat_button.disabled or game.seat_button.atr(game.seat_button.text) != expected or (locale != "en" and expected == key):
			printerr("Incorrect ferry action in ", locale, " for ", key)
			quit(1)
			return false
	TranslationServer.set_locale(original)
	return true
