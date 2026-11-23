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
		game.find_child("ResumeCheckpoint", true, false).pressed.emit()
		assert(game.vehicle_index == i)
		assert(game.ambulance.global_position.is_equal_approx(positions[i]))
		game.free()
		game = scene.instantiate()
		root.add_child(game)
	game.find_child("SeparateProfiles", true, false).button_pressed = false
	assert(not game.find_child("ResumeCheckpoint", true, false))
	print("Both drivers resumed their own vehicle and position. Shared progress stayed empty.")
	quit()
