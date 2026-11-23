extends SceneTree

func _initialize() -> void:
	call_deferred("verify_city")

func fail(message: String) -> void:
	printerr(message)
	quit(1)

func verify_city() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	await physics_frame
	await physics_frame
	check_geometry(game)

func check_geometry(game) -> void:
	var route = preload("res://scripts/street_route.gd").new()
	var asphalt: Array[Rect2] = []
	for child in game.get_children():
		if child is MeshInstance3D and child.material_override == game.road_finish:
			var bounds: AABB = child.transform * child.get_aabb()
			asphalt.append(Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z))
	# The station entrance crosses the pavement into a yard, outside the street graph.
	var driveway_mesh: MeshInstance3D = game.get_node("Station driveway")
	var yard_mesh: MeshInstance3D = game.get_node("Station forecourt")
	var drive_box := driveway_mesh.transform * driveway_mesh.get_aabb()
	var yard_box := yard_mesh.transform * yard_mesh.get_aabb()
	var driveway := Rect2(drive_box.position.x, drive_box.position.z, drive_box.size.x, drive_box.size.z)
	var yard := Rect2(yard_box.position.x, yard_box.position.z, yard_box.size.x, yard_box.size.z)
	asphalt.erase(driveway)
	asphalt.erase(yard)
	var entry := Vector2(game.STATION_DROP.x, driveway.position.y)
	var exit := Vector2(entry.x, driveway.end.y)
	if not asphalt.any(func(rect: Rect2): return rect.grow(.001).has_point(entry)) or not yard.grow(.001).has_point(exit):
		fail("Station driveway does not connect the street and forecourt")
		return
	var ids: PackedInt64Array = route.graph.get_point_ids()
	for id in ids:
		if route.graph.get_point_connections(id).size() < 2 or route.graph.get_id_path(ids[0], id).is_empty():
			fail("Isolated junction or dead end at " + str(route.graph.get_point_position(id)))
			return
	for edge in route.edges:
		var start: Vector2 = route.graph.get_point_position(edge.x)
		var end: Vector2 = route.graph.get_point_position(edge.y)
		var samples := ceili(start.distance_to(end) * 4)
		for i in range(samples + 1):
			var sample := start.lerp(end, float(i) / samples)
			if not asphalt.any(func(rect: Rect2): return rect.grow(.001).has_point(sample)):
				fail("Gap in street surface at " + str(sample))
				return
	# Also check actual asphalt for street ends missing from the navigation graph.
	for rect in asphalt:
		var axis := Vector2.RIGHT if rect.size.x >= rect.size.y else Vector2.DOWN
		for sign_value in [-1, 1]:
			var tip := rect.get_center() + rect.size * axis * .5 * float(sign_value)
			var nearest: Vector2i = route._nearest(tip)
			var projection := Geometry2D.get_closest_point_to_segment(tip, route.graph.get_point_position(nearest.x), route.graph.get_point_position(nearest.y))
			if tip.distance_to(projection) > game.ROAD_HALF + .01:
				fail("Unconnected asphalt extension at " + str(tip))
				return
	var wall := game.get_node("CityPerimeter") as Node3D
	if wall.find_children("*", "StaticBody3D", false, false).size() != 4:
		fail("Missing perimeter collision")
		return
	var area: Rect2 = game.CITY_INTERIOR
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for x in [area.position.x, area.end.x]:
		for z in [area.position.y, area.end.y]:
			var corner := Vector2(x, z)
			var outward := (corner - area.get_center()).sign()
			for height in [-.8, 1.6]:
				var origin := Vector3(corner.x - outward.x, height, corner.y - outward.y)
				var target := Vector3(corner.x + outward.x, height, corner.y + outward.y)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, target))
				if hit.is_empty() or not wall.is_ancestor_of(hit.collider):
					fail("Open perimeter corner at " + str(corner) + " height " + str(height))
					return
	for normal in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var side: Vector2 = area.get_center() + area.size * normal * .5
		var outside: Vector2 = side + normal
		if game._on_foot_clear(Vector3(outside.x, 0, outside.y)):
			fail("Walking through wall at " + str(side))
			return
		var start: Vector2 = side - normal * 5
		game.ambulance.position = Vector3(start.x, 0, start.y)
		game.ambulance.rotation.y = atan2(-normal.x, -normal.y)
		game.speed = 85
		game._drive(.2)
		var extent: Vector2 = game._player_extent()
		var center := Vector2(game.ambulance.position.x, game.ambulance.position.z)
		if (side-center).dot(normal) + .001 < extent.dot(normal.abs()) or not is_zero_approx(game.speed):
			fail("Vehicle penetrated perimeter or failed to stop at " + str(side))
			return
	print("Verified ", ids.size(), " junctions, ", route.edges.size(), " road segments, ", asphalt.size(), " asphalt meshes and four perimeter walls including corner collisions.")
	game._finish_quit()
