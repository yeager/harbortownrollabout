extends SceneTree
## Run with an isolated user data directory, starting without saved progress.

func _initialize() -> void:
	check_profiles.call_deferred()

func choose_driver(game: Node, driver: String) -> void:
	for button: Button in game.find_children("*", "Button", true, false):
		if button.text == driver:
			button.button_pressed = true
			button.pressed.emit()
			return
	assert(false, "Missing driver button")

func check_profiles() -> void:
	var scene := preload("res://main.tscn")
	var positions := [Vector3(-8, 0, 2), Vector3(12, 0, 2)]
	var game = scene.instantiate()
	root.add_child(game)
	game.find_child("SeparateProfiles", true, false).button_pressed = true
	for i in 2:
		choose_driver(game, ["Axel", "Alma"][i])
		assert(not game.find_child("ResumeCheckpoint", true, false))
		game._on_vehicle_selected(i)
		game.start_button.pressed.emit()
		game.ambulance.global_position = positions[i]
		game._save_checkpoint()
		game.free()
		game = scene.instantiate()
		root.add_child(game)
	for i in 2:
		choose_driver(game, ["Axel", "Alma"][i])
		Input.action_press("ui_up")
		game.find_child("ResumeCheckpoint", true, false).pressed.emit()
		assert(game.vehicle_index == i)
		assert(game.ambulance.global_position.is_equal_approx(positions[i]))
		game._drive(.1)
		Input.action_release("ui_up")
		assert(is_zero_approx(game.speed), "Resuming must ignore the previously held accelerator")
		game._drive(.01)
		assert(game._keyboard_pedals_available(), "Releasing the accelerator must restore pedal control")
		game._change_seat()
		game.walker.position = game.BOULE_BENCH_APPROACH
		game._set_boule_seated(true)
		game._save_checkpoint()
		assert(game.road_checkpoint.get("boule_bench", false))
		if i == 1:
			# Earlier builds stored a lowered standing origin without a bench flag.
			game.road_checkpoint.erase("boule_bench")
			game.road_checkpoint.walk_position.y += .20
			game._save_preferences()
		game.free()
		game = scene.instantiate()
		root.add_child(game)
	for i in 2:
		choose_driver(game, ["Axel", "Alma"][i])
		game.find_child("ResumeCheckpoint", true, false).pressed.emit()
		assert(game.walker.visible and game.boule_seated)
		var gait = game.walker.get_meta("gait")
		for shoe: Node3D in gait.shoes:
			var sole := shoe.to_global(Vector3.DOWN * gait.SOLE_HEIGHT)
			assert(absf(sole.y - game._foot_height(sole.x, sole.z)) < .004)
		game._change_seat()
		assert(not game.boule_seated and game.walker.position.is_equal_approx(game.BOULE_BENCH_APPROACH))
		game.free()
		game = scene.instantiate()
		root.add_child(game)
	game.find_child("SeparateProfiles", true, false).button_pressed = false
	assert(not game.find_child("ResumeCheckpoint", true, false))
	print("Both profiles restored their own vehicle and the seated bench pose. A legacy bench save also resumed seated.")
	quit()
