extends SceneTree

func _initialize() -> void:
	call_deferred("check_rounds")

func check_rounds() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	for step: float in [1.0/60.0, 0.1]:
		var throws: Array[int] = []
		var pickups: Array[int] = []
		var saw_result := false
		for frame in ceili(70.0/step):
			var before: Array = game.boule_grounded.duplicate()
			game._update_boule(step)
			for i in before.size():
				if before[i] != game.boule_grounded[i]:
					if before[i]: pickups.append(i)
					else: throws.append(i)
			if game.boule_result_rings.any(func(ring): return ring.visible):
				if not game.boule_grounded.all(func(grounded): return grounded):
					printerr("Result shown before all three throws settled")
					quit(1)
					return
				saw_result = true
			if pickups.size() == 3 and game.boule_collector == -1: break
		if throws != [0,1,2] or pickups != throws or not saw_result or game.boule_turn != 0 or game.boule_collector != -1:
			printerr("Incomplete round: throws ",throws,", pickups ",pickups)
			quit(1)
			return
		for i in game.boules.size():
			var person: Node3D = game.boule_players[i]
			var hand: Node3D = person.get_meta("gait").palms[1]
			if person.position.distance_to(game._boule_waiting_spot(i)) > .01 or game.boules[i].position.distance_to(hand.to_global(game.PALM_GRIP)) > .01 or game.boule_result_rings[i].visible:
				printerr("Player ",i," did not return holding the ball")
				quit(1)
				return
	print("Two successive boule rounds completed at different frame rates.")
	quit()
