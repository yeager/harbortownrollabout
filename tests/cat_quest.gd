extends SceneTree

func _initialize() -> void:
	call_deferred("check_quest")

func check_quest() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.walker.show()
	var initial_wallet: int = game.wallet
	# Linger just ahead of the neighbour until she reaches the pavement's end.
	for frame in 900:
		game.walker.position = game.cat_owner.position + Vector3.RIGHT * 3
		game._update_cat_quest(1.0 / 60)
	game.walker.position = game.cat_owner.position
	game._update_cat_quest(1.0 / 60)
	game.walker.position = game.lost_cat.position
	game._update_cat_quest(1.0 / 60)
	var waiting_position: Vector3 = game.lost_cat.position
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
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Cat waited during the detour, reunited with the neighbour and paid once.")
	quit()
