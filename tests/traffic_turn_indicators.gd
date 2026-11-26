extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func fail(message: String) -> void:
	printerr(message)
	quit(1)

func verify() -> void:
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	for traffic: Dictionary in game.traffic_data:
		if traffic.turn_signals.left.size() < 2 or traffic.turn_signals.right.size() < 2:
			fail("Traffic vehicle is missing front or rear indicators on either side")
			return
	game.traffic_data.clear()
	game.ambulance.hide()
	game.calm_mode = false
	game.steady_player_lights = false
	var actor: Node3D = game._spawn_traffic("res://vehicles/traffic_bmw_blue.glb", -103, 2.35, 1, 0.0)
	var item: Dictionary = game.traffic_data.back()
	for lamps in [item.turn_signals.left, item.turn_signals.right]:
		if not lamps.any(func(lamp): return lamp.get_parent().name.begins_with("Front amber indicator")):
			fail("The X5i must use its modeled front indicator lenses")
			return
	for direction in [-1, 1]:
		var route := Curve3D.new()
		route.add_point(Vector3(-103, 0, 2.35))
		route.add_point(Vector3(-99, 0, 2.35))
		route.add_point(Vector3(-99, 0, 2.35 + 25 * direction))
		item.route = route
		item.distance = 0.0
		game._place_traffic(item)
		game._update_traffic(.04)
		if not selected_side_is_lit(item.turn_signals, direction):
			fail("A waiting car did not indicate its planned turn at %s" % actor.position)
			return
		game._update_traffic(.4)
		if not both_sides_are_dark(item.turn_signals):
			fail("The turning car's indicator did not blink off")
			return
		item.distance = 13.0
		game._place_traffic(item)
		game._update_traffic(.04)
		if item.turn_signals.direction != 0 or not both_sides_are_dark(item.turn_signals):
			fail("The car did not cancel its indicator after the turn")
			return
	var tram = game.tram
	var users: Array[AABB] = []
	var car: Dictionary = tram.road_cars.front()
	var west_south_start := Vector3(tram.WEST + tram.RADIUS, .04, tram.SOUTH)
	var west_south_end := Vector3(tram.WEST, .04, tram.SOUTH - tram.RADIUS)
	for direction in [-1, 1]:
		var point := west_south_start if direction > 0 else west_south_end
		car.offset = tram.track.get_closest_offset(point) - 3.0 * direction
		car.direction = direction
		car.actor.transform = tram._carriageway_pose(car.offset, direction)
		tram._advance_road_cars(.04, users)
		if not selected_side_is_lit(car.turn_signals, direction):
			fail("A boulevard car did not indicate the bend in direction %d" % direction)
			return
	var corner: float = tram.track.get_closest_offset(west_south_start)
	tram.distance = corner - 3.0
	tram.place_sections()
	tram.advance(.04, true, false, true)
	for signals in tram.cab_indicators:
		if not selected_side_is_lit(signals, 1, 1):
			fail("The tram's front and rear must indicate on the same side")
			return
	tram.distance = corner + 35.0
	tram.place_sections()
	tram.advance(.04, true, false, true)
	for signals in tram.cab_indicators:
		if signals.direction != 0 or not both_sides_are_dark(signals):
			fail("The tram did not cancel both cab indicators after the bend")
			return
	print("Road cars indicated left and right and cancelled after the turn. Both tram ends indicated the same side around the bend.")
	quit()

func selected_side_is_lit(signals: RefCounted, direction: int, minimum_lamps := 2) -> bool:
	var selected: Array[MeshInstance3D] = signals.right if direction > 0 else signals.left
	var other: Array[MeshInstance3D] = signals.left if direction > 0 else signals.right
	return signals.direction == direction and selected.size() >= minimum_lamps \
		and selected.all(func(lamp: MeshInstance3D): return lamp.visible) \
		and not other.any(func(lamp: MeshInstance3D): return lamp.visible)

func both_sides_are_dark(signals: RefCounted) -> bool:
	return not (signals.left + signals.right).any(func(lamp: MeshInstance3D): return lamp.visible)
