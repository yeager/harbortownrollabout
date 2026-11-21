extends Node3D

const TARGETS: Array[Vector3] = [Vector3(30, 0, 3), Vector3(0, 0, -25), Vector3(99.65, 0, -24)]
const WALK_TARGETS: Array[Vector3] = [Vector3(30,0,12), Vector3(6.35,0,-25), Vector3(90,0,-24)]
const TARGET_NAMES := ["Help at the square", "Pick up the medic", "Deliver first aid to the marina"]
const ROAD_HALF := 4.8
const VEHICLE_NAMES := ["Ambulance", "Police car", "Fire engine"]
const VEHICLE_SCENES := ["res://vehicles/ambulance.glb", "res://vehicles/polisbil.glb", "res://vehicles/brandbil.glb"]
const VEHICLE_NAMES_ALL := ["Ambulance", "Police car", "Fire engine", "BMW X5 M60i", "Taxi", "Recovery truck"]
const VEHICLE_SCENES_ALL := ["res://vehicles/ambulance.glb", "res://vehicles/polisbil.glb", "res://vehicles/brandbil.glb", "res://vehicles/bmw_x5_m60i.glb", "res://vehicles/taxi.glb", "res://vehicles/bargare.glb"]
const SIREN_SOUNDS := ["res://audio/siren_ambulance.wav", "res://audio/siren_police.wav", "res://audio/siren_fire.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav"]
const BUILDING_SCENES := {"Sjukhuset":"res://environment/sjukhus.glb", "Polisstationen":"res://environment/polisstation.glb", "Bageriet":"res://environment/bageri.glb", "Vårdcentralen":"res://environment/vardcentral.glb", "Brandstationen":"res://environment/brandstation.glb", "Biblioteket":"res://environment/bibliotek.glb"}
const TREE_SCENES := ["res://environment/lovtrad.glb", "res://environment/gran.glb", "res://environment/bredkronigt_lovtrad.glb"]

var ambulance: Node3D
var trunks := PackedVector3Array() # Centre X, trunk radius, centre Z.
var building_bounds: Array[AABB] = []
var pier_surfaces: Array[AABB] = []
var driving_surfaces: Array[AABB] = []
var reverse_feed: SubViewport
var reverse_camera: Camera3D
var reverse_monitor: Sprite3D
var dash_direction: Label3D
var dash_speed: Label3D
var vehicle_model: Node3D
var headlights: Array[SpotLight3D] = []
var bicycle_lenses: Array[StandardMaterial3D] = []
var traffic_headlights: Array[SpotLight3D] = []
var quay_finish := ShaderMaterial.new()
var soil_finish: ShaderMaterial
var sidewalk_finish: ShaderMaterial
var road_finish: ShaderMaterial
var apartment_lights: Array[StandardMaterial3D] = []
var city_env: Environment
var city_sun: DirectionalLight3D
var city_fill: OmniLight3D
var entrance_lights: Array[SpotLight3D] = []
var entrance_diffuser: StandardMaterial3D
var street_lights: Array[SpotLight3D] = []
var lamp_glass: StandardMaterial3D
var weather := preload("res://city_weather.gd").new()
var previous_season := 0
var greeting_timer := 0.0
var greeting_number := 0
var greeting := Label3D.new()
var wiper_pivots: Array[Node3D] = []
var wiper_phase := 0.0
var cockpit_look := Vector2.ZERO
var orbit_angle := 0.0
var orbit_height := 0.0
var time_mode := 0
var day_phase := 0.0
var last_night := -1.0
var walker: Node3D
var parked_cars: Array[Node3D] = []
var parked_footprints: Array[Rect2] = []
var parked_sizes: Array[Vector2] = []
var listener := AudioListener3D.new()
var walking_velocity := Vector3.ZERO
var walk_basis := Basis.IDENTITY
var crossing_pedestrian: Node3D
var crossing_wait := 4.0
var crossing_direction := 1.0
var walk_phase := 0.0
var entry_marker := Label3D.new()
const TAXI := 4
const HORNS := ["ambulance","police","fire","bmw","taxi","recovery"]
var horn := AudioStreamPlayer.new()
var horn_button: Button
const RECOVERY := 5
const SERVICE_STOPS := [Vector3(18,0,2.35), Vector3(34,0,-46), Vector3(126,0,-2.35), Vector3(34,0,-46)]
const SERVICE_MESSAGES := ["Collect the car with a smoking bonnet.","Take the car to the workshop.","Collect the car with a missing wheel.","Take the car to the workshop."]
var recovery_leg := 0
const WORKSHOP_CAR_BOUNDS := AABB(Vector3(27.9,-1,-40.86),Vector3(4.2,3,1.72))
var workshop_car: Node3D
var casualty: Node3D
var warning_triangle := Node3D.new()
var loose_wheel: Node3D
var lost_wheel: Node3D
var bonnet_smoke := CPUParticles3D.new()
var taxi_leg := 0
var arriving_passenger: Node3D
var passenger: Node3D
var seat_button: Button
var vehicle_index := 0
var activity := OptionButton.new()
var vehicle_selector: OptionButton
var camera_turn := 0.0
var cockpit_view := false
var camera_button: Button
var camera: Camera3D
var navigator := preload("res://street_route.gd").new()
var route_arrows: Array[Node3D] = []
var route_timer := 0.0
var medical_bag := Node3D.new()
var square_neighbour: Node3D
var marina_recipient: Node3D
var waiting_medic: Node3D
var mission_marker: Node3D
var reverse_lens: StandardMaterial3D
var front_reach := 0.0
var rear_reach := 0.0
var player_half_size := Vector2.ZERO # Local half-width and half-length.
var cabin_wheel: Node3D
var cabin_wheel_rest_basis := Basis.IDENTITY
var cabin_wheel_axis := Vector3.BACK
var front_knuckles: Array[Node3D] = []
var player_wheels: Array[Node3D] = []
var player_brake_lens: StandardMaterial3D
var driving_controls := preload("res://driving_controls.gd").new()
var release_walk_keys := false
var mouse_gas := false
var mouse_brake := false
var gentle_driving := true
var waiting_for_signal := false
var brake_held := false
var tire_player := AudioStreamPlayer.new()
var skid_marks := MultiMesh.new()
var skid_cursor := 0
var rear_tire_contacts := PackedVector3Array()
var skid_anchors := PackedVector3Array()
const SKID_CAPACITY := 2048
var speed := 0.0
var steering := 0.0
var free_drive := false
var mission_index := 0
var parked_at_target := 0.0
var mode := "menu"
var paused := false
var lights_on := false
var parked_light_settings: Array[bool] = [false, false, false, false, false, false]
var sound_on := true
var parked_sound_settings: Array[bool] = [false, false, false, true, true, true]
var siren_player: AudioStreamPlayer
var ui: CanvasLayer
var play_as_alma := false
var wallet := 0
var wallet_label: Label
var shops := preload("res://shop_street.gd").new()
var purchases := {}
var phone := preload("res://mission_phone.gd").new()
var last_dispatch := ""
var mission_label: Label
const HELP_DURATION := 0.8
var arrival_progress := ProgressBar.new()
var status_label: Label
var overlay: ColorRect
var overlay_panel: PanelContainer
var brand_logo := TextureRect.new()
var title_label: Label
var subtitle_label: Label
var start_button: Button
var preview_sound_button: Button
var light_button: Button
var siren_button: Button
var pause_button: Button
var message := ""
var message_timer := 0.0
var light_phase := 0.0
var blue_light_meshes: Array[MeshInstance3D] = []
var red_light_meshes: Array[MeshInstance3D] = []
var siren_streams: Array[AudioStreamWAV] = []
var tree_count := 0
var traffic_data: Array[Dictionary] = []
const SETTINGS_PATH := "user://preferences.cfg"
var traffic_siren_volume := 100.0
var traffic_light_mode := 0
var steady_player_lights := false
var emergency_traffic: Array[Dictionary] = []
var moorings: Array[Dictionary] = []
var street_signals := preload("res://street_signals.gd").new()
var tram := preload("res://tram.gd").new()
var boating := false
var grip_radius := 0.0
var road_driver: Node3D
var skipper: Node3D
var launch: Node3D
var navigation_lenses: Array[StandardMaterial3D] = []
var outboard: Node3D
var launch_speed := 0.0
var helicopter: Node3D
var main_rotor: Node3D
var tail_rotor: Node3D
var patrol_angle := 0.0
var tram_mode := 0
var water_finish := ShaderMaterial.new()
var saloon_glazing: StandardMaterial3D
var ferry: Node3D
var wave_time := 0.0
var walker_data: Array[Dictionary] = []

func _ready() -> void:
	_load_preferences()
	add_child(weather)
	_build_world()
	_build_ui()
	_build_brake_effects()
	_update_mission_marker()
	_refresh_ui()
	start_button.grab_focus()

func _process(delta: float) -> void:
	if mode == "playing" and not paused:
		weather.tick(delta)
		_advance_wipers(delta)
	if previous_season != weather.season:
		previous_season = weather.season
		for finish in foliage_finishes:
			var tint: Color = finish.albedo_color
			if not finish.resource_name.begins_with("Spruce"):
				match weather.season:
					1: tint = tint.lerp(Color("#9ab959"),.35)
					3: tint = tint.lerp(Color("#bd742e"),.72)
					4: tint = tint.lerp(Color("#acb2a8"),.78)
			foliage_finishes[finish].set_shader_parameter("leaf_color", tint)
	weather.position = camera.position + Vector3.UP*8
	for surface in [road_finish,sidewalk_finish,soil_finish,quay_finish]:
		surface.set_shader_parameter("wet",weather.wet)
		surface.set_shader_parameter("snow_cover",weather.snow)
	water_finish.set_shader_parameter("rain",weather.intensity.x)
	city_env.sky.sky_material.set_shader_parameter("overcast",maxf(weather.intensity.x,weather.intensity.y))
	_update_daylight(delta)
	if message_timer > 0.0:
		message_timer = maxf(0.0, message_timer - delta)
	if mode == "playing" and not paused:
		_update_patrol(delta)
		street_signals.advance(delta)
		var tram_gas := mouse_gas or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		var tram_brake := mouse_brake or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
		tram.advance(delta, tram_mode == 2, tram_gas, tram_brake)
		if tram_mode == 2:
			driving_controls.set_controls(0,tram_gas and not tram_brake,tram_brake)
		if boating:
			_drive_launch(delta)
		elif tram_mode > 0:
			_end_skid()
		elif walker.visible:
			_walk(delta)
		else:
			_drive(delta)
		_update_arrival(delta)
		route_timer -= delta
		if route_timer<=0:
			_update_route_arrows()
			route_timer=.3
		_update_traffic(delta)
		_update_pedestrians(delta)
		_update_moorings(delta)
		if vehicle_index >= 3 and siren_player.playing:
			siren_player.pitch_scale = 0.88 + clampf(absf(speed) / (250.0 / 3.6), 0.0, 1.0) * 0.72
	else:
		_end_skid()
	_update_traffic_signals(delta)
	if lights_on and not steady_player_lights and mode == "playing" and not paused:
		light_phase += delta * 3.2
		_update_emergency_lights()
	shops.update_customer(walker.visible and not boating and tram_mode==0,walker.position,mode=="playing" and not paused)
	weather.visible = shops.inside < 0
	_update_camera(delta)
	_refresh_status()

func _input(event: InputEvent) -> void:
	if mode == "playing" and not paused and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		if cockpit_view and not boating and tram_mode==0:
			cockpit_look.x = clampf(cockpit_look.x-event.relative.x*.007,-1.4,1.4)
			cockpit_look.y = clampf(cockpit_look.y-event.relative.y*.006,-.45,.52)
			return
		orbit_angle -= event.relative.x*.007
		orbit_height = clampf(orbit_height+event.relative.y*.022,-1.8,5)
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: mouse_gas = false
		if event.button_index == MOUSE_BUTTON_RIGHT: mouse_brake = false

func _unhandled_input(event: InputEvent) -> void:
	if mode == "playing" and not paused and (tram_mode == 2 or (tram_mode == 0 and (boating or not walker.visible))) and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: mouse_gas = true
		if event.button_index == MOUSE_BUTTON_RIGHT: mouse_brake = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		if shops.inside >= 0: shops.rebuild_menu()
		_update_mission_marker()
		_refresh_ui()
		driving_controls.queue_redraw()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_gas = false
		mouse_brake = false
		if mode == "playing" and not paused:
			_toggle_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				if phone.visible: phone.toggle()
			KEY_H: _honk()
			KEY_F: _change_seat()
			KEY_C: _toggle_camera_view()
			KEY_ESCAPE, KEY_P:
				if mode == "playing": _toggle_pause()
			KEY_SPACE:
				if mode == "playing" and not paused: _help_at_target()
			KEY_ENTER:
				if mode == "menu": _start_game()
			KEY_R:
				if mode == "complete": _start_game()

func _honk() -> void:
	if mode != "playing" or paused or (walker.visible and not boating and tram_mode == 0) or tram_mode == 1 or horn.playing: return
	horn.stream = load("res://audio/horn_%s.wav" % ("tram" if tram_mode == 2 else "motorboat" if boating else HORNS[vehicle_index]))
	horn.play()

func _update_patrol(delta: float) -> void:
	patrol_angle = fmod(patrol_angle+delta*.115,TAU)
	var a := patrol_angle
	helicopter.position = Vector3(54+74*sin(a),36+2*sin(2*a),-16+37*cos(a))
	var tangent := Vector3(74*cos(a),4*cos(2*a),-37*sin(a))
	# The Blender nose faces -Y, imported as local +Z.
	helicopter.look_at(helicopter.position+tangent,Vector3.UP,true)
	helicopter.rotate_object_local(Vector3.BACK,.095)
	main_rotor.rotate_y(delta*28)
	tail_rotor.rotate_x(delta*52)

func _drive_launch(delta: float) -> void:
	var gas := mouse_gas or Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W)
	var brake := mouse_brake or Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S)
	var turn := Input.get_axis("ui_left","ui_right")
	if Input.is_physical_key_pressed(KEY_A): turn=-1
	if Input.is_physical_key_pressed(KEY_D): turn=1
	var target := -1.6 if brake else (5.0 if gentle_driving else 9.0) if gas else 0.0
	launch_speed = move_toward(launch_speed,target,delta*(3.4 if brake else 1.5))
	var steering_flow := clampf(launch_speed,-1,2)
	if gas and not brake and launch_speed >= 0.0:
		steering_flow = maxf(.8,steering_flow)
	elif brake and launch_speed <= 0.0:
		steering_flow = minf(-.8,steering_flow)
	outboard.rotation.y = lerp_angle(outboard.rotation.y,-turn*.52,1-exp(-8*delta))
	launch.rotation.y -= turn*steering_flow*delta*.53
	var heading := Vector3.FORWARD.rotated(Vector3.UP,launch.rotation.y)
	var course := heading*signf(launch_speed)
	var clearance := INF
	if absf(course.x)>.0001:
		clearance = ((84.0 if course.x>0 else 58.0)-launch.position.x)/course.x
	if absf(course.z)>.0001:
		clearance = minf(clearance,((74.0 if course.z>0 else 9.0)-launch.position.z)/course.z)
	if clearance < INF:
		var frame_brake := 3.4*delta
		var safe_speed := sqrt(frame_brake*frame_brake+6.8*maxf(clearance,0))-frame_brake
		launch_speed = signf(launch_speed)*minf(absf(launch_speed),safe_speed)
	var next := launch.position+heading*launch_speed*delta
	var bounded := Vector3(clampf(next.x,58,84),-.94+.026*sin(wave_time*1.7),clampf(next.z,9,74))
	if absf(next.x-bounded.x)+absf(next.z-bounded.z)>.0001: launch_speed=0
	launch.position=bounded
	launch.rotation.z=lerpf(launch.rotation.z,-turn*absf(launch_speed)*.012,1-exp(-3*delta))
	driving_controls.set_controls(turn,gas,brake,launch_speed<-.1)

func _walk_pedal_pressed() -> bool:
	return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S)

func _drive(delta: float) -> void:
	var throttle := Input.get_axis("ui_down", "ui_up")
	var steer_input := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_W): throttle = 1.0
	if Input.is_key_pressed(KEY_S): throttle = -1.0
	if release_walk_keys:
		release_walk_keys = _walk_pedal_pressed()
		throttle = 0.0
	if mouse_gas: throttle = 1.0
	if mouse_brake: throttle = -1.0
	if Input.is_key_pressed(KEY_A): steer_input = -1.0
	if Input.is_key_pressed(KEY_D): steer_input = 1.0
	var max_speed := 250.0 / 3.6 if vehicle_index == 3 else 11.0
	var acceleration := lerpf(8.0, 2.3, clampf(speed / max_speed, 0.0, 1.0)) if vehicle_index == 3 else 7.2
	if gentle_driving:
		max_speed = 30.0 / 3.6
		acceleration = 6.0 if is_zero_approx(throttle) else 2.8
	if mouse_brake or (throttle < 0.0 and speed > 0.0):
		brake_held = true
	elif throttle >= 0.0:
		brake_held = false
	var previous_speed := speed
	var previous_pose := ambulance.global_transform
	if brake_held:
		speed = move_toward(speed, 0.0, (18.0 - 2.0*weather.wet - 3.0*weather.snow) * absf(throttle) * delta)
	elif throttle < 0.0:
		speed = move_toward(speed, throttle * (1.8 if gentle_driving else 4.0), 3.0 * delta)
	else:
		speed = move_toward(speed, throttle * max_speed, acceleration * delta)
	steering = move_toward(steering, steer_input, (2.0 if gentle_driving else 3.4) * delta)
	if cabin_wheel:
		cabin_wheel.basis = cabin_wheel_rest_basis * Basis(cabin_wheel_axis,-steering*1.2)
		_pose_driver_arms()
	for knuckle in front_knuckles:
		knuckle.rotation.y = -steering * deg_to_rad(33.0)
	driving_controls.set_controls(steering, throttle > 0, brake_held, throttle < 0 and not brake_held)
	var wheelbase: float = [3.7, 2.75, 4.1, 2.975, 2.85, 4.0][vehicle_index]
	var yaw_rate := speed * tan(steering * deg_to_rad(33.0)) / wheelbase
	# Limit lateral acceleration at speed while retaining tight parking turns.
	var max_yaw_rate := 8.0 / maxf(absf(speed), 1.0)
	ambulance.rotate_y(-clampf(yaw_rate, -max_yaw_rate, max_yaw_rate) * delta)
	var forward := -ambulance.global_transform.basis.z
	var travel_direction := forward * signf(speed)
	var leading_reach := rear_reach if speed<0 else front_reach
	var signal_gap := street_signals.red_clearance(ambulance.position,forward if is_zero_approx(speed) else travel_direction,leading_reach)
	var stopping_distance := signal_gap
	var people: Array = [crossing_pedestrian,passenger,arriving_passenger,waiting_medic,marina_recipient,square_neighbour]
	for item in walker_data:
		people.append(item.actor)
	for person: Node3D in people:
		if not person.visible: continue
		var offset := ambulance.to_local(person.position)
		if absf(offset.x)<player_half_size.x+.36 and -offset.z*signf(speed)>0:
			stopping_distance = minf(stopping_distance,maxf(0,absf(offset.z)-leading_reach-.65))
	# Plan the stop before the bumper reaches a person or a stationary queue.
	for item in traffic_data:
		var offset := ambulance.to_local(item.actor.position)
		var rail := ambulance.global_basis.x
		var side_extent := absf(rail.x)*float(item.length)+absf(rail.z)*float(item.width)
		if absf(offset.x)>player_half_size.x+side_extent: continue
		var ahead := -offset.z*signf(speed)
		if ahead<=0: continue
		var end_extent := absf(forward.x)*float(item.length)+absf(forward.z)*float(item.width)
		var leader_speed := maxf(0,travel_direction.x*float(item.direction)*float(item.speed))
		stopping_distance = minf(stopping_distance,maxf(0,ahead-leading_reach-end_extent-.65)+leader_speed*leader_speed/10)
	var assisted_braking := false
	if stopping_distance < INF:
		# Reserve the current frame's travel before applying the stopping curve.
		var frame_brake := 5.0*delta
		var limit := sqrt(frame_brake*frame_brake + 10.0*maxf(0,stopping_distance-.04))-frame_brake
		assisted_braking = absf(speed)>limit
		speed = signf(speed)*minf(absf(speed),limit)
	waiting_for_signal = signal_gap <= .35 and signal_gap == stopping_distance and absf(speed) < .25
	if player_brake_lens:
		_set_rear_lights(player_brake_lens, brake_held or assisted_braking)
	var step := forward * speed * delta
	var extent := _player_extent()
	for item in traffic_data:
		var obstacle: Node3D = item.actor
		var offset := ambulance.position - obstacle.position
		var bounds := Vector2(extent.x + float(item.length), extent.y + float(item.width))
		var footprint := AABB(Vector3(-bounds.x, -1, -bounds.y), Vector3(bounds.x * 2, 2, bounds.y * 2))
		if footprint.has_point(offset) and offset.dot(step) >= 0:
			continue
		var contact = footprint.intersects_segment(offset, offset + step)
		if contact != null:
			step = step.limit_length(maxf(0.0, offset.distance_to(contact) - 0.02))
			speed = 0.0
	# In vehicle space the sweep is straight along Z. A round trunk also
	# clears the bumper corners when passing diagonally beside a tree.
	var travel_sign := signf(step.dot(forward))
	for trunk in trunks:
		var relative := ambulance.to_local(Vector3(trunk.x, ambulance.position.y, trunk.z))
		var side_gap := maxf(absf(relative.x) - player_half_size.x, 0.0)
		if side_gap >= trunk.y or relative.z * travel_sign >= 0.0:
			continue
		var clearance := absf(relative.z) - leading_reach - sqrt(trunk.y * trunk.y - side_gap * side_gap)
		if clearance <= step.length():
			step = step.limit_length(maxf(0.0, clearance - 0.02))
			speed = 0.0
	var obstacles := building_bounds.duplicate()
	if workshop_car.visible: obstacles.append(WORKSHOP_CAR_BOUNDS)
	if casualty.visible and casualty.get_parent()==self:
		obstacles.append(AABB(casualty.position-Vector3(2.1,1,.86),Vector3(4.2,3,1.72)))
	for person in [crossing_pedestrian,passenger,arriving_passenger,waiting_medic,marina_recipient,square_neighbour]:
		if not person.visible: continue
		obstacles.append(AABB(person.position-Vector3(.28,1,.28),Vector3(.56,3,.56)))
	for neighbour in walker_data:
		var person: Node3D = neighbour.actor
		obstacles.append(AABB(person.position-Vector3(.28,1,.28),Vector3(.56,3,.56)))
		if neighbour.has("stretch"):
			var cart_position := person.position-person.basis.z*.73
			obstacles.append(AABB(cart_position-Vector3(.48,1,.32),Vector3(.96,3,.64)))
	for i in parked_cars.size():
		if parked_cars[i].visible:
			obstacles.append(_parked_bounds(i))
	var margin := Vector3(extent.x, 0, extent.y)
	for building in obstacles:
		var wall := AABB(building.position - margin, building.size + 2 * margin)
		if wall.has_point(ambulance.position):
			# A vehicle swap can enlarge the footprint beside an existing wall.
			var exit_normal := wall.get_center().direction_to(ambulance.position)
			if step.dot(exit_normal) < 0:
				step = Vector3.ZERO
				speed = 0.0
			continue
		var contact = wall.intersects_segment(ambulance.position, ambulance.position + step)
		if contact != null:
			step = step.limit_length(maxf(0.0, ambulance.position.distance_to(contact) - 0.02))
			speed = 0.0
	# Sweep the car footprint against the three open-water spans between bridges.
	for banks in [Vector2(-90,-52.9), Vector2(-43.1,-4.9), Vector2(4.9,82)]:
		var water := AABB(Vector3(55.0 - extent.x, -2, banks.x - extent.y),
			Vector3(32.0 + 2 * extent.x, 4, banks.y - banks.x + 2 * extent.y))
		var hit = water.intersects_segment(ambulance.position, ambulance.position + step)
		if hit != null and not water.has_point(ambulance.position):
			step = step.limit_length(maxf(0, ambulance.position.distance_to(hit) - 0.02))
			speed = 0.0
	var destination := ambulance.position + step
	var pos := destination
	pos.x = clampf(pos.x, -60.0 + extent.x, 170.0 - extent.x)
	pos.z = clampf(pos.z, -86.0 + extent.y, 65.0 - extent.y)
	if not pos.is_equal_approx(destination):
		speed = 0.0
	pos.y = _surface_height(pos.x, pos.z)
	if pos.y < -0.15:
		speed = clampf(speed, -3.0, 6.0)
	_roll_wheels(player_wheels, (pos - previous_pose.origin).dot(forward))
	ambulance.global_position = pos
	if reverse_lens:
		reverse_lens.emission_energy_multiplier = 2.0 if speed < -0.01 else 0.0
	if brake_held and throttle < -0.7 and previous_speed > (2.0 if not skid_anchors.is_empty() else 7.0) and pos.y > -0.15 and previous_pose.origin.distance_squared_to(pos) > 0.000001:
		_draw_skid(previous_pose)
	else:
		_end_skid()

func _build_brake_effects() -> void:
	var rubber := StandardMaterial3D.new()
	rubber.vertex_color_use_as_albedo = true
	rubber.vertex_color_is_srgb = true
	rubber.roughness = 1.0
	var strip := PlaneMesh.new()
	strip.size = Vector2.ONE
	strip.material = rubber
	skid_marks.transform_format = MultiMesh.TRANSFORM_3D
	skid_marks.use_colors = true
	skid_marks.mesh = strip
	skid_marks.instance_count = SKID_CAPACITY
	skid_marks.visible_instance_count = 0
	var trails := MultiMeshInstance3D.new()
	trails.multimesh = skid_marks
	trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trails)
	var scrub := preload("res://audio/tire_scrub.wav").duplicate() as AudioStreamWAV
	scrub.loop_mode = AudioStreamWAV.LOOP_FORWARD
	scrub.loop_end = scrub.data.size() / 2
	tire_player.stream = scrub
	add_child(tire_player)

func _end_skid() -> void:
	skid_anchors.clear()
	if tire_player.playing:
		tire_player.stop()

func _draw_skid(previous_pose: Transform3D) -> void:
	var starting := skid_anchors.is_empty()
	# Tyres compress snow into wider grey tracks and expose darker slush when wet.
	var track_color := Color("#1b1b1c").lerp(Color("#83949b").lerp(Color("#47575c"), weather.wet), weather.snow)
	var track_width := lerpf(.19,.245,weather.snow)
	for wheel in rear_tire_contacts.size():
		var offset := rear_tire_contacts[wheel]
		if starting:
			skid_anchors.append(previous_pose * offset)
		var endpoint := ambulance.global_transform * offset
		var start := skid_anchors[wheel]
		var segment := Vector3(endpoint.x - start.x, 0, endpoint.z - start.z)
		var length := segment.length()
		if length < 0.10:
			continue
		var center := (endpoint + start) * 0.5
		center.y = _surface_height(center.x, center.z) + 0.009
		var direction := segment / length
		var axes := Basis(Vector3.UP.cross(direction) * track_width, Vector3.UP, direction * (length + 0.015))
		skid_marks.set_instance_transform(skid_cursor, Transform3D(axes, center))
		skid_marks.set_instance_color(skid_cursor, track_color)
		skid_cursor = (skid_cursor + 1) % SKID_CAPACITY
		skid_marks.visible_instance_count = mini(SKID_CAPACITY, skid_marks.visible_instance_count + 1)
		skid_anchors[wheel] = endpoint
	if not AudioServer.is_bus_mute(0):
		tire_player.pitch_scale = 0.78 + clampf(speed / (250.0 / 3.6), 0, 1) * 0.45
		tire_player.volume_db = lerpf(-20.0, -8.0, clampf(speed / 22.0, 0, 1)) - 5.0*weather.snow
		if not tire_player.playing:
			tire_player.play()
	elif tire_player.playing:
		tire_player.stop()

func _taxi_stop(leg: int = taxi_leg) -> int:
	return [0,2,1,0,2,1][leg%6]

func _taxi_instruction() -> String:
	return "Pick up your passenger" if taxi_leg%2==0 else "Drop off your passenger"

func _mission_destination() -> Vector3:
	var destination := WALK_TARGETS[mission_index] if walker.visible else TARGETS[mission_index]
	if vehicle_index == TAXI:
		destination = TARGETS[_taxi_stop()]
	elif vehicle_index == RECOVERY:
		destination = SERVICE_STOPS[recovery_leg%4]
	destination.y = _surface_height(destination.x,destination.z)
	return destination

func _arrival_radius() -> float:
	return 2.1 if walker.visible else 5.2

func _at_target() -> bool:
	if free_drive or boating or tram_mode != 0 or (vehicle_index in [TAXI,RECOVERY] and walker.visible) or mission_index >= TARGETS.size(): return false
	var actor := walker if walker.visible else ambulance
	return actor.position.distance_to(_mission_destination()) < _arrival_radius()

func _update_arrival(delta: float) -> void:
	var stopped := walking_velocity.length() < .12 if walker.visible else absf(speed) < .12
	if gentle_driving and _at_target() and stopped:
		parked_at_target += delta
		if parked_at_target >= HELP_DURATION:
			_help_at_target()
	else:
		parked_at_target = 0.0

func _help_at_target() -> void:
	if free_drive or mission_index >= TARGETS.size(): return
	if vehicle_index == RECOVERY:
		if _at_target() and absf(speed)<.2:
			recovery_leg+=1
			parked_at_target=0
			if recovery_leg%2==0:
				wallet+=20
				_save_preferences()
				phone.receive("Recovery complete. You earned 20 coins.")
				message = "Recovery complete. You earned 20 coins."
			else:
				message = "Car loaded onto the flatbed."
			message_timer = 3.0
			_update_mission_marker()
			_refresh_ui()
		return
	if vehicle_index == TAXI:
		if _at_target() and absf(speed)<.2:
			taxi_leg += 1
			if taxi_leg%2==0:
				phone.receive("Fare complete. You earned 15 coins.")
				wallet+=15
				_save_preferences()
			parked_at_target = 0
			message = "Passenger on board." if taxi_leg%2 else "Thank you for the ride!"
			message_timer = 3
			_update_mission_marker()
			_refresh_ui()
		return
	if _at_target() and (walker.visible or absf(speed)<.12):
		parked_at_target = 0.0
		mission_index += 1
		phone.receive("First-aid supplies delivered to the marina. You earned 10 coins." if mission_index==TARGETS.size() else "Thank you for helping! You earned 10 coins.")
		wallet+=10
		_save_preferences()
		speed = 0.0
		message = "Mission complete. Well done!"
		message_timer = 3.0
		if mission_index >= TARGETS.size():
			mode = "complete"
			_update_siren()
			message = "All missions complete! The city thanks you."
		_refresh_ui()
		if mode == "complete":
			start_button.grab_focus()
		_update_mission_marker()
	else:
		if mission_index == 2:
			message = "Cross a bridge to the east side." if (walker.position.x if walker.visible else ambulance.position.x) < 87 else "Follow the quay to the green marker by the boats."
		else:
			message = "Follow the green mission marker."
		message_timer = 2.5
		_refresh_status()

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	city_env = env
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://environment/daylight.gdshader")
	sky_mat.set_shader_parameter("city_light", preload("res://environment/portland_landing_pad.exr"))
	sky_mat.set_shader_parameter("cloud_density", preload("res://environment/cloud_density.png"))
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c4d5d1")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.25
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	city_sun = sun
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("#fff1df")
	sun.light_energy = 0.73
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	var fill := OmniLight3D.new()
	city_fill = fill
	fill.position = Vector3(0, 10, 0)
	fill.light_color = Color("#d7e5dd")
	fill.light_energy = 0.45
	fill.omni_range = 48
	add_child(fill)
	var ground := _make_driving_surface("Natural ground", Vector3(115, 0.3, 174), Vector3(-2.5, -0.35, -6), Color("#78916e"), true)
	soil_finish = _noise_material(Color("#607751"), Color("#83966b"), 1.7, 0.14)
	ground.material_override = soil_finish
	_build_road_network()
	_build_city_blocks()
	_build_waterfront()
	_build_trees()
	_build_new_blocks()
	add_child(shops)
	_build_lampposts()
	_update_daylight(0)
	_build_ambulance()
	_build_traffic()
	_build_pedestrians()
	_build_depot()
	_build_target_marker()
	_build_camera()
	add_child(tram)
	helicopter = preload("res://vehicles/polishelikopter.glb").instantiate()
	add_child(helicopter)
	main_rotor = helicopter.find_child("MainRotor",true,false)
	tail_rotor = helicopter.find_child("TailRotor",true,false)
	_update_patrol(0)
	add_child(street_signals)

func _build_road_network() -> void:
	road_finish = _noise_material(Color("#303538"), Color("#45494a"), 2.3, .22)
	var main_road := _make_driving_surface("Main street", Vector3(100, 0.12, 9.6), Vector3(0, -0.08, 0), Color("#3e484a"), true)
	main_road.material_override = road_finish
	var cross_road := _make_driving_surface("Cross street", Vector3(9.6, 0.13, 72), Vector3(0, -0.07, -12), Color("#3e484a"), true)
	cross_road.material_override = road_finish
	sidewalk_finish = _noise_material(Color("#8d8b7f"), Color("#aaa899"), 2.5, 0.09)
	for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var end_distance := 50.0
		if direction == Vector3.FORWARD: end_distance = 48.0
		if direction == Vector3.BACK: end_distance = 24.0
		var edge: Vector3 = direction.cross(Vector3.UP)
		var start_distance := ROAD_HALF
		for side in [-1.0, 1.0]:
			var walk_start := start_distance if direction.x != 0 else 7.575
			var walk_length := end_distance - walk_start
			var walk := _make_driving_surface("Stone sidewalk", direction.abs() * walk_length + edge.abs() * 2.45 + Vector3.UP * 0.10,
				direction * (walk_start + walk_length / 2) + edge * side * 6.35 + Vector3.DOWN * 0.07, Color("#aaa899"), true)
			walk.material_override = sidewalk_finish
			var length := end_distance - start_distance
			var middle: Vector3 = direction * (start_distance + length / 2)
			_make_box("Kerb", direction.abs() * length + edge.abs() * 0.22 + Vector3.UP * 0.18,
				middle + edge * side * 4.95, Color("#ddd6ba"), true)
			_make_box("Cycle lane border", direction.abs() * length + edge.abs() * 0.07 + Vector3.UP * 0.025,
				middle + edge * side * 3.85 + Vector3.UP * 0.015, Color("#e0dfda"))
		for distance in range(12, int(end_distance) - 1, 7):
			_make_box("Road marking", direction.abs() * 2.8 + edge.abs() * 0.12 + Vector3.UP * 0.025,
				direction * distance, Color("#e0dfda"))
	# Crossings align with the pedestrians' east-west route.
	for z in [-6.35, 6.35]:
		for x in range(-4, 5):
			_make_box("Crosswalk", Vector3(0.50, 0.025, 2.1), Vector3(x, 0.016, z), Color("#eee9d9"))

func _build_waterfront() -> void:
	var asphalt := Color("#414648")
	_make_driving_surface("Östra stranden", Vector3(92, 0.3, 174), Vector3(133, -0.35, -6), Color("#859378")).material_override = soil_finish
	var canal := _make_box("Sjöstadskanalen", Vector3(32, 0.12, 174), Vector3(71, -1.05, -6), Color("#376675"))
	var water := Shader.new()
	water.code = """
	shader_type spatial;
	uniform float rain = 0.0;
	uniform vec3 ferry_center;
	uniform vec2 stern;
	uniform vec2 wake_heading;
	uniform float wake_strength;
	uniform float dusk;
	varying vec2 surface;
	void vertex(){ surface=(MODEL_MATRIX*vec4(VERTEX,1.)).xz; }
	void fragment(){
		vec2 p = surface;
		float swell = sin(dot(p,vec2(1.3,.7)) + TIME*.72);
		float chop = sin(dot(p,vec2(4.1,-2.3)) + swell*1.6 - TIME*1.25);
		float fine = sin(dot(p,vec2(8.3,3.9)) + chop*1.1 + TIME*2.0);
		float detail = 1.0 - smoothstep(.05,.35,length(fwidth(p)));
		vec2 slope = vec2(.024,.013)*swell + vec2(.040,-.022)*chop + detail*vec2(.026,.013)*fine;
		if (rain > .001 && detail > .001) {
			vec2 cell = floor(p*2.);
			float seed = fract(sin(dot(cell,vec2(37.1,91.7)))*4317.);
			vec2 radial = fract(p*2.)-.5+(vec2(seed,fract(seed*31.7))-.5)*.18;
			float radius = length(radial);
			float age = fract(TIME*1.4+seed);
			float crest = (radius-age*.38)*48.;
			slope += radial/max(radius,.001)*crest*exp(-crest*crest)*(1.-age)*rain*detail*.32;
		}
		NORMAL_MAP = normalize(vec3(slope,1.0))*.5+.5;
		ALBEDO = mix(vec3(.027,.062,.078),vec3(.051,.093,.117),.5+.5*chop);
		vec2 trail = p-stern;
		float aft = -dot(trail,wake_heading);
		float across = abs(dot(trail,vec2(-wake_heading.y,wake_heading.x)));
		float edge = across-.43-max(aft,0.)*.23+.12*chop;
		float crests = exp(-edge*edge*7.) + .48*exp(-across*across*2.);
		float foam = wake_strength*smoothstep(-.3,.5,aft)*(1.-smoothstep(1.,3.+8.*wake_strength,aft))*crests;
		ALBEDO = mix(ALBEDO,vec3(.62,.74,.74),clamp(foam*(.55+.22*chop+.17*fine),0.,1.));
		// Intersect the reflected sightline with the two saloon window bands.
		vec3 eye = CAMERA_POSITION_WORLD;
		vec3 ray = normalize(vec3(p.x-eye.x,eye.y+.99,p.y-eye.z));
		ray.xz += slope*.9;
		float side = sign(eye.x-ferry_center.x);
		float face = ferry_center.x+side*1.86;
		float t = (face-p.x)/(abs(ray.x)>.001 ? ray.x : .001);
		vec2 hit = vec2(-.99+ray.y*t-ferry_center.y,p.y+ray.z*t-ferry_center.z);
		float band = smoothstep(1.42,1.57,hit.x)*(1.-smoothstep(2.15,2.32,hit.x));
		float pane = smoothstep(.03,.13,abs(fract((hit.y+4.1)/.82+.5)-.5));
		float reflection = float(t>0.)*band*(1.-smoothstep(4.,4.24,abs(hit.y)))*pane;
		EMISSION = dusk*(vec3(.034,.058,.084)*(.75+.25*chop)+vec3(.66,.42,.21)*reflection*(.25+.75*smoothstep(-.5,.8,chop+fine*.38)));
		ROUGHNESS = .31+.10*rain;
		METALLIC = .12;
	}
	"""
	water_finish.shader = water
	canal.material_override = water_finish
	for bank in [55.0,87.0]:
		_make_box("Kajmur", Vector3(.5,1.5,174), Vector3(bank,-.86,-6), Color("#807b70"))
	for street_z in [0.0,-48.0]:
		var start_x := 50.0 if street_z == 0 else -4.8
		_make_driving_surface("Kajgata", Vector3(55-start_x,.12,9.6), Vector3((55+start_x)/2,-.08,street_z),asphalt).material_override = road_finish
		_make_driving_surface("Brodäck", Vector3(32,.56,11.6),Vector3(71,-.30,street_z),asphalt).material_override = road_finish
		for side in [-1,1]:
			var z: float = street_z + side*5.5
			_make_driving_surface("Brokant",Vector3(32,.24,1.1),Vector3(71,.02,z),Color("#bab6aa"))
			for height in [.54,1.06]:
				_make_box("Broräcke",Vector3(32,.065,.08),Vector3(71,height,z),Color("#43565a"))
			for x in range(55,88,2):
				_make_box("Räckesstolpe",Vector3(.09,1.05,.09),Vector3(x,.53,z),Color("#536467"))
		_make_driving_surface("Östra allén",Vector3(78,.12,9.6),Vector3(126,-.08,street_z),asphalt).material_override = road_finish
	for x in [102,162]:
		_make_driving_surface("Tvärgata",Vector3(9.6,.10,144),Vector3(x,-.09,-10),asphalt).material_override = road_finish
	# Close the eastern avenues and form two western blocks around the depot and square.
	for route in [
		["Norra kajgatan",Vector2(102,-82),Vector2(162,-82)],
		["Södra kajgatan",Vector2(102,60),Vector2(162,60)],
		["Depågatan",Vector2(-55,-48),Vector2(-55,35)],
		["Verkstadsgatan",Vector2(-55,-48),Vector2(0,-48)],
		["Stationsallén",Vector2(-55,35),Vector2(48,35)],
		["Parkgatan",Vector2(48,-48),Vector2(48,35)],
		["Torgets förlängning",Vector2(0,24),Vector2(0,35)],
		["Depåinfarten",Vector2(-55,0),Vector2(-50,0)]
	]:
		var start: Vector2 = route[1]
		var end: Vector2 = route[2]
		var middle := (start+end)*.5
		var span := (end-start).abs()+Vector2(7.4,7.4)
		_make_driving_surface(route[0],Vector3(span.x,.10,span.y),Vector3(middle.x,-.095,middle.y),asphalt).material_override = road_finish
	_build_quay_lane_markings()
	# The eastern quay promenade follows the water between the bridge approaches.
	quay_finish.shader = preload("res://environment/quay_paving.gdshader")
	# Keep each bridge approach open where the pavement meets the junction.
	for span in [Vector2(-74,-52.8), Vector2(-43.2,-4.8), Vector2(4.8,60)]:
		var middle: float = (span.x + span.y) * .5
		var length: float = span.y - span.x
		var footway := _make_driving_surface("Trottoar vid kajhusen",Vector3(1.08,.26,length),Vector3(107.46,-.05,middle),Color("#b7afa2"))
		footway.material_override = quay_finish
		_make_driving_surface("Granitkant",Vector3(.12,.26,length),Vector3(106.86,-.05,middle),Color("#999893"))
	for span in [Vector2(-90,-54), Vector2(-42,-6), Vector2(6,77)]:
		var middle: float = (span.x + span.y) / 2
		var promenade := _make_driving_surface("Strandpromenad", Vector3(6,.15,span.y-span.x), Vector3(90,-.11,middle), Color("#b7afa2"))
		promenade.material_override = quay_finish
		for z in range(int(span.x)+1,int(span.y),3):
			_make_box("Kajstolpe",Vector3(.12,.86,.12),Vector3(87.5,.40,z),Color("#525d60"))
		_make_box("Handledare",Vector3(.065,.07,span.y-span.x),Vector3(87.5,.82,middle),Color("#626c6e"))
	var balcony_glass := StandardMaterial3D.new()
	balcony_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	balcony_glass.albedo_color = Color(.53,.72,.72,.36)
	balcony_glass.roughness = .18
	var plaster := [Color("#d0c9bb"), Color("#aa604b"), Color("#c7c6be"), Color("#ad7964")]
	var panes := [Color("#354852"), Color("#475d68"), Color("#596971"), Color("#384e56")]
	var window_batches: Array = [[], [], [], []]
	for row in range(3):
		for col in range(4):
			var x := 115.0 + (col % 2)*21
			var z: float = [-69, -35, -21, 17, 34, 51][row * 2 + floori(col/2.0)]
			var floors := 3+(col+row)%4
			var height := floors*2.8
			building_bounds.append(AABB(Vector3(x-7,-1,z-5),Vector3(14,height+1,10)))
			_make_box("Kajhus",Vector3(14,height,10),Vector3(x,height/2-.2,z),plaster[(row+col)%4])
			_make_box("Takfot",Vector3(14.5,.23,10.5),Vector3(x,height-.15,z),Color("#526264"))
			_make_box("Indragen takvåning",Vector3(10,2.5,7),Vector3(x,height+1.1,z),Color("#ece7df"))
			# Glazed doors open onto the set-back roof terrace.
			for bay in [-2.3,0.0,2.3]:
				window_batches[(row+col)%4].append(Transform3D(Basis.from_scale(Vector3(.07,1.88,1.72)),Vector3(x-5.05,height+.97,z+bay)))
			if col % 2 == 0:
				_make_tree(Vector3(94,0,z),1.25)
			for level in range(floors):
				if col % 2 == 0:
					var y := level*2.8
					for bay in range(4):
						var center_z := z-3.0+2.0*bay
						if level == 0 and bay == 1:
							_make_quay_entrance(Vector3(x-7, -.18, center_z))
							continue
						window_batches[(row+bay+level*3)%4].append(Transform3D(Basis.from_scale(Vector3(.07,2.35,1.93)),Vector3(x-7.04,y+1.32,center_z)))
					for mullion in [-4,-2,0,2,4]:
						_make_box("Fönsterprofil",Vector3(.09,2.4,.07),Vector3(x-7.09,y+1.32,z+mullion),Color("#ced0cb"))
					if level > 0:
						_make_box("Kajbalkong",Vector3(1.5,.15,9),Vector3(x-7.72,y,z),Color("#dddcd3"))
						var railing := _make_box("Glasräcke",Vector3(.06,.93,9),Vector3(x-8.43,y+.53,z),Color.WHITE)
						railing.material_override = balcony_glass
						_make_box("Överliggare",Vector3(.08,.05,9),Vector3(x-8.43,y+1.02,z),Color("#b8bbb8"))
						if (level + row + col) % 3 == 1:
							var bay_z := z + (2.2 if level % 2 == 1 else -2.2)
							var cloth := Color("#425970") if (level + col) % 2 == 1 else Color("#b8ac88")
							var awning := _make_box("Terrassmarkis",Vector3(1.65,.045,3.35),Vector3(x-7.82,y+2.26,bay_z),cloth)
							awning.rotation.z = .22
							_make_box("Markiskappa",Vector3(.04,.14,3.35),Vector3(x-8.62,y+2.02,bay_z),cloth)
							for bracket in [-1.42,1.42]:
								var arm := _make_box("Markisarm",Vector3(1.65,.038,.038),Vector3(x-7.82,y+2.21,bay_z+bracket),Color("#93958c"))
								arm.rotation.z = .22

				for face in [-1,1]:
					for bay in [-4.8,0,4.8]:
						for half in [-1,1]:
							var pane_center := Vector3(x+bay+half*.68,1.45+level*2.8,z+face*5.04)
							window_batches[posmod(col+level+roundi(bay)+half,4)].append(Transform3D(Basis.from_scale(Vector3(1.28,1.68,.07)),pane_center))
					if level>0:
						_make_box("Balkongplatta",Vector3(3.4,.18,1.35),Vector3(x,level*2.8,z+face*5.6),Color("#c9c9bb"))
						_make_box("Balkongfront",Vector3(3.4,.82,.09),Vector3(x,level*2.8+.44,z+face*6.2),Color("#83979a"))

	for i in panes.size():
		var glass := _material(panes[i],.19)
		glass.metallic = .32
		if i == 1 or i == 3:
			glass.emission_enabled = true
			if i == 1:
				glass.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				glass.emission_texture = preload("res://environment/apartment_evening.svg")
				glass.uv1_scale = Vector3(3,2,1) # One room per BoxMesh atlas face.
			glass.emission = Color("#ffc385") if i == 1 else Color("#ffdfa7")
			glass.emission_energy_multiplier = 0.0
			apartment_lights.append(glass)
		var pane_mesh := BoxMesh.new()
		pane_mesh.material = glass
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = pane_mesh
		batch.instance_count = window_batches[i].size()
		for j in batch.instance_count:
			batch.set_instance_transform(j,window_batches[i][j])
		var windows := MultiMeshInstance3D.new()
		windows.multimesh = batch
		add_child(windows)
	_build_marina()

func _make_quay_entrance(base: Vector3) -> void:
	var aluminium := Color("#637273")
	_make_box("Portglas",Vector3(.075,2.22,1.45),base+Vector3(-.06,1.11,0),Color("#354c52"))
	for side in [-1,1]:
		_make_box("Portkarm",Vector3(.15,2.27,.065),base+Vector3(-.10,1.135,side*.745),aluminium)
	for height in [.19,2.24]:
		_make_box("Dörrprofil",Vector3(.13,.08,1.50),base+Vector3(-.11,height,0),aluminium)
	_make_box("Sparkplåt",Vector3(.13,.18,1.45),base+Vector3(-.11,.09,0),aluminium)
	_make_box("Draghandtag",Vector3(.06,.52,.04),base+Vector3(-.20,1.12,.55),Color("#bbc2be"))
	_make_box("Porttak",Vector3(.94,.10,2.02),base+Vector3(-.47,2.37,0),aluminium)
	_add_entry_light(base + Vector3(-.55,2.30,0),Vector3(.12,.035,.65),3.8)

func _add_entry_light(lamp_position: Vector3, lens_size: Vector3, reach: float) -> void:
	var diffuser := _make_box("Portbelysning",lens_size,lamp_position,Color.WHITE)
	if entrance_diffuser == null:
		entrance_diffuser = _material(Color("#ffe3b7"),.45,true)
	diffuser.material_override = entrance_diffuser
	var light := SpotLight3D.new()
	light.position = lamp_position - Vector3.UP*.035
	light.rotation_degrees.x = -90
	light.light_color = Color("#ffddaf")
	light.spot_range = reach
	light.spot_angle = 55
	add_child(light)
	entrance_lights.append(light)

func _build_quay_lane_markings() -> void:
	var dashes: Array[Transform3D] = []
	for z in [0.0, -48.0]:
		var first := 54 if z == 0 else 12
		for x in range(first, 165, 7):
			if absi(x - 102) < 7 or absi(x - 162) < 7:
				continue
			dashes.append(Transform3D(Basis.IDENTITY, Vector3(x, _surface_height(x,z)+0.006, z)))
	for x in [102.0, 162.0]:
		for z in range(-70, 60, 7):
			if absi(z) < 7 or absi(z + 48) < 7:
				continue
			dashes.append(Transform3D(Basis(Vector3.UP, PI/2),Vector3(x,_surface_height(x,z)+0.006,z)))
	var dash := PlaneMesh.new()
	dash.size = Vector2(2.8, 0.12)
	dash.material = _material(Color("#deddd6"), 0.91)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = dash
	batch.instance_count = dashes.size()
	for i in dashes.size():
		batch.set_instance_transform(i,dashes[i])
	var markings := MultiMeshInstance3D.new()
	markings.name = "Kajgatornas mittlinjer"
	markings.multimesh = batch
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(markings)

func _pier_section(label: String, size: Vector3, center: Vector3, color: Color) -> void:
	_make_box(label,size,center,color)
	pier_surfaces.append(AABB(center-size*.5,size))

func _pier_height(x: float,z: float) -> float:
	for section in pier_surfaces:
		if x >= section.position.x and x <= section.end.x and z >= section.position.z and z <= section.end.z:
			return section.end.y
	return NAN

func _foot_height(x: float,z: float) -> float:
	var deck := _pier_height(x,z)
	return _surface_height(x,z) if is_nan(deck) else deck

func _build_marina() -> void:
	launch = Node3D.new()
	add_child(launch)
	var launch_model := preload("res://vehicles/motorboat.glb").instantiate() as Node3D
	launch_model.rotation.y = PI
	launch.add_child(launch_model)
	for side in [-1,1]:
		var tint := Color("#dc3936") if side<0 else Color("#359e64")
		var mount := Vector3(side*.94,.64,-.7)
		_make_box("Sidelight housing",Vector3(.09,.10,.19),mount,Color("#2c3439"),false,launch)
		var lens := _make_box("Sidelight lens",Vector3(.038,.065,.12),
			mount+Vector3(side*.044,.014,-.024),tint,false,launch)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = tint.darkened(.34)
		finish.emission_enabled = true
		finish.emission = tint
		lens.material_override = finish
		navigation_lenses.append(finish)
	outboard = launch_model.find_child("Outboard swivel",true,false)
	launch.position=Vector3(79,-.94,46)
	for x in [58,65,72,79,84]:
		for z in [6.8,76.5]:
			_make_box("Fairway buoy",Vector3(.35,.75,.35),Vector3(x,-.82,z),Color("#bf5e37"))
	ferry = (load("res://vehicles/lotten.glb") as PackedScene).instantiate()
	add_child(ferry)
	var windows := ferry.find_child("Continuous tinted glazing*",true,false) as MeshInstance3D
	saloon_glazing = windows.get_active_material(0).duplicate() as StandardMaterial3D
	saloon_glazing.emission_enabled = true
	saloon_glazing.emission = Color("#ffcc8c")
	windows.material_override = saloon_glazing
	for landing_z in [-35.0,-12.0]:
		_pier_section("Ferry landing",Vector3(2.0,.20,7.5),Vector3(64.9,-.76,landing_z),Color("#847968"))
		for tread in 4:
			var height := -.18-.12*tread
			_pier_section("Granite tread",Vector3(.46,.22,2),Vector3(55.02+.45*tread,height-.11,landing_z),Color("#b2a897"))
		_pier_section("Timber gangway",Vector3(7.46,.17,2),Vector3(60.31,-.745,landing_z),Color("#9d8469"))
		for end in [-1,1]:
			_make_box("Pier pile",Vector3(.24,1.4,.24),Vector3(65.75,-.67,landing_z+end*3.4),Color("#514e41"))
	# Boardwalk joins both ferry approaches along the sheltered bank.
	_pier_section("Waterside boardwalk",Vector3(2.0,.18,21.1),Vector3(58.0,-.75,-23.5),Color("#ab9071"))
	for i in range(46):
		_make_box("Plank joint",Vector3(2.0,.006,.011),Vector3(58,-.657,-33.86+i*.454),Color("#736552"))
	for i in range(8):
		var post_z := -33.8+i*2.94
		_make_box("Timber bollard",Vector3(.14,1.70,.14),Vector3(59.08,-.53,post_z),Color("#6b5948"))
		if i<7:
			for segment in 6:
				var a := segment/6.
				var b := (segment+1)/6.
				var start := Vector3(59.08,.22-.60*a*(1-a),post_z+2.94*a)
				var end := Vector3(59.08,.22-.60*b*(1-b),post_z+2.94*b)
				var rope_span := _make_box("Hemp rope",Vector3(.032,.032,start.distance_to(end)),(start+end)*.5,Color("#c9b38e"))
				rope_span.look_at(end)
	_make_box("Flytbrygga",Vector3(1.4,.25,32),Vector3(85.8,-.63,-24),Color("#877962"))
	var rope := CylinderMesh.new()
	rope.top_radius = 0.018
	rope.bottom_radius = 0.018
	rope.height = 1.0
	rope.radial_segments = 6
	rope.rings = 0
	rope.material = _material(Color("#a29a84"), 0.94)
	for berth in range(7):
		var z := -38.0 + berth*4.5
		var boat := Node3D.new()
		add_child(boat)
		boat.position = Vector3(81.9,-.92,z)
		boat.rotation.y = sin(berth*2.1)*.07
		# Cross sections along the keel taper to a pointed bow.
		var hull := SurfaceTool.new()
		hull.begin(Mesh.PRIMITIVE_TRIANGLES)
		var finishes := [Color("#d4d1c4"),Color("#27445b"),Color("#9c5838"),Color("#acb8b6")]
		var hull_material := _material(finishes[berth % finishes.size()],.36)
		hull_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		hull.set_material(hull_material)
		var previous: Array[Vector3] = []
		for section in [Vector2(-2.8,.025),Vector2(-2.15,.61),Vector2(-1.25,.91),Vector2(.5,1.02),Vector2(2.55,.85)]:
			var x: float = section.x
			var w: float = section.y
			var ring: Array[Vector3] = [Vector3(x,.58,-w),Vector3(x,.08,-w*.8),Vector3(x,-.18,0),Vector3(x,.08,w*.8),Vector3(x,.58,w)]
			if not previous.is_empty():
				for k in range(5):
					var n := (k+1)%5
					for point in [previous[k],ring[k],ring[n],previous[k],ring[n],previous[n]]:
						hull.add_vertex(point)
			if x == 2.55 or x == -2.8:
				for k in range(1,4):
					for point in [ring[0],ring[k],ring[k+1]]: hull.add_vertex(point)
			previous = ring
		hull.generate_normals()
		var shell := MeshInstance3D.new()
		shell.mesh = hull.commit()
		boat.add_child(shell)
		var pane := _make_box("Vindruta",Vector3(.07,.56,1.46),Vector3(-.57,.86,0),Color("#44616a"),false,boat)
		pane.rotation.z = -.29
		_make_box("Förlucka",Vector3(.54,.04,.42),Vector3(-1.52,.605,0),Color("#41535b"),false,boat)
		var cover := [Color("#253b51"),Color("#b7afa0"),Color("#365b64")][berth%3] as Color
		if berth % 3 == 2:
			for seat_x in [.1,1.36]:
				_make_box("Sittdyna",Vector3(.40,.09,1.40),Vector3(seat_x,.64,0),Color("#c8b299"),false,boat)
				_make_box("Ryggdyna",Vector3(.10,.34,1.40),Vector3(seat_x+.20,.81,0),Color("#ad947a"),false,boat)
		else:
			var fabric := SurfaceTool.new()
			fabric.begin(Mesh.PRIMITIVE_TRIANGLES)
			var canvas := _material(cover,.88)
			canvas.cull_mode = BaseMaterial3D.CULL_DISABLED
			fabric.set_material(canvas)
			var frames: Array = []
			for station in [Vector3(-.65,1.10,.68),Vector3(-.36,1.38,.79),
					Vector3(.70,1.42,.81),Vector3(1.35,1.23,.77),Vector3(1.72,.64,.72)]:
				var x: float = station.x
				var h: float = station.y
				var w: float = station.z
				var arch := [Vector3(x,h-.13,-w),Vector3(x,h-.025,-w*.75),
					Vector3(x,h,0),Vector3(x,h-.025,w*.75),Vector3(x,h-.13,w)]
				if frames.size()>0:
					var last: Array = frames.back()
					for k in 4:
						for pt in [last[k],arch[k],arch[k+1],last[k],arch[k+1],last[k+1]]:
							fabric.add_vertex(pt)
				frames.append(arch)
			fabric.generate_normals()
			var canopy := MeshInstance3D.new()
			canopy.mesh = fabric.commit()
			boat.add_child(canopy)
			for side in [-.72,.72]:
				_make_box("Kapellstöd",Vector3(.035,.68,.035),Vector3(.70,.93,side),Color("#909694"),false,boat)
		var buoy := MeshInstance3D.new()
		var float_mesh := CapsuleMesh.new()
		float_mesh.radius=.14
		float_mesh.height=.89
		buoy.mesh=float_mesh
		buoy.material_override=_material(Color("#c82c38"),.38)
		buoy.position=Vector3(78.35,-.73,z+.8)
		buoy.rotation.z=.13*sin(berth)
		add_child(buoy)
		var lines: Array[MeshInstance3D] = []
		for i in range(3):
			var line := MeshInstance3D.new()
			line.mesh = rope
			add_child(line)
			lines.append(line)
		moorings.append({"boat":boat, "buoy":buoy, "lines":lines, "phase":berth*1.7,
			"heading":boat.rotation.y, "berth_z":z})
	_update_moorings(0.0)

func _update_moorings(delta: float) -> void:
	wave_time += delta
	var heading := Vector2(-sin(launch.rotation.y),-cos(launch.rotation.y))
	var stern := Vector2(launch.position.x,launch.position.z)-heading*1.95
	water_finish.set_shader_parameter("stern",stern)
	water_finish.set_shader_parameter("wake_heading",heading*signf(launch_speed))
	water_finish.set_shader_parameter("wake_strength",clampf(absf(launch_speed)/6.0,0,1) if boating else 0.0)
	# A double-ended ferry can reverse away from either landing without turning.
	# Each crossing includes a five-second stop and gentle acceleration.
	var half_trip := fmod(wave_time,58.0)
	var crossing := smoothstep(5.0,29.0,fmod(half_trip,29.0))
	if half_trip >= 29.0:
		crossing = 1.0-crossing
	ferry.position = Vector3(68,-.97+.024*sin(wave_time*1.1),lerpf(-35.0,-12.0,crossing))
	water_finish.set_shader_parameter("ferry_center",ferry.position)
	ferry.rotation.z = .006*sin(wave_time*.88)
	for berth in moorings:
		var boat: Node3D = berth.boat
		var buoy: Node3D = berth.buoy
		var phase: float = wave_time*1.25 + berth.phase
		boat.position.y = -0.92 + 0.035*sin(phase)
		boat.rotation = Vector3(0.016*sin(phase+0.7), berth.heading, 0.009*cos(phase))
		buoy.position.y = -0.73 + 0.049*sin(phase+0.5)
		buoy.rotation.z = 0.085*sin(phase+0.9)
		for i in range(3):
			var side := -1.0 if i == 1 else 1.0
			var start := boat.to_global(Vector3(2.44,.56,.71*side))
			var end := Vector3(85.28,-.50,berth.berth_z+1.35*side)
			if i == 0:
				start = boat.to_global(Vector3(-2.71,.53,0))
				end = buoy.to_global(Vector3(0,.39,0))
			var axis := end-start
			var line: MeshInstance3D = berth.lines[i]
			line.transform = Transform3D(Basis(Quaternion(Vector3.UP,axis.normalized())).scaled_local(Vector3(1,axis.length(),1)),(start+end)*.5)


func _build_city_blocks() -> void:
	var plots := [
		[Vector3(-34,0,-15),Vector3(13,6.4,9),Color("#835143"),"Polisstationen"],
		[Vector3(128,0,-60),Vector3(20,13.3,9),Color("#e1e5df"),"Sjukhuset"],
		[Vector3(-15, 0, -15), Vector3(13, 8, 11.6), Color("#d5c4a4"), "Bageriet"],
		[Vector3(16, 0, -15), Vector3(13.8, 11, 13), Color("#bdcfc5"), "Vårdcentralen"],
		[Vector3(-16, 0, 17), Vector3(16.4, 9, 14), Color("#d8c0b5"), "Brandstationen"],
		[Vector3(16, 0, 18), Vector3(13.6, 7, 13), Color("#d8d0b7"), "Biblioteket"]
	]
	for plot in plots:
		_build_building(plot[0], plot[1], plot[2], plot[3])
	_make_driving_surface("Hospital ambulance apron",Vector3(14,.10,8),Vector3(128,-.12,-52),Color("#818884"))
	_make_driving_surface("Police forecourt",Vector3(9,.10,6.5),Vector3(-34,-.12,-7.75),Color("#a6a29a"))
	# Låg kantsten och planteringar runt torget.
	_make_driving_surface("Square paving", Vector3(14, 0.24, 13), Vector3(30, -0.09, 16), Color("#cbbf9f"), true)
	for p in [Vector3(25, 0, 12), Vector3(35, 0, 12), Vector3(25, 0, 20), Vector3(35, 0, 20)]:
		_make_box("Planter", Vector3(1.3, 0.35, 1.3), p + Vector3(0, 0.15, 0), Color("#697f58"), true)
		_make_tree(p, 0.9, "", 0.325)
	_make_box("Bench seat", Vector3(2.0, 0.18, 0.45), Vector3(30, 0.6, 21.7), Color("#80664c"), true)
	_make_box("Bench back", Vector3(2.0, 0.7, 0.16), Vector3(30, 0.95, 21.9), Color("#80664c"), true)

func _build_building(center: Vector3, size: Vector3, _color: Color, sign_text: String) -> void:
	building_bounds.append(AABB(Vector3(center.x-size.x/2,-1,center.z-size.z/2), size+Vector3.UP))
	var packed: PackedScene = load(BUILDING_SCENES[sign_text])
	var model := packed.instantiate() as Node3D
	model.name = sign_text.replace(" ", "_")
	model.position = Vector3(center.x, 0.0, center.z)
	# Blender -Y (the signed entrance facade) imports as Godot +Z.
	if center.z > 0.0:
		model.rotation.y = PI
	add_child(model)

func _build_trees() -> void:
	for x in range(-40, 45, 8):
		if absf(x) < 7: continue
		_make_tree(Vector3(x, 0, -8.6), 0.95)
		_make_tree(Vector3(x + 3.2, 0, 8.6), 0.82)
	for z in range(-31, 22, 8):
		if absf(z) < 7: continue
		_make_tree(Vector3(-8.6, 0, z), 0.92)
		_make_tree(Vector3(8.6, 0, z + 2.8), 0.78)
	for p in [Vector3(-27,0,-9), Vector3(-23,0,7), Vector3(22,0,-8), Vector3(40,0,-10), Vector3(-34,0,9), Vector3(6,0,27), Vector3(-10,0,-29)]:
		_make_tree(p, 1.15)

	# Keep the bridge approaches and the middle of the promenade open.
	var grate := PlaneMesh.new()
	grate.size = Vector2(1.75, 2.35)
	var iron := ShaderMaterial.new()
	iron.shader = preload("res://environment/tree_grate.gdshader")
	grate.material = iron
	for z in [-67,-57,-38,-26,-14,11,24,37,50,63]:
		var center := Vector3(92.0,-0.035,z)
		var tree_pit := MeshInstance3D.new()
		tree_pit.name = "Trädgaller"
		tree_pit.mesh = grate
		tree_pit.position = center + Vector3.UP * 0.028
		add_child(tree_pit)
		_make_tree(center, 0.79 + 0.13 * sin(z), TREE_SCENES[2 if tree_count % 2 else 0])

var foliage_finishes := {}
var distant_tree_meshes := {}

func _make_tree(pos: Vector3, scale_factor: float, species := "", planting_height := NAN) -> void:
	var path: String = TREE_SCENES[tree_count % TREE_SCENES.size()] if species.is_empty() else species
	var packed: PackedScene = load(path)
	var tree := packed.instantiate() as Node3D
	tree.name = "StreetTree_%02d" % tree_count
	if not distant_tree_meshes.has(path):
		var card := QuadMesh.new()
		card.size = Vector2(9, 9)
		card.center_offset = Vector3.UP * 4.5
		var finish := StandardMaterial3D.new()
		finish.albedo_texture = load(path.get_basename() + "_distance.png")
		finish.albedo_color = Color(0.82, 0.76, 0.73) if path == TREE_SCENES[1] else Color(0.71, 0.67, 0.69)
		finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		finish.alpha_scissor_threshold = 0.32
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		finish.billboard_keep_scale = true
		card.material = finish
		distant_tree_meshes[path] = card
	for part: MeshInstance3D in tree.find_children("*", "MeshInstance3D", true, false):
		part.visibility_range_end = 32.0
		part.visibility_range_end_margin = 0.0
		for surface in part.mesh.get_surface_count():
			var finish := part.mesh.surface_get_material(surface)
			if finish and finish.resource_name.begins_with("Natural bark"):
				part.set_surface_override_material(surface, preload("res://environment/bark.tres"))
			elif finish is StandardMaterial3D and finish.resource_name in ["Leaf green", "Sunlit leaves", "Deep leaves", "Spruce needles", "Spruce tips"]:
				if not foliage_finishes.has(finish):
					var foliage := ShaderMaterial.new()
					foliage.shader = preload("res://environment/foliage.gdshader")
					foliage.set_shader_parameter("leaf_color", finish.albedo_color)
					foliage.set_shader_parameter("stiffness", 0.35 if finish.resource_name.begins_with("Spruce") else 1.0)
					foliage_finishes[finish] = foliage
				part.set_surface_override_material(surface, foliage_finishes[finish])
	var distant := MeshInstance3D.new()
	distant.mesh = distant_tree_meshes[path]
	distant.visibility_range_begin = 32.0
	distant.visibility_range_begin_margin = 0.0
	distant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.add_child(distant)
	tree.position = pos
	var ground_height := _surface_height(pos.x, pos.z) if is_nan(planting_height) else planting_height
	tree.position.y = ground_height - 0.015
	tree.rotation.y = fmod(tree_count * 2.4, TAU)
	tree.scale = Vector3.ONE * scale_factor * 0.86
	add_child(tree)
	trunks.append(Vector3(pos.x, 0.19 * tree.scale.x, pos.z))
	tree_count += 1

func _build_new_blocks() -> void:
	for i in 5:
		var p := Vector3(-42+i*5.4,0,-38)
		var paint: Color = [Color("#a15940"),Color("#d7bd8b"),Color("#a7bab0")][i%3]
		_make_box("Townhouse",Vector3(5.3,5.1,7),p+Vector3.UP*2.35,paint)
		building_bounds.append(AABB(p+Vector3(-2.65,-1,-3.5),Vector3(5.3,8,7)))
		for side in [-1,1]:
			var roof := _make_box("Clay tile roof",Vector3(5.55,.24,4.0),p+Vector3(0,5.65,side*1.83),Color("#85452e"))
			roof.rotation.x = side*.42
		_make_box("Chimney",Vector3(.64,1.7,.68),p+Vector3(1.6,6.1,-.9),Color("#754d42"))
		for x in [-1.5,1.4]:
			for y in [1.3,3.65]:
				_make_box("Window frame",Vector3(1.45,1.46,.14),p+Vector3(x,y,3.54),Color("#e5e1d7"))
				_make_box("Window pane",Vector3(1.21,1.22,.16),p+Vector3(x,y,3.58),Color("#47606b"))
		_make_box("Entrance door",Vector3(.94,2.1,.16),p+Vector3(0,.91,3.55),Color("#334b48"))
	var p := Vector3(34,0,-32)
	_make_box("Brick workshop",Vector3(18,5.8,10),p+Vector3.UP*2.7,Color("#995f48"))
	building_bounds.append(AABB(p+Vector3(-9,-1,-5),Vector3(18,9,10)))
	for i in 4:
		var roof := _make_box("Sawtooth skylight roof",Vector3(4.8,.24,10.3),p+Vector3(-6.75+i*4.5,6.15,0),Color("#475a5b"))
		roof.rotation.z=.26
		_make_box("Clerestory glass",Vector3(.12,1.15,9.9),p+Vector3(-4.57+i*4.5,6.1,0),Color("#77959a"))
		var bay := p+Vector3(-6.75+4.5*i,2.25,5.05)
		_make_box("Factory glazing",Vector3(3.65,2.9,.16),bay,Color("#405763"))
		for bar in [-1,0,1]:
			_make_box("Steel mullion",Vector3(.08,2.9,.21),bay+Vector3.RIGHT*bar*.91,Color("#84908b"))
		_make_box("Steel transom",Vector3(3.65,.08,.21),bay,Color("#84908b"))
	# The recovery route approaches the workshop from the north.
	for x in [-4.0,4.0]:
		var lamp_mount := p+Vector3(x,3.94,-5.43)
		_make_box("Workshop door lamp",Vector3(1.32,.12,.64),lamp_mount,Color("#34424b"))
		_add_entry_light(lamp_mount+Vector3(0,-.08,-.14),Vector3(1.12,.05,.22),6.0)
		var door := p+Vector3(x,1.78,-5.08)
		_make_box("Workshop roller shutter",Vector3(5.8,3.55,.16),door,Color("#708588"))
		for row in range(-4,5):
			_make_box("Shutter seam",Vector3(5.72,.035,.04),door+Vector3(0,row*.35,-.10),Color("#52676a"))
		for pane in [-1,0,1]:
			_make_box("Shutter window",Vector3(1.1,.43,.05),door+Vector3(pane*1.48,.69,-.13),Color("#263f49"))
	_make_box("Workshop fascia",Vector3(14.8,.92,.18),p+Vector3(0,4.57,-5.12),Color("#244750"))
	var workshop_name := Label3D.new()
	workshop_name.text="SJÖSTADENS BILVERKSTAD"
	workshop_name.pixel_size=.012
	workshop_name.font_size=48
	workshop_name.outline_size=0
	workshop_name.position=p+Vector3(0,4.57,-5.23)
	workshop_name.rotation.y=PI
	add_child(workshop_name)
	for crossing in [Vector3(-12,0,0),Vector3(91,0,0),Vector3(91,0,-48),Vector3(143,0,-48)]:
		for stripe in range(-4,5):
			_make_box("Zebra crossing",Vector3(2.4,.014,.52),crossing+Vector3(0,_surface_height(crossing.x,crossing.z)+.014,stripe),Color("#eee9d9"))

func _update_daylight(delta: float) -> void:
	if time_mode == 2:
		if mode == "playing" and not paused:
			day_phase = fmod(day_phase+delta/360.0,1.0)
	var night := 1.0 if time_mode == 1 else (smoothstep(-.4,.4,-cos(day_phase*TAU)) if time_mode == 2 else 0.0)
	var cloud := maxf(weather.intensity.x,weather.intensity.y)*(1.0-night)
	city_sun.light_energy = lerpf(.73,.17,night)*(1.0-.52*cloud)
	city_sun.shadow_opacity = 1.0-.48*cloud
	if absf(night-last_night)<.006: return
	last_night = night
	for lens in navigation_lenses:
		lens.emission_energy_multiplier = night*3.2
	water_finish.set_shader_parameter("dusk",night)
	if saloon_glazing:
		saloon_glazing.emission_energy_multiplier = night*.85
	if player_brake_lens:
		_set_rear_lights(player_brake_lens, player_brake_lens.emission_energy_multiplier >= 2.399)
	for item in traffic_data:
		if item.brake_lens:
			_set_rear_lights(item.brake_lens, item.brake_lens.emission_energy_multiplier >= 2.4 - .001)
	for i in apartment_lights.size():
		var dusk := smoothstep(.22+.18*i,.85+.12*i,night)
		apartment_lights[i].emission_energy_multiplier = dusk*(.83-.22*i)
	city_env.sky.sky_material.set_shader_parameter("night",night)
	city_env.ambient_light_energy = lerpf(.38,.28,night)
	city_env.ambient_light_color = Color("#c4d5d1").lerp(Color("#9cb1d3"),night)
	city_sun.light_color = Color("#fff1df").lerp(Color("#9db5eb"),night)
	city_sun.rotation_degrees = Vector3(-48+21*night,-28+73*night,0)
	city_fill.light_energy = .45*(1-night)
	var entrance_glow := smoothstep(.15,.85,night)
	entrance_diffuser.emission_energy_multiplier = entrance_glow*2.0
	for lamp in entrance_lights:
		lamp.visible = entrance_glow > .001
		lamp.light_energy = entrance_glow*2.1
	for lamp in street_lights:
		lamp.visible = night>.05
		lamp.light_energy = night*3.2
	lamp_glass.emission_energy_multiplier = .1+night*3.0
	for lens in bicycle_lenses:
		lens.emission_energy_multiplier = 3.0*night
	for beam in traffic_headlights:
		beam.visible = night>.05
		beam.light_energy = 2.8*night
	for beam in headlights:
		beam.visible = night>.05
		beam.light_energy = 4.5*night
	for path in distant_tree_meshes:
		var tint := Color(.82,.76,.73) if path == TREE_SCENES[1] else Color(.71,.67,.69)
		distant_tree_meshes[path].material.albedo_color = tint.lerp(Color("#394451"),night*.92)

func _build_lampposts() -> void:
	lamp_glass = _material(Color("#ffdfac"), .35, true)
	var sites: Array[Vector3] = [Vector3(92,0,6),Vector3(92,0,-54),Vector3(143,0,-54),Vector3(70,0,5.6),Vector3(70,0,-53.6),Vector3(-35,0,10),Vector3(-12,0,6),Vector3(-5.8,0,-7), Vector3(5.8,0,8), Vector3(18,0,-7), Vector3(40,0,8), Vector3(-37,0,-7)]
	for x in [102,162]:
		for z in [-72,-55,-34,-16,10,28,47,57]:
			sites.append(Vector3(x+5.4,0,z))
	for z in [-82,60]:
		for x in [114,132,150]:
			sites.append(Vector3(x,0,z+4.1))
	for x in [-55,48]:
		for z in [-37,-18,14,29]:
			sites.append(Vector3(x-4.3,0,z))
	for x in [-43,-24,-8,13,34]:
		sites.append(Vector3(x,0,39.3))
		sites.append(Vector3(x,0,-52.3))
	for p in sites:
		_make_box("Lamp post", Vector3(0.16, 4.5, 0.16), p + Vector3(0,2.25,0), Color("#45524e"), false)
		_make_box("Lamp arm", Vector3(0.85, 0.13, 0.13), p + Vector3(0.34,4.35,0), Color("#45524e"), false)
		var lens := _make_box("Lamp", Vector3(0.52, 0.15, 0.42), p + Vector3(0.66,4.24,0), Color("#e5d9ad"), false)
		lens.material_override = lamp_glass
		var light := SpotLight3D.new()
		light.position = lens.position-Vector3.UP*.12
		light.rotation_degrees.x = -90
		light.light_color = Color("#ffdbad")
		light.spot_range = 17
		light.spot_angle = 63
		light.shadow_enabled = true
		light.distance_fade_enabled = true
		light.distance_fade_begin = 34
		light.distance_fade_shadow = 24
		add_child(light)
		street_lights.append(light)

func _apply_player_appearance() -> void:
	var jacket := _material(Color("#a85641") if play_as_alma else Color("#648faa"))
	for figure: Node3D in [walker,skipper,road_driver]:
		figure.scale = Vector3.ONE*(.88 if play_as_alma else 1.0)
		figure.get_node("Ponytail").visible = play_as_alma
		figure.get_node("Jacket").material_override = jacket
		for arm in figure.get_meta("arms"):
			arm.get_child(0).material_override = jacket
			if figure == road_driver:
				arm.get_node("Forearm").material_override = jacket
	# Keep the hips on the cushion as the selected driver's height changes.
	road_driver.scale *= .78
	road_driver.position = Vector3(-.32, .88 - .87 * road_driver.scale.y, -.04)

func _pose_driver_arms() -> void:
	if not road_driver.visible:
		return
	var arms: Array = road_driver.get_meta("arms")
	for index in arms.size():
		var shoulder: Node3D = arms[index]
		var grip := cabin_wheel.to_global(Vector3.RIGHT * grip_radius * (-1 if index == 0 else 1))
		var reach := road_driver.to_local(grip) - shoulder.position
		# Bend the elbow down and slightly out, keeping the wrist on the rim.
		var axis := reach.normalized()
		var outward := Vector3(-.25 if index == 0 else .25,-1,0)
		var bend := outward.slide(axis).normalized()
		var half_reach := reach.length() * .5
		var offset := sqrt(maxf(0.0, .37 * .37 - half_reach * half_reach))
		var elbow := reach * .5 + bend * offset
		var upper := shoulder.get_child(0) as MeshInstance3D
		var lower := shoulder.get_node("Forearm") as MeshInstance3D
		_fit_driver_sleeve(upper, Vector3.ZERO, elbow)
		_fit_driver_sleeve(lower, elbow, reach)
		shoulder.get_node("Hand").position = reach

func _fit_driver_sleeve(sleeve: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var segment := end - start
	sleeve.position = (start + end) * .5
	sleeve.quaternion = Quaternion(Vector3.DOWN, segment.normalized())
	sleeve.scale.y = (segment.length() + .045) / .65

func _build_depot() -> void:
	_make_driving_surface("Motor pool", Vector3(25,.1,11), Vector3(-37,-.18,15), Color("#565c5a"))
	_make_driving_surface("Recovery apron",Vector3(8.4,.10,9.8),Vector3(-45,-.18,25.4),Color("#565c5a"))
	# A continuous pedestrian route from the parking bays to Stationsallén.
	for span in [Vector2(20.5,31.3),Vector2(38.7,42.5)]:
		_make_driving_surface("Depot footpath",Vector3(2.3,.08,span.y-span.x),
			Vector3(-39,-.09,(span.x+span.y)*.5),Color("#afa99b"))
	_make_driving_surface("Shop pavement",Vector3(37,.08,2.5),Vector3(-24.9,-.09,41.25),Color("#afa99b"))
	for i in 8:
		_make_box("Stationsallén crossing",Vector3(2.25,.014,.48),Vector3(-39,-.028,31.85+i*.90),Color("#edece1"))
	var waypost := Vector3(-37.65,0,21.2)
	_make_box("Footpath signpost",Vector3(.085,1.9,.085),waypost+Vector3.UP*.9,Color("#758384"))
	_make_box("Shop direction sign",Vector3(2.0,.49,.08),waypost+Vector3.UP*1.68,Color("#20554c"))
	var directions := Label3D.new()
	directions.text = "↑  Café · Kiosk"
	directions.position = waypost+Vector3(0,1.68,-.047)
	directions.rotation.y = PI
	directions.font_size = 42
	directions.pixel_size = .0048
	add_child(directions)
	var sign := Label3D.new()
	sign.text = "Vehicle depot"
	sign.position = Vector3(-37,3.2,18.8)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = .008
	add_child(sign)
	for i in VEHICLE_SCENES_ALL.size():
		var body := Node3D.new()
		add_child(body)
		var model := (load(VEHICLE_SCENES_ALL[i]) as PackedScene).instantiate() as Node3D
		model.rotation.y = PI
		body.add_child(model)
		body.position = Vector3(-45,-.13,25) if i==RECOVERY else Vector3(-47+5*i,-.13,15)
		for lamp in model.find_children("Flash*", "MeshInstance3D", true, false):
			lamp.visible = false
		parked_cars.append(body)
		var bounds := _model_bounds(body,model)
		parked_footprints.append(Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z))
		parked_sizes.append(Vector2(maxf(-bounds.position.x,bounds.end.x),maxf(-bounds.position.z,bounds.end.z)))
		if i == RECOVERY:
			for side in [-1,1]:
				_make_box("Recovery bay stripe",Vector3(.1,.025,9.3),body.position+Vector3(side*2.5,.014,.45),Color("#deddd1"))
		else:
			_make_box("Parking stripe", Vector3(.10,.025,7.8), Vector3(body.position.x-2.5,-.116,15), Color("#deddd1"))
			if i==TAXI:
				_make_box("Parking stripe",Vector3(.10,.025,7.8),Vector3(body.position.x+2.5,-.116,15),Color("#deddd1"))
	_make_walker("Player on foot",0,0,1,Color("#648faa"),Color("#30414d"))
	walker = walker_data.pop_back().actor
	var ponytail := MeshInstance3D.new()
	ponytail.name = "Ponytail"
	var lock := CapsuleMesh.new()
	lock.radius=.092
	lock.height=.34
	ponytail.mesh=lock
	ponytail.position=Vector3(0,1.65,.17)
	ponytail.rotation.x=-.23
	ponytail.material_override=_material(Color("#523b30"))
	walker.add_child(ponytail)
	_make_walker("BMW driver",0,0,1,Color("#648faa"),Color("#30414d"))
	road_driver = walker_data.pop_back().actor
	road_driver.reparent(ambulance,false)
	road_driver.rotation = Vector3.ZERO
	road_driver.add_child(ponytail.duplicate())
	for leg in road_driver.get_meta("legs"):
		leg.rotation.x = 1.35
	for arm in road_driver.get_meta("arms"):
		var forearm := arm.get_child(0).duplicate() as MeshInstance3D
		forearm.name = "Forearm"
		forearm.scale = Vector3(.82,1,.82)
		arm.add_child(forearm)
		var hand := MeshInstance3D.new()
		hand.name = "Hand"
		var palm := SphereMesh.new()
		palm.radius = .067
		palm.height = .15
		hand.mesh = palm
		hand.material_override = _material(Color("#c58e6d"),.94)
		arm.add_child(hand)
	road_driver.hide()
	_make_walker("Helmsperson",0,0,1,Color("#648faa"),Color("#30414d"))
	skipper = walker_data.pop_back().actor
	skipper.reparent(launch,false)
	skipper.rotation = Vector3.ZERO
	skipper.position = Vector3(-.21,-.16,.56)
	skipper.add_child(ponytail.duplicate())
	var vest_finish := _material(Color("#f07724"),.91)
	for side in [-1,0,1]:
		var pad := MeshInstance3D.new()
		var padding := CapsuleMesh.new()
		padding.radius = .16
		padding.height = .54
		pad.mesh = padding
		pad.name = "Flotation padding"
		pad.position = Vector3(side*.128,1.26,.12 if side==0 else -.13)
		pad.scale = Vector3(1.55 if side==0 else .84,1,.83)
		pad.material_override = vest_finish
		skipper.add_child(pad)
		var patch := _make_box("Reflective tape",Vector3(.09,.084,.018),
			Vector3(side*.128,1.39,.237 if side==0 else -.25),Color("#d7dbcf"),false,skipper)
		patch.rotation.z = side*.12
	_make_box("Vest buckle",Vector3(.075,.052,.032),Vector3(0,1.17,-.231),Color("#374046"),false,skipper)

	for leg in skipper.get_meta("legs"):
		leg.rotation.x = .86
	for arm in skipper.get_meta("arms"):
		arm.rotation.x = 1.16
	skipper.hide()
	_apply_player_appearance()
	walker.visible = false
	entry_marker.name = "AvailableVehicle"
	entry_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	entry_marker.font_size = 42
	entry_marker.pixel_size = .0026
	entry_marker.outline_size = 9
	entry_marker.visible = false
	add_child(entry_marker)


func _parked_bounds(i: int) -> AABB:
	var area := parked_footprints[i]
	return parked_cars[i].transform * AABB(Vector3(area.position.x,-1,area.position.y),Vector3(area.size.x,4,area.size.y))

func _nearest_car() -> int:
	var best_distance := 2.1
	var best := -1
	for i in parked_cars.size():
		var car := parked_cars[i]
		if not car.visible: continue
		var local := car.to_local(walker.position)
		var size := parked_sizes[i]
		var door := Vector3(size.x * (-1 if local.x < 0 else 1), 0, -size.y*.27)
		var distance := local.distance_to(door)
		if distance >= best_distance: continue
		var handle := car.to_global(door) + Vector3.UP
		var clear := true
		for wall in building_bounds:
			if wall.intersects_segment(walker.position+Vector3.UP,handle) != null:
				clear = false
				break
		if clear:
			best_distance = distance
			best = i
	return best

func _near_parked_vehicle(p: Vector3, margin: float) -> bool:
	for i in parked_cars.size():
		if parked_cars[i].visible:
			var local := parked_cars[i].to_local(p)
			if parked_footprints[i].grow(margin).has_point(Vector2(local.x,local.z)):
				return true
	return false

func _on_foot_clear(p: Vector3) -> bool:
	if is_instance_valid(workshop_car) and workshop_car.visible and WORKSHOP_CAR_BOUNDS.grow(.2).has_point(p): return false
	if is_instance_valid(casualty) and casualty.visible and casualty.get_parent()==self and AABB(casualty.position-Vector3(2.35,1,1.1),Vector3(4.7,3,2.2)).has_point(p): return false
	if p.x < -60 or p.x > 170 or p.z < -86 or p.z > 65:
		return false
	if p.x > 55 and p.x < 87 and absf(p.z)>5.4 and absf(p.z+48)>5.4 and is_nan(_pier_height(p.x,p.z)):
		return false
	for wall in building_bounds:
		if wall.grow(.25).has_point(p+Vector3.UP):
			return false
	if _near_parked_vehicle(p,.22): return false
	for item in traffic_data:
		var offset: Vector3 = p - item.actor.position
		if absf(offset.x) < float(item.length)+.28 and absf(offset.z) < float(item.width)+.28:
			return false
	for trunk in trunks:
		if Vector2(p.x-trunk.x,p.z-trunk.z).length_squared() < pow(trunk.y+.22,2):
			return false
	return true

func _change_seat() -> void:
	if boating or tram_mode!=0: return
	if mode != "playing" or paused: return
	if not walker.visible:
		if absf(speed)>.2:
			message = "Stop first to get out."
			message_timer = 2
			return
		var old_car := parked_cars[vehicle_index]
		old_car.transform = ambulance.transform
		old_car.visible = true
		var door := ambulance.position
		for side in [1,-1]:
			var candidate := ambulance.to_global(Vector3(side*(player_half_size.x+.65),0,-parked_sizes[vehicle_index].y*.27))
			if _on_foot_clear(candidate):
				door = candidate
				break
		if door == ambulance.position:
			message = "Both doors are blocked. Park where there is more room."
			message_timer = 3
			old_car.visible = false
			return
		walker.position = Vector3(door.x,_foot_height(door.x,door.z),door.z)
		walk_basis = ambulance.basis
		walker.rotation.y = ambulance.rotation.y
		walker.visible = true
		cockpit_view = false
		ambulance.visible = false
		walking_velocity = Vector3.ZERO
		listener.reparent(walker, false)
		listener.position = Vector3.UP*1.6
		listener.global_basis = walk_basis
		listener.make_current()
		speed = 0
		steering = 0
		mouse_gas = false
		mouse_brake = false
		_end_skid()
		parked_sound_settings[vehicle_index] = sound_on
		parked_light_settings[vehicle_index] = lights_on
		siren_player.stop()
	else:
		var next := _nearest_car()
		if next < 0: return
		release_walk_keys = _walk_pedal_pressed()
		vehicle_index = next
		sound_on = parked_sound_settings[next]
		lights_on = parked_light_settings[next]
		vehicle_selector.select(next)
		ambulance.transform = parked_cars[next].transform
		parked_cars[next].visible = false
		ambulance.visible = true
		walker.visible = false
		_load_vehicle_model()
		_update_siren()
		listener.reparent(ambulance, false)
		listener.transform = Transform3D(Basis.IDENTITY, Vector3.UP*1.3)
		listener.make_current()
		_update_camera(0,true)
	message_timer = 0
	parked_at_target = 0
	_update_mission_marker()
	_refresh_ui()
	get_viewport().gui_release_focus()

func _walk(delta: float) -> void:
	var keys := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	keys += Vector2(int(Input.is_key_pressed(KEY_D))-int(Input.is_key_pressed(KEY_A)),int(Input.is_key_pressed(KEY_S))-int(Input.is_key_pressed(KEY_W)))
	var motion := walk_basis * Vector3(keys.x,0,keys.y).limit_length(1) * 3.4 * delta
	var next := walker.position
	for step in [Vector3(motion.x,0,0),Vector3(0,0,motion.z)]:
		if _on_foot_clear(next+step): next += step
	next.y = _foot_height(next.x,next.z)
	var travel := next-walker.position
	if travel.length_squared()>.000001:
		walker.rotation.y = atan2(-travel.x,-travel.z)
	walker.position = next
	walking_velocity = travel / maxf(delta,.00001)
	listener.global_basis = walk_basis
	walk_phase += travel.length()*4.0
	for i in 2:
		var swing := sin(walk_phase+i*PI)*.38 if travel.length_squared()>.000001 else 0.0
		walker.get_meta("legs")[i].rotation.x = swing
		walker.get_meta("arms")[i].rotation.x = -swing
	_update_entry_button()

func _update_entry_button() -> void:
	var nearest := _nearest_car()
	entry_marker.visible = nearest >= 0 and mode == "playing" and not paused
	if entry_marker.visible:
		var car := parked_cars[nearest]
		var side := signf(car.to_local(walker.position).x)
		entry_marker.global_position = car.to_global(Vector3(side * parked_sizes[nearest].x, 2.05, -parked_sizes[nearest].y * .27))
		entry_marker.text = tr("F · Enter %s") % tr(VEHICLE_NAMES_ALL[nearest])
	seat_button.disabled = nearest < 0
	seat_button.text = tr("Enter %s") % tr(VEHICLE_NAMES_ALL[nearest]) if nearest >= 0 else tr("Walk to a vehicle")

func _build_ambulance() -> void:
	ambulance = Node3D.new()
	ambulance.name = "EmergencyVehicle"
	ambulance.position = Vector3(-35, _surface_height(-35, 0), 0)
	ambulance.rotation.y = -PI * 0.5
	add_child(ambulance)
	listener.position.y = 1.3
	ambulance.add_child(listener)
	listener.make_current()
	_load_vehicle_model()

const TRAFFIC_WEST := -47.0
const TRAFFIC_EAST := 162.0

func _build_traffic() -> void:
	_spawn_traffic("res://vehicles/a_traktor.glb", 51, 2.35, 1, 3.2, 1)
	_spawn_traffic("res://vehicles/a_traktor.glb", 95, -2.35, -1, 3.5, 1)
	# Two-way, steady traffic on both sides of the main street.
	_spawn_traffic("res://vehicles/traffic_bmw_blue.glb", -40.0, 2.35, 1.0, 6.4)
	_spawn_traffic("res://vehicles/traffic_bmw_silver.glb", 5.0, 2.35, 1.0, 6.4)
	_spawn_traffic("res://vehicles/traffic_bmw_silver.glb", 39.0, -2.35, -1.0, 7.0)
	_spawn_traffic("res://vehicles/traffic_bmw_blue.glb", -6.0, -2.35, -1.0, 7.0)
	_spawn_traffic("res://environment/cyklist.glb", -24.0, 4.18, 1.0, 2.7, 0.72)
	_spawn_traffic("res://environment/cyklist.glb", 26.0, -4.18, -1.0, 2.45, 0.72)

	_spawn_traffic("res://vehicles/traffic_bmw_silver.glb", 124.0, 2.35, 1.0, 6.1)
	_spawn_traffic("res://vehicles/traffic_bmw_blue.glb", 108.0, -2.35, -1.0, 6.8)

	for spawn in [Vector3(68,2.35,1),Vector3(146,-2.35,-1)]:
		_spawn_traffic("res://vehicles/raggarbil.glb",spawn.x,spawn.y,spawn.z,4.75,.89)
		var cruiser: Dictionary=traffic_data.back()
		cruiser.lane_center=spawn.y
		cruiser.cruise_phase=0.0
		# Reserve the lateral envelope of the yawed bonnet as well as its tyres.
		cruiser.width+=float(cruiser.length)*.065
	_spawn_emergency_traffic(0, -19.0, 2.35, 1.0)
	_spawn_emergency_traffic(1, 19.0, -2.35, -1.0)
	_spawn_emergency_traffic(2, 77.0, 2.35, 1.0)

func _spawn_emergency_traffic(index: int, x: float, lane: float, direction: float) -> void:
	var actor := _spawn_traffic(VEHICLE_SCENES_ALL[index], x, lane, direction, 9.0, 1.0)
	var lamps: Array[MeshInstance3D] = []
	var blue := _material(Color("#1679ff"), 0.2, true)
	for node in actor.find_children("Flash*", "MeshInstance3D", true, false):
		var lamp := node as MeshInstance3D
		lamp.material_override = blue
		lamp.visible = false
		lamps.append(lamp)
	# One local light per responding vehicle keeps the night-time spill affordable.
	var spill := OmniLight3D.new()
	spill.position.y = [2.8,1.7,3.1][index]
	spill.light_color = Color("#3879ff")
	spill.light_energy = 2.6
	spill.omni_range = 6.0
	spill.distance_fade_enabled = true
	spill.distance_fade_begin = 24
	spill.distance_fade_length = 12
	spill.visible = false
	actor.add_child(spill)
	var siren := AudioStreamPlayer3D.new()
	siren.stream = load(SIREN_SOUNDS[index])
	siren.unit_size = 7
	siren.max_distance = 65
	siren.volume_db = -6 + linear_to_db(maxf(.001, traffic_siren_volume / 100.0))
	actor.add_child(siren)
	emergency_traffic.append({"traffic": traffic_data.back(), "lamps": lamps, "spill": spill, "siren": siren, "phase": index * 0.21})

func _listener_velocity() -> Vector3:
	if boating:
		return Vector3.FORWARD.rotated(Vector3.UP,launch.rotation.y)*launch_speed
	if tram_mode > 0:
		return -tram.sections[0].global_basis.z * tram.velocity
	if walker.visible:
		return walking_velocity
	return -ambulance.global_basis.z * speed

func _update_traffic_signals(delta: float) -> void:
	var active := mode == "playing" and not paused
	var listener_velocity := _listener_velocity()
	for unit in emergency_traffic:
		if active:
			unit.phase = fmod(float(unit.phase) + delta, 1.0)
		var pulse := fmod(float(unit.phase),.5) < .40
		var lit := active and (traffic_light_mode == 1 or (traffic_light_mode == 0 and pulse))
		unit.spill.visible = lit
		for lamp: MeshInstance3D in unit.lamps:
			lamp.visible = lit and (traffic_light_mode == 1 or lamp.name.begins_with("FlashBlue") == (float(unit.phase) < .5))
		var siren: AudioStreamPlayer3D = unit.siren
		if active and traffic_siren_volume > 0 and not AudioServer.is_bus_mute(0):
			var traffic: Dictionary = unit.traffic
			var towards_listener := siren.global_position.direction_to(listener.global_position)
			var source_velocity := Vector3.RIGHT * float(traffic.direction) * float(traffic.speed)
			var received := 343.0 - listener_velocity.dot(towards_listener)
			var emitted := 343.0 - source_velocity.dot(towards_listener)
			siren.pitch_scale = clampf(received / emitted, 0.85, 1.15)
			if not siren.playing:
				siren.play()
		elif siren.playing:
			siren.stop()

func _spawn_traffic(scene_path: String, x: float, lane_z: float, direction: float, speed_value: float, model_scale := 0.8) -> Node3D:
	var actor := Node3D.new()
	actor.name = "MovingTraffic"
	actor.position = Vector3(x, _surface_height(x, lane_z), lane_z)
	actor.rotation.y = -direction * PI * 0.5
	add_child(actor)
	var packed: PackedScene = load(scene_path)
	var model := packed.instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	model.rotation.y = PI
	actor.add_child(model)
	var half_size := _vehicle_half_size(actor, model)
	if not scene_path.ends_with("cyklist.glb"):
		# A single beam represents the overlapping pools from the two dipped lamps.
		var beam := SpotLight3D.new()
		beam.name = "Dipped beam"
		beam.position = Vector3(0,.7,-half_size.y)
		beam.rotation.x = deg_to_rad(-9)
		beam.spot_angle = 30
		beam.spot_range = 21
		beam.light_color = Color("#fff1dc")
		beam.distance_fade_enabled = true
		beam.distance_fade_begin = 32
		beam.distance_fade_length = 14
		beam.visible = last_night>.05
		beam.light_energy = 2.8*maxf(last_night,0.0)
		actor.add_child(beam)
		traffic_headlights.append(beam)
	else:
		for front in [true,false]:
			var mount := Vector3(0,1.08,-.66) if front else Vector3(0,1.09,.41)
			var housing := _make_box("Cycle light",Vector3(.105,.085,.11)*model_scale,mount*model_scale,Color("#303539"),false,actor)
			var face := -.061 if front else .061
			var lens := _make_box("Cycle lens",Vector3(.085,.064,.022)*model_scale,Vector3(0,0,face)*model_scale,Color.WHITE,false,housing)
			var finish := _material(Color("#fff3cf") if front else Color("#fd3729"),.28,true)
			finish.emission_energy_multiplier = 3.0*maxf(last_night,0.0)
			lens.material_override = finish
			bicycle_lenses.append(finish)
	var traffic_horn := AudioStreamPlayer3D.new()
	var voice := "bicycle" if scene_path.ends_with("cyklist.glb") else "bmw"
	var emergency_index := VEHICLE_SCENES.find(scene_path)
	if emergency_index >= 0:
		voice = HORNS[emergency_index]
	traffic_horn.stream = load("res://audio/horn_%s.wav" % voice)
	traffic_horn.volume_db = -9
	traffic_horn.unit_size = 5
	traffic_horn.max_distance = 45
	actor.add_child(traffic_horn)
	traffic_data.append({"tractor":scene_path.ends_with("a_traktor.glb"), "horn":traffic_horn, "greeted":false, "actor": actor, "direction": direction, "cruise": speed_value, "wheels": _rig_wheels(model), "brake_lens": _brake_lens(model),
		"speed": speed_value, "length": half_size.y,
		"width": half_size.x})
	return actor

func _model_bounds(actor: Node3D, model: Node3D) -> AABB:
	var bounds := AABB()
	var world_to_actor := actor.global_transform.affine_inverse()
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		bounds = bounds.merge((world_to_actor * part.global_transform) * part.get_aabb())
	return bounds

func _vehicle_half_size(actor: Node3D, model: Node3D) -> Vector2:
	var bounds := _model_bounds(actor,model)
	if actor == ambulance:
		front_reach = -bounds.position.z
		rear_reach = bounds.end.z
	return Vector2(maxf(-bounds.position.x, bounds.end.x), maxf(-bounds.position.z, bounds.end.z))

func _player_extent() -> Vector2:
	var heading := ambulance.transform.basis.z.abs()
	return Vector2(heading.x * player_half_size.y + heading.z * player_half_size.x,
		heading.z * player_half_size.y + heading.x * player_half_size.x)

func _update_traffic(delta: float) -> void:
	var weather_pace := 1.0-.12*weather.wet-.23*weather.snow
	var player_size := _player_extent()
	for item in traffic_data:
		var actor: Node3D = item.actor
		var direction: float = item.direction
		var clearance := minf(TRAFFIC_EAST - TRAFFIC_WEST,street_signals.red_clearance(actor.position,Vector3.RIGHT*direction,float(item.length)) + 1.0)
		var tractor_ahead := false
		for other in traffic_data:
			var neighbour: Node3D = other.actor
			if neighbour == actor or absf(neighbour.position.z - actor.position.z) >= float(item.width) + float(other.width):
				continue
			var ahead := fposmod((neighbour.position.x - actor.position.x) * direction, TRAFFIC_EAST - TRAFFIC_WEST)
			var gap := ahead - float(item.length) - float(other.length)
			if gap<clearance:
				clearance = gap
				tractor_ahead = other.tractor and other.direction==direction
		if casualty.visible and casualty.get_parent()==self:
			var offset := casualty.position-actor.position
			var gap := offset.x*direction-float(item.length)-2.1
			if offset.x*direction>=0 and absf(offset.z)<float(item.width)+.86:
				clearance=minf(clearance,gap)
		var player_offset := ambulance.position - actor.position
		if absf(player_offset.z) < player_size.y + float(item.width):
			var ahead := player_offset.x * direction
			var buffer := player_size.x + float(item.length)
			if ahead < -buffer and ambulance.position.x >= TRAFFIC_WEST - buffer and ambulance.position.x <= TRAFFIC_EAST + buffer:
				# Check the entry as well when this lane wraps at the edge of town.
				ahead += TRAFFIC_EAST - TRAFFIC_WEST
			if ahead >= -buffer:
				clearance = minf(clearance, ahead - buffer)
		for i in parked_cars.size():
			if not parked_cars[i].visible: continue
			var bounds := _parked_bounds(i)
			var offset := bounds.get_center()-actor.position
			if absf(offset.z)<float(item.width)+bounds.size.z*.5 and offset.x*direction >= 0:
				clearance = minf(clearance,offset.x*direction-bounds.size.x*.5-float(item.length))
		for person: Node3D in [walker,passenger,arriving_passenger,waiting_medic,marina_recipient,square_neighbour]:
			if not person.visible: continue
			var offset := person.position - actor.position
			if offset.x * direction >= 0 and absf(offset.z) < float(item.width)+.45:
				clearance = minf(clearance, offset.x*direction-float(item.length)-.45)
		if crossing_wait <= 0.0 and (absf(crossing_pedestrian.position.z)<6.31 or street_signals.phase==3):
			var ahead := (crossing_pedestrian.position.x-actor.position.x)*direction
			var remaining := (actor.position.z-crossing_pedestrian.position.z)*crossing_direction
			if ahead >= 0 and remaining >= -float(item.width)-.45:
				clearance = minf(clearance,ahead-float(item.length)-1.2)
		if tractor_ahead and clearance<8 and not item.tractor and item.speed>1:
			if not item.greeted:
				item.horn.play()
				item.greeted = true
		elif clearance>15:
			item.greeted = false
		var free_space := maxf(0.0, clearance - 1.0)
		var target := minf(float(item.cruise)*weather_pace, free_space * .95*weather_pace)
		if free_space < 0.1:
			target = 0
		var previous_speed := float(item.speed)
		var next_speed := move_toward(previous_speed, target, (6.5 if target < previous_speed else 2.2) * delta)
		var travel := minf(next_speed * delta, free_space)
		item.speed = travel / delta if delta > 0.0 else previous_speed
		if item.brake_lens:
			var braking := float(item.speed) < previous_speed - .0001 or target == 0.0
			_set_rear_lights(item.brake_lens, braking)
		_roll_wheels(item.wheels, travel)
		actor.position.x = wrapf(actor.position.x + direction * travel, TRAFFIC_WEST, TRAFFIC_EAST)
		if item.has("lane_center"):
			item.cruise_phase=fmod(float(item.cruise_phase)+travel*.23,TAU)
			var phase: float=item.cruise_phase
			actor.position.z=float(item.lane_center)+.27*sin(phase)
			actor.rotation.y=-direction*(PI*.5+atan(.27*.23*cos(phase)))
		actor.position.y = _surface_height(actor.position.x, actor.position.z)

func _build_pedestrians() -> void:
	greeting.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	greeting.pixel_size = .003
	greeting.font_size = 64
	greeting.visible = false
	add_child(greeting)
	_make_walker("Child",12,6.42,1,Color("#568f86"),Color("#404c59"))
	walker_data.back().actor.scale = Vector3.ONE*.72
	_make_walker("Parent",10.9,6.42,1,Color("#876681"),Color("#424850"))
	walker_data.back().speed = walker_data[-2].speed
	_make_walker("JoggingNeighbour", -31.0, -6.32, 1.0, Color("#344e63"), Color("#4c514a"))
	_make_walker("WalkingNeighbour", 31.0, 6.32, -1.0, Color("#9a5836"), Color("#33424a"))
	_make_walker("ParkVisitor", -18.0, 6.42, 1.0, Color("#d1a33f"), Color("#38474a"))

	_make_walker("Neighbour with pushchair",-26,-6.7,1,Color("#87633f"),Color("#465662"))
	_equip_walker(preload("res://environment/barnvagn.glb"),.97,Vector2(-43,-16))
	_make_walker("Neighbour with rollator",22,7.0,-1,Color("#567375"),Color("#51495b"))
	_equip_walker(preload("res://environment/rullator.glb"),.61,Vector2(12,40))
	var senior: Node3D=walker_data.back().actor
	senior.get_node("Hair").material_override=_material(Color("#bcbab3"))
	_make_walker("CrossingNeighbour",-12,-6.32,1,Color("#bb703d"),Color("#465663"))
	crossing_pedestrian = walker_data.pop_back().actor

func _equip_walker(scene: PackedScene, pace: float, stretch: Vector2) -> void:
	var neighbour: Dictionary = walker_data.back()
	var person: Node3D = neighbour.actor
	person.add_child(scene.instantiate())
	neighbour.speed = pace
	neighbour.stretch = stretch
	for arm in person.get_meta("arms"):
		arm.position.y=1.40
		arm.rotation.x=.63

func _advance_crossing(delta: float) -> void:
	crossing_wait = maxf(0,crossing_wait-delta)
	var step := 0.0
	if crossing_wait <= 0.0 and (absf(crossing_pedestrian.position.z)<6.31 or street_signals.phase==3):
		step = minf(delta*1.25,absf(6.32*crossing_direction-crossing_pedestrian.position.z))*crossing_direction
		var next := crossing_pedestrian.position+Vector3.BACK*step
		var car_offset := ambulance.to_local(next)
		var player_blocks := ambulance.visible and absf(car_offset.x)<player_half_size.x+.4 and absf(car_offset.z)<player_half_size.y+.4
		if player_blocks or _near_parked_vehicle(next,.4):
			step = 0.0
		for item in traffic_data:
			var offset: Vector3 = next-item.actor.position
			if absf(offset.x)<float(item.length)+.5 and absf(offset.z)<float(item.width)+.5:
				step = 0.0
				break
		crossing_pedestrian.position.z += step
		crossing_pedestrian.rotation.y = PI if crossing_direction>0 else 0.0
		if absf(crossing_pedestrian.position.z-6.32*crossing_direction)<.01:
			crossing_direction *= -1
			crossing_wait = 12.0
	for i in 2:
		var swing := sin(crossing_pedestrian.position.z*4+i*PI)*.38 if step!=0 else 0.0
		crossing_pedestrian.get_meta("legs")[i].rotation.x = swing
		crossing_pedestrian.get_meta("arms")[i].rotation.x = -swing

func _make_walker(label: String, start_x: float, lane_z: float, direction: float, shirt: Color, trousers: Color) -> void:
	var person := Node3D.new()
	person.name = label
	person.position = Vector3(start_x, 0.04, lane_z)
	person.rotation.y = -direction * PI * 0.5
	add_child(person)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.23
	torso_mesh.height = 0.82
	torso.mesh = torso_mesh
	torso.position = Vector3(0, 1.13, 0)
	torso.material_override = _material(shirt, 0.92)
	torso.name="Jacket"
	person.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	head.mesh = head_mesh
	head.position = Vector3(0, 1.72, 0)
	head.material_override = _material(Color("#c58e6d"), 0.94)
	person.add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.175
	hair_mesh.height = 0.18
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 1.85, 0)
	hair.material_override = _material(Color("#46372e"), 0.95)
	hair.name="Hair"
	person.add_child(hair)
	for side in [-1,1]:
		_make_box("Eye",Vector3(.024,.022,.014),Vector3(side*.064,1.745,-.15),Color("#45382e"),false,person)
	_make_box("Collar",Vector3(.26,.073,.23),Vector3(0,1.50,0),shirt.lightened(.22),false,person)
	for side in [-1.0, 1.0]:
		var leg_pivot := Node3D.new()
		leg_pivot.position = Vector3(side * 0.115, 0.77, 0)
		person.add_child(leg_pivot)
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.095
		leg_mesh.height = 0.78
		leg.mesh = leg_mesh
		leg.position.y = -0.36
		leg.material_override = _material(trousers, 0.94)
		leg_pivot.add_child(leg)
		_make_box("Shoe",Vector3(.17,.105,.27),Vector3(0,-.695,-.045),Color("#484443"),false,leg_pivot)
		var arm_pivot := Node3D.new()
		arm_pivot.position = Vector3(side * 0.22, 1.38, 0)
		person.add_child(arm_pivot)
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.075
		arm_mesh.height = 0.65
		arm.mesh = arm_mesh
		arm.position.y = -0.29
		arm.material_override = _material(shirt, 0.9)
		arm_pivot.add_child(arm)
		if not person.has_meta("legs"): person.set_meta("legs", [])
		if not person.has_meta("arms"): person.set_meta("arms", [])
		person.get_meta("legs").append(leg_pivot)
		person.get_meta("arms").append(arm_pivot)
	walker_data.append({"actor": person, "direction": direction, "speed": 1.15 + randf() * 0.45, "phase": randf() * TAU})

func _greet_nearby_player(person: Node3D) -> void:
	var nearby := person.is_visible_in_tree() and walker.visible and walker.position.distance_to(person.position)<2.9
	if nearby and not person.get_meta("greeted",false) and greeting_timer==0:
		var phrase := tr(["Hello!", "How are you?", "Hi there!"][greeting_number%3])
		greeting_number += 1
		greeting.reparent(person,false)
		greeting.position = Vector3.UP*2.18
		greeting.text = phrase
		greeting.visible = true
		greeting_timer = 7.5
		person.set_meta("greeted", true)
		if not AudioServer.is_bus_mute(0):
			var voices := DisplayServer.tts_get_voices_for_language(TranslationServer.get_locale().left(2))
			if not voices.is_empty():
				var level := roundi(65 * db_to_linear(AudioServer.get_bus_volume_db(0)))
				DisplayServer.tts_speak(phrase,voices[0],clampi(level,0,100))
	if walker.position.distance_to(person.position)>8:
		person.set_meta("greeted", false)

func _update_pedestrians(delta: float) -> void:
	_advance_crossing(delta)
	greeting_timer = maxf(0,greeting_timer-delta)
	greeting.visible = walker.visible and greeting_timer>4.0
	for person: Node3D in [square_neighbour, waiting_medic, marina_recipient, passenger, arriving_passenger]:
		if is_instance_valid(person):
			_greet_nearby_player(person)
	for item in walker_data:
		var person: Node3D = item["actor"]
		_greet_nearby_player(person)
		var direction: float = item["direction"]
		var next := person.position
		next.x = wrapf(next.x + direction * float(item.speed) * delta, -44.0, 44.0)
		if item.has("stretch"):
			var stretch: Vector2 = item.stretch
			if next.x<stretch.x or next.x>stretch.y:
				next.x=clampf(next.x,stretch.x,stretch.y)
				item.direction=-direction
				person.rotation.y=direction*PI*.5
		var local := ambulance.to_local(next)
		var blocked := ambulance.visible and absf(local.x) < player_half_size.x+.4 and absf(local.z) < player_half_size.y+.4
		# Wait at the kerb on red. People already crossing continue to the pavement.
		var enters_crossing := absf(person.position.x)>=5.15 and absf(next.x)<5.15
		if absf(absf(next.z)-6.35)<1.05 and enters_crossing and street_signals.phase!=0:
			blocked = true
		blocked = blocked or _near_parked_vehicle(next,.4)
		if item.has("stretch"):
			var front := next-person.basis.z*.88
			var relative := ambulance.to_local(front)
			blocked = blocked or (ambulance.visible and absf(relative.x)<player_half_size.x+.36 and absf(relative.z)<player_half_size.y+.4)
			blocked = blocked or _near_parked_vehicle(front,.38)
		if not blocked:
			person.position = next
			item.phase += delta * float(item.speed) * 4.0
		var legs: Array = person.get_meta("legs")
		var arms: Array = person.get_meta("arms")
		for i in range(legs.size()):
			var swing := sin(float(item.phase) + i * PI) if not blocked else 0.0
			legs[i].rotation.x = swing * .38
			arms[i].rotation.x = .63 if item.has("stretch") else -swing * .26

func _rig_wheels(model: Node3D) -> Array[Node3D]:
	var pivots: Array[Node3D] = []
	var pieces := model.find_children("*", "MeshInstance3D", true, false)
	for tire: MeshInstance3D in pieces:
		if not String(tire.name).begins_with("Performance tire") and not String(tire.name).begins_with("Däck") and not String(tire.name).begins_with("All terrain tire") and not String(tire.name).begins_with("Rear axle tire") and not String(tire.name).begins_with("Bicycle wheel"):
			continue
		var knuckle := Node3D.new()
		model.add_child(knuckle)
		knuckle.global_position = tire.to_global(tire.get_aabb().get_center())
		var pivot := Node3D.new()
		knuckle.add_child(pivot)
		tire.reparent(pivot)
		var bounds: AABB = tire.global_transform * tire.get_aabb()
		pivot.set_meta("radius", bounds.size.y * 0.5)
		pivots.append(pivot)
	if pivots.is_empty():
		return pivots
	for part: MeshInstance3D in pieces:
		var title := String(part.name)
		var is_wheel_part := false
		for prefix in ["Bicycle spoke", "Wheel hub", "Five double spokes", "Fälghål", "Wheel bolt", "Rear axle alloy", "Sidewall ring", "Alloy wheel", "Center cap", "Aluminiumfälg", "Diamond cut rim", "Anthracite wheel barrel", "Brake disc", "Red brake caliper", "Centre cap", "Blue hub enamel"]:
			if title.begins_with(prefix):
				is_wheel_part = true
				break
		if not is_wheel_part:
			continue
		var center := part.to_global(part.get_aabb().get_center())
		var nearest := pivots[0]
		for pivot in pivots:
			if pivot.global_position.distance_squared_to(center) < nearest.global_position.distance_squared_to(center):
				nearest = pivot
		part.reparent(nearest.get_parent() if title.begins_with("Red brake caliper") else nearest)
	return pivots

func _roll_wheels(pivots: Array[Node3D], distance: float) -> void:
	for pivot in pivots:
		pivot.rotate_x(distance / float(pivot.get_meta("radius")))

func _brake_lens(model: Node3D, reversing := false) -> StandardMaterial3D:
	var lens: StandardMaterial3D
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for index in part.mesh.get_surface_count():
			var original := part.mesh.surface_get_material(index) as StandardMaterial3D
			if not original:
				continue
			var matches := original.resource_name.begins_with("Tail lamp")
			if reversing:
				matches = part.name.begins_with("Kombinationslykta") and original.resource_name.begins_with("Glass reflection")
			if matches:
				if not lens:
					lens = original.duplicate()
					lens.emission_enabled = true
					lens.emission = Color.WHITE if reversing else Color(1.0, 0.015, 0.006)
					lens.emission_energy_multiplier = 0.0 if reversing else 0.18
				if part.name.begins_with("Centre brake lamp"):
					var centre := lens.duplicate() as StandardMaterial3D
					lens.set_meta("centre_lamp", centre)
					part.set_surface_override_material(index, centre)
				else:
					part.set_surface_override_material(index, lens)
	if lens and not reversing:
		_set_rear_lights(lens, false)
	return lens

func _set_rear_lights(lens: StandardMaterial3D, braking: bool) -> void:
	var energy := 2.4 if braking else lerpf(.18, .75, clampf(last_night, 0, 1))
	if not is_equal_approx(lens.emission_energy_multiplier, energy):
		lens.emission_energy_multiplier = energy
	if lens.has_meta("centre_lamp"):
		var centre: StandardMaterial3D = lens.get_meta("centre_lamp")
		centre.emission_enabled = braking
		if braking:
			centre.emission_energy_multiplier = 2.4

func _advance_wipers(delta: float) -> void:
	if wiper_pivots.is_empty(): return
	var precipitation := maxf(weather.intensity.x,weather.intensity.y)
	if precipitation < .06 and is_zero_approx(wiper_phase): return
	var next_phase := wiper_phase + delta*lerpf(2.0,5.4,precipitation)
	wiper_phase = 0.0 if precipitation < .06 and next_phase >= TAU else fmod(next_phase,TAU)
	var sweep := .64*(1.0-cos(wiper_phase))
	for pivot in wiper_pivots:
		pivot.basis = Basis(Vector3(0,.77,.64).normalized(),sweep)

func _load_vehicle_model() -> void:
	wiper_pivots.clear()
	wiper_phase = 0.0
	cockpit_view = false
	if is_instance_valid(vehicle_model):
		vehicle_model.queue_free()
	blue_light_meshes.clear()
	red_light_meshes.clear()
	var packed: PackedScene = load(VEHICLE_SCENES_ALL[vehicle_index])
	vehicle_model = packed.instantiate() as Node3D
	vehicle_model.name = VEHICLE_NAMES_ALL[vehicle_index] + "_BlenderModel"
	vehicle_model.rotation.y = PI
	ambulance.add_child(vehicle_model)
	dash_direction = null
	dash_speed = null
	reverse_feed = null
	reverse_monitor = null
	reverse_camera = null
	cabin_wheel = null
	if vehicle_index == 3:
		var arms := vehicle_model.find_children("Wiper arm*","MeshInstance3D",true,false)
		var blades := vehicle_model.find_children("Windscreen wiper blade*","MeshInstance3D",true,false)
		for i in mini(arms.size(),blades.size()):
			var arm := arms[i] as MeshInstance3D
			var bounds := arm.get_aabb()
			var pivot := Node3D.new()
			arm.get_parent().add_child(pivot)
			pivot.global_position = arm.to_global(Vector3(bounds.position.x,bounds.position.y,bounds.end.z))
			arm.reparent(pivot)
			blades[i].reparent(pivot)
			wiper_pivots.append(pivot)
		var rim := vehicle_model.find_child("Steering wheel rim*",true,false) as MeshInstance3D
		if rim:
			cabin_wheel = Node3D.new()
			vehicle_model.add_child(cabin_wheel)
			cabin_wheel.global_transform = Transform3D(ambulance.global_basis,rim.to_global(rim.get_aabb().get_center()))
			cabin_wheel_rest_basis = cabin_wheel.basis
			# Fit the rim's tilt in the vehicle's vertical/longitudinal plane.
			# The exported mesh already includes the X5's dimensional corrections.
			var rim_to_pivot := cabin_wheel.global_transform.affine_inverse() * rim.global_transform
			grip_radius = 0.0
			var yy := 0.0
			var yz := 0.0
			var zz := 0.0
			for surface_index in rim.mesh.get_surface_count():
				var points: PackedVector3Array = rim.mesh.surface_get_arrays(surface_index)[Mesh.ARRAY_VERTEX]
				for vertex in points:
					var point := rim_to_pivot * vertex
					grip_radius = maxf(grip_radius, absf(point.x))
					yy += point.y * point.y
					yz += point.y * point.z
					zz += point.z * point.z
			grip_radius *= .9
			var tilt := 0.5 * atan2(2.0 * yz, yy - zz)
			cabin_wheel_axis = Vector3(0,-sin(tilt),cos(tilt))
			for part in vehicle_model.find_children("*steering spoke*", "MeshInstance3D",true,false) + vehicle_model.find_children("Steering wheel*", "MeshInstance3D",true,false):
				part.reparent(cabin_wheel)

		var screen := vehicle_model.find_child("Curved instrument screen*",true,false) as MeshInstance3D
		if screen:
			var bounds: AABB = ambulance.global_transform.affine_inverse() * screen.global_transform * screen.get_aabb()
			dash_speed = Label3D.new()
			vehicle_model.add_child(dash_speed)
			var face := bounds.get_center()
			face.x += bounds.size.x*.02
			face.z = bounds.end.z+.003
			dash_speed.global_transform = ambulance.global_transform * Transform3D(Basis.IDENTITY,face)
			dash_speed.pixel_size = .00075
			dash_speed.font_size = 44
			dash_speed.outline_size = 0
			dash_speed.modulate = Color("#def4f7")
			dash_speed.text = "0 km/h"
			dash_direction = Label3D.new()
			vehicle_model.add_child(dash_direction)
			dash_direction.global_transform = dash_speed.global_transform.translated_local(Vector3.UP*.031)
			dash_direction.pixel_size = .00065
			dash_direction.font_size = 32
			dash_direction.outline_size = 0
			reverse_feed = SubViewport.new()
			reverse_feed.size = Vector2i(320,108)
			reverse_feed.render_target_update_mode = SubViewport.UPDATE_DISABLED
			vehicle_model.add_child(reverse_feed)
			reverse_feed.world_3d = get_world_3d()
			reverse_camera = Camera3D.new()
			reverse_camera.fov = 54
			reverse_feed.add_child(reverse_camera)
			reverse_monitor = Sprite3D.new()
			reverse_monitor.texture = reverse_feed.get_texture()
			reverse_monitor.pixel_size = .00078
			reverse_monitor.flip_h = true
			reverse_monitor.visible = false
			vehicle_model.add_child(reverse_monitor)
			reverse_monitor.global_transform = dash_speed.global_transform.translated_local(Vector3(bounds.size.x*.25,0,0))
	player_half_size = _vehicle_half_size(ambulance, vehicle_model)
	for beam in headlights:
		beam.queue_free()
	headlights.clear()
	for side in [-1,1]:
		var beam := SpotLight3D.new()
		beam.position = Vector3(side*player_half_size.x*.72,.87,-front_reach-.03)
		beam.rotation.x = deg_to_rad(-7.0)
		beam.spot_range = 28
		beam.spot_angle = 26
		beam.light_color = Color("#fff0d9")
		beam.light_energy = 4.5*maxf(last_night,0.0)
		beam.visible = last_night>.05
		ambulance.add_child(beam)
		headlights.append(beam)
	player_wheels = _rig_wheels(vehicle_model)
	_end_skid()
	rear_tire_contacts.clear()
	front_knuckles.clear()
	for pivot in player_wheels:
		var hub := ambulance.to_local(pivot.global_position)
		if hub.z < 0.0:
			front_knuckles.append(pivot.get_parent())
		elif hub.z > 0.0:
			rear_tire_contacts.append(Vector3(hub.x, 0.0, hub.z))
	player_brake_lens = _brake_lens(vehicle_model)
	reverse_lens = _brake_lens(vehicle_model, true) if vehicle_index == 0 else null
	_find_light_meshes(vehicle_model)
	_update_emergency_lights()

func _find_light_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			if "RoofBeacon" in str(child.name):
				var spill := OmniLight3D.new()
				spill.name = "Blue roof light"
				spill.light_color = Color("#3879ff")
				spill.light_energy = 2.6
				spill.omni_range = 5.0
				spill.position = child.get_aabb().get_center() + Vector3.UP*.14
				child.add_child(spill)
			if child.name.begins_with("FlashBlue"):
				blue_light_meshes.append(child)
				child.visible = false
			elif child.name.begins_with("FlashRed"):
				red_light_meshes.append(child)
				child.visible = false
		_find_light_meshes(child)

func _update_route_arrows() -> void:
	for arrow in route_arrows: arrow.visible = false
	if free_drive or mode!="playing" or mission_index>=TARGETS.size(): return
	var origin := walker.position if walker.visible else ambulance.position
	var target := _mission_destination()
	var points := navigator.path(Vector2(origin.x,origin.z),Vector2(target.x,target.z))
	var gap := 3.5
	var used := 0
	for i in range(1,points.size()):
		var segment := points[i]-points[i-1]
		var length := segment.length()
		var direction := segment.normalized()
		while gap<length and used<route_arrows.size():
			var point := points[i-1]+direction*gap
			var arrow := route_arrows[used]
			arrow.position = Vector3(point.x,_surface_height(point.x,point.y)+.07,point.y)
			arrow.rotation.y = atan2(-direction.x,-direction.y)
			arrow.visible=true
			used+=1
			gap+=6
		gap-=length
		if used==route_arrows.size(): break

func _sync_recovery() -> void:
	var active := vehicle_index==RECOVERY and not free_drive
	var loaded := recovery_leg%2==1
	workshop_car.visible=recovery_leg>=2 and not loaded
	var carrier := ambulance if not walker.visible else parked_cars[RECOVERY]
	if loaded and vehicle_index!=RECOVERY:
		carrier=parked_cars[RECOVERY]
	var parent: Node3D = carrier if loaded else self
	if casualty.get_parent()!=parent: casualty.reparent(parent,false)
	casualty.visible=active or (loaded and carrier.visible and not free_drive)
	if loaded:
		casualty.position=Vector3(0,1.25,1.59)
		casualty.rotation.y=PI
	else:
		var stop:Vector3=SERVICE_STOPS[recovery_leg%4]
		casualty.position=stop+Vector3(0,0,4.2 if recovery_leg%4==0 else -4.2)
		casualty.rotation.y=PI/2
	lost_wheel.visible=recovery_leg%4<2
	loose_wheel.visible=active and recovery_leg%4==2
	warning_triangle.visible=active and not loaded
	bonnet_smoke.emitting=active and recovery_leg%4==0

func _build_target_marker() -> void:
	var roadside_model := preload("res://vehicles/traffic_bmw_silver.glb")
	workshop_car=roadside_model.instantiate()
	add_child(workshop_car)
	workshop_car.position=Vector3(30,0,-40)
	workshop_car.scale=Vector3.ONE*.79
	workshop_car.rotation.y=PI/2
	workshop_car.hide()
	casualty=roadside_model.instantiate()
	add_child(casualty)
	casualty.scale=Vector3.ONE*.79
	casualty.add_child(warning_triangle)
	warning_triangle.position=Vector3(0,0,-3.75)
	_make_box("Triangle foot",Vector3(.68,.06,.34),Vector3(0,.035,0),Color("#33393b"),false,warning_triangle)
	var corners := [Vector3(-.34,.10,0),Vector3(.34,.10,0),Vector3(0,.69,0)]
	var reflector := _material(Color("#ff542f"),.35,true)
	for i in corners.size():
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i+1)%3]
		var strip := _make_box("Warning reflector",Vector3(a.distance_to(b),.074,.045),(a+b)*.5,Color.WHITE,false,warning_triangle)
		strip.rotation.z=atan2(b.y-a.y,b.x-a.x)
		strip.material_override=reflector
	lost_wheel=_rig_wheels(casualty)[0]
	loose_wheel=lost_wheel.duplicate()
	casualty.add_child(loose_wheel)
	var hub := casualty.to_local(lost_wheel.global_position)
	loose_wheel.position=Vector3(signf(hub.x)*(absf(hub.x)+1.05),.15,hub.z+.35)
	loose_wheel.rotation.z=PI*.5
	loose_wheel.hide()
	bonnet_smoke.position=Vector3(0,1.27,1.85)
	bonnet_smoke.amount=32
	bonnet_smoke.lifetime=1.6
	bonnet_smoke.direction=Vector3(.25,1,0)
	bonnet_smoke.gravity=Vector3(0,.6,0)
	bonnet_smoke.initial_velocity_min=.37
	bonnet_smoke.initial_velocity_max=.68
	var puff := SphereMesh.new()
	puff.radius=.105
	puff.height=.17
	puff.radial_segments=8
	puff.rings=3
	var haze := _material(Color(.52,.54,.56,.48))
	haze.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material=haze
	bonnet_smoke.mesh=puff
	casualty.add_child(bonnet_smoke)
	for i in 24:
		var arrow := Node3D.new()
		add_child(arrow)
		for side in [-1,1]:
			var bar := _make_box("Route chevron",Vector3(.18,.025,.95),Vector3(side*.29,0,0),Color("#65d6a8"),false,arrow)
			bar.rotation.y=side*.68
			bar.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arrow.visible=false
		route_arrows.append(arrow)
	_make_walker("Taxi passenger",0,0,1,Color("#724e74"),Color("#324c57"))
	passenger = walker_data.pop_back().actor
	_make_walker("Arrived taxi passenger",0,0,1,Color("#724e74"),Color("#324c57"))
	arriving_passenger = walker_data.pop_back().actor
	var square := WALK_TARGETS[0]
	_make_walker("Neighbour at the square",square.x+.9,square.z,-1,Color("#408a91"),Color("#465162"))
	square_neighbour = walker_data.pop_back().actor
	square_neighbour.position.y = _foot_height(square_neighbour.position.x,square.z)
	square_neighbour.rotation.y = 0
	var quay := WALK_TARGETS[2]
	_make_walker("Marina attendant",quay.x+.8,quay.z,1,Color("#e18a39"),Color("#314755"))
	marina_recipient = walker_data.pop_back().actor
	marina_recipient.position.y = _foot_height(marina_recipient.position.x,quay.z)
	var pickup := WALK_TARGETS[1]
	_make_walker("Waiting medic",pickup.x,pickup.z+1.3,1,Color("#d5db46"),Color("#275744"))
	waiting_medic = walker_data.pop_back().actor
	waiting_medic.position.y = _surface_height(pickup.x,pickup.z+1.3)
	waiting_medic.rotation.y = PI/2
	waiting_medic.add_child(medical_bag)
	medical_bag.name = "FirstAidKit"
	_make_box("Medical bag",Vector3(.24,.30,.38),Vector3.ZERO,Color("#30605b"),false,medical_bag)
	for side in [-1,1]:
		for size in [Vector3(.012,.14,.045),Vector3(.012,.045,.14)]:
			_make_box("First aid symbol",size,Vector3(side*.122,0,0),Color("#eef0df"),false,medical_bag)
	_make_box("Bag handle",Vector3(.045,.10,.14),Vector3(0,.18,0),Color("#253f40"),false,medical_bag)
	mission_marker = Node3D.new()
	add_child(mission_marker)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .946
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.name = "ArrivalZone"
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.material_override = _material(Color("#7fda9b"), 0.35, true)
	mission_marker.add_child(ring)
	var beacon := _make_box("Mission beacon", Vector3(0.32, 1.1, 0.32), Vector3(0, 0.62, 0), Color("#83dda0"), false, mission_marker)
	beacon.material_override = _material(Color("#83dda0"), 0.25, true)
	var label := Label3D.new()
	label.name = "MissionLabel"
	label.text = "MISSION"
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.1
	label.modulate = Color("#f4ffe9")
	mission_marker.add_child(label)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58
	add_child(camera)
	_update_camera(0.0, true)

func _toggle_camera_view() -> void:
	if vehicle_index != 3 or boating or tram_mode!=0 or walker.visible or paused or mode != "playing": return
	cockpit_look = Vector2.ZERO
	cockpit_view = not cockpit_view
	_update_camera(0,true)
	_refresh_ui()
	get_viewport().gui_release_focus()

func _update_camera(delta: float, snap_to_car := false) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(ambulance): return
	if boating and is_instance_valid(launch):
		camera.position = launch.to_global(Vector3(1,3.6+orbit_height,7).rotated(Vector3.UP,orbit_angle))
		camera.look_at(launch.to_global(Vector3(0,.4,-1.7)))
		return
	if tram_mode > 0 and not tram.sections.is_empty():
		var cab: Node3D = tram.sections[0]
		camera.position = cab.to_global(Vector3(4.0,4.1+orbit_height,8.0).rotated(Vector3.UP,orbit_angle))
		camera.look_at(cab.to_global(Vector3(0,1.4,-1)))
		return
	if walker.visible and shops.inside>=0:
		camera.position=walker.position+Vector3(0,3.8,-2.7)
		camera.look_at(walker.position+Vector3(0,.9,1))
		return
	if walker.visible:
		var target := walker.position + Vector3.UP*1.2
		var chase := camera.position.lerp(target+walk_basis.z.rotated(Vector3.UP,orbit_angle)*5+Vector3.UP*(2.7+orbit_height),1-exp(-6*delta))
		camera.position = _clear_camera_view(target, chase)
		camera.look_at(target)
		return
	if cockpit_view and vehicle_index == 3:
		camera.global_position = ambulance.to_global(Vector3(-.32,1.56,-.10))
		var gaze := Vector3(steering*.38,-.16,-5.9).rotated(Vector3.RIGHT,cockpit_look.y).rotated(Vector3.UP,cockpit_look.x)
		camera.look_at(camera.global_position + ambulance.global_basis*gaze)
		return
	var forward := -ambulance.global_transform.basis.z
	var desired := ambulance.global_position - forward.rotated(Vector3.UP,orbit_angle) * 10.5 + Vector3(0, 6.0+orbit_height, 0)
	var preview := steering * clampf(1.0 - absf(speed) / 45.0, 0.35, 1.0)
	if speed < -0.1:
		preview = 0.0
	camera_turn = 0.0 if snap_to_car else lerpf(camera_turn, preview, 1.0 - exp(-5.0 * delta))
	var right := ambulance.global_transform.basis.x
	desired += right * camera_turn * 0.65
	var look := ambulance.global_position + forward * 4.0 + right * camera_turn * 2.5 + Vector3.UP
	var weight := 1.0 if snap_to_car else 1.0 - exp(-4.0 * maxf(delta, 0.0))
	var followed := camera.global_position.lerp(desired, weight)
	# Bound lag along the road while preserving the damped orbit through turns.
	var lag := (desired - followed).dot(forward)
	followed += forward * (lag - clampf(lag, -2.0, 2.0))
	var anchor := ambulance.global_position + Vector3.UP * 2.8
	camera.global_position = _clear_camera_view(anchor, followed)
	camera.look_at(look, Vector3.UP)

func _clear_camera_view(anchor: Vector3, desired: Vector3) -> Vector3:
	for building in building_bounds:
		var contact = building.grow(0.18).intersects_segment(anchor, desired)
		if contact != null:
			desired = anchor.move_toward(contact, maxf(0.04, anchor.distance_to(contact) - 0.08))
	return desired

func _update_mission_marker() -> void:
	if not is_instance_valid(mission_marker): return
	_sync_recovery()
	_update_route_arrows()
	passenger.visible = not free_drive and vehicle_index == TAXI and taxi_leg%2==0
	passenger.position = WALK_TARGETS[_taxi_stop()]
	arriving_passenger.visible = passenger.visible and taxi_leg >= 2
	if arriving_passenger.visible:
		arriving_passenger.position = WALK_TARGETS[_taxi_stop(taxi_leg-1)]
	var rescue := not free_drive and not boating and vehicle_index not in [TAXI, RECOVERY]
	square_neighbour.visible = rescue and mission_index <= 1
	square_neighbour.get_meta("arms")[1].rotation.z = 2.35 if mission_index == 0 else 0.0
	waiting_medic.visible = rescue and mission_index == 1
	marina_recipient.visible = rescue and mission_index >= 2
	var carrier: Node3D = waiting_medic
	var bag_position := Vector3(.34,.53,0)
	medical_bag.visible = rescue and mission_index >= 1
	if mission_index == 2:
		carrier = walker if walker.visible else ambulance
		bag_position = Vector3(.34,.53,0) if walker.visible else Vector3.ZERO
		medical_bag.visible = rescue and walker.visible
	elif mission_index == TARGETS.size():
		carrier = marina_recipient
	if medical_bag.get_parent() != carrier:
		medical_bag.reparent(carrier,false)
	medical_bag.position = bag_position
	if free_drive or mission_index >= TARGETS.size():
		mission_marker.visible = false
		return
	mission_marker.visible = true
	var zone := mission_marker.get_node("ArrivalZone") as MeshInstance3D
	zone.scale = Vector3(_arrival_radius(),.4,_arrival_radius())
	mission_marker.global_position = _mission_destination() + Vector3(0, 0.05, 0)
	var marker_label: Label3D = mission_marker.get_node("MissionLabel")
	marker_label.text = tr(SERVICE_MESSAGES[recovery_leg%4] if vehicle_index==RECOVERY else _taxi_instruction() if vehicle_index==TAXI else TARGET_NAMES[mission_index]).to_upper()

func _update_emergency_lights() -> void:
	var phase := int(light_phase * 2.0) % 2
	for light in blue_light_meshes:
		light.visible = lights_on and (steady_player_lights or phase == 0)
	for light in red_light_meshes:
		light.visible = lights_on and (steady_player_lights or phase == 1)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_top = 18
	top.offset_right = -22
	top.offset_bottom = 92
	top.add_theme_stylebox_override("panel", _style(Color(0.055, 0.09, 0.11, 0.94), 18))
	ui.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	var title := Label.new()
	title.text = "Axel's Emergency Vehicles"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f4f1e8"))
	row.add_child(title)
	mission_label = Label.new()
	mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 20)
	mission_label.add_theme_color_override("font_color", Color("#c5efce"))
	row.add_child(mission_label)
	wallet_label=Label.new()
	wallet_label.accessibility_name="Wallet"
	row.add_child(wallet_label)
	light_button = _button("Lights OFF", 140)
	light_button.pressed.connect(_toggle_lights)
	row.add_child(light_button)
	camera_button = _button("Driver view · C",140)
	camera_button.pressed.connect(_toggle_camera_view)
	row.add_child(camera_button)
	siren_button = _button("Siren OFF", 130)
	siren_button.pressed.connect(_toggle_sound)
	row.add_child(siren_button)
	pause_button = _button("Pause", 95)
	pause_button.pressed.connect(_toggle_pause)
	row.add_child(pause_button)
	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	status_label.position = Vector2(-450, -100)
	status_label.size = Vector2(900, 48)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(status_label)
	ui.add_child(arrival_progress)
	arrival_progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	arrival_progress.offset_left = -72
	arrival_progress.offset_right = 72
	arrival_progress.offset_top = -108
	arrival_progress.offset_bottom = -100
	arrival_progress.show_percentage = false
	arrival_progress.max_value = HELP_DURATION
	arrival_progress.step = 0.0
	arrival_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrival_progress.add_theme_stylebox_override("background", _style(Color("#203137"), 3))
	arrival_progress.add_theme_stylebox_override("fill", _style(Color("#83dda0"), 3))
	add_child(horn)
	horn.volume_db = -5
	horn_button = _button("Horn · H",135)
	ui.add_child(horn_button)
	horn_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	horn_button.offset_left = -220
	horn_button.offset_right = -22
	horn_button.offset_top = -82
	horn_button.offset_bottom = -34
	horn_button.pressed.connect(_honk)
	seat_button = _button("Get out · F", 135)
	ui.add_child(seat_button)
	seat_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	seat_button.offset_left=-220
	seat_button.offset_right=-22
	seat_button.pressed.connect(_change_seat)
	var help := Label.new()
	help.name = "DrivingHints"
	help.text = "W / ↑  Drive     A D / ← →  Steer     S / ↓  Brake or reverse\nRelease to slow down   ·   Space to help   ·   P to pause"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	help.offset_top = -50
	help.add_theme_font_size_override("font_size", 16)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", Color("#f5f1df"))
	help.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	ui.add_child(help)
	ui.add_child(driving_controls)
	driving_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shops.build_menu(ui)
	ui.add_child(phone)
	_build_overlay()
	siren_player = AudioStreamPlayer.new()
	siren_player.volume_db = -11
	add_child(siren_player)
	for path in SIREN_SOUNDS:
		var stream: AudioStreamWAV = load(path)
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		siren_streams.append(stream)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.035, 0.045, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	overlay_panel = PanelContainer.new()
	overlay_panel.custom_minimum_size = Vector2(620, 350)
	overlay_panel.add_theme_stylebox_override("panel", _style(Color("#172b32"), 24))
	center.add_child(overlay_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	overlay_panel.add_child(box)
	brand_logo.custom_minimum_size = Vector2(320, 128)
	brand_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(brand_logo)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color("#f5f1e4"))
	box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color("#d4e2dc"))
	box.add_child(subtitle_label)
	start_button = _button("Start a gentle drive", 300)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_overlay_action)
	vehicle_selector = OptionButton.new()
	vehicle_selector.custom_minimum_size = Vector2(320, 48)
	vehicle_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vehicle_selector.add_theme_font_size_override("font_size", 19)
	for name in VEHICLE_NAMES_ALL:
		vehicle_selector.add_item(name)
	vehicle_selector.item_selected.connect(_on_vehicle_selected)
	var player_row := HBoxContainer.new()
	player_row.alignment=BoxContainer.ALIGNMENT_CENTER
	box.add_child(player_row)
	var character := OptionButton.new()
	character.accessibility_name="Character"
	character.add_item("Axel · 15")
	character.add_item("Alma · 12")
	character.select(int(play_as_alma))
	character.item_selected.connect(func(index: int):
		play_as_alma=index==1
		_apply_player_appearance()
		_save_preferences()
		_refresh_ui()
	)
	player_row.add_child(character)
	player_row.add_child(vehicle_selector)
	activity.accessibility_name = "Activity"
	activity.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	activity.add_item("Three missions")
	activity.add_item("Free exploration")
	activity.add_item("Ride the tram")
	activity.add_item("Drive the tram")
	activity.add_item("Drive the motorboat")
	activity.item_selected.connect(func(index: int):
		boating = index==4
		if mode == "menu" and index >= 2: siren_player.stop()
		tram_mode = index-1 if index in [2,3] else 0
		launch_speed = 0
		var ear: Node3D = tram.sections[0] if tram_mode > 0 else launch if boating else (walker if walker.visible else ambulance)
		if listener.get_parent()!=ear:
			listener.reparent(ear,false)
			listener.position=Vector3.UP*1.3
		free_drive = index != 0
		parked_at_target = 0.0
		message_timer = 0.0
		_update_mission_marker()
		_refresh_ui()
	)
	box.add_child(activity)
	box.add_child(start_button)
	var settings_toggle := _button("Settings", 220)
	settings_toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_toggle.toggle_mode = true
	box.add_child(settings_toggle)
	var settings := VBoxContainer.new()
	settings.visible = false
	settings.add_theme_constant_override("separation", 8)
	box.add_child(settings)
	settings_toggle.toggled.connect(func(expanded: bool):
		settings.visible = expanded
		settings_toggle.text = "Close settings" if expanded else "Settings"
	)
	var language_row := HBoxContainer.new()
	language_row.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_child(language_row)
	var language_label := Label.new()
	language_label.text = "Language"
	language_row.add_child(language_label)
	var language := OptionButton.new()
	language.accessibility_name = "Language"
	language.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var locales := PackedStringArray(["en"])
	for locale in TranslationServer.get_loaded_locales():
		if not locale in locales:
			locales.append(locale)
	for locale in locales:
		language.add_item("Svenska" if locale == "sv" else TranslationServer.get_locale_name(locale))
	language.select(maxi(0, locales.find(TranslationServer.get_locale())))
	language.item_selected.connect(func(index: int):
		TranslationServer.set_locale(locales[index])
		_save_preferences()
	)
	language_row.add_child(language)
	var handling := OptionButton.new()
	handling.name = "Korlage"
	handling.accessibility_name = "Driving mode"
	handling.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	handling.add_item("Gentle driving · up to 30 km/h")
	handling.add_item("Full speed")
	handling.select(0 if gentle_driving else 1)
	handling.item_selected.connect(_set_handling)
	settings.add_child(handling)
	preview_sound_button = _button("Preview vehicle sound", 300)
	preview_sound_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_sound_button.pressed.connect(_preview_sound)
	settings.add_child(preview_sound_button)
	var volume_row := HBoxContainer.new()
	volume_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var volume_label := Label.new()
	volume_label.text = "Game volume"
	volume_row.add_child(volume_label)
	var volume := HSlider.new()
	volume.accessibility_name = "Game volume"
	volume.custom_minimum_size.x = 180
	volume.max_value = 100
	volume.step = 5
	volume.value = 0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0)) * 100
	volume.value_changed.connect(_set_game_volume)
	volume_row.add_child(volume)
	var traffic_volume_label := Label.new()
	traffic_volume_label.text = "Traffic sirens"
	volume_row.add_child(traffic_volume_label)
	var traffic_volume := HSlider.new()
	traffic_volume.accessibility_name = "Traffic sirens"
	traffic_volume.custom_minimum_size.x = 120
	traffic_volume.max_value = 100
	traffic_volume.step = 5
	traffic_volume.value = traffic_siren_volume
	traffic_volume.value_changed.connect(func(percent: float):
		traffic_siren_volume = percent
		for unit in emergency_traffic:
			unit.siren.volume_db = -6 + linear_to_db(maxf(.001, percent / 100.0))
		_update_traffic_signals(0)
		_save_preferences()
	)
	volume_row.add_child(traffic_volume)
	settings.add_child(volume_row)
	var traffic_lights := OptionButton.new()
	traffic_lights.name = "Trafikljusval"
	traffic_lights.accessibility_name = "Emergency lights in traffic"
	traffic_lights.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for caption in ["Traffic lights · Flashing blue", "Traffic lights · Steady blue", "Traffic lights · Blue lights off"]:
		traffic_lights.add_item(caption)
	traffic_lights.select(traffic_light_mode)
	traffic_lights.item_selected.connect(_set_traffic_light_mode)
	var beacon_row := HBoxContainer.new()
	beacon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_child(beacon_row)
	beacon_row.add_child(traffic_lights)
	var own_beacon := OptionButton.new()
	own_beacon.add_item("My vehicle · Flashing")
	own_beacon.add_item("My vehicle · Steady")
	own_beacon.select(int(steady_player_lights))
	own_beacon.item_selected.connect(func(index: int):
		steady_player_lights = index == 1
		_update_emergency_lights()
		_save_preferences()
	)
	beacon_row.add_child(own_beacon)
	var daylight := OptionButton.new()
	daylight.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for caption in ["Time · Day", "Time · Night", "Time · Day and night"]:
		daylight.add_item(caption)
	daylight.select(time_mode)
	daylight.item_selected.connect(func(index: int):
		time_mode = index
		_update_daylight(0)
		_save_preferences()
	)
	var weather_row := HBoxContainer.new()
	weather_row.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_child(weather_row)
	weather_row.add_child(daylight)
	for is_season in [true,false]:
		var choice := OptionButton.new()
		for caption in (weather.SEASONS if is_season else weather.CONDITIONS):
			choice.add_item(caption)
		choice.select(weather.season_setting if is_season else weather.weather_setting)
		choice.item_selected.connect(func(index: int):
			if is_season: weather.season_setting = index
			else: weather.weather_setting = index
			_save_preferences()
		)
		weather_row.add_child(choice)

func _button(caption: String, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(width, 48)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#172b32"))
	button.add_theme_stylebox_override("normal", _style(Color("#d9e8dc"), 12))
	button.add_theme_stylebox_override("hover", _style(Color("#f3f5e9"), 12))
	button.add_theme_stylebox_override("pressed", _style(Color("#a8cfb1"), 12))
	return button

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _starting_position() -> Vector3:
	var best_x := -35.0
	var largest_gap := -INF
	var lane := 2.35
	for x in range(-40, -7):
		var gap := INF
		for item in traffic_data:
			var other: Node3D = item.actor
			if absf(other.position.z - lane) >= player_half_size.x + float(item.width):
				continue
			gap = minf(gap, absf(other.position.x - x) - float(item.length) - player_half_size.y)
		if gap > largest_gap:
			largest_gap = gap
			best_x = x
	return Vector3(best_x, _surface_height(best_x, lane), lane)

func _start_game() -> void:
	waiting_for_signal = false
	last_dispatch=""
	phone.messages.clear()
	phone.unread=0
	phone.handset.hide()
	parked_sound_settings.assign([false, false, false, true, true, true])
	parked_light_settings.fill(false)
	mode = "playing"
	paused = false
	mission_index = 0
	recovery_leg = 0
	taxi_leg = 0
	parked_at_target = 0.0
	var ear: Node3D = tram.sections[0] if tram_mode > 0 else launch if boating else ambulance
	if listener.get_parent() != ear:
		listener.reparent(ear,false)
	listener.transform = Transform3D(Basis.IDENTITY,Vector3.UP*(1.0 if boating else 1.3))
	listener.make_current()
	walker.visible = false
	ambulance.visible = true
	for i in parked_cars.size():
		parked_cars[i].visible = i != vehicle_index
		parked_cars[i].position = Vector3(-45,-.13,25) if i==RECOVERY else Vector3(-47+5*i,-.13,15)
		parked_cars[i].rotation = Vector3.ZERO
	ambulance.global_position = _starting_position()
	ambulance.rotation = Vector3(0, -PI * 0.5, 0)
	_update_camera(0.0, true)
	speed = 0
	steering = 0
	message = ""
	_update_mission_marker()
	_update_siren()
	_refresh_ui()
	get_viewport().gui_release_focus()

func _on_vehicle_selected(index: int) -> void:
	if mode == "playing" and not paused:
		vehicle_selector.select(vehicle_index)
		return
	if siren_player.playing:
		siren_player.stop()
	if index != vehicle_index:
		parked_light_settings[vehicle_index] = lights_on
		lights_on = parked_light_settings[index]
	if paused and index != vehicle_index:
		parked_sound_settings[vehicle_index] = sound_on
		sound_on = parked_sound_settings[index]
		parked_cars[vehicle_index].transform = parked_cars[index].transform
		parked_cars[vehicle_index].visible = true
		parked_cars[index].visible = false
	vehicle_index = clampi(index, 0, VEHICLE_NAMES_ALL.size() - 1)
	speed = 0
	steering = 0
	brake_held = false
	_end_skid()
	_load_vehicle_model()
	_update_mission_marker()
	_refresh_ui()

func _preview_sound() -> void:
	if siren_player.playing:
		siren_player.stop()
		sound_on = false
	else:
		sound_on = true
		siren_player.stream = siren_streams[vehicle_index]
		siren_player.volume_db = -1.0
		siren_player.pitch_scale = 1.0
		siren_player.play()
	_refresh_ui()

func _overlay_action() -> void:
	if mode == "playing" and paused:
		_toggle_pause()
	else:
		_start_game()

func _toggle_pause() -> void:
	if mode != "playing": return
	paused = not paused
	_update_siren()
	_refresh_ui()
	if paused:
		start_button.grab_focus()
	else:
		get_viewport().gui_release_focus()

func _toggle_lights() -> void:
	if vehicle_index >= 3 or walker.visible: return
	lights_on = not lights_on
	_update_emergency_lights()
	_refresh_ui()

func _load_preferences() -> void:
	TranslationServer.set_locale("en")
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	play_as_alma=config.get_value("player","alma",false)==true
	purchases=config.get_value("player","purchases",{})
	wallet=maxi(0,int(config.get_value("player","coins",0)))
	var saved_locale := str(config.get_value("language", "locale", "en"))
	if saved_locale in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(saved_locale)
	weather.season_setting = clampi(int(config.get_value("world","season",0)),0,4)
	weather.weather_setting = clampi(int(config.get_value("world","weather",0)),0,4)
	time_mode = clampi(int(config.get_value("world","daylight",0)),0,2)
	steady_player_lights = config.get_value("driving","steady_lights",false) == true
	var gentle = config.get_value("driving","gentle",true)
	if gentle is bool:
		gentle_driving = gentle
	var mode_value = config.get_value("traffic","lights",0)
	if mode_value is int:
		traffic_light_mode = clampi(mode_value,0,2)
	traffic_siren_volume = clampf(float(config.get_value("audio","traffic_sirens",100)),0,100)
	var volume_value = config.get_value("audio","volume",100)
	if volume_value is float or volume_value is int:
		_apply_game_volume(clampf(volume_value,0,100))

func _save_preferences() -> void:
	var config := ConfigFile.new()
	var volume := 0.0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0))*100
	config.set_value("player","alma",play_as_alma)
	config.set_value("player","coins",wallet)
	config.set_value("player","purchases",purchases)
	config.set_value("language", "locale", TranslationServer.get_locale())
	config.set_value("audio","volume",roundi(volume))
	config.set_value("audio","traffic_sirens",roundi(traffic_siren_volume))
	config.set_value("world","season",weather.season_setting)
	config.set_value("world","weather",weather.weather_setting)
	config.set_value("world","daylight",time_mode)
	config.set_value("driving","gentle",gentle_driving)
	config.set_value("traffic","lights",traffic_light_mode)
	config.set_value("driving","steady_lights",steady_player_lights)
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Kunde inte spara spelinställningarna: " + error_string(result))

func _set_handling(index: int) -> void:
	gentle_driving = index == 0
	if gentle_driving:
		speed = clampf(speed, -1.8, 30.0 / 3.6)
	_save_preferences()

func _set_traffic_light_mode(index: int) -> void:
	traffic_light_mode = index
	_save_preferences()

func _set_game_volume(percent: float) -> void:
	_apply_game_volume(percent)
	_save_preferences()

func _apply_game_volume(percent: float) -> void:
	AudioServer.set_bus_mute(0, percent <= 0)
	if percent <= 0 and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	if percent > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(percent / 100.0))

func _toggle_sound() -> void:
	sound_on = not sound_on
	_update_siren()
	_refresh_ui()

func _update_siren() -> void:
	if sound_on and not boating and tram_mode == 0 and mode == "playing" and not paused and not walker.visible:
		if siren_player.stream != siren_streams[vehicle_index]:
			siren_player.stream = siren_streams[vehicle_index]
		if vehicle_index < 3:
			siren_player.pitch_scale = 1.0
		siren_player.volume_db = -1.0
		if not siren_player.playing: siren_player.play()
	else:
		if mode != "menu" or not siren_player.playing:
			siren_player.stop()

func _refresh_dispatch() -> void:
	phone.visible = mode=="playing" and not paused
	phone.refresh()
	if free_drive or mode!="playing" or mission_index>=TARGETS.size():
		last_dispatch=""
		return
	var dispatch: String
	if vehicle_index==RECOVERY:
		match recovery_leg%4:
			0: dispatch="A car is smoking on the main street. Follow the arrows and stop beside it."
			2: dispatch="A car on the east bank has lost a wheel. Follow the arrows to pick it up."
			_: dispatch="The car is on your flatbed. Follow the arrows to the workshop for 20 coins."
	elif vehicle_index==TAXI:
		var requests := ["Taxi requested at the square.","Please take me to the marina.","Taxi requested at the clinic.","Please take me to the square.","Taxi requested at the marina.","Please take me to the clinic."]
		dispatch=requests[taxi_leg%requests.size()]
	else:
		dispatch=["A neighbour needs help at the square.","A medic is waiting at the clinic. Please pick them up.","Please bring the first-aid supplies to the marina."][mission_index]
	if dispatch!=last_dispatch:
		last_dispatch=dispatch
		phone.receive(dispatch)

func _refresh_ui() -> void:
	if road_driver:
		road_driver.visible = vehicle_index == 3 and mode == "playing" and not walker.visible and not boating and tram_mode == 0 and not cockpit_view
	if skipper: skipper.visible = boating and mode == "playing"
	if not is_instance_valid(mission_label): return
	var mission_activity := "Taxi fares" if vehicle_index == TAXI else "Roadside recovery" if vehicle_index == RECOVERY else "Three missions"
	if activity.item_count > 0 and activity.get_item_text(0) != mission_activity:
		activity.set_item_text(0,mission_activity)
	_refresh_dispatch()
	wallet_label.text = tr("%d coins") % wallet
	light_button.text = "Lights ON" if lights_on else "Lights OFF"
	if vehicle_index >= 3:
		siren_button.text = "Engine ON" if sound_on else "Engine OFF"
	else:
		siren_button.text = "Siren ON" if sound_on else "Siren OFF"
	pause_button.text = "Resume" if paused else "Pause"
	if tram_mode > 0:
		mission_label.text = "Ride the tram" if tram_mode == 1 else "Drive the tram"
	elif boating:
		mission_label.text = "Drive the motorboat"
	elif free_drive:
		mission_label.text = "Free exploration"
	elif vehicle_index==RECOVERY:
		mission_label.text=tr(SERVICE_MESSAGES[recovery_leg%4])
	elif vehicle_index==TAXI:
		mission_label.text = tr(_taxi_instruction())
	elif mission_index < TARGET_NAMES.size():
		mission_label.text = tr("MISSION %d / %d   ·   %s") % [mission_index + 1, TARGET_NAMES.size(), tr(TARGET_NAMES[mission_index])]
	else:
		mission_label.text = "ALL MISSIONS COMPLETE"
	var show_overlay := mode == "menu" or mode == "complete" or paused
	for control in [light_button, siren_button, pause_button]:
		control.focus_mode = Control.FOCUS_NONE if show_overlay else Control.FOCUS_ALL
	camera_button.visible = tram_mode == 0 and not boating and vehicle_index == 3 and not walker.visible and not show_overlay
	camera_button.text = "Outside view · C" if cockpit_view else "Driver view · C"
	horn_button.visible = not show_overlay and (tram_mode==2 or (tram_mode==0 and (boating or not walker.visible)))
	horn_button.text = "Tram bell · H" if tram_mode==2 else "Horn · H"
	seat_button.visible = not show_overlay and tram_mode==0 and not boating
	light_button.visible = tram_mode == 0 and not boating and not walker.visible and vehicle_index < 3
	siren_button.visible = tram_mode == 0 and not boating and not walker.visible
	if walker.visible:
		_update_entry_button()
	else:
		seat_button.disabled = false
		entry_marker.visible = false
		seat_button.text = "Get out · F"
	driving_controls.show_wheel = tram_mode == 0
	driving_controls.visible = not show_overlay and (tram_mode == 2 or (tram_mode == 0 and (boating or not walker.visible)))
	var hints := ui.get_node("DrivingHints") as Label
	hints.visible = driving_controls.visible or (tram_mode > 0 and not show_overlay)
	if tram_mode == 1:
		hints.text = "Passenger ride · P to pause"
	elif tram_mode == 2:
		hints.text = "W / ↑ Accelerate · S / ↓ Brake · Automatic station stops"
	elif boating:
		hints.text = "W / ↑ Throttle · A D / ← → Steer · S / ↓ Slow or reverse · H Horn · P Pause"
	elif free_drive:
		hints.text = "W / ↑ Drive   ·   A D / ← → Steer   ·   S / ↓ Brake or reverse   ·   F Get out   ·   P Pause"
	else:
		hints.text = "W / ↑  Drive     A D / ← →  Steer     S / ↓  Brake or reverse\nRelease to slow down   ·   Space to help   ·   P to pause"
	if show_overlay:
		mouse_gas = false
		mouse_brake = false
	overlay.visible = show_overlay
	overlay_panel.visible = show_overlay
	vehicle_selector.visible = show_overlay and not walker.visible and not boating and tram_mode == 0
	preview_sound_button.visible = mode == "menu" and not boating and tram_mode == 0
	preview_sound_button.text = "Stop preview" if siren_player.playing and mode == "menu" else ("Preview engine" if vehicle_index >= 3 else "Preview siren")
	var locale := TranslationServer.get_locale().get_slice("_", 0)
	var localized_logo := locale in ["en", "sv"]
	title_label.visible = mode != "menu" or not localized_logo
	brand_logo.visible = mode == "menu" and localized_logo
	brand_logo.texture = preload("res://branding/game-logo-sv.png") if locale == "sv" else preload("res://branding/game-logo-en.png")
	brand_logo.accessibility_name = tr("Axel's Emergency Vehicles")
	get_window().title = tr("Axel's Emergency Vehicles")
	if mode == "menu":
		title_label.text = "Axel's Emergency Vehicles"
		subtitle_label.text = "Choose a vehicle and drive to three missions.\nTake your time. You control the lights and siren."
		if free_drive:
			subtitle_label.text = "Explore on foot or by vehicle. Stop at the depot to change vehicles."
		elif vehicle_index == TAXI:
			subtitle_label.text = "Pick up a passenger at the square and drive them to the marina."
		elif vehicle_index == RECOVERY:
			subtitle_label.text = "Collect the car with a smoking bonnet and take it to the workshop."
		start_button.text = "Start driving"
	elif mode == "complete":
		title_label.text = "All missions complete!"
		subtitle_label.text = tr("Well done, %s!") % ("Alma" if play_as_alma else "Axel") + "\n" + tr("First-aid supplies delivered to the marina. You earned 10 coins.")
		start_button.text = "Drive again"
	else:
		title_label.text = "Pause"
		subtitle_label.text = "You can change vehicles here and continue your mission."
		if free_drive:
			subtitle_label.text = "Explore on foot or by vehicle. Stop at the depot to change vehicles."
		if walker.visible:
			subtitle_label.text = "Walk up to a parked vehicle to get in."
		start_button.text = "Continue walking" if walker.visible else "Continue driving"
	if show_overlay and mode != "complete":
		if boating:
			subtitle_label.text = "Explore the canal. Steer with A and D or the arrow keys."
			start_button.text = "Start boating" if mode=="menu" else "Continue boating"
		elif tram_mode > 0:
			subtitle_label.text = "The tram drives itself and stops at each platform." if tram_mode==1 else "Control the speed. The tram follows the rails and stops at each platform."
			start_button.text = "Ride the tram" if tram_mode==1 else "Drive the tram"
			if paused: start_button.text = "Resume"
	_refresh_status()

func _refresh_status() -> void:
	if not is_instance_valid(status_label): return
	if reverse_monitor:
		var reversing := cockpit_view and not walker.visible and speed < -.12 and mode == "playing" and not paused
		reverse_monitor.visible = reversing
		reverse_feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS if reversing else SubViewport.UPDATE_DISABLED
		if reversing:
			reverse_camera.global_position = ambulance.to_global(Vector3(0,1,player_half_size.y+.04))
			reverse_camera.look_at(ambulance.to_global(Vector3(0,.48,player_half_size.y+4)))
	if dash_speed:
		var direction := "Reversing" if speed < -.12 else "Forward" if speed > .12 else "Stopped"
		if dash_direction.text != direction:
			dash_direction.text = direction
			dash_direction.modulate = Color("#ffd07a") if speed < -.12 else Color("#def4f7")
		var reading := "%d km/h" % roundi(absf(speed)*3.6)
		if dash_speed.text != reading:
			dash_speed.text = reading
	arrival_progress.visible = mode == "playing" and not paused and not free_drive and parked_at_target > 0.0
	arrival_progress.value = parked_at_target
	if tram_mode > 0 and mode == "playing" and not paused:
		if tram.dwell > 0:
			var station: String = tram.STATION_NAMES[posmod(tram.next_stop-1,tram.stops.size())]
			status_label.text = tr("%s · Departure in %d s") % [station,ceili(tram.dwell)]
		else:
			status_label.text = tr("Next stop: %s · %d m · %d km/h") % [tram.STATION_NAMES[tram.next_stop],ceili(tram.distance_to_next_stop()),roundi(tram.velocity*3.6)]
	elif message_timer > 0 and message != "":
		status_label.text = message
	elif mode == "playing" and not paused and walker.visible and _at_target():
		status_label.text = "Stand here to help" if gentle_driving else "Press Space to help"
	elif mode == "playing" and not paused and _at_target():
		if absf(speed) >= .12:
			status_label.text = "Stop here to help."
		else:
			status_label.text = "Helping …" if gentle_driving else "Press Space to help"
	elif waiting_for_signal and mode=="playing" and not paused and not walker.visible and not boating:
		status_label.text = "Waiting for a green light"
	elif walker.visible and not boating and not paused:
		status_label.text = "Walk with WASD or arrows · F to enter a vehicle"
	elif paused:
		status_label.text = "Paused — take your time."
	else:
		status_label.text = tr("Speed  %02d km/h") % roundi(absf(launch_speed if boating else speed) * 3.6)

func _make_driving_surface(label: String, size: Vector3, pos: Vector3, color: Color, collision := false) -> MeshInstance3D:
	driving_surfaces.append(AABB(pos - size * 0.5, size))
	var surface := _make_box(label, size, pos, color, collision)
	if size.y < .2:
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return surface

func _surface_height(x: float, z: float) -> float:
	var height := -0.2
	for surface in driving_surfaces:
		if x >= surface.position.x and x <= surface.end.x and z >= surface.position.z and z <= surface.end.z:
			height = maxf(height, surface.end.y)
	return height

func _make_box(label: String, size: Vector3, pos: Vector3, color: Color, collision := false, parent: Node = self) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		body.position = pos
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		parent.add_child(body)
	return mesh_instance

func _material(color: Color, roughness := 0.82, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.1
	return material

func _noise_material(dark_color: Color, light_color: Color, frequency: float, strength: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
	shader_type spatial;
	uniform vec4 dark_color : source_color;
	uniform vec4 light_color : source_color;
	uniform float wet = 0.0;
	uniform float snow_cover = 0.0;
	uniform float frequency = 2.0;
	uniform float strength = 0.1;
	varying vec3 world_position;
	float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
	float noise(vec2 p) {
		vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
		return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
	}
	void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
	void fragment() {
		vec2 p = world_position.xz * frequency;
		float footprint = length(fwidth(p));
		float broad = mix(noise(p), .5, smoothstep(.25, 1., footprint));
		float grain = mix(noise(p * 12.), .5, smoothstep(.25, 1., footprint * 12.));
		ALBEDO = mix(dark_color.rgb, light_color.rgb, clamp(0.5 + (broad - 0.5) * strength * 3.0 + (grain - 0.5) * strength * 0.4, 0.0, 1.0));
		ALBEDO *= 1.0 - wet*.42;
		ALBEDO = mix(ALBEDO,vec3(.73,.81,.85),snow_cover*smoothstep(.15,.68,broad));
		ROUGHNESS = mix(.92,.23,wet);
	}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("dark_color", dark_color)
	material.set_shader_parameter("light_color", light_color)
	material.set_shader_parameter("frequency", frequency)
	material.set_shader_parameter("strength", strength)
	return material
