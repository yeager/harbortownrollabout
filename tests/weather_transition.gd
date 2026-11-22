extends SceneTree

func _initialize() -> void:
	call_deferred("check_transition")

func check_transition() -> void:
	var weather := preload("res://city_weather.gd").new()
	root.add_child(weather)
	weather.weather_setting = 3
	for second in range(5):
		weather.tick(1.0)
	if weather.cloud_cover <= 0 or weather.intensity.y > 0:
		printerr("Clouds should gather before the first flakes")
		quit(1)
		return
	for second in range(100):
		weather.tick(1.0)
	if not is_equal_approx(weather.intensity.y, 1.0):
		printerr("The requested snowfall never reached full strength")
		quit(1)
		return
	weather.weather_setting = 0
	weather.tick(1.0)
	if weather.forecast != 3 or not is_equal_approx(weather.intensity.y, 1.0):
		printerr("Automatic weather lost the ongoing snowfall")
		quit(1)
		return
	weather.weather_setting = 4
	for second in range(160):
		weather.tick(1.0)
	if not Vector2(weather.wet, weather.snow).is_equal_approx(Vector2(.65, .55)):
		printerr("Slush should leave both moisture and snow on the ground")
		quit(1)
		return
	if not weather.rain_particles.emitting or not weather.snow_particles.emitting:
		printerr("Slush needs both particle emitters")
		quit(1)
		return
	weather.weather_setting = 1
	for second in range(150):
		weather.tick(1.0)
	if weather.rain_particles.emitting or weather.snow_particles.emitting:
		printerr("Clear weather should stop both particle emitters")
		quit(1)
		return
	weather.season_setting = 4
	weather.weather_setting = 3
	for second in range(160): weather.tick(1.0)
	weather.season_setting = 2
	if weather.snow > 0 or weather.snow_particles.emitting or weather.weather_setting != 0 or weather.forecast != 1:
		printerr("Summer retained winter snowfall")
		quit(1)
		return
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	game.weather.season_setting = 4
	game.weather.weather_setting = 4
	game.weather.tick(160)
	game._process(0)
	var ground := [game.road_finish,game.marking_finish,game.sidewalk_finish,game.soil_finish,game.quay_finish]
	for surface in ground:
		if surface.get_shader_parameter("snow_cover") <= 0:
			printerr("Winter slush failed to reach the ground material")
			quit(1)
			return
	game.snow_marks.visible_instance_count = 1
	game.snow_cursor = 1
	game.weather.season_setting = 2
	game._process(0)
	for surface in ground:
		if surface.get_shader_parameter("snow_cover") != 0.0:
			printerr("Summer retained visible ground snow")
			quit(1)
			return
	if game.snow_marks.visible_instance_count != 0 or game.snow_cursor != 0 or game.snow_track_finish.albedo_color.a > 0:
		printerr("Summer retained snow tracks")
		quit(1)
		return
	if game.weather.snow_particles.emitting or not game.weather.rain_particles.emitting:
		printerr("Winter slush did not change to summer rain")
		quit(1)
		return
	print("Snowfall, slush and summer transitions verified on ground materials, tracks and emitters.")
	quit()
