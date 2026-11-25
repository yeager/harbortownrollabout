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
	var ploughed_position := game.walker.position
	if game.ploughs.is_empty() or not game.ploughs.all(func(blade: Node3D): return blade.visible):
		printerr("The tractor plough should be fitted in winter")
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
	if game.ploughs.any(func(blade: Node3D): return blade.visible):
		printerr("Summer retained the tractor plough")
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
	if game.ground_work.cleared_at(ploughed_position) or not game.ploughs.all(func(blade: Node3D): return blade.visible):
		printerr("A new winter retained the cleared strip or failed to restore the plough")
		quit(1)
		return
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
	var bulb_colors := {}
	for bulb in spruce.bulbs:
		bulb_colors[bulb.emission] = true
	if bulb_colors.size() < 4:
		printerr("Christmas lights should have at least four distinct colours")
		quit(1)
		return
	var winter_cover := game.weather.snow
	game.weather.snow = 0.0
	game._update_daylight(0)
	game._update_pedestrians(0)
	if spruce.visible or game.roadside_solids.has(spruce.obstacle) or game.santa.visible or game.midsummer_pole.visible:
		printerr("Snow-free winter should leave the square clear of seasonal decorations")
		quit(1)
		return
	game.weather.snow = winter_cover
	game._update_daylight(0)
	game._update_pedestrians(0)
	if not spruce.visible or game.roadside_solids.count(spruce.obstacle) != 1 or not game.santa.visible:
		printerr("Returning winter snow should restore the tree and Santa once")
		quit(1)
		return
	print("Snow-free winter clears the tree and Santa; snowfall restores both and four or more light colours.")
	game._apply_calm_mode(false)
	game._update_daylight(.75)
	if game.chimney_beacon.emission_enabled or not game.shops.candy_blade_glow.emission_enabled:
		printerr("The candy sign should stay lit between chimney flashes")
		quit(1)
		return
	game._apply_calm_mode(true)
	game._update_daylight(2.75)
	if not game.chimney_beacon.emission_enabled:
		printerr("The chimney beacon should stay lit in calm mode")
		quit(1)
		return
	game._apply_calm_mode(false)
	game._update_daylight(.25)
	if not game.chimney_beacon.emission_enabled:
		printerr("The chimney beacon should resume with a lit pulse")
		quit(1)
		return
	game.time_mode = 2
	var evening_levels: Array[float] = []
	var sun_rays := PackedVector3Array()
	for phase in [.0, .24, .5, .76, .0]:
		game.day_phase = phase
		game._update_daylight(0)
		sun_rays.append(-game.city_sun.global_basis.z)
		evening_levels.append(spruce.star_finish.emission_energy_multiplier)
		for bulb in spruce.bulbs:
			if (bulb.emission_energy_multiplier > 0) != spruce.glow.visible:
				printerr("Tree bulbs disagree with square lighting at phase ", phase)
				quit(1)
				return
	if not game.city_sun.shadow_enabled or sun_rays[1].x * sun_rays[3].x >= 0 or sun_rays[0].y >= maxf(sun_rays[1].y, sun_rays[3].y) or not sun_rays[0].is_equal_approx(sun_rays[4]):
		printerr("Shadow-casting sunlight did not sweep from morning to evening: ", sun_rays)
		quit(1)
		return
	if evening_levels[0] != 0 or evening_levels[4] != 0 or not (0 < evening_levels[1] and evening_levels[1] < evening_levels[2] and is_equal_approx(evening_levels[3], evening_levels[1])):
		printerr("Unexpected star brightness from noon through dawn: ", evening_levels)
		quit(1)
		return
	if game.chimney_beacon.emission_enabled or game.shops.candy_blade_glow.emission_enabled:
		printerr("Night lighting remained on after the cycle reached noon")
		quit(1)
		return
	var original_cloud: float = game.weather.cloud_cover
	var shadow_levels := PackedFloat32Array()
	var sunlight_levels := PackedFloat32Array()
	for coverage in [0.0, 0.5, 1.0, 0.0]:
		game.weather.cloud_cover = coverage
		game._update_daylight(0)
		shadow_levels.append(game.city_sun.shadow_opacity)
		sunlight_levels.append(game.city_sun.light_energy)
	if not (shadow_levels[0] > shadow_levels[1] and shadow_levels[1] > shadow_levels[2] and shadow_levels[0] == shadow_levels[3]
			and sunlight_levels[0] > sunlight_levels[1] and sunlight_levels[1] > sunlight_levels[2] and sunlight_levels[0] == sunlight_levels[3]):
		printerr("Clouds did not gradually soften the sun and its shadows")
		quit(1)
		return
	game.weather.cloud_cover = original_cloud
	game._update_daylight(0)
	game.walker.position = game.santa.position
	game.bubble_time = 0
	game.santa_encounters.clear()
	game._update_pedestrians(0)
	if not game.santa.visible or game.greeting.get_parent() != game.santa or game.speech_key != "Ho ho ho" or game.greeting_voice.stream == null:
		printerr("Santa should greet a nearby walker in snowy winter")
		quit(1)
		return
	game.bubble_time = 0.0
	game._update_santa_encounters()
	if game.bubble_time > 0.0 or not game.santa_encounters.has(game.walker):
		printerr("Santa repeated his greeting during the same encounter")
		quit(1)
		return
	game.walker.position = game.santa.position + Vector3.RIGHT * 6.0
	game._update_santa_encounters()
	game.walker.position = game.santa.position
	game._update_santa_encounters()
	if game.bubble_time <= 0.0 or not game.santa_encounters.has(game.walker):
		printerr("Santa did not greet the returning walker")
		quit(1)
		return
	seasons.get_child(2).pressed.emit()
	game._update_daylight(0)
	game._update_pedestrians(0)
	if game.santa.visible or not game.santa_encounters.is_empty() or (game.greeting.get_parent() == game.santa and (game.greeting.visible or game.greeting_voice.playing)):
		printerr("Santa or his greeting remained after switching to summer")
		quit(1)
		return
	if spruce.visible or game.roadside_solids.has(spruce.obstacle):
		printerr("Seasonal tree remained on summer square")
		quit(1)
		return
	var pole := game.midsummer_pole
	var fountain := game.field_fountain
	var opening_speeds := PackedFloat32Array()
	for season in [2, 3, 4, 1, 2]:
		seasons.get_child(season).pressed.emit()
		game._process(0)
		var summer: bool = season == 2
		for step in 12:
			var path_point: Vector3 = game.FOUNTAIN_APPROACH + Vector3.FORWARD * step * .25
			path_point.y = game._foot_height(path_point.x, path_point.z)
			if not game._on_foot_clear(path_point):
				printerr("Fountain approach is blocked at ", path_point, " in season ", season)
				quit(1)
				return
		if pole.visible != summer or game.roadside_solids.count(pole.obstacle) != int(summer):
			printerr("Midsummer pole visibility or collision is wrong in season ", season)
			quit(1)
			return
		var snowy_winter: bool = season == 4 and game.weather.snow > .02
		if spruce.visible != snowy_winter or game.roadside_solids.count(spruce.obstacle) != int(snowy_winter):
			printerr("The square retained the wrong tree or collision in season ", season)
			quit(1)
			return
		if summer:
			var anchors := PackedVector3Array()
			for wreath in pole.wreaths:
				anchors.append(wreath.position)
			pole.move_wreaths(0.0, 0.4)
			var first_pose: Vector3 = pole.wreaths[0].rotation
			pole.move_wreaths(0.9, 0.4)
			if anchors.size() != 2 or pole.wreaths[0].rotation.is_equal_approx(first_pose) or pole.wreaths[0].position != anchors[0] or pole.wreaths[1].position != anchors[1]:
				printerr("Summer wreaths did not sway around fixed hanging points")
				quit(1)
				return
		if fountain.jets.size() != 16 or fountain.covers.get_child_count() != 16 or fountain.covers.visible != (season == 4):
			printerr("Fountain nozzles or winter covers are missing")
			quit(1)
			return
		for jet in fountain.jets:
			if jet.emitting != summer or jet.visible != summer:
				printerr("Fountain spray is wrong in season ", season)
				quit(1)
				return
		if fountain.is_processing() != summer or fountain.spray_audio.playing != summer:
			printerr("Fountain animation or positional sound did not follow the summer schedule")
			quit(1)
			return
		if summer:
			var speeds := PackedFloat32Array()
			for jet in fountain.jets:
				speeds.append(jet.initial_velocity_max)
			if opening_speeds.is_empty():
				opening_speeds = speeds
			elif speeds != opening_speeds:
				printerr("New summer did not restart every nozzle at its opening velocity")
				quit(1)
				return
			var speed := fountain.jets[0].initial_velocity_max
			fountain._process(.5)
			if is_equal_approx(fountain.jets[0].initial_velocity_max, speed):
				printerr("Fountain spray height did not change")
				quit(1)
				return
	print("Fountain restarts its animated spray each summer.")
	seasons.get_child(4).pressed.emit()
	conditions.get_child(3).pressed.emit()
	game.weather.tick(160)
	game.mode = "menu"
	game._on_vehicle_selected(game.FARM_TRACTOR)
	game.start_button.pressed.emit()
	game.traffic_data.clear()
	game.ambulance.position = Vector3(-285, 0, 2.35)
	game.ambulance.rotation.y = PI * .5
	game._process(0)
	var blade_midpoint := game.vehicle_model.to_global((game.blade_left + game.blade_right) * .5)
	var ahead := blade_midpoint + Vector3.LEFT
	var outside_blade := ahead + Vector3.BACK * 3.0
	game.mouse_gas = true
	for frame in 100:
		game._drive(1.0 / 60.0)
	game.mouse_gas = false
	if not game.ground_work.cleared_at(ahead) or game.ground_work.cleared_at(outside_blade):
		printerr("Driving the tractor did not clear only the strip swept by the blade")
		quit(1)
		return
	game.footstep.stop()
	game.free()
	weather.free()
	await process_frame
	await process_frame
	print("Weather transitions verified on surfaces, tracks, footprints, footsteps and emitters.")
	quit()
