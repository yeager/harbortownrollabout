extends Node3D

const SEASONS := ["Season · Automatic", "Spring", "Summer", "Autumn", "Winter"]
const CONDITIONS := ["Weather · Automatic", "Sun", "Rain", "Snow", "Slush"]
const PRECIPITATION := [Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2(.65,.55)]
var season_setting := 0:
	set(value):
		if value == season_setting: return
		season_setting = value
		season_age = 0
		if value != 0: season = value

var weather_setting := 0:
	set(value):
		if value == weather_setting: return
		if value == 0: forecast = weather_setting
		weather_setting = value
		forecast_age = 0
var season := 2
var forecast := 1
var season_age := 0.0
var forecast_age := 0.0
var intensity := Vector2.ZERO
var wet := 0.0
var snow := 0.0
var rain_particles: GPUParticles3D
var snow_particles: GPUParticles3D

func _ready() -> void:
	rain_particles = particles(false)
	snow_particles = particles(true)
	# Start a new session in the chosen conditions. Later changes still ease in.
	intensity = PRECIPITATION[weather_setting if weather_setting else forecast]
	wet = intensity.x
	snow = intensity.y
	rain_particles.amount_ratio = wet
	snow_particles.amount_ratio = snow

func particles(flakes: bool) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(15,1,15)
	motion.direction = Vector3(.12,-1,.06)
	motion.spread = 7 if flakes else 2
	motion.gravity = Vector3.ZERO
	motion.initial_velocity_min = 1.7 if flakes else 12.0
	motion.initial_velocity_max = 2.4 if flakes else 14.0
	emitter.process_material = motion
	var drop := BoxMesh.new()
	drop.size = Vector3(.045,.035,.04) if flakes else Vector3(.014,.20,.012)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("#e7edf1") if flakes else Color("#a2b7c2")
	drop.material = finish
	emitter.draw_pass_1 = drop
	emitter.amount = 1200
	emitter.amount_ratio = 0
	emitter.lifetime = 8 if flakes else 1.4
	emitter.visibility_aabb = AABB(Vector3(-24,-24,-24),Vector3(48,29,48))
	emitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(emitter)
	return emitter

func tick(delta: float) -> void:
	if season_setting == 0: season_age += delta
	if weather_setting == 0: forecast_age += delta
	if season_age >= 1800:
		season = season%4+1
		season_age = 0
	if forecast_age >= 300:
		forecast_age = 0
		var choices := [1,2] if season != 4 else [1,3,4]
		choices.erase(forecast)
		forecast = choices.pick_random()
	if season != 4 and forecast in [3,4]:
		forecast = 2
	var target: Vector2 = PRECIPITATION[weather_setting if weather_setting else forecast]
	intensity = intensity.move_toward(target,delta/(75.0 if weather_setting==0 else 8.0))
	var previous_snow := snow
	snow = move_toward(snow,intensity.y,delta/55)
	var meltwater := maxf(0.0,previous_snow-snow)
	# Melt first wets exposed pavement, which then dries more slowly than rain accumulates.
	var moisture_time := 35.0 if intensity.x > wet else 95.0
	wet = minf(1.0,move_toward(wet,intensity.x,delta/moisture_time)+meltwater)
	rain_particles.amount_ratio = intensity.x
	snow_particles.amount_ratio = intensity.y
