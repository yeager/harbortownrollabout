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
	game._toggle_camera_view()
	if not game.cockpit_view or absf(truck.to_local(game.camera.global_position).x - wheel_x) > .02:
		printerr("Cab camera must face the road from the driver's seat")
		quit(1)
		return
	print("Fire engine wheel, both drivers and cockpit camera share the left seat.")
	quit()
