extends SceneTree

func _initialize() -> void:
	call_deferred("check_perimeter")

func check_perimeter() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(game.MOWER)
	game._start_game()
	for practice in [false, true]:
		game.practice_active = practice
		var bounds: Rect2 = game.PRACTICE_YARD if practice else game.CITY_INTERIOR
		for outward: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1,-1), Vector2(-1,1), Vector2(1,-1), Vector2(1,1)]:
			for reverse in [false, true]:
				var facing := -outward if reverse else outward
				game.ambulance.rotation = Vector3(0, atan2(-facing.x, -facing.y), 0)
				var extent: Vector2 = game._player_extent()
				var limit := bounds.get_center() + outward * (bounds.size * .5 - extent)
				var start := limit - outward * .18
				game.ambulance.position = Vector3(start.x, game._surface_height(start.x, start.y), start.y)
				game.speed = -2.0 if reverse else 2.0
				game.mouse_gas = not reverse
				game.mouse_brake = reverse
				for frame in 20:
					game._drive(.025)
					var pos: Vector3 = game.ambulance.position
					var gap := (limit - Vector2(pos.x,pos.z)) * outward
					if minf(gap.x, gap.y) < -.001:
						printerr("Mower crossed perimeter: ", bounds, outward, reverse, gap)
						quit(1)
						return
				var end: Vector3 = game.ambulance.position
				if Vector2(end.x,end.z).distance_to(limit) > .02 or absf(game.speed) > .05:
					printerr("Mower did not reach and stop at perimeter: ",outward,reverse,end,limit,game.speed)
					quit(1)
					return
			# Face the first-choice exit toward the nearest edge or corner.
			game.ambulance.rotation.y = atan2(-outward.y, outward.x)
			var side_extent: Vector2 = game._player_extent()
			var parking_spot := bounds.get_center() + outward * (bounds.size * .5 - side_extent)
			game.ambulance.position = Vector3(parking_spot.x, game._surface_height(parking_spot.x, parking_spot.y), parking_spot.y)
			game.speed = 0
			game._change_seat()
			var foot: Vector3 = game.walker.position
			var straight_edge := outward.x == 0 or outward.y == 0
			var stepped_outward := outward.dot(Vector2(foot.x,foot.z)-parking_spot) >= 0
			if (straight_edge and stepped_outward) or not game.walker.visible or not bounds.grow(-.25).has_point(Vector2(foot.x,foot.z)) or not game._on_foot_clear(foot):
				printerr("No safe exit from mower: ",bounds,outward,foot)
				quit(1)
				return
			game._change_seat()
			if game.walker.visible or game.vehicle_index != game.MOWER:
				printerr("Could not get back onto the mower")
				quit(1)
				return
	# A misplaced mower must return to the area selected for that saved game.
	for practice in [false, true]:
		game.practice_active = practice
		game.ambulance.position = Vector3.ZERO if practice else game.PRACTICE_START
		game._recover_position()
		var safe_bounds: Rect2 = game.PRACTICE_YARD if practice else game.CITY_INTERIOR
		var recovered: Vector3 = game.ambulance.position
		if not safe_bounds.has_point(Vector2(recovered.x, recovered.z)):
			printerr("Recovery sent the mower to the wrong area: ", recovered)
			quit(1)
			return
		game.ambulance.position = Vector3.ZERO if practice else game.PRACTICE_START
		game._save_checkpoint()
		game.free()
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		var bounds: Rect2 = game.PRACTICE_YARD if practice else game.CITY_INTERIOR
		var restored: Vector3 = game.ambulance.position
		if game.practice_active != practice or game.vehicle_index != game.MOWER or not bounds.has_point(Vector2(restored.x, restored.z)):
			printerr("Misplaced mower resumed in the wrong play area: ", restored)
			quit(1)
			return
		game._change_seat()
		var edge := Vector3(bounds.position.x + .05, 0, bounds.get_center().y)
		game.walker.position = edge
		game._save_checkpoint()
		game.free()
		game = load("res://main.tscn").instantiate()
		root.add_child(game)
		game._resume_road_checkpoint()
		var feet: Vector3 = game.walker.position
		if not game.walker.visible or not bounds.grow(-.25).has_point(Vector2(feet.x, feet.z)) or not game._on_foot_clear(feet):
			printerr("Walking checkpoint left the player against the perimeter: ", feet)
			quit(1)
			return
		if not practice:
			game.free()
			game = load("res://main.tscn").instantiate()
			root.add_child(game)
			game._on_vehicle_selected(game.MOWER)
			game._start_game()
	print("Mower stopped inside all four edges and corners, forward and in reverse, in both play areas.")
	quit()
