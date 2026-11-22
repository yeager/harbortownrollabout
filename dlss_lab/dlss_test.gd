extends Node3D

## Reproducible visual and performance harness for temporal upscaler work.
## Run with: godot --path . --rendering-method forward_plus res://dlss_lab/dlss_test.tscn

const GAME_SCENE := preload("res://main.tscn")
const LOG_INTERVAL := 5.0
const WARMUP_SECONDS := 30.0
const SCENARIO_VEHICLE_INDEX := 1 # Swedish patrol SUV/saloon; emergency lights and siren are reproducible.

var elapsed := 0.0
var sample_elapsed := 0.0
var frame_count := 0
var frame_times_ms: Array[float] = []
var hud: Label
var game: Node3D

func _ready() -> void:
	get_tree().get_root().set_meta("dlss_lab_autostart", {"vehicle_index": SCENARIO_VEHICLE_INDEX})
	game = GAME_SCENE.instantiate()
	game.name = "Game"
	add_child(game)
	# Start directly in a repeatable active city scene. The root-meta contract is
	# opt-in and only used by this lab, so normal game startup is unchanged.
	await get_tree().process_frame
	get_tree().get_root().remove_meta("dlss_lab_autostart")
	await get_tree().process_frame
	var dlss_runtime_supported: bool = game._active_renderer_reports_dlss()
	print("DLSS-SR runtime capability query: %s" % ("supported" if dlss_runtime_supported else "unsupported/unavailable"))
	if "--fsr2" in OS.get_cmdline_user_args():
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		get_viewport().scaling_3d_scale = 0.75
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	elif "--dlss" in OS.get_cmdline_user_args():
		get_viewport().set("scaling_3d_mode", 5)
		get_viewport().scaling_3d_scale = 0.67
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	game.weather.season_setting = 2
	game.weather.weather_setting = 2
	game.weather.season = 2
	game.day_phase = 0.5
	game.time_mode = 1 # Fixed night: stable high contrast for rain and vehicle lights.
	game.lights_on = true
	game.sound_on = false # Sirens are disabled so audio and CPU load are consistent.
	game._update_emergency_lights()
	game._update_daylight(0.0)
	game._refresh_ui()
	# Make the camera drive a deterministic slow orbit around the city, exposing
	# traffic, pedestrians, trees, water and wet-road highlights to temporal AA.
	game.orbit_angle = 0.0
	game.orbit_height = 4.0
	game._update_camera(0.0, true)
	game.set_process(true)
	hud = Label.new()
	hud.position = Vector2(16, 16)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(hud)
	add_child(layer)
	var requested_mode := "DLSS NGX requested · 67%" if "--dlss" in OS.get_cmdline_user_args() else ("FSR 2.2 · 75%" if "--fsr2" in OS.get_cmdline_user_args() else "Native · 100%")
	print("DLSS lab: active city drive started (%s, vehicle index %d). Check renderer output for NGX feature creation/evaluation before treating DLSS as active. Warm-up %.0fs; FPS/frame-time values are CPU-side frame pacing, not GPU timing." % [requested_mode, SCENARIO_VEHICLE_INDEX, WARMUP_SECONDS])

func _process(delta: float) -> void:
	elapsed += delta
	# Hold gameplay time fixed and only advance the orbit camera. This preserves
	# moving traffic and pedestrians while keeping weather/lighting repeatable.
	game.day_phase = 0.5
	game.patrol_angle = fmod(elapsed * 0.055, TAU)
	game.orbit_angle = fmod(elapsed * 0.055, TAU)
	game.orbit_height = 3.0 + sin(elapsed * 0.025) * 1.2
	game._update_camera(delta)
	var frame_ms := delta * 1000.0
	if elapsed > WARMUP_SECONDS:
		sample_elapsed += delta
		frame_count += 1
		frame_times_ms.append(frame_ms)
	if sample_elapsed >= LOG_INTERVAL:
		var sorted_times := frame_times_ms.duplicate()
		sorted_times.sort()
		var avg_ms := sample_elapsed * 1000.0 / maxf(1.0, float(frame_count))
		var p50_ms := _percentile(sorted_times, 0.50)
		var p95_ms := _percentile(sorted_times, 0.95)
		var p99_index := clampi(int(ceil(sorted_times.size() * 0.99)) - 1, 0, sorted_times.size() - 1)
		var p99_ms: float = sorted_times[p99_index] if not sorted_times.is_empty() else 0.0
		var average_fps := 1000.0 / avg_ms if avg_ms > 0.0 else 0.0
		print("DLSS lab sample %.0fs: avg %.1f FPS, frame ms avg/p50/p95/p99 %.2f/%.2f/%.2f/%.2f (CPU-side pacing)" % [elapsed - WARMUP_SECONDS, average_fps, avg_ms, p50_ms, p95_ms, p99_ms])
		frame_count = 0
		sample_elapsed = 0.0
		frame_times_ms.clear()
	if hud:
		var status := "Warm-up %ds" % int(ceil(WARMUP_SECONDS - elapsed)) if elapsed < WARMUP_SECONDS else "Sampling · CPU frame pacing"
		var render_mode := "DLSS NGX requested" if "--dlss" in OS.get_cmdline_user_args() else ("FSR 2.2" if "--fsr2" in OS.get_cmdline_user_args() else "Native Forward+")
		hud.text = "DLSS evaluation · %s\nFPS: %d  |  elapsed: %02d:%02d\n%s\nCamera motion: orbit with middle mouse" % [render_mode, Engine.get_frames_per_second(), int(elapsed / 60.0), int(fmod(elapsed, 60.0)), status]

func _percentile(sorted_values: Array[float], percentile: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(int(ceil(sorted_values.size() * percentile)) - 1, 0, sorted_values.size() - 1)
	return sorted_values[index]
