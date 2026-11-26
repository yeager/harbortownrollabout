extends Node3D

## The touchdown origin coincides with the bottom of the skids.
const MODEL = preload("res://vehicles/ambulance_helicopter.glb")
const RotorMotion := preload("res://scripts/rotor_motion.gd")
const LANDING_YAW := PI * .5
const SEGMENT_SECONDS := [20.0, 14.0, 12.0, 15.0, 11.0, 16.0, 18.0, 18.0]
const CYCLE_SECONDS := 124.0
const TOUCHDOWN_AT := 46.0
const LIFTOFF_AT := 61.0

var pad: Vector3
var flight_seconds := 29.0
var main_rotor: Node3D
var tail_rotor: Node3D
var rotor_blur: Array[MeshInstance3D] = []
var rotor_audio := AudioStreamPlayer3D.new()


func configure(landing_center: Vector3) -> void:
	name = "Ambulance Helicopter Flight"
	pad = landing_center
	var aircraft := MODEL.instantiate()
	add_child(aircraft)
	main_rotor = aircraft.find_child("MainRotor", true, false) as Node3D
	tail_rotor = aircraft.find_child("TailRotor", true, false) as Node3D
	rotor_blur = [RotorMotion.fit(main_rotor, 4.955, 5), RotorMotion.fit(tail_rotor, .515, 9, true)]
	var rotor_loop := preload("res://audio/medical_helicopter_rotor.wav").duplicate() as AudioStreamWAV
	rotor_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rotor_loop.loop_end = roundi(rotor_loop.get_length() * rotor_loop.mix_rate)
	rotor_audio.name = "Medical helicopter rotor sound"
	rotor_audio.stream = rotor_loop
	rotor_audio.bus = &"Traffic and radio"
	rotor_audio.position.y = 2.8
	rotor_audio.unit_size = 15.0
	rotor_audio.max_distance = 125.0
	add_child(rotor_audio)
	advance(0.0)
	rotation.y = LANDING_YAW


func set_audio_active(active: bool) -> void:
	if active and not rotor_audio.playing:
		rotor_audio.play()
	elif not active and rotor_audio.playing:
		rotor_audio.stop()


func advance(delta: float) -> void:
	flight_seconds = fposmod(flight_seconds + delta, CYCLE_SECONDS)
	var waypoints := [
		pad + Vector3(-205, 40, -105),
		pad + Vector3(-83, 33, 0),
		pad + Vector3.UP * 24.0,
		pad,
		pad,
		pad + Vector3.UP * 25.0,
		pad + Vector3(109, 44, 0),
		pad + Vector3(17, 49, -164),
		pad + Vector3(-205, 40, -105),
	]
	var phase := 0
	var remaining := flight_seconds
	while remaining >= SEGMENT_SECONDS[phase] and phase < SEGMENT_SECONDS.size() - 1:
		remaining -= SEGMENT_SECONDS[phase]
		phase += 1
	var from: Vector3 = waypoints[phase]
	var toward: Vector3 = waypoints[phase + 1]
	var progress: float = remaining / SEGMENT_SECONDS[phase]
	position = from.lerp(toward, smoothstep(0.0, 1.0, progress))
	var track := toward - from
	var heading := LANDING_YAW if is_zero_approx(Vector2(track.x, track.z).length_squared()) else atan2(track.x, track.z)
	rotation.y = rotate_toward(rotation.y, heading, delta * .45)
	var rotor_rate := 28.0
	if phase == 3:
		# Slow the blades while on the pad, then bring them up before lifting off.
		rotor_rate = lerpf(28.0, 3.0, smoothstep(0.0, .28, progress))
		rotor_rate = lerpf(rotor_rate, 28.0, smoothstep(.68, 1.0, progress))
	main_rotor.rotate_y(delta * rotor_rate)
	tail_rotor.rotate_x(delta * rotor_rate * 2.0)
	var power := rotor_rate / 28.0
	for motion in rotor_blur:
		motion.material_override.set_shader_parameter("power", power)
	rotor_audio.pitch_scale = lerpf(.48, 1.0, power)
	rotor_audio.volume_db = lerpf(-28.0, -10.0, power)
