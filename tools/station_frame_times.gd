extends SceneTree
## Run with --rendering-method gl_compatibility. The benchmark opens a 960 × 600 window.
## Use a fresh XDG_DATA_HOME so saved game preferences do not influence the run.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 600)
	seed(74)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	Engine.max_fps = 0
	game.time_mode = 2
	game.day_phase = .27
	game.weather.season_setting = 2
	game.weather.weather_setting = 2
	game.weather.tick(160)
	var station_x: float = game.STATION_DROP.x
	game.ambulance.rotation.y = -PI/2
	var times := PackedFloat64Array()
	var previous := 0
	for frame in range(-60,241):
		game.day_phase = .27
		var x := station_x - 24.0 + maxf(frame,0)*.2
		game.ambulance.position = Vector3(x,game._surface_height(x,2.35),2.35)
		game._update_camera(0,true)
		await process_frame
		var now := Time.get_ticks_usec()
		if frame > 0:
			times.append((now-previous)/1000.0)
		previous = now
	if game.traffic_data.is_empty() or not game.weather.rain_particles.emitting or game.last_night < .5:
		printerr("Benchmark conditions were not active")
		quit(1)
		return
	times.sort()
	print("Station drive | ",RenderingServer.get_video_adapter_name()," | ",root.size,
		" | traffic ",game.traffic_data.size()," | frames ",times.size(),
		" | median %.2f ms | p95 %.2f ms | max %.2f ms" % [
			(times[119]+times[120])*.5,times[227],times[-1]])
	quit()
