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
	print("Manual snowfall builds gradually and continues in automatic mode.")
	quit()
