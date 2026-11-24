extends SceneTree

class WeatherMenuGame extends "res://scripts/main.gd":
	# Menu selections in this test must leave the player's preferences untouched.
	func _save_preferences() -> void:
		pass

func _initialize() -> void:
	call_deferred("check_transition")

func check_transition() -> void:
	var weather := preload("res://scripts/city_weather.gd").new()
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
	var marks_before_plough := game.sole_marks.visible_instance_count
	var strip := Transform3D(Basis.IDENTITY, game.walker.position + Vector3.FORWARD)
	game.ground_work.sweep(strip, strip.translated(Vector3.BACK*2), Vector3.LEFT, Vector3.RIGHT, false)
	for i in 24:
		game._animate_steps(game.walker, .08, .033)
	if game.footstep.stream != game.DRY_STEP or game.sole_marks.visible_instance_count != marks_before_plough:
		printerr("Walking on ploughed ground should sound dry and leave no new prints")
		quit(1)
		return
	game.walker.position.x += 3
	for i in 24:
		game._animate_steps(game.walker, .08, .033)
	if game.footstep.stream != game.SNOW_STEP or game.sole_marks.visible_instance_count <= marks_before_plough:
		printerr("Stepping off the ploughed strip should restore crunch and footprints")
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
	var spruce := game.christmas_spruce
	game.time_mode = 0
	game._update_daylight(0)
	if not spruce.visible or spruce.glow.visible:
		printerr("Snowy square should have a tree with unlit daytime bulbs")
		quit(1)
		return
	game.time_mode = 1
	game._update_daylight(0)
	if not spruce.glow.visible or spruce.bulbs.size() < 4 or spruce.bulbs[0].emission_energy_multiplier < 1:
		printerr("Missing illuminated Christmas bulbs at night")
		quit(1)
		return
	game.time_mode = 2
	var evening_levels: Array[float] = []
	for phase in [.0, .24, .5, .76, .0]:
		game.day_phase = phase
		game._update_daylight(0)
		evening_levels.append(spruce.star_finish.emission_energy_multiplier)
		for bulb in spruce.bulbs:
			if (bulb.emission_energy_multiplier > 0) != spruce.glow.visible:
				printerr("Tree bulbs disagree with square lighting at phase ", phase)
				quit(1)
				return
	if evening_levels[0] != 0 or evening_levels[4] != 0 or not (0 < evening_levels[1] and evening_levels[1] < evening_levels[2] and is_equal_approx(evening_levels[3], evening_levels[1])):
		printerr("Unexpected star brightness from noon through dawn: ", evening_levels)
		quit(1)
		return
	seasons.get_child(2).pressed.emit()
	game._update_daylight(0)
	if spruce.visible or game.roadside_solids.has(spruce.obstacle):
		printerr("Seasonal tree remained on summer square")
		quit(1)
		return
	var pole := game.midsummer_pole
	var fountain := game.field_fountain
	for season in [2, 3, 4, 1, 2]:
		seasons.get_child(season).pressed.emit()
		game._process(0)
		var summer: bool = season == 2
		if pole.visible != summer or game.roadside_solids.count(pole.obstacle) != int(summer):
			printerr("Midsummer pole visibility or collision is wrong in season ", season)
			quit(1)
			return
		if fountain.jets.is_empty() or fountain.covers.visible != (season == 4):
			printerr("Fountain nozzles or winter covers are missing")
			quit(1)
			return
		for jet in fountain.jets:
			if jet.emitting != summer or jet.visible != summer:
				printerr("Fountain spray is wrong in season ", season)
				quit(1)
				return
	game.footstep.stop()
	game.free()
	weather.free()
	await process_frame
	await process_frame
	print("Weather transitions verified on surfaces, tracks, footprints, footsteps and emitters.")
	quit()
