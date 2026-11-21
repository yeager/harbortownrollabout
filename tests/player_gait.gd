extends SceneTree
## Check planted feet and upper-body motion on both playable characters.

func _initialize() -> void:
	call_deferred("check_gait")

func check_gait() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game._change_seat()
	var player: Node3D = game.walker
	for alma in [false, true]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		var min_shift := 1.0
		var max_shift := -1.0
		var heel_contact := false
		var toe_off := false
		for frame in 140:
			game._animate_steps(player, 1.4 / 60.0, 1.0 / 60.0)
			var gait = player.get_meta("gait")
			min_shift = minf(min_shift, gait.lateral_shift)
			max_shift = maxf(max_shift, gait.lateral_shift)
			for side in 2:
				var cycle := fposmod(gait.phase + side * .5, 1.0)
				if cycle >= gait.STANCE:
					continue
				var shoe: Node3D = gait.shoes[side]
				var ankle := player.to_local(shoe.global_position)
				if absf(ankle.x - gait.hip_centres[side]) > .001:
					printerr("Stance foot slipped sideways as weight shifted")
					quit(1)
					return
				var relative := player.global_basis.inverse() * shoe.global_basis
				var pitch := relative.get_euler().x
				heel_contact = heel_contact or (cycle < .13 and pitch > .10)
				toe_off = toe_off or (cycle > .35 and pitch < -.18)
				if cycle >= .13 and cycle <= .35 and absf(pitch) > .001:
					printerr("Support shoe tilted off the ground")
					quit(1)
					return
		var gait = player.get_meta("gait")
		if not heel_contact or not toe_off or min_shift > -.015 or max_shift < .015 or gait.elbows.size() != 2:
			printerr("Incomplete support transfer or elbow articulation")
			quit(1)
			return
		for frame in 90:
			game._animate_steps(player, 0.0, 1.0 / 60.0)
		if absf(gait.lateral_shift) > .001 or absf(gait.jacket.rotation.y) > .001:
			printerr("Player did not settle into a balanced standing pose")
			quit(1)
			return
		var terrain: Callable = gait.ground_height
		gait.ground_height = func(x: float, z: float) -> float:
			var local := player.to_local(Vector3(x, player.global_position.y, z))
			return player.global_position.y + (.12 if local.z < -.10 else 0.0)
		game._animate_steps(player, 0.0, 1.0 / 60.0)
		for shoe: Node3D in gait.shoes:
			var toe := shoe.to_global(Vector3(0, -gait.SOLE_HEIGHT, -.155))
			if absf(toe.y - player.global_position.y - .12) > .002:
				printerr("Toe did not rest on the higher tread")
				quit(1)
				return
		gait.ground_height = terrain
	print("Axel and Alma transfer weight, maintain lateral foot placement and settle at rest.")
	quit()
