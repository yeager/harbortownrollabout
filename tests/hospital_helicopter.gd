extends SceneTree

func _initialize() -> void:
	call_deferred("check_landing")

func check_landing() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var aircraft: Node3D = game.medical_helicopter
	var pad: Vector3 = game.HOSPITAL_HELIPAD
	var audio: AudioStreamPlayer3D = aircraft.rotor_audio
	var rotor_loop := audio.stream as AudioStreamWAV
	if not rotor_loop or rotor_loop.loop_mode != AudioStreamWAV.LOOP_FORWARD or audio.bus != &"Traffic and radio" or audio.playing:
		printerr("Rotor sound did not use a spatial loop on the traffic bus, silent at the menu")
		quit(1)
		return
	game._start_game()
	game._process(0.0)
	if not audio.playing:
		printerr("Rotor sound did not start during play")
		quit(1)
		return
	var skids := aircraft.find_children("Black tubular skid*", "MeshInstance3D", true, false)
	if skids.size() != 2 or aircraft.main_rotor.get_child_count() != 7 or aircraft.tail_rotor.get_child_count() != 10:
		printerr("Medical aircraft is missing skids or working rotor assemblies")
		quit(1)
		return
	aircraft.flight_seconds = aircraft.TOUCHDOWN_AT - 8.0
	game._update_patrol(0.0)
	if aircraft.position.y <= pad.y + 3.0 or not is_equal_approx(aircraft.position.x, pad.x):
		printerr("The final descent did not start above the hospital")
		quit(1)
		return
	var before_rotor: float = aircraft.main_rotor.rotation.y
	game._update_patrol(8.0)
	if not aircraft.position.is_equal_approx(pad) or is_equal_approx(aircraft.main_rotor.rotation.y, before_rotor):
		printerr("Landing did not reach the pad with spinning blades")
		quit(1)
		return
	var flight_gain := audio.volume_db
	var flight_pitch := audio.pitch_scale
	game._update_patrol(7.0)
	if audio.pitch_scale >= flight_pitch or audio.volume_db >= flight_gain:
		printerr("Rotor sound did not slow and soften on the roof")
		quit(1)
		return
	for skid: MeshInstance3D in skids:
		var bounds := skid.global_transform * skid.get_aabb()
		if absf(bounds.position.y - pad.y) > .02:
			printerr("Skid did not meet the pad surface: ", bounds.position.y, " / ", pad.y)
			quit(1)
			return
	game._update_patrol(7.0)
	if not aircraft.position.is_equal_approx(pad):
		printerr("Aircraft did not wait on the roof")
		quit(1)
		return
	game._update_patrol(7.0)
	if aircraft.position.y <= pad.y + 8.0 or not is_equal_approx(aircraft.position.z, pad.z):
		printerr("Aircraft did not depart by climbing over the landing pad")
		quit(1)
		return
	if not is_equal_approx(audio.pitch_scale, flight_pitch) or not is_equal_approx(audio.volume_db, flight_gain):
		printerr("Rotor sound did not recover on takeoff")
		quit(1)
		return
	game._update_patrol(aircraft.CYCLE_SECONDS - aircraft.flight_seconds + aircraft.TOUCHDOWN_AT)
	if not aircraft.position.is_equal_approx(pad):
		printerr("A subsequent circuit did not return to the helipad")
		quit(1)
		return
	print("Medical helicopter descended, rested on both skids, lifted off and returned the next circuit.")
	game.paused = true
	game._process(0.0)
	if audio.playing:
		printerr("Pausing the game did not pause the rotor sound")
		quit(1)
		return
	print("Spatial rotor audio softened on the pad, ramped up for takeoff and paused with the game.")
	quit()
