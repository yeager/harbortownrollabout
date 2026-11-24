extends SceneTree

func _initialize() -> void:
	call_deferred("check_driver")

func check_driver() -> void:
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	game._on_vehicle_selected(2)
	game._start_game()
	var truck: Node3D = game.ambulance
	var wheel_x := truck.to_local(game.cabin_wheel.global_position).x
	if wheel_x >= 0:
		printerr("Fire engine steering wheel must be on the left side of the cab")
		quit(1)
		return
	for alma in [false, true]:
		game.play_as_alma = alma
		game._apply_player_appearance()
		game._refresh_ui()
		if absf(truck.to_local(game.road_driver.global_position).x - wheel_x) > .02:
			printerr("Driver and steering wheel are in different seats")
			quit(1)
			return
	var blades := truck.find_children("Crew cab wiper blade*", "MeshInstance3D", true, false)
	if blades.size() != 2:
		printerr("Both fire engine wiper blades must be present")
		quit(1)
		return
	var parked: Array[Transform3D] = []
	for blade: MeshInstance3D in blades:
		parked.append(blade.global_transform)
	game.weather.intensity.x = 1.0
	game._advance_wipers(PI / 5.4)
	for i in blades.size():
		var blade := blades[i] as MeshInstance3D
		var centre := blade.get_aabb().get_center()
		if blade.to_global(centre).y < (parked[i] * centre).y + .1:
			printerr("Rain should sweep each blade up the glass")
			quit(1)
			return
	game.weather.intensity = Vector2.ZERO
	game._advance_wipers(2.0)
	for i in blades.size():
		if not blades[i].global_transform.is_equal_approx(parked[i]):
			printerr("Both blades must park after rain stops")
			quit(1)
			return
	game._toggle_camera_view()
	if not game.cockpit_view or absf(truck.to_local(game.camera.global_position).x - wheel_x) > .02:
		printerr("Cab camera must face the road from the driver's seat")
		quit(1)
		return
	print("Fire engine wheel, both drivers and cockpit camera share the left seat.")
	quit()
