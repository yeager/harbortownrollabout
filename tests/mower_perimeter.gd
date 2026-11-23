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
		for outward: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
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
					var gap := outward.dot(limit - Vector2(pos.x,pos.z))
					if gap < -.001:
						printerr("Mower crossed perimeter: ", bounds, outward, reverse, gap)
						quit(1)
						return
				var end: Vector3 = game.ambulance.position
				if Vector2(end.x,end.z).distance_to(limit) > .02 or absf(game.speed) > .05:
					printerr("Mower did not reach and stop at perimeter: ",outward,reverse,end,limit,game.speed)
					quit(1)
					return
			# Park parallel with the first-choice exit facing out of bounds.
			game.ambulance.rotation.y = atan2(-outward.y, outward.x)
			var side_extent: Vector2 = game._player_extent()
			var parking_spot := bounds.get_center() + outward * (bounds.size * .5 - side_extent)
			game.ambulance.position = Vector3(parking_spot.x, game._surface_height(parking_spot.x, parking_spot.y), parking_spot.y)
			game.speed = 0
			game._change_seat()
			var foot: Vector3 = game.walker.position
			if not game.walker.visible or not bounds.grow(-.25).has_point(Vector2(foot.x,foot.z)) or outward.dot(Vector2(foot.x,foot.z)-parking_spot) >= 0:
				printerr("No safe inward exit from mower: ",bounds,outward,foot)
				quit(1)
				return
			game._change_seat()
			if game.walker.visible or game.vehicle_index != game.MOWER:
				printerr("Could not get back onto the mower")
				quit(1)
				return
	print("Mower stopped inside all four edges, forward and in reverse, in both play areas.")
	quit()
