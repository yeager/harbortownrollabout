extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	game._change_seat()
	for alma in [false, true]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		game.walker.position = Vector3(-24, 0, 28)
		game.weather.snow = 1.0 if alma else 0.0
		var initial_prints: int = game.sole_marks.visible_instance_count
		game._unhandled_key_input(key)
		var peak := 0.0
		var impacts := 0
		game.footstep.stop()
		for frame in 60:
			game._walk(1.0/60)
			if game.footstep.playing:
				assert(game.walk_jump_left == 0)
				assert(game.footstep.stream == (game.SNOW_STEP if alma else game.DRY_STEP))
				impacts += 1
				game.footstep.stop()
			if game.walk_jump_left > 0:
				assert(game.sole_marks.visible_instance_count == initial_prints)
			if frame == 18:
				var gait = game.walker.get_meta("gait")
				for knee in gait.knees:
					assert(knee.get_bone_pose_rotation(1).get_angle() > .8)
			if frame == 12: game._unhandled_key_input(key)
			peak = maxf(peak, game.walker.position.y - game._foot_height(game.walker.position.x, game.walker.position.z))
			if frame == 39: assert(game.walk_jump_left == 0)
		assert(absf(peak-.5)<.01 and impacts == 1)
		assert(game.sole_marks.visible_instance_count == initial_prints + (2 if alma else 0))
	game._start_game()
	game.gentle_driving = false
	for direction: float in [-1, 1]:
		for approach_speed: float in [5, 18]:
			var crest: float = game.HIGH_BRIDGE_X[1 if direction > 0 else 2]
			var x := crest-direction*.2
			game.ambulance.position = Vector3(x, game._surface_height(x,-48), -48)
			game.ambulance.rotation.y = -direction*PI/2
			game.speed = approach_speed
			var peak := 0.0
			for frame in 45:
				game._drive(1.0/60)
				var pos: Vector3 = game.ambulance.position
				peak = maxf(peak, pos.y-game._surface_height(pos.x,pos.z))
			assert(game.bridge_jump_left == 0)
			assert(peak < .001 if approach_speed == 5 else peak > .15 and peak < .4)
	print("Walking jumps and fast/slow approaches to both bridge crests passed.")
	game._finish_quit()
