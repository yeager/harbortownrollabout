extends SceneTree

func _initialize() -> void:
	call_deferred("check_contact")

func check_contact() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	var other: Dictionary = game.traffic_data.front()
	game.traffic_data.clear()
	game.traffic_data.append(other)
	game.ambulance.rotation.y = -PI / 2
	game.ambulance.position = Vector3(-200, game._surface_height(-200, 0), 0)
	var start: Vector3 = game.ambulance.position
	var clearance: float = game._player_extent().x + other.length
	other.actor.position = start + Vector3.RIGHT * (clearance + 1.0)
	game.mouse_gas = true
	game.speed = 8.0
	for frame in 30:
		game._drive(1.0 / 60.0)
		if game.speed < 0:
			var gap: float = other.actor.position.x - game.ambulance.position.x - clearance
			if gap >= -.001 and gap <= .03:
				print("Bumpers meet and rebound without overlap.")
				quit()
				return
			break
	printerr("Expected a bumper impact at contact distance")
	quit(1)
