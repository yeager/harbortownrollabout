extends SceneTree

func _initialize() -> void:
	call_deferred("check_contact")

func check_contact() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.RECOVERY)
	game.ambulance.rotation.y = PI / 4
	var post_size := Vector3(.12, 2, .12)
	for side in [-1, 1]:
		for touches in [false, true]:
			var offset: float = game.player_half_size.x + (-.03 if touches else .30)
			var post_center: Vector3 = game.ambulance.to_global(Vector3(side * offset, 0, 0))
			var post := AABB(post_center - post_size * .5, post_size)
			var depth: float = game._vehicle_overlap_depth(post, game._player_extent(), game.ambulance.basis)
			if (depth > 0) != touches:
				printerr("Turned tow truck misclassified a post beside its body")
				quit(1)
				return
	game._on_vehicle_selected(0) # Ambulance for the driving and braking checks.
	game._start_game()
	game.allow_crashes = true
	var other: Dictionary = game.traffic_data.front()
	game.traffic_data.clear()
	game.traffic_data.append(other)
	game.ambulance.rotation.y = -PI / 2
	game.ambulance.position = Vector3(-200, game._surface_height(-200, 0), 0)
	var bounced := false
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
				bounced = true
			break
	if not bounced:
		printerr("Expected a bumper impact at contact distance")
		quit(1)
		return

	game.allow_crashes = false
	game.mouse_gas = false
	for direction in [1,-1]:
		game.ambulance.position = start
		game.speed = 0
		other.actor.position = start + Vector3.RIGHT * direction * (clearance + 1.0)
		var action := "ui_up" if direction == 1 else "ui_down"
		Input.action_press(action)
		for frame in 180:
			game._drive(1.0 / 60.0)
			var gap: float = (other.actor.position.x-game.ambulance.position.x)*direction-clearance
			if gap < .30 or game.speed*direction < 0:
				printerr("Assisted driving crossed the safety margin or rebounded")
				quit(1)
				return
		Input.action_release(action)
		var final_gap: float = absf(other.actor.position.x-game.ambulance.position.x)-clearance
		if absf(game.speed) > .01 or final_gap > .45:
			printerr("Assisted driving failed to approach and stop")
			quit(1)
			return
	game.queue_free()
	await process_frame
	await create_timer(.4).timeout
	print("Bumper contact and assisted forward and reverse stops passed.")
	quit()
