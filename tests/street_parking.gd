extends SceneTree

const STREETS := ["Stationsallén", "Norra kajgatan", "Södra kajgatan"]

func _initialize() -> void:
	call_deferred("check_parking")

func check_parking() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	world._on_vehicle_selected(world.TAXI)
	world._start_game()
	world.set_process(false)
	world.traffic_data.clear()
	var bays := get_nodes_in_group("street_parking_bays")
	if bays.size() != 7:
		printerr("Expected seven street parking bays")
		quit(1)
		return
	for marker: Node3D in bays:
		var spot := marker.global_position
		var parked_body := AABB(spot + Vector3(-2.75, -.02, -1.03), Vector3(5.5, 2.3, 2.06))
		for obstacle: AABB in world.building_bounds + world.roadside_solids:
			if obstacle.intersects(parked_body):
				printerr("An obstacle occupies the parking bay on ", marker.get_parent().name)
				quit(1)
				return
		for trunk: Vector3 in world.trunks:
			if parked_body.grow(trunk.y).has_point(Vector3(trunk.x, .4, trunk.z)):
				printerr("A tree occupies the parking bay on ", marker.get_parent().name)
				quit(1)
				return
	for street in STREETS:
		var row: Node3D = world.get_node("Street parking").get_node(street)
		var spot: Vector3 = row.get_node("Parking bay 1").global_position
		var direction := 1.0 if street == "Södra kajgatan" else -1.0
		if not drive_into_bay(world, spot, direction):
			printerr("The taxi could not enter the parking bay on ", street)
			quit(1)
			return
	print("Seven parking bays were clear, and the taxi drove inside a white rectangle on all three streets.")
	quit()

func drive_into_bay(world: Node, spot: Vector3, direction: float) -> bool:
	world.ambulance.position = spot + Vector3(-direction * 16.0, 0, -direction * 2.675)
	world.ambulance.rotation.y = -PI / 2.0 * direction
	world.speed = 1.9
	world.steering = 0.0
	for tick in 500:
		var error: Vector3 = spot - world.ambulance.position
		if error.x * direction < .09:
			break
		var target := Vector3(direction, 0, clampf(error.z * .26, -.4, .4)).normalized()
		var forward: Vector3 = -world.ambulance.basis.z
		world.mouse_steering = clampf(-forward.signed_angle_to(target, Vector3.UP) * 3.2, -.85, .85)
		world.mouse_gas = world.speed < 2.0
		world._drive(.04)
	var offset: Vector3 = spot - world.ambulance.position
	var half_size: Vector2 = world._player_extent()
	return absf(offset.x) + half_size.x < 3.15 and absf(offset.z) + half_size.y < 1.28
