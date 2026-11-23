extends SceneTree

func _initialize() -> void:
	call_deferred("check_quest")

func check_quest() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.walker.show()
	var initial_wallet: int = game.wallet
	var initial_points: int = game.foot_quest_points
	# Linger just ahead of the neighbour until she reaches the pavement's end.
	for frame in 900:
		game.walker.position = game.cat_owner.position + Vector3.RIGHT * 3
		game._update_cat_quest(1.0 / 60)
	game.walker.position = game.cat_owner.position
	game._update_cat_quest(1.0 / 60)
	if not await check_dialogue(game, "Can you find my cat? Look for white paws along this pavement.", "lost_cat"):
		quit(1)
		return
	game.walker.position = game.lost_cat.position
	game._update_cat_quest(1.0 / 60)
	for locale in ["fi", "sv", "de", "es", "nb", "fr", "en"]:
		TranslationServer.set_locale(locale)
		await process_frame
		if game.greeting.get_parent() != game.lost_cat or game.greeting.text != game.tr("Meow!") or not game.greeting.visible:
			printerr("Missing cat caption in ", locale)
			quit(1)
			return
	var waiting_position: Vector3 = game.lost_cat.position
	var walk_position: Vector3 = game.walker.position
	var car_position: Vector3 = game.ambulance.position
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	if not game.walker.visible or not game.walker.position.is_equal_approx(walk_position) or not game.parked_cars[game.vehicle_index].position.is_equal_approx(car_position):
		printerr("Walk or parked car was not restored")
		quit(1)
		return
	game.walker.position = game.cat_owner.position + Vector3.BACK * 12
	for frame in 120:
		game._update_cat_quest(1.0 / 60)
	if game.cat_quest != game.FootQuest.RETURNING or game.lost_cat.position != waiting_position:
		printerr("The cat must wait on the pavement while the player crosses the street.")
		quit(1)
		return
	game.walker.position = game.cat_owner.position
	for frame in 1200:
		game._update_cat_quest(1.0 / 60)
	if game.cat_quest != game.FootQuest.FINISHED or game.wallet != initial_wallet + 10:
		printerr("Expected a reunion and one ten-coin reward.")
		quit(1)
		return
	var saved := ConfigFile.new()
	if saved.load(game.SETTINGS_PATH) != OK or saved.get_value("player","coins",-1) != initial_wallet + 10 or saved.get_value("player","foot_quest_points",-1) != initial_points + 10 or game.foot_quest_points != initial_points + 10:
		printerr("Expected the ten coins and ten points to be awarded once and saved.")
		quit(1)
		return
	if not await check_dialogue(game, "There you are, Socks! Thank you for bringing her home.", "cat_returned"):
		quit(1)
		return
	game.walker.position = game.shoe_owner.position
	game._update_shoe_quest(0)
	game.walker.position = game.lost_shoe.position
	game._update_shoe_quest(0)
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.find_child("ResumeCheckpoint", true, false).pressed.emit()
	if not game.walker.is_ancestor_of(game.lost_shoe) or not game.lost_shoe.is_visible_in_tree():
		printerr("Lost the shoe from the player's hand during restart")
		quit(1)
		return
	game.walker.position = game.shoe_owner.position
	game._update_shoe_quest(0)
	game._update_shoe_quest(0)
	if game.shoe_quest != game.FootQuest.FINISHED or not game.returned_trainer.visible or game.wallet != initial_wallet + 20:
		printerr("Could not return the saved shoe for one reward")
		quit(1)
		return
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Cat waited during the detour, reunited with the neighbour and paid once.")
	quit()

func check_dialogue(game: Node, phrase: String, clip_name: String) -> bool:
	for locale in ["de", "es", "fi", "fr", "nb", "sv", "en"]:
		TranslationServer.set_locale(locale)
		await process_frame
		var clip = game.greeting_voice.stream
		var expected_path := "res://audio/voices/%s_%s.wav" % [locale, clip_name]
		if clip == null or clip.resource_path != expected_path or not game.greeting_voice.playing:
			printerr("Missing spoken quest dialogue in ", locale)
			return false
		if game.greeting.text.replace("\n", " ") != game.tr(phrase) or not game.greeting.visible:
			printerr("Quest speech bubble did not follow the voice in ", locale)
			return false
	return true
