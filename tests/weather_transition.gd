extends SceneTree

class WeatherMenuGame extends "res://main.gd":
	# Menu selections in this test must leave the player's preferences untouched.
	func _save_preferences() -> void:
		pass

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
	var game := WeatherMenuGame.new()
	root.add_child(game)
	var seasons := game.find_child("SeasonChoices", true, false)
	var conditions := game.find_child("WeatherChoices", true, false)
	if not seasons or not conditions:
		printerr("Weather settings buttons missing")
		quit(1)
		return
	seasons.get_child(4).pressed.emit()
	conditions.get_child(4).pressed.emit()
	game.weather.tick(160)
	game._process(0)
	var ground := [game.road_finish,game.marking_finish,game.sidewalk_finish,game.soil_finish,game.quay_finish]
	for surface in ground:
		if surface.get_shader_parameter("snow_cover") <= 0:
			printerr("Winter slush failed to reach the ground material")
			quit(1)
			return
	game.walker.visible = true
	game.walker.position = Vector3(-24, 0, 28)
	for i in 24:
		game._animate_steps(game.walker, .08, .033)
	if game.footstep.stream != game.SNOW_STEP or game.sole_marks.visible_instance_count == 0:
		printerr("Winter steps should crunch and leave footprints")
		quit(1)
		return
	game.snow_marks.visible_instance_count = 1
	game.snow_cursor = 1
	seasons.get_child(2).pressed.emit()
	game._process(0)
	for surface in ground:
		if surface.get_shader_parameter("snow_cover") != 0.0:
			printerr("Summer retained visible ground snow")
			quit(1)
			return
	if game.snow_marks.visible_instance_count != 0 or game.snow_cursor != 0 or game.snow_track_finish.get_shader_parameter("snow_opacity") > 0:
		printerr("Summer retained snow tracks")
		quit(1)
		return
	if game.weather.snow_particles.emitting or not game.weather.rain_particles.emitting:
		printerr("Winter slush did not change to summer rain")
		quit(1)
		return
	for i in 24:
		game._animate_steps(game.walker, .08, .033)
	if game.footstep.stream != game.DRY_STEP or game.sole_marks.visible_instance_count != 0 or game.sole_cursor != 0:
		printerr("Summer retained winter footsteps")
		quit(1)
		return
	seasons.get_child(4).pressed.emit()
	conditions.get_child(3).pressed.emit()
	game.weather.tick(160)
	game._process(0)
	if game.sole_marks.visible_instance_count != 0:
		printerr("Old footprints reappeared after fresh snowfall")
		quit(1)
		return
	for i in 24:
		game._animate_steps(game.walker, .08, .033)
	if game.footstep.stream != game.SNOW_STEP or game.sole_marks.visible_instance_count == 0:
		printerr("Fresh snowfall should restore snow footsteps")
		quit(1)
		return
	game.footstep.stop()
	game.free()
	weather.free()
	await process_frame
	await process_frame
	print("Weather transitions verified on surfaces, tracks, footprints, footsteps and emitters.")
	quit()
