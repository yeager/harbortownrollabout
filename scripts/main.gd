extends Node3D

const L10n := preload("res://l10n/localization.gd")

const TARGETS: Array[Vector3] = [Vector3(30, 0, 3), Vector3(0, 0, -25), Vector3(99.65, 0, -24)]
const HOSPITAL_INTAKE_STOP := Vector3(128, 0, -55.4)
const HOSPITAL_RECEIVING_POINT := Vector3(130.75, 0, -57.4)
const HOSPITAL_HELIPAD := Vector3(128, 10.42, -68.5)
const WALK_TARGETS: Array[Vector3] = [Vector3(30,0,12), Vector3(6.35,0,-25), Vector3(90,0,-24)]
const TARGET_NAMES := ["Pick up the patient at the square", "Drop off the patient at the hospital", "Deliver first aid to the marina"]
const PATROL_TASKS := ["Check the crossing at the square", "Check the clinic entrance", "Patrol the marina"]
const FIRE_TASKS := ["Test the water hose at the square", "Meet the fire safety team at the clinic", "Check the rescue equipment at the marina"]
const DELIVERY_TASKS := ["Collect parcels at the square", "Deliver a parcel to the clinic", "Deliver the last parcel to the marina"]
const SLED_TASKS := ["Collect warm blankets at the square", "Bring blankets to the clinic", "Bring blankets to the marina"]
func _mission_stop() -> int:
	match vehicle_index:
		1, XC60_POLICE: return [2, 0, 1][mission_index]
		2: return [1, 2, 0][mission_index]
		_: return mission_index

const Mass := preload("res://vehicles/mass.gd")
const Gait := preload("res://characters/walking_gait.gd")
const ROAD_HALF := 4.8
# Inside faces of the continuous perimeter wall, in world X/Z.
const PRACTICE_YARD := Rect2(-130, 89, 64, 40)
const SCHOOL_CAR := 3
const PRACTICE_SPEED_LIMIT := 20
const PRACTICE_SPEED_DISTANCE := 15.0
const PRACTICE_STOP_X := -84.0
const PRACTICE_SIGNAL_X := -73.0
const PRACTICE_STOP_LANE_Z := 109.0
const PRACTICE_START := Vector3(-119, 0, 109)
const CITY_INTERIOR := Rect2(-520, -92, 690, 172)
const VEHICLE_NAMES := ["Ambulance", "Police car", "Fire engine"]
const VEHICLE_SCENES := ["res://vehicles/ambulance.glb", "res://vehicles/polisbil.glb", "res://vehicles/brandbil.glb"]
const VEHICLE_NAMES_ALL := ["Ambulance", "Police car", "Fire engine", "BMV X5i", "Taxi", "Recovery truck", "BMV M3 E33", "Volva 241", "Saav 97", "Teslo Model Z", "City bus", "Snowmobile", "Volva HT-6 police SUV", "Porsje GT5RS", "Ice cream van", "Mino Kuper S", "Pusch Dakotta", "Monster truck", "A-tractor", "Classic cruiser", "Volva L91 wheel loader", "Farm tractor", "Food truck", "Ride-on mower", "Garbage truck", "Shopping trike", "DAM pickup", "Audo Sport Kvattro"]
const VEHICLE_SCENES_ALL := ["res://vehicles/ambulance.glb", "res://vehicles/polisbil.glb", "res://vehicles/brandbil.glb", "res://vehicles/bmw_x5_m60i.glb", "res://vehicles/taxi.glb", "res://vehicles/bargare.glb", "res://vehicles/m3_e30.glb", "res://vehicles/volvo240.glb", "res://vehicles/saab96.glb", "res://vehicles/model_s.glb", "res://vehicles/city_bus.glb", "res://vehicles/snowmobile.glb", "res://vehicles/volvo_xc60_polis.glb", "res://vehicles/porsche_gt3_rs.glb", "res://vehicles/ice_cream_van.tscn", "res://vehicles/mini_cooper_cabriolet.glb", "res://vehicles/puch_dakota.glb", "res://vehicles/monster_truck.glb", "res://vehicles/a_traktor.glb", "res://vehicles/raggarbil.glb", "res://vehicles/volvo_wheel_loader.glb", "res://vehicles/farm_tractor.glb", "res://vehicles/food_truck_road.glb", "res://vehicles/ride_on_mower.glb", "res://vehicles/refuse_truck.glb", "res://vehicles/shopping_trike.glb", "res://vehicles/dam_pickup.glb", "res://vehicles/sport_quattro.glb"]
const SIREN_SOUNDS := ["res://audio/siren_ambulance.wav", "res://audio/siren_police.wav", "res://audio/siren_fire.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/electric_drive.wav", "res://audio/bmw_engine.wav", "res://audio/sled_engine.wav", "res://audio/siren_police.wav", "res://audio/porsche_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/moped_engine.wav", "res://audio/monster_engine.wav", "res://audio/bmw_engine.wav", "res://audio/bmw_engine.wav", "res://audio/loader_diesel.wav", "res://audio/tractor_diesel.wav", "res://audio/bmw_engine.wav", "res://audio/mower_engine.wav", "res://audio/loader_diesel.wav", "res://audio/moped_engine.wav", "res://audio/bmw_engine.wav", "res://audio/quattro_engine.wav"]
const BUILDING_SCENES := {"Polisstationen":"res://environment/polisstation.glb", "Bageriet":"res://environment/bageri.glb", "Vårdcentralen":"res://environment/vardcentral.glb", "Brandstationen":"res://environment/brandstation.glb", "Biblioteket":"res://environment/bibliotek.glb"}
const TREE_SCENES := ["res://environment/lovtrad.glb", "res://environment/gran.glb", "res://environment/bredkronigt_lovtrad.glb"]

var ambulance: Node3D
var trunks := PackedVector3Array() # Centre X, trunk radius, centre Z.
var roadside_solids: Array[AABB] = []
var building_bounds: Array[AABB] = []
var fire_station_shutter: MeshInstance3D
var fire_door_bounds: AABB
var fire_door_index: int
var fire_door_open := 0.0
var canopy_camera_bounds: Array[AABB] = []
var pier_surfaces: Array[AABB] = []
var driving_surfaces: Array[AABB] = []
var reverse_feed: SubViewport
var reverse_camera: Camera3D
var reverse_monitor: Sprite3D
var dash_direction: Label3D
var dash_speed: Label3D
var shopper_boarding := false
var shopper_recovery_requested := false
var wash_jets: Array[CPUParticles3D] = []
var wash_center := Vector3.ZERO
var vehicle_dirt := {}
var muddy_parts: Array[Dictionary] = []
var mud_finish := ShaderMaterial.new()
var vehicle_model: Node3D
var headlights: Array[SpotLight3D] = []
var tractor_beacon: StandardMaterial3D
var projector_finish: StandardMaterial3D
var traffic_running_lenses: Array[StandardMaterial3D] = []
var bus_plate_finish: StandardMaterial3D
var bus_plate_lamp_finish: StandardMaterial3D
var bus_side_marker_finish: StandardMaterial3D
var bus_rear_marker_finish: StandardMaterial3D
var traffic_headlights: Array[SpotLight3D] = []
var quay_finish := ShaderMaterial.new()
var soil_finish: ShaderMaterial
var sidewalk_finish: ShaderMaterial
var marking_finish: ShaderMaterial
var ground_finishes: Array[ShaderMaterial] = []
var road_finish: ShaderMaterial
var apartment_lights: Array[StandardMaterial3D] = []
var quay_stair_light: StandardMaterial3D
var city_env: Environment
var quattro_glazing: ShaderMaterial
var bus_glazing: ShaderMaterial
var quattro_gauge_marks: StandardMaterial3D
var quattro_gauge_needle: StandardMaterial3D
var chimney_beacon: StandardMaterial3D
var chimney_beacon_phase := 0.0
var city_sun: DirectionalLight3D
var city_fill: OmniLight3D
var entrance_lights: Array[SpotLight3D] = []
var station_readouts: Dictionary[Label3D, String] = {}
var meter_backlight: StandardMaterial3D
var fire_sign_face: StandardMaterial3D
var tower_lightbox: StandardMaterial3D
var entrance_diffuser: StandardMaterial3D
var street_lights: Array[SpotLight3D] = []
var lamp_glass: StandardMaterial3D
var weather := preload("res://scripts/city_weather.gd").new()
var previous_season := 0
var greeting_timer := 0.0
var greeting_number := 0
const RADIO_KEYS := [[KEY_J, KEY_B, KEY_X], [KEY_N, KEY_M, KEY_Z]]
const NUMBER_MOVEMENT := {
	KEY_W: [KEY_8, KEY_KP_8],
	KEY_A: [KEY_4, KEY_KP_4],
	KEY_S: [KEY_5, KEY_KP_5],
	KEY_D: [KEY_6, KEY_KP_6],
}
var number_movement := false
var seat_f3 := false
var camera_f6 := false
var pause_f7 := false
var scooter_key := KEY_U
var horn_f4 := false
var quit_key := KEY_F10
var practice_active := false
var practice_speed_distance := 0.0
var practice_stop_complete := false
var practice_stop_missed := false
var practice_signal_lamps: Array
var practice_signal_elapsed := 0.0
var practice_signal_phase := 0
var practice_signal_waited := false
var practice_signal_missed := false
var practice_signal_complete := false
var recovery_key := KEY_R
var jump_key := KEY_E
var look_key := KEY_V
var map_key := KEY_F5
var number_vehicle_switches := false
var number_camera := false
var insert_help := false
var ctrl_run := false
var radio_keys: Array[int] = [KEY_J, KEY_N]
var driving_hints := Label.new()
var driving_footer_margin := MarginContainer.new()
var large_text := false
var extra_reading_time := false
var greeting := Label3D.new()
var bubble_back := Sprite3D.new()
enum FootQuest { WAITING, SEARCHING, RETURNING, FINISHED }
var shoe_quest := FootQuest.WAITING
var shoe_owner: Node3D
var cat_quest := FootQuest.WAITING
var cat_owner: Node3D
var lost_cat := Node3D.new()
var cat_meow := AudioStreamPlayer3D.new()
var cat_hint: Button
var shoe_hint: Button
var shoe_trail := Node3D.new()
var cat_legs: Array[Node3D] = []
var cat_stride := 0.0
var lost_shoe := Node3D.new()
var returned_trainer: Node3D
var socked_foot: MeshInstance3D
var speech_key := ""
var speech_clip := ""
var speech_locale := ""
var bubble_time := 0.0
var greeting_voice := AudioStreamPlayer.new()
var wiper_pivots: Array[Node3D] = []
const SHOPPER_WIPER_SEGMENTS := [
	[Vector2(-.58,1), Vector2(-.09,.65)], # Spindle to blade joint
	[Vector2(.15,.45), Vector2(-.09,.65)], # Lower rubber strip
	[Vector2(-.09,.65), Vector2(-.33,.85)] # Upper rubber strip
]
var shopper_wiper_parts: Array[MeshInstance3D] = []
var wiper_phase := 0.0
var cockpit_look := Vector2.ZERO
var orbit_angle := 0.0
const DRY_STEP := preload("res://audio/footstep.wav")
const SNOW_STEP := preload("res://audio/snow_step.wav")
var footstep := AudioStreamPlayer.new()
var star_chime := AudioStreamPlayer.new()
var walk_camera_height := 0.0
var orbit_height := 0.0
const DAY_CYCLE_SECONDS := 360.0
var time_mode := 2
# Noon is phase zero. Begin on the eastern, rising part of the arc.
var school_hour_hand := Node3D.new()
var school_minute_hand := Node3D.new()
var day_phase := .80
var santa: Node3D
var santa_encounters := {}
var field_fountain := preload("res://environment/field_fountain.gd").new()
var midsummer_pole := preload("res://environment/midsummer_pole.gd").new()
var dax := preload("res://environment/dax_restaurant.gd").new()
var dax_button: Button
var suburban_villas := preload("res://environment/suburban_villas.gd").new()
var christmas_spruce := preload("res://environment/christmas_spruce.gd").new()
var last_night := -1.0
var parked_door_offset := Vector3.ZERO
const Scooter := preload("res://vehicles/kick_scooter.gd")
var scooter := Scooter.new()
var excavator: Node3D
const CrawlerBelt := preload("res://vehicles/crawler_belt.gd")
var crawler_belts: Array[CrawlerBelt] = []
var cab_turntable := Node3D.new()
var boom_joint := Node3D.new()
var stick_joint := Node3D.new()
var excavation_sand := preload("res://environment/excavation_sand.gd").new()
var bucket_joint := Node3D.new()
class LiftCylinder:
	var foot: Node3D
	var head: Node3D
	var barrel: Node3D
	var gland: Node3D
	var rod: Node3D
	var barrel_length: float
	var gland_length: float
	var rod_length: float

	func update_pose() -> void:
		var axis := foot.position.direction_to(foot.get_parent_node_3d().to_local(head.global_position))
		var length := foot.global_position.distance_to(head.global_position)
		var frame := Basis(Vector3.RIGHT,atan2(axis.z,axis.y))
		barrel.transform = Transform3D(frame,foot.position + axis*barrel_length*.5)
		gland.transform = Transform3D(frame,foot.position + axis*(barrel_length + gland_length*.5))
		var rod_start := barrel_length + gland_length*.5
		var visible_length := length - rod_start
		rod.transform = Transform3D(frame.scaled_local(Vector3(1,visible_length/rod_length,1)),foot.position + axis*(rod_start + visible_length*.5))

var boom_lifts: Array[LiftCylinder] = [LiftCylinder.new(), LiftCylinder.new()]
var stick_cylinder := LiftCylinder.new()
var bucket_cylinder := LiftCylinder.new()
var bucket_profile := PackedVector2Array()
const EXTRA_GALLERY_NAMES := ["Volva HT-16 tracked excavator", "Tram", "Motorboat"]
var start_in_excavator := false
var crawler_speed := 0.0
var operating_excavator := false
var excavator_wall := -1
var run_reserve := 60.0
var winded := false
var run_ready_hint_time := 0.0
var walker: Node3D
var parked_cars: Array[Node3D] = []
var parked_footprints: Array[Rect2] = []
var tractor_bare_bounds: AABB
var tractor_plough_bounds: AABB
var parked_sizes: Array[Vector2] = []
var parcel_mounts := PackedVector3Array()
var listener := AudioListener3D.new()
var walking_velocity := Vector3.ZERO
const WALK_JUMP_TIME := .64
var walk_jump_left := 0.0
var bridge_jump_time := 0.0
var bridge_jump_left := 0.0
var walk_basis := Basis.IDENTITY
var crossing_pedestrian: Node3D
var crossing_wait := 4.0
var crossing_direction := 1.0
var entry_marker := Label3D.new()
const BUS := 10
const SNOWMOBILE := 11
const PORSCHE := 13
const ICE_CREAM := 14
const MINI_CABRIO := 15
const PUCH_DAKOTA := 16
const WHEEL_LOADER := 20
const FARM_TRACTOR := 21
const FOOD_TRUCK := 22
const MOWER := 23
const REFUSE := 24
const SHOPPER := 25
const DAM_PICKUP := 26
const QUATTRO := 27
var ground_work := preload("res://environment/ground_work.gd").new(CITY_INTERIOR)
var blade_left: Vector3
var blade_right: Vector3
var ploughs: Array[Node3D] = []
var spreader_particles: CPUParticles3D
var spreader_audio: AudioStreamPlayer3D
var spreader_button: Button
var spreader_enabled := true
const SPREADER_EDGE := Vector3(1.72,0,-3.18)
const DRIVER_VIEW_VEHICLES := [2, 3, PUCH_DAKOTA, FOOD_TRUCK, FARM_TRACTOR, BUS, REFUSE, QUATTRO]
const MopedRider := preload("res://vehicles/moped_rider.gd")
var moped_pose := MopedRider.new()
const ICE_STOPS := [0, SCHOOL, 2]
const XC60_POLICE := 12
const SCHOOL := 3
const SCHOOL_CURB := Vector3(136,0,3)
var school_plough_flags: Array[Label3D] = []
var school_plough_open := false
var meadow_sign: Label3D
const SCHOOL_GATE := Vector3(136,0,7)
const TAXI_STOPS := [0,2, 0,SCHOOL, 1,0, SCHOOL,1, 2,1]
const WEST_STOPS := [Vector3(-205,0,2.8),Vector3(-460,0,-45.2)]
const BUS_DESTINATION := "74  SICKLA UDDE"
const BUS_REGISTRATION := "HBR 074"
const BUS_SIDE_INDICATOR := Vector3(1.275, 1.16, 3.91)
const BUS_STOPS := [0,SCHOOL,2,1,4,5]
const BUS_MESSAGES := ["Collect passengers at the square.", "Drop off passengers at the school.", "Collect passengers at the marina.", "Drop off passengers at the clinic.", "Collect passengers at Västra torget.", "Drop off passengers at Sickla udde."]
const BUS_MERGE_SECONDS := 6.0
var bus_merge_time := 0.0
var bus_departure_pending := false
var bus_departure_lamps: Array[MeshInstance3D] = []
const TurnIndicators := preload("res://scripts/turn_indicators.gd")
var driven_turn_signals: TurnIndicators
var excavator_turn_signals := TurnIndicators.new()
var bus_stop_request: Label3D
var bus_request_arm: Node3D
var bus_press_time := 0.0
var next_bus_stop_board: Label3D
var driver_bus_stop_board: Label3D
var rear_bus_board: Label3D
var side_bus_board: Label3D
var seated_bus_riders: Node3D
var bus_board: Label3D
var bus_ceiling_lights: Array[SpotLight3D] = []
var bus_ceiling_diffuser: StandardMaterial3D
var bus_dashboard_backlight: StandardMaterial3D
const BUS_STOP_NAMES := ["THE SQUARE","HEALTH CENTRE","MARINA","HARBOR TOWN SCHOOL","VÄSTRA TORGET","SICKLA UDDE"]
var bus_leg := 0
const TAXI := 4
const HORNS := ["ambulance","police","fire","bmw","taxi","recovery", "m3_e30", "volvo240", "saab96", "model_s", "city_bus","snowmobile", "police", "porsche", "icecream", "bmw", "saab96", "bmw", "volvo240", "bmw", "recovery", "recovery", "bmw", "saab96", "recovery", "saab96", "bmw", "m3_e30"]
var horn := AudioStreamPlayer.new()
var next_song_button: Button
var radio_button: Button
var radio := AudioStreamPlayer.new()
var radio_enabled := false
var restoring_radio := false
var radio_vehicle := ""
var radio_language := ""
var radio_tracks := PackedStringArray()
var radio_bag: Array[String] = []
var radio_track := ""
var song_card := PanelContainer.new()
var song_cover := TextureRect.new()
var song_title := Label.new()
var song_card_seconds := 0.0
var horn_button: Button
const RECOVERY := 5
const STATION_DROP := Vector3(-121,0,12)
const STATION_PARKING := Vector3(-120,0,20)
var tyre_service_button: Button
const FIXED_TYRE_VEHICLES := [SNOWMOBILE, PUCH_DAKOTA, FARM_TRACTOR, WHEEL_LOADER, MOWER, SHOPPER]
var winter_tyre_models := PackedStringArray()
const SERVICE_STOPS := [Vector3(18,0,2.35), STATION_DROP, Vector3(126,0,-2.35), STATION_DROP]
const SERVICE_MESSAGES := ["Collect the car with a smoking bonnet.","Take the car to the petrol station.","Collect the car with a missing wheel.","Take the car to the petrol station."]
var recovery_leg := 0
enum FlourStage { AT_SQUARE, ON_TRUCK, AT_BAKERY }
var flour_stage := FlourStage.AT_SQUARE
enum CrateStage { AT_KIOSK, IN_VAN, AT_DEPOT }
var crate_stage := CrateStage.AT_KIOSK
var ice_crates := Node3D.new()
const CRATE_PICKUP := "Stop outside the ice cream kiosk to collect the empty crates."
const CRATE_RETURN := "Drive west along Stationsallén. Park by the blue “Ice cream depot” sign."
const CRATE_DONE := "The ice cream depot received both empty crates."
var flour_sacks := Node3D.new()
const FLOUR_CURB := Vector3(-15,0,-3)
const FLOUR_PICKUP := "Stop the flatbed at the square in the morning to collect flour."
const FLOUR_ROUTE := "Drive to the bakery. Look for the coffee cup above the door. Drop off the flour there."
const WORKSHOP_CAR_BOUNDS := AABB(STATION_PARKING - Vector3(2.1,1,.86),Vector3(4.2,3,1.72))
var workshop_wheel: Node3D
var wheel_rest: Vector3
var workshop_smoke: CPUParticles3D
var workshop_tool := Node3D.new()
var repair_tween: Tween
var workshop_car: Node3D
var casualty: Node3D
var hazard_lenses: Array[MeshInstance3D] = []
var hazard_amber: StandardMaterial3D
var hazard_phase := 0.0
var warning_triangle := Node3D.new()
var loose_wheel: Node3D
var lost_wheel: Node3D
var bonnet_smoke := CPUParticles3D.new()
var taxi_leg := 0
var blanket_rolls: Array[Node3D] = []
var ice_order := PanelContainer.new()
var requested_ice := TextureRect.new()
var flavour_choices := GridContainer.new()
var ice_flavours: Array[AtlasTexture] = []
var grocery_bags: Array[Node3D] = []
const PARCEL_MASS_KG := [32.0, 9.0]
const PARCEL_SPACING := .50
const PARCEL_VEHICLES := [3,6,7,8,9,PORSCHE,MINI_CABRIO,DAM_PICKUP]
var carried_parcel_leg := -1
var delivery_parcels: Array[Node3D] = []
var clinic_fire_team: Array[Node3D] = []
var bus_companions: Array[Node3D] = []
var arriving_passenger: Node3D
var passenger: Node3D
var seat_button: Button
var vehicle_index := 0
var renderer_choices := GridContainer.new()
var game_volume_slider := HSlider.new()
var traffic_volume_slider := HSlider.new()
const GALLERY_GROUPS := {
	"All vehicles": [],
	"Emergency vehicles": ["Ambulance", "Police car", "Volva HT-6 police SUV", "Fire engine"],
	"Work vehicles": ["Farm tractor", "Garbage truck", "Recovery truck", "Volva L91 wheel loader", "Volva HT-16 tracked excavator", "Ride-on mower", "Ice cream van", "Food truck", "DAM pickup"],
	"Cars": ["BMV X5i", "BMV M3 E33", "Volva 241", "Saav 97", "Teslo Model Z", "Porsje GT5RS", "Mino Kuper S", "Classic cruiser", "A-tractor", "Audo Sport Kvattro"],
	"Passenger transport": ["City bus", "Tram", "Taxi"],
	"Leisure vehicles": ["Monster truck", "Pusch Dakotta", "Snowmobile", "Shopping trike", "Motorboat"]
}
var category_tabs := HBoxContainer.new()
var favorites := PackedStringArray()
var gallery_category := "All vehicles"
var vehicle_selector := GridContainer.new()
var camera_turn := 0.0
var excavator_work_view := false
var cockpit_view := false
var camera_button: Button
var camera: Camera3D
var long_view_distance := false
var streetlamp_shadows := true
var shadow_streetlamps: Array[SpotLight3D] = []
var navigator := preload("res://scripts/street_route.gd").new()
var turn_preview := Label.new()
var route_arrows: Array[Node3D] = []
var route_timer := 0.0
var medical_bag := Node3D.new()
var passenger_wave_time := 0.0
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
var moped_speed_needle: Node3D
var quattro_speed_needle: Node3D
var player_wheels: Array[Node3D] = []
var player_brake_lens: StandardMaterial3D
var driving_controls := preload("res://scripts/driving_controls.gd").new()
var release_pedal_keys := false
var mouse_steering := 0.0
var mouse_gas := false
var mouse_brake := false
var brake_pedal_held := false
var gentle_driving := true
var allow_crashes := true
var show_turn_street := false
var allow_red_lights := false
var slowing_for_amber := false
var waiting_for_signal := false
var waiting_for_clear_crossing := false
var brake_held := false
var tire_player := AudioStreamPlayer.new()
var skid_marks := MultiMesh.new()
var skid_cursor := 0
var snow_marks := MultiMesh.new()
var sole_marks := MultiMesh.new()
var sole_cursor := 0
var sole_finish := ShaderMaterial.new()
var snow_cursor := 0
var asphalt_track_finish := ShaderMaterial.new()
var snow_track_finish := ShaderMaterial.new()
var rear_tire_contacts := PackedVector3Array()
var skid_anchors := PackedVector3Array()
const SKID_CAPACITY := 2048
var speed := 0.0
var steering := 0.0
var snow_slip_angle := 0.0
var map_goal := Vector3.INF
var map_button := Button.new()
var leave_practice_button := Button.new()
const FOUNTAIN_APPROACH := Vector3(41,0,39.5)
const MAP_STOREFRONTS := ["Pizzeria","Sweet shop","Momo & Bori","Toy Harbour"]
const MAP_NAMES := ["Town square","Clinic","Marina","School","Fuel and tyre service","Hot dog stand","Bakery","Boule court","Pizzeria","Sweet shop","Momo & Bori","Fountain","Motorboat","Toy Harbour","Villa district","Dax"]
var free_drive := true
var mission_index := 0
const FireLocker := preload("res://scripts/fire_locker.gd")
var driven_fire_locker: FireLocker
var parked_fire_locker: FireLocker
const FIRE_RETURN_BAY := Vector3(-37,-.13,15)
var fire_bay_button: Button
var practice_hose := Node3D.new()
var practice_spray := CPUParticles3D.new()
var hose_seconds := 0.0
var refuse_pump := AudioStreamPlayer3D.new()
var refuse_beacon: StandardMaterial3D
var refuse_lift: Tween
var curb_bay := Node3D.new()
var refuse_bins: Array[Node3D] = []
var vehicle_progress := {}

func _change_mission_vehicle(next: int) -> void:
	if next != vehicle_index:
		parked_at_target = 0.0
		message_timer = 0.0
	vehicle_progress[vehicle_index] = mission_index
	vehicle_index = next
	mission_index = vehicle_progress.get(next, 0)

func _vehicle_tasks() -> Array:
	match vehicle_index:
		0: return TARGET_NAMES
		1, XC60_POLICE: return PATROL_TASKS
		2: return FIRE_TASKS
		FARM_TRACTOR: return ["Collect seedlings at the square", "Deliver herbs to the clinic garden", "Bring flowers to the marina"]
		SHOPPER: return ["Pick up groceries at the square", "Deliver groceries to the clinic", "Deliver groceries to the marina"]
		REFUSE: return ["Empty the blue paper bin at the square", "Empty the green glass bin at the clinic", "Unload recycling at the marina"]
		FOOD_TRUCK: return ["Pick up soup ingredients at the square", "Serve lunch to the clinic staff", "Serve soup to the boat crews"]
		SNOWMOBILE: return SLED_TASKS
		ICE_CREAM: return ["Serve ice cream at the square", "Serve ice cream outside the school", "Serve ice cream at the marina"]
		_: return DELIVERY_TASKS

var quit_dialog := ConfirmationDialog.new()
var parked_at_target := 0.0
var mode := "menu"
var paused := false:
	set(value):
		paused = value
		if weather.is_node_ready():
			weather.rain_particles.speed_scale = 0.0 if value else 1.0
			weather.snow_particles.speed_scale = weather.rain_particles.speed_scale
var lights_on := false
var parked_light_settings: Array[bool] = []
var sound_on := true
var parked_sound_settings: Array[bool] = []
var siren_player: AudioStreamPlayer
var menu_footer := HBoxContainer.new()
var version_label := Label.new()
var ui: CanvasLayer
var wardrobe := preload("res://characters/weather_clothing.gd").new()
var jacket_palette := -1
var at_colour_bench := false
const BENCH_COLOURS := [Color("#905bb9"), Color("#f1ab38"), Color("#399d83")]
var play_as_alma := false
var separate_profiles := false
const STAR_SITES := {
	"main_street": Vector2(-7, 2.35), "park": Vector2(49, 2.35),
	"west_avenue": Vector2(-205, 2.35), "north_bridge": Vector2(71, -45.65),
	"south_bridge": Vector2(71, 2.35), "canal": Vector2(71, 42),
	"east_street": Vector2(104.35, 32), "work_yard": Vector2(-113, 45)
}
const POINTS_PER_STAR := 10
const POINTS_PER_FOOT_QUEST := 10
var foot_quest_points := 0
var delivery_points := 0
var collected_stars := PackedStringArray()
var star_markers := {}
var wallet := 0
const MEMORY_SHEETS := {
	"vehicle": preload("res://branding/vehicle-job-actions.svg"),
	"foot": preload("res://branding/foot-job-actions.svg"),
}
var mission_memories := PackedStringArray()
var reward_badge := Button.new()
var reward_seconds := 0.0
var wallet_label: Label
var shops := preload("res://scripts/shop_street.gd").new()
var boutique_jacket := ""
var purchases := {}
var happy_seconds := 0.0
var phone := preload("res://scripts/mission_phone.gd").new()
var last_dispatch := ""
var mission_label: Label
const HELP_DURATION := 0.8
var arrival_progress := ProgressBar.new()
var status_label: Label
var overlay: ColorRect
var overlay_panel: PanelContainer
var brand_logo := TextureRect.new()
var title_label: Label
var pause_action_picture := TextureRect.new()
var subtitle_label: Label
var road_checkpoint := {}
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
const SETTINGS_PATH := L10n.SETTINGS_PATH
var language_preference := ""
var radio_track_gain_db := -10.0
var radio_ducking := 100.0
const MIX_CHANNELS := ["Speech", "Radio", "Engines"]
var traffic_siren_volume := 100.0
var traffic_light_mode := 0
var calm_mode := false
var steady_player_lights := false
var emergency_traffic: Array[Dictionary] = []
var moorings: Array[Dictionary] = []
var street_signals := preload("res://scripts/street_signals.gd").new()
var tram := preload("res://scripts/tram.gd").new()
var boating := false
var shopper_grip_points: Array[Vector3] = []
var grip_radius := 0.0
var road_driver: Node3D
var skipper: Node3D
const LAUNCH_BERTH := Vector3(79,-.94,46)
const LAUNCH_LANDING := Vector2(80.9,46)
const LAUNCH_PIER := Rect2(80.5,44.75,7.2,2.5)
const LAUNCH_MAP_STOP := Vector3(LAUNCH_LANDING.x,0,LAUNCH_LANDING.y)
const LAUNCH_ROAD_STOP := Vector3(95.6,-.04,LAUNCH_LANDING.y)
var launch: Node3D
var navigation_lenses: Array[StandardMaterial3D] = []
var outboard: Node3D
var launch_speed := 0.0
var helicopter: Node3D
var medical_helicopter := preload("res://scripts/medical_helicopter.gd").new()
var main_rotor: Node3D
var tail_rotor: Node3D
var patrol_angle := 0.0
var passenger_look := Vector2.ZERO
var tram_mode := 0
var tram_driver_exit_requested := false
var water_finish := ShaderMaterial.new()
var saloon_glazing: StandardMaterial3D
const EAST_QUAY_WATER_EDGE := 86.75
const FLOATING_DOCK_ACCESS_Z := -10.5
const MOORING_BUOY_OFFSET := 7.5
const MOORING_START_Z := -38.0
const MOORING_SPACING := 4.5
const MOORING_COUNT := 7
const MOORING_BUOY_Z_OFFSET := .35
const MOORING_BUOY_RADIUS := .14
const MOORING_BUOY_HEIGHT := .89
const FERRY_LANDINGS := [-72.0, -12.0]
const CANAL_BOUNDS := Rect2(55,-93,32,174)
const HIGH_BRIDGE_X := [51.5, 65.0, 78.0, 98.0]
const HIGH_BRIDGE_RISE := 5.85
const SOUTH_BRIDGE_RISE := 3.0
const LAUNCH_CHANNEL := Rect2(58.0, -88.0, 26.0, 162.0)
var bridge_pier_footprints: Array[Rect2] = []
var ferry_boarding_lamps: Array[MeshInstance3D] = []
var ferry_boarding_chime := AudioStreamPlayer3D.new()
var ferry_displays: Array[Label3D] = []
var ferry_display_second := -1
var ferry_display_locale := ""
var ferry_passenger := false
var ferry_exit_requested := false
var ferry: Node3D
var ferry_hull_bounds: AABB
var ferry_engine := AudioStreamPlayer3D.new()
var wave_time := 0.0
var ferry_delay := 0.0
var ferry_speed_factor := 1.0
const PET_REQUESTS := ["Find the dog’s blue ball on the pavement.", "Lay the lizard’s picnic mat by the square bench."]
var pet_stages := PackedInt32Array([0,0])
var shepherd: Node3D
var dog_ball := MeshInstance3D.new()
var lizard_mat := Node3D.new()
var komodo: Node3D
var chat_pair: Array[Node3D] = []
var chat_topic := 0
var chat_reply := false
var chat_wait := 0.0
const SMALL_TALK := [
	["Did you feel a raindrop?", "chat_rain", "My boots vote for puddles!", "chat_puddle"],
	["Which ice cream would you pick?", "chat_ice", "Blueberry, with a cherry on top!", "chat_flavour"],
	["Can AI dream?", "chat_ai", "Maybe it dreams of electric sheep!", "chat_dream"],
	["What did the dog find?", "chat_dog", "A leaf worth a really good sniff!", "chat_sniff"],
]
var boule_join_requested := false
const BOULE_BENCH := BOULE_CENTRE + Vector3(3.3,-.20,0)
const BOULE_BENCH_APPROACH := BOULE_BENCH + Vector3.LEFT*.85
var boule_seated := false
const THERMOS_REQUEST := "I lost my green flask after the boule match. Could you check by the bench?"
const THERMOS_RETURN := "Bring the flask back to the boule player in the green jacket."
const UMBRELLA_RETURN := "Bring the umbrella to the passenger in the yellow jacket at Lotten’s landing."
var umbrella_stage := FootQuest.WAITING
const FIGURINE_RETURN := "Bring the moon rabbit to the clothing shop counter."
const FIGURINE_THANKS := "Thank you! Our moon rabbit is back!"
var figurine_stage := FootQuest.WAITING
var lost_figurine: Node3D
const COURIER_REQUEST := "I mixed up two parcels. Can you fetch the striped one from the grocery store?"
const COURIER_RETURN := "Bring the striped parcel back to the cyclist outside the café."
var courier_stage := FootQuest.WAITING
var courier := Node3D.new()
var courier_parcel := Node3D.new()
var boutique_owner: Node3D
const CAKE_ROUTE := "Bring the cake to the birthday table at the square."
var cake_stage := FootQuest.WAITING
var cake_box := Node3D.new()
var cake_lid := Node3D.new()
var birthday_host: Node3D

var umbrella_owner: Node3D
var umbrella := Node3D.new()
var canopy := Node3D.new()
var thermos_stage := FootQuest.WAITING
var boule_match_finished := false
var thermos := Node3D.new()
var boule_guest_turn := false
var boule_choices := VBoxContainer.new()
var boule_aim := HSlider.new()
var boule_throw_buttons := HBoxContainer.new()
var boule_throw_length := -1
var boule_pause_focus: Control
const BOULE_CENTRE := Vector3(94.9, 0, 69)
var boule_players: Array[Node3D] = []
var boules: Array[MeshInstance3D] = []
var boule_jack: MeshInstance3D
var boule_result_rings: Array[MeshInstance3D] = []
var boule_turn := 0
var boule_clock := 0.0
var boule_impact := AudioStreamPlayer3D.new()
var boule_velocity: Array[Vector3] = []
var boule_grounded: Array[bool] = []
var boule_clink := AudioStreamPlayer3D.new()
var boule_collector := -1
var boule_pickup_spot := Vector3.ZERO
var quay_windsock := Node3D.new()
var boule_release := Vector3.ZERO
var walker_data: Array[Dictionary] = []

func _reset_parked_controls() -> void:
	parked_light_settings.resize(VEHICLE_SCENES_ALL.size())
	parked_sound_settings.resize(VEHICLE_SCENES_ALL.size())
	parked_light_settings.fill(false)
	for i in parked_sound_settings.size():
		parked_sound_settings[i] = i >= 3

func _ready() -> void:
	L10n.load_catalogs()
	greeting_voice.bus = &"Speech"
	greeting_voice.volume_db = -4
	add_child(greeting_voice)
	star_chime.stream = preload("res://audio/star_pickup.wav")
	star_chime.volume_db = -9
	add_child(star_chime)
	footstep.stream = DRY_STEP
	footstep.volume_db = -13
	add_child(footstep)
	_reset_parked_controls()
	_recover_unsupported_dlss_setting()
	if RenderingServer.get_current_rendering_method()=="forward_plus" and "--fsr2" in OS.get_cmdline_user_args():
		get_viewport().scaling_3d_mode=Viewport.SCALING_3D_MODE_FSR2
		get_viewport().scaling_3d_scale=.75
		get_viewport().msaa_3d=Viewport.MSAA_DISABLED
	_load_preferences()
	add_child(weather)
	wardrobe.update(weather.season, weather.intensity)
	_build_world()
	ground_finishes.append_array([road_finish, marking_finish, sidewalk_finish, soil_finish, quay_finish])
	for ground_material in ground_finishes:
		ground_work.attach(ground_material)
	soil_finish.set_shader_parameter("is_grass",true)
	_build_stars()
	_build_ui()
	var dialog_theme := Theme.new()
	dialog_theme.set_constant("buttons_min_width","AcceptDialog",120)
	dialog_theme.set_constant("buttons_min_height","AcceptDialog",48)
	quit_dialog.theme = dialog_theme
	quit_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_dialog.exclusive = true
	add_child(quit_dialog)
	_color_action(quit_dialog.get_ok_button(), true)
	_color_action(quit_dialog.get_cancel_button(), false)
	quit_dialog.confirmed.connect(_finish_quit)
	quit_dialog.canceled.connect(func():
		get_tree().paused = false
		if paused:
			radio.stream_paused = true
			greeting_voice.stream_paused = true
	)
	_build_brake_effects()
	_update_mission_marker()
	_refresh_ui()
	start_button.grab_focus()
	if get_tree().get_root().has_meta("dlss_lab_autostart"):
		var lab_config: Dictionary = get_tree().get_root().get_meta("dlss_lab_autostart")
		_set_vehicle_and_activity_for_dlss_lab(lab_config)
	if "--check-startup" in OS.get_cmdline_user_args():
		_finish_startup_check.call_deferred()

func _finish_startup_check() -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	print("Harbortown main menu ready.")
	_finish_quit(false)

func _set_vehicle_and_activity_for_dlss_lab(lab_config: Dictionary) -> void:
	var selected_vehicle := clampi(int(lab_config.get("vehicle_index", 1)), 0, VEHICLE_NAMES_ALL.size() - 1)
	if selected_vehicle != vehicle_index:
		vehicle_index = selected_vehicle
		_load_vehicle_model()
	_mark_selected_vehicle(vehicle_index)
	free_drive = true
	_start_game()

func _engine_supports_dlss_mode() -> bool:
	return ClassDB.class_get_integer_constant_list("Viewport", true).has("SCALING_3D_MODE_DLSS")

func _active_renderer_reports_dlss() -> bool:
	if not ClassDB.class_has_method("RenderingServer", "is_dlss_supported"):
		return false
	return bool(RenderingServer.call("is_dlss_supported"))

func _recover_unsupported_dlss_setting() -> void:
	if _engine_supports_dlss_mode() and _active_renderer_reports_dlss():
		return
	var graphics := ConfigFile.new()
	if graphics.load("user://graphics.cfg") != OK:
		return
	if int(graphics.get_value("rendering", "scaling_3d/mode", 0)) != 5:
		return
	# A user may switch back to stock Godot after selecting DLSS in the custom fork.
	# Clear the fork-only value so the stock renderer never keeps an unknown mode.
	graphics.set_value("rendering", "scaling_3d/mode", 0)
	graphics.set_value("rendering", "scaling_3d/scale", 1.0)
	graphics.set_value("rendering", "anti_aliasing/quality/msaa_3d", 2)
	graphics.save("user://graphics.cfg")
	get_viewport().set("scaling_3d_mode", 0)
	get_viewport().scaling_3d_scale = 1.0
	push_warning("Saved DLSS setting is unsupported by this Godot build or active video adapter; restored standard Forward+ scaling.")

func _process(delta: float) -> void:
	medical_helicopter.set_audio_active(mode == "playing" and not paused)
	if reward_badge.visible and reward_seconds > 0:
		reward_seconds = maxf(0,reward_seconds-delta)
		if reward_seconds == 0 or mode == "menu": reward_badge.hide()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _world_controls_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not paused or not practice_hose.visible:
		var hose_out := vehicle_index == 2 and practice_hose.visible
		if is_instance_valid(driven_fire_locker):
			driven_fire_locker.advance(delta,hose_out,not walker.visible and speed < -.01)
			driven_fire_locker.set_road_speed(speed)
		parked_fire_locker.advance(delta,hose_out and walker.visible)
	if mode == "playing" and not paused:
		if happy_seconds > 0:
			happy_seconds = maxf(0, happy_seconds-delta)
			if happy_seconds == 0: _refresh_ui()
		phone.advance(delta)
		if song_card.visible:
			song_card_seconds -= delta
			if song_card_seconds <= 0: song_card.hide()
		weather.tick(delta)
		_advance_wipers(delta)
		if warning_triangle.is_visible_in_tree():
			hazard_phase = fmod(hazard_phase + delta, 1.0)
			_update_hazard_lights()
	wardrobe.update(weather.season, weather.intensity)
	ground_work.update(delta, weather.snow)
	_update_school_plough()
	_update_meadow_sign()
	if previous_season != weather.season:
		for winter_attachment in ploughs:
			winter_attachment.visible = weather.season == 4
		_set_spreader_active(false)
		_update_tractor_footprint()
		previous_season = weather.season
		for finish in foliage_finishes:
			var tint: Color = finish.albedo_color
			if not finish.resource_name.begins_with("Spruce"):
				match weather.season:
					1: tint = tint.lerp(Color("#9ab959"),.35)
					3: tint = tint.lerp(Color("#bd742e"),.72)
					4: tint = tint.lerp(Color("#acb2a8"),.78)
			foliage_finishes[finish].set_shader_parameter("leaf_color", tint)
	for surface in ground_finishes:
		surface.set_shader_parameter("wet",weather.wet)
		surface.set_shader_parameter("snow_cover",weather.snow)
	asphalt_track_finish.set_shader_parameter("snow_opacity", 1.0 - smoothstep(.05,.7,weather.snow))
	snow_track_finish.set_shader_parameter("snow_opacity", smoothstep(.01,.25,weather.snow))
	sole_finish.set_shader_parameter("snow_opacity", smoothstep(.05,.35,weather.snow))
	if weather.snow <= .01 and sole_marks.visible_instance_count > 0:
		sole_marks.visible_instance_count = 0
		sole_cursor = 0
	if weather.snow <= .01 and snow_marks.visible_instance_count > 0:
		snow_marks.visible_instance_count = 0
		snow_cursor = 0
	water_finish.set_shader_parameter("rain",weather.intensity.x)
	city_env.sky.sky_material.set_shader_parameter("overcast",weather.cloud_cover)
	quattro_glazing.set_shader_parameter("overcast",weather.cloud_cover)
	if bus_glazing: bus_glazing.set_shader_parameter("overcast",weather.cloud_cover)
	_update_daylight(delta)
	if radio.playing:
		var target_gain := _radio_target_gain()
		var rate := 480.0 if radio.volume_db > target_gain else 16.0
		radio.volume_db = move_toward(radio.volume_db,target_gain,rate*delta)
	var traffic_bus := AudioServer.get_bus_index("Traffic and radio")
	var traffic_gain := AudioServer.get_bus_volume_db(traffic_bus)
	var traffic_target := _traffic_target_gain()
	if not is_equal_approx(traffic_gain, traffic_target):
		var rate := 480.0 if traffic_gain > traffic_target else 18.0
		AudioServer.set_bus_volume_db(traffic_bus, move_toward(traffic_gain, traffic_target, rate*delta))
	if not paused and message_timer > 0.0:
		message_timer = maxf(0.0, message_timer - delta)
	if mode == "playing" and not paused:
		var star_actor := _player_actor()
		var before := star_actor.global_position
		_update_patrol(delta)
		street_signals.advance(delta)
		shops.advance_grill_sign(delta, calm_mode)
		_update_fire_station_door(delta)
		var tram_controls := tram_mode == 2 and _world_controls_available()
		var tram_keys := tram_controls and _keyboard_pedals_available()
		var tram_gas := tram_controls and (mouse_gas or (tram_keys and (Input.is_action_pressed("ui_up") or _movement_pressed(KEY_W))))
		var tram_brake := tram_controls and (mouse_brake or brake_pedal_held or (tram_keys and (Input.is_action_pressed("ui_down") or _movement_pressed(KEY_S))))
		tram.advance(delta, tram_mode == 2, tram_gas, tram_brake)
		if tram_mode == 2 and tram_driver_exit_requested and tram.open_station() >= 0:
			_change_seat()
		if tram_mode != 0: _update_entry_button()
		if tram_mode == 2:
			driving_controls.set_controls(0,tram_gas and not tram_brake,tram_brake)
		if walker.visible or operating_excavator or boating or tram_mode > 0 or ferry_passenger:
			_set_spreader_active(false)
		if operating_excavator:
			_drive_excavator(delta)
		elif boating:
			_drive_launch(delta)
			var can_step_ashore := _launch_at_berth()
			if seat_button.visible != can_step_ashore:
				seat_button.visible = can_step_ashore
				if can_step_ashore:
					_update_entry_button()
		elif tram_mode > 0 or ferry_passenger:
			_end_skid()
		elif walker.visible:
			_walk(delta)
		else:
			_drive(delta)
		_collect_stars(before, star_actor.global_position)
		if vehicle_index == BUS and not free_drive and bus_leg % 2 == 1:
			_update_bus_stop_request(delta)
		_update_flour_delivery()
		_update_crate_return()
		_update_arrival(delta)
		route_timer -= delta
		if route_timer<=0:
			_update_route_arrows()
			route_timer=.3
		_update_traffic(delta)
		_update_pedestrians(delta)
		_update_moorings(delta)
		if not boating and not operating_excavator and vehicle_index >= 3 and vehicle_index != XC60_POLICE and siren_player.playing:
			var pitch_speed := 12.0 if vehicle_index in [FARM_TRACTOR, WHEEL_LOADER] else 8.33 if vehicle_index == PUCH_DAKOTA else 32.0 if vehicle_index == SNOWMOBILE else 250.0 / 3.6
			if vehicle_index == QUATTRO: pitch_speed = 29.0
			siren_player.pitch_scale = 0.88 + clampf(absf(speed) / pitch_speed, 0.0, 1.0) * 0.72
	else:
		_set_spreader_active(false)
		ferry_engine.stop()
		_end_skid()
	_update_traffic_signals(delta)
	if lights_on and not (calm_mode or steady_player_lights) and mode == "playing" and not paused:
		light_phase += delta * 3.2
		_update_emergency_lights()
	var entrance_target := -1
	if mode == "playing" and not paused and walker.visible and tram_mode == 0 and not ferry_passenger and not boating and not phone.handset.is_visible_in_tree():
		if free_drive and map_goal == shops.grill_counter(): entrance_target = 6
		elif free_drive and map_goal == shops.pizzeria_entrance(): entrance_target = 2
		elif courier_stage == FootQuest.SEARCHING and absf(walker.position.x-shops.storefront_x(4)) < 6.6: entrance_target = 4
		elif figurine_stage == FootQuest.RETURNING: entrance_target = 5
	shops.update_entrance_picture(entrance_target,walker.position)
	shops.update_customer(walker.visible and not ferry_passenger and not boating and tram_mode==0,walker.position,mode=="playing" and not paused)
	weather.visible = not shops.customer_is_indoors() and tram_mode != 1
	_update_camera(delta)
	weather.position = camera.position + Vector3.UP*8
	_refresh_status()

func _save_checkpoint() -> void:
	if mode == "complete":
		road_checkpoint.clear()
		_save_preferences()
		return
	if mode == "playing":
		road_checkpoint.clear()
		road_checkpoint = {
			"vehicle": vehicle_index, "position": ambulance.global_position, "practice": practice_active,
			"heading": ambulance.rotation.y, "mission": mission_index,
			"sand": Vector2i(excavation_sand.remaining, excavation_sand.delivered),
			"recovery": recovery_leg, "taxi": taxi_leg, "bus": bus_leg,
			"free_drive": free_drive, "progress": vehicle_progress.duplicate()
		}
		if not radio_vehicle.is_empty():
			road_checkpoint["radio"] = {
				"enabled": radio_enabled, "track": radio_track,
				"position": radio.get_playback_position() if radio.playing else 0.0,
				"remaining": PackedStringArray(radio_bag)
			}
		if vehicle_index == 2 and mission_index == 2 and practice_hose.visible:
			road_checkpoint["hose_seconds"] = hose_seconds
		if vehicle_index == BUS and not free_drive and bus_leg % 2 == 1 and bus_stop_request.visible:
			road_checkpoint["bus_stop_requested"] = true
		if vehicle_index == BUS and not free_drive and not walker.visible and bus_departure_pending:
			road_checkpoint["bus_departure_pending"] = true
		if cockpit_view and not walker.visible and vehicle_index in DRIVER_VIEW_VEHICLES and not boating and tram_mode == 0 and not operating_excavator:
			road_checkpoint["cockpit_view"] = true
		if practice_active and vehicle_index == SCHOOL_CAR:
			road_checkpoint["lesson"] = {
				"speed_distance": minf(practice_speed_distance,PRACTICE_SPEED_DISTANCE),
				"stop_complete": practice_stop_complete,
				"signal_complete": practice_signal_complete,
			}
		if free_drive and map_goal.is_finite():
			road_checkpoint["map_goal"] = map_goal
		if tram_mode != 0:
			road_checkpoint["tram"] = {
				"mode": tram_mode, "distance": tram.distance, "next_stop": tram.next_stop,
				"dwell": tram.dwell, "velocity": tram.velocity, "parked": not ambulance.visible,
				"driver_exit_requested": tram_driver_exit_requested
			}
		elif operating_excavator:
			road_checkpoint["excavator"] = {
				"base": excavator.transform, "slew": cab_turntable.rotation.y,
				"arm": Vector3(boom_joint.rotation.x, stick_joint.rotation.x, bucket_joint.rotation.x)
			}
		elif boating:
			road_checkpoint["launch_transform"] = launch.transform
		elif walker.visible:
			road_checkpoint["carried_parcel_leg"] = carried_parcel_leg
			road_checkpoint["walk_position"] = walker.position
			road_checkpoint["walk_heading"] = walker.rotation.y
			road_checkpoint["door_offset"] = parked_door_offset
			road_checkpoint["scooter"] = scooter.visible
			if boule_seated:
				road_checkpoint["boule_bench"] = true
			if ferry_passenger:
				road_checkpoint["ferry_time"] = _ferry_clock()
				road_checkpoint["exit_at_landing"] = ferry_exit_requested
		road_checkpoint["quests"] = {
			"shoe": shoe_quest, "cat": cat_quest, "shoe_owner": shoe_owner.position,
			"cat_owner": cat_owner.position, "lost_cat": lost_cat.position,
			"pets": pet_stages.duplicate(), "komodo_present": komodo.visible
		}
		_save_preferences()

func _finish_quit(save_checkpoint := true) -> void:
	if save_checkpoint:
		_save_checkpoint()
	var tree := get_tree()
	# Release the game's audio players before the audio server shuts down.
	for player in find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
	for player in find_children("*", "AudioStreamPlayer3D", true, false):
		player.stop()
	tree.create_timer(maxf(.4, AudioServer.get_output_latency() + AudioServer.get_time_to_next_mix())).timeout.connect(tree.quit)
	queue_free()

func _dialog_quit_key(event: InputEvent, dialog: Window) -> void:
	if event is InputEventKey and event.keycode == quit_key and event.pressed and not event.echo and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
		dialog.set_input_as_handled()
		_request_quit(dialog)

func _request_quit(parent_window: Window = null) -> void:
	if quit_dialog.visible: return
	var host: Node = parent_window if parent_window else self
	if quit_dialog.get_parent() != host:
		quit_dialog.reparent(host, false)
	_release_mouse_pedals()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit_dialog.title = tr("Quit game")
	quit_dialog.dialog_text = tr("Do you want to quit the game?")
	quit_dialog.ok_button_text = tr("Yes")
	quit_dialog.cancel_button_text = tr("No")
	get_tree().paused = true
	quit_dialog.popup_centered()
	quit_dialog.get_cancel_button().grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == quit_key and event.pressed and not event.echo and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
		get_viewport().set_input_as_handled()
		_request_quit()
		return
	if event is InputEventKey and event.keycode == look_key and not event.echo:
		if not event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif _world_controls_available() and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and (mouse_gas or mouse_brake or brake_pedal_held) and tram_mode == 0 and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _world_controls_available():
		mouse_steering = clampf(mouse_steering + event.screen_relative.x / 150.0, -1.0, 1.0)
		return
	if event is InputEventMouseMotion and _world_controls_available() and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		if tram_mode == 1:
			passenger_look.x = wrapf(passenger_look.x - event.relative.x * .007, -PI, PI)
			passenger_look.y = clampf(passenger_look.y - event.relative.y * .006, -1.1, 1.1)
			return
		if cockpit_view and not walker.visible and not boating and tram_mode==0:
			cockpit_look.x = clampf(cockpit_look.x-event.relative.x*.007,-1.4,1.4)
			cockpit_look.y = clampf(cockpit_look.y-event.relative.y*.006,-.45,.52)
			return
		if walker.visible and tram_mode == 0 and not (boating or ferry_passenger or operating_excavator):
			walk_camera_height = clampf(walk_camera_height + event.relative.y*.022,-1.5,3.5)
			return
		orbit_angle -= event.relative.x*.007
		orbit_height = clampf(orbit_height+event.relative.y*.022,-1.8,5)
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _world_controls_available():
		if tram_mode == 2 or (tram_mode == 0 and (boating or not walker.visible)):
			if event.button_index == MOUSE_BUTTON_LEFT:
				mouse_gas = true
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				mouse_brake = true
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and not event.pressed:
		var released_brake: bool = (event.button_index == MOUSE_BUTTON_RIGHT and mouse_brake) or (event.button_index == MOUSE_BUTTON_LEFT and brake_pedal_held)
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_gas = false
			brake_pedal_held = false
		if event.button_index == MOUSE_BUTTON_RIGHT: mouse_brake = false
		if released_brake and not (mouse_brake or brake_pedal_held or Input.is_action_pressed("ui_down") or _movement_pressed(KEY_S)):
			brake_held = false
		if not (mouse_gas or mouse_brake or brake_pedal_held): mouse_steering = 0.0

func _release_mouse_pedals() -> void:
	if (mouse_brake or brake_pedal_held) and not (Input.is_action_pressed("ui_down") or _movement_pressed(KEY_S)):
		brake_held = false
	mouse_steering = 0.0
	mouse_gas = false
	mouse_brake = false
	brake_pedal_held = false

func _world_controls_available() -> bool:
	return mode == "playing" and not paused and not phone.handset.is_visible_in_tree() and not shops.shop_card.is_visible_in_tree()

func _unhandled_input(event: InputEvent) -> void:
	if not _world_controls_available(): return
	if (tram_mode == 2 or (tram_mode == 0 and (boating or not walker.visible))) and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			brake_pedal_held = driving_controls.over_brake_pedal(driving_controls.get_global_transform_with_canvas().affine_inverse() * event.position)
			mouse_gas = not brake_pedal_held
		if event.button_index == MOUSE_BUTTON_RIGHT: mouse_brake = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		if bubble_time > 0 and not speech_key.is_empty() and speech_locale != TranslationServer.get_locale():
			_say(greeting.get_parent(), speech_key, speech_clip)
		_translate_boule_controls()
		renderer_choices.accessibility_name = tr("Graphics mode")
		game_volume_slider.accessibility_name = tr("Game volume")
		traffic_volume_slider.accessibility_name = tr("Traffic sirens")
		for tile: Button in vehicle_selector.get_children():
			tile.accessibility_name = tr(tile.text)
			tile.get_node("Favorite").accessibility_name = tr("Favorite vehicles") + " · " + tr(tile.text)
		if category_tabs.get_child_count() > 0:
			category_tabs.get_child(-1).tooltip_text = tr("Favorite vehicles")
			category_tabs.get_child(-1).accessibility_name = tr("Favorite vehicles")
		for label in station_readouts:
			label.text = _station_readout_text(station_readouts[label])
		for poster: Label3D in get_tree().get_nodes_in_group("fitted_world_signs"):
			_fit_world_sign(poster)
		for label: Label3D in get_tree().get_nodes_in_group("bus_stop_labels"):
			_update_stop_label(label)
		if shops.inside >= 0: shops.rebuild_menu()
		_update_mission_marker()
		_refresh_ui()
		driving_controls.queue_redraw()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_release_mouse_pedals()
		if mode == "playing" and not paused and not get_tree().paused:
			_toggle_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not event.alt_pressed and not event.meta_pressed:
		if event.keycode == jump_key or (jump_key == KEY_0 and event.keycode == KEY_KP_0):
			if mode == "playing" and not paused and walker.visible and not boule_seated and not scooter.visible and not ferry_passenger and tram_mode == 0 and not operating_excavator and not boating and not phone.handset.is_visible_in_tree() and walk_jump_left <= 0:
				walk_jump_left = WALK_JUMP_TIME
			return
		if event.keycode == recovery_key and mode == "playing" and not paused:
			_recover_position()
			return
		if event.keycode in radio_keys:
			if event.ctrl_pressed:
				return
			if event.keycode == radio_keys[0]:
				_toggle_radio()
			elif next_song_button.is_visible_in_tree():
				_next_radio_track()
			return
		if event.keycode == phone.toggle_key:
			if phone.visible: phone.toggle()
			return
		if event.keycode == scooter_key:
			_toggle_scooter()
			return
		if event.keycode == map_key:
			if _world_controls_available() and map_button.is_visible_in_tree() and not event.ctrl_pressed:
				map_button.pressed.emit()
			return
		if number_vehicle_switches and event.keycode in [KEY_7, KEY_KP_7]:
			if mode == "playing" and not paused and not phone.handset.is_visible_in_tree() and spreader_button.is_visible_in_tree():
				spreader_button.button_pressed = not spreader_button.button_pressed
			return
		if number_vehicle_switches and event.keycode in [KEY_1,KEY_2,KEY_KP_1,KEY_KP_2] and mode == "playing" and not paused and not phone.handset.is_visible_in_tree():
			var control := light_button if event.keycode in [KEY_1,KEY_KP_1] else siren_button
			if control.is_visible_in_tree() and not control.disabled:
				control.pressed.emit()
			return
		match event.keycode:
			KEY_H: _honk()
			KEY_F4:
				if horn_f4: _honk()
			KEY_F, KEY_F3:
				if (event.keycode == KEY_F or seat_f3) and not phone.handset.is_visible_in_tree():
					_change_seat()
			KEY_C, KEY_F6:
				if event.keycode == KEY_C or camera_f6: _toggle_camera_view()
			KEY_ESCAPE, KEY_P, KEY_F7:
				if event.ctrl_pressed: return
				if event.keycode == KEY_F7 and not pause_f7: return
				if event.keycode == KEY_ESCAPE and phone.handset.is_visible_in_tree():
					phone.toggle()
					get_viewport().set_input_as_handled()
				elif mode == "playing":
					_toggle_pause()
			KEY_SPACE, KEY_INSERT:
				if event.keycode == KEY_INSERT and not insert_help: return
				if mode == "playing" and not paused and not phone.handset.is_visible_in_tree():
					if not _serve_dax():
						_help_at_target()
			KEY_ENTER, KEY_KP_ENTER:
				if mode in ["menu", "complete"]: _start_game()
			KEY_R:
				if mode == "complete": _start_game()

func _toggle_radio() -> void:
	if radio_button.disabled or not radio_button.is_visible_in_tree(): return
	radio_enabled = not radio_enabled
	_sync_radio()

func _sync_radio() -> void:
	var language_code := TranslationServer.get_locale()
	if language_code != radio_language:
		radio_language = language_code
		var localized_tracks := L10n.radio_tracks(language_code)
		if localized_tracks != radio_tracks:
			radio.stop()
			radio.stream = null
			radio_track = ""
			radio_bag.clear()
			radio_tracks = localized_tracks
		elif not radio_track.is_empty():
			radio_button.tooltip_text = tr("Now playing: %s") % song_title.text
	var aboard := mode == "playing" and (not walker.visible or scooter.visible or boating or operating_excavator or tram_mode > 0 or ferry_passenger)
	var current_vehicle := ""
	if aboard:
		if boating: current_vehicle = "boat"
		elif operating_excavator: current_vehicle = "excavator"
		elif scooter.visible: current_vehicle = "scooter"
		elif tram_mode > 0: current_vehicle = "tram"
		elif ferry_passenger: current_vehicle = "ferry"
		else: current_vehicle = VEHICLE_NAMES_ALL[vehicle_index]
	if current_vehicle != radio_vehicle and (aboard or mode != "playing"):
		radio_vehicle = current_vehicle
		radio.stop()
		radio_enabled = aboard
	radio_button.visible = aboard and not paused
	next_song_button.visible = radio_button.visible and radio_enabled and radio_tracks.size() > 1
	radio_button.disabled = radio_tracks.is_empty()
	radio_button.icon = preload("res://branding/radio/station.svg") if not radio_enabled and not radio_button.disabled else null
	if not aboard or paused or not radio_enabled or radio_button.disabled:
		song_card.hide()
	if radio_button.disabled:
		radio_button.text = "No songs yet"
		radio_button.tooltip_text = tr("No songs available in this language yet.")
		return
	radio_button.text = tr("Turn radio off · %s" if radio_enabled else "Turn radio on · %s") % OS.get_keycode_string(radio_keys[0])
	next_song_button.text = tr("Next song · %s") % OS.get_keycode_string(radio_keys[1])
	if not radio_enabled:
		radio_button.tooltip_text = ""
		radio.stop()
		radio.stream_paused = false
	elif paused or not aboard:
		radio.stream_paused = true
	else:
		radio.stream_paused = false
		if not radio.playing and not restoring_radio: _next_radio_track()

# Gain offsets for tracks more than 1 LU from the song library's -16 LUFS target.
const RADIO_GAIN_DB := {
	"Hafenradio (DE).mp3": 4.3,
	"Satamaradio (FI).mp3": 2.1,
	"Radio del Puerto (ES).mp3": -2.0,
	"The Splash Disco.mp3": -1.8,
	"Regn på mitt plåttak (SV).mp3": -1.2,
}

func _next_radio_track() -> void:
	if radio_tracks.is_empty() or not radio_enabled or paused: return
	if radio_bag.is_empty():
		radio_bag.assign(radio_tracks)
		radio_bag.shuffle()
		if radio_bag.size() > 1 and radio_bag.back() == radio_track:
			var last := radio_bag.size() - 1
			radio_bag[last] = radio_bag[0]
			radio_bag[0] = radio_track
	_play_radio_track(radio_bag.pop_back())

func _play_radio_track(track: String, position := 0.0) -> void:
	radio_track = track
	song_title.text = L10n.radio_title_and_language(radio_track)[0]
	radio_button.tooltip_text = tr("Now playing: %s") % song_title.text
	var cover_path := "res://branding/radio/" + radio_track.get_basename() + ".webp"
	song_cover.texture = load(cover_path) if ResourceLoader.exists(cover_path) else preload("res://branding/radio/station.svg")
	song_cover.visible = song_cover.texture != null
	song_card_seconds = 5.0
	song_card.show()
	radio_track_gain_db = -10.0 + float(RADIO_GAIN_DB.get(radio_track, 0.0))
	radio.volume_db = _radio_target_gain()
	radio.stream = load("res://audio/radio/" + radio_track)
	radio.play(position if position < radio.stream.get_length() else 0.0)

func _radio_target_gain() -> float:
	# Hold music down across quiet syllables as well as audible ones.
	var speaking := phone.job_voice.playing or (greeting_voice.playing and not greeting_voice.stream_paused)
	return radio_track_gain_db - (8.0 * radio_ducking / 100.0 if speaking else 0.0)

func _honk() -> void:
	if not _world_controls_available() or (walker.visible and not boating and tram_mode == 0) or tram_mode == 1 or horn.playing: return
	horn.stream = load("res://audio/horn_%s.wav" % ("tram" if tram_mode == 2 else "motorboat" if boating else HORNS[vehicle_index]))
	horn.play()

func _update_patrol(delta: float) -> void:
	var angular_speed := .115
	patrol_angle = fmod(patrol_angle + delta * angular_speed, TAU)
	var a := patrol_angle
	helicopter.position = Vector3(54+74*sin(a),36+2*sin(2*a),-16+37*cos(a))
	var tangent := Vector3(74*cos(a),4*cos(2*a),-37*sin(a))
	# The Blender nose faces -Y, imported as local +Z.
	helicopter.look_at(helicopter.position+tangent,Vector3.UP,true)
	var acceleration := Vector3(-74*sin(a), 0, -37*cos(a)) * angular_speed * angular_speed
	var lateral_force := acceleration.dot(helicopter.basis.x.normalized()) * Mass.PATROL_HELICOPTER_KG
	var bank := atan2(lateral_force, 31400.0)
	helicopter.rotate_object_local(Vector3.BACK, -bank)
	main_rotor.rotate_y(delta*28)
	tail_rotor.rotate_x(delta*52)
	medical_helicopter.advance(delta)

func _drive_launch(delta: float) -> void:
	var controls_available := _world_controls_available()
	var pedal_keys := controls_available and _keyboard_pedals_available()
	var gas := controls_available and (mouse_gas or (pedal_keys and (Input.is_action_pressed("ui_up") or _movement_pressed(KEY_W))))
	var brake := controls_available and (mouse_brake or brake_pedal_held or (pedal_keys and (Input.is_action_pressed("ui_down") or _movement_pressed(KEY_S))))
	var turn := 0.0
	if controls_available:
		turn = Input.get_axis("ui_left","ui_right")
		if is_zero_approx(turn): turn = mouse_steering
		if _movement_pressed(KEY_A): turn = -1
		if _movement_pressed(KEY_D): turn = 1
	var reverse_requested := brake and not gas
	var target := 0.0
	if reverse_requested:
		target = -1.6
	elif gas and not brake:
		target = 5.0 if gentle_driving else 9.0
	launch_speed = move_toward(launch_speed,target,delta*(2890.0 if brake else 1275.0)/Mass.LAUNCH_KG)
	var steering_flow := clampf(launch_speed,-1,2)
	if gas and not brake and launch_speed >= 0.0:
		steering_flow = maxf(.8,steering_flow)
	elif reverse_requested and launch_speed <= 0.0:
		steering_flow = minf(-.8,steering_flow)
	outboard.rotation.y = lerp_angle(outboard.rotation.y,-turn*.52,1-exp(-8*delta))
	var previous_yaw := launch.rotation.y
	launch.rotation.y -= turn*steering_flow*delta*.53
	var heading := Vector3.FORWARD.rotated(Vector3.UP,launch.rotation.y)
	var course := heading*signf(launch_speed)
	var clearance := INF
	if absf(course.x)>.0001:
		clearance = ((LAUNCH_CHANNEL.end.x if course.x>0 else LAUNCH_CHANNEL.position.x)-launch.position.x)/course.x
	if absf(course.z)>.0001:
		clearance = minf(clearance,((LAUNCH_CHANNEL.end.y if course.z>0 else LAUNCH_CHANNEL.position.y)-launch.position.z)/course.z)
	if clearance < INF:
		var frame_brake := 3.4*delta
		var safe_speed := sqrt(frame_brake*frame_brake+6.8*maxf(clearance,0))-frame_brake
		launch_speed = signf(launch_speed)*minf(absf(launch_speed),safe_speed)
	var next := launch.position+heading*launch_speed*delta
	var bounded := Vector3(clampf(next.x, LAUNCH_CHANNEL.position.x, LAUNCH_CHANNEL.end.x), -.94+.026*sin(wave_time*1.7), clampf(next.z, LAUNCH_CHANNEL.position.y, LAUNCH_CHANNEL.end.y))
	if absf(next.x-bounded.x)+absf(next.z-bounded.z)>.0001: launch_speed=0
	if _launch_obstacle_overlap(bounded, launch.rotation.y) > _launch_obstacle_overlap(launch.position, previous_yaw) + .0001:
		bounded.x = launch.position.x
		bounded.z = launch.position.z
		launch.rotation.y = previous_yaw
		launch_speed = 0.0
	var engine_load := clampf(absf(launch_speed) / 9.0, 0, 1)
	siren_player.pitch_scale = move_toward(siren_player.pitch_scale, 0.8 + engine_load * .85, delta * 1.5)
	launch.position=bounded
	launch.rotation.z=lerpf(launch.rotation.z,-turn*absf(launch_speed)*.012,1-exp(-3*delta))
	driving_controls.set_controls(turn,gas and not brake,brake,reverse_requested and launch_speed<-.1)

func _launch_footprint(position_on_water: Vector3, yaw: float) -> Rect2:
	# Project the hull's width and length onto the pier axes.
	var along := Vector2(absf(sin(yaw)), absf(cos(yaw)))
	var across := Vector2(along.y, along.x)
	var half_size := along * 2.7 + across
	var center := Vector2(position_on_water.x, position_on_water.z)
	return Rect2(center - half_size, half_size * 2.0)

func _launch_obstacle_overlap(position_on_water: Vector3, yaw: float) -> float:
	var hull := _launch_footprint(position_on_water, yaw)
	var overlap := 0.0
	for pier in pier_surfaces:
		var footprint := Rect2(pier.position.x, pier.position.z, pier.size.x, pier.size.z)
		overlap += footprint.intersection(hull).get_area()
	for pier in bridge_pier_footprints:
		overlap += pier.intersection(hull).get_area()
	for berth in moorings:
		var boat: Node3D = berth.boat
		var bounds: AABB = boat.global_transform * berth.hull_bounds
		var footprint := Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)
		overlap += footprint.intersection(hull).get_area()
	var ferry_bounds := ferry.global_transform * ferry_hull_bounds
	var ferry_footprint := Rect2(ferry_bounds.position.x, ferry_bounds.position.z, ferry_bounds.size.x, ferry_bounds.size.z)
	return overlap + ferry_footprint.intersection(hull).get_area()

func _keyboard_pedals_available() -> bool:
	if not release_pedal_keys:
		return true
	release_pedal_keys = _keyboard_pedal_pressed()
	return false

func _keyboard_pedal_pressed() -> bool:
	return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or _movement_pressed(KEY_W) or _movement_pressed(KEY_S)

func _parcel_load() -> Vector2:
	# Total mass and its lateral first moment about the vehicle centreline.
	var load := Vector2.ZERO
	for i in delivery_parcels.size():
		var parcel := delivery_parcels[i]
		if parcel.visible and parcel.get_parent() == ambulance:
			var mass: float = PARCEL_MASS_KG[i]
			load += Vector2(mass,mass*parcel.position.x)
	return load

func _vehicle_payload() -> float:
	if vehicle_index == 0 and not free_drive and mission_index == 1:
		return 75.0
	if vehicle_index == ICE_CREAM and crate_stage == CrateStage.IN_VAN: return 4.0
	if vehicle_index in PARCEL_VEHICLES:
		return _parcel_load().x
	if vehicle_index == RECOVERY and free_drive and flour_stage == FlourStage.ON_TRUCK:
		return 75.0
	if vehicle_index == RECOVERY and casualty.visible and casualty.get_parent() == ambulance:
		return 1380.0
	if not free_drive and vehicle_index == TAXI and taxi_leg % 2 == 1:
		return 35.0 if _school_fare(taxi_leg) else 75.0
	if not free_drive and vehicle_index == BUS and bus_leg % 2 == 1:
		return 6 * 75.0
	if vehicle_index == REFUSE and not free_drive and mission_index < 3:
		return mission_index * 400.0
	return 0.0

func _road_coverage() -> Vector2:
	if (not ground_work.has_ploughed and not ground_work.has_gritted) or weather.snow <= .01:
		return Vector2(weather.snow,0)
	var contacts := PackedVector3Array()
	for offset in rear_tire_contacts:
		contacts.append(ambulance.to_global(offset))
	for knuckle in front_knuckles:
		contacts.append(knuckle.global_position)
	if contacts.is_empty():
		contacts.append(ambulance.position)
	var coverage := Vector2.ZERO
	for point in contacts:
		if not ground_work.cleared_at(point):
			coverage.x += weather.snow
		if ground_work.gritted_at(point):
			coverage.y += 1.0
	return coverage / contacts.size()

func _drive(delta: float) -> void:
	if shopper_boarding: return
	var throttle := Input.get_axis("ui_down", "ui_up")
	var steer_input := Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(steer_input): steer_input = mouse_steering
	if _movement_pressed(KEY_W): throttle = 1.0
	if _movement_pressed(KEY_S): throttle = -1.0
	if not _keyboard_pedals_available():
		throttle = 0.0
	if mouse_gas: throttle = 1.0
	if mouse_brake or brake_pedal_held: throttle = -1.0
	if vehicle_index == REFUSE and refuse_lift and refuse_lift.is_running():
		throttle = 0.0
	if _movement_pressed(KEY_A): steer_input = -1.0
	if _movement_pressed(KEY_D): steer_input = 1.0
	if not _world_controls_available():
		throttle = 0.0
		steer_input = 0.0
	var road_cover := _road_coverage()
	var road_snow := road_cover.x * (1.0-.55*road_cover.y)
	var winter_tyres: bool = VEHICLE_SCENES_ALL[vehicle_index] in winter_tyre_models
	var max_speed := 250.0 / 3.6 if vehicle_index in [3, XC60_POLICE] else 11.0
	var acceleration := lerpf(8.0, 2.3, clampf(speed / max_speed, 0.0, 1.0)) if vehicle_index in [3, XC60_POLICE] else 7.2
	if vehicle_index >= 6 and vehicle_index <= SNOWMOBILE:
		max_speed = [53.0, 10.0, 8.5, 64.0, 12.0, 16.0][vehicle_index-6]
		acceleration = [7.8, 2.2, 1.8, 10.0, 2.6, 5.2][vehicle_index-6]
	if vehicle_index == QUATTRO:
		max_speed = 22.0
		# The all-wheel-drive launch retains grip on wet roads. Snow still
		# limits the traction that the tyres can transmit to the ground.
		var engine_pull := lerpf(6.0,2.4,clampf(absf(speed)/44.0,0,1))
		var traction := lerpf(6.3,5.0,weather.wet) - (1.25 if winter_tyres else 2.4)*road_snow
		acceleration = minf(engine_pull,maxf(2.0,traction))
	if not gentle_driving:
		max_speed *= 2.0
	if gentle_driving:
		max_speed = 30.0 / 3.6
		acceleration = 6.0 if is_zero_approx(throttle) else minf(acceleration, 2.8)
	if vehicle_index == MOWER:
		max_speed = 2.7 if gentle_driving else 4.0
		acceleration = 2.0
	if vehicle_index in [PUCH_DAKOTA, SHOPPER]:
		max_speed = 30.0 / 3.6
		acceleration = 2.2
	if vehicle_index == PORSCHE:
		max_speed *= 3.0
		if throttle > 0.0:
			acceleration *= 3.0
	var grip_loss := .12 if winter_tyres else .37
	var tyre_traction := 1.0 if vehicle_index in FIXED_TYRE_VEHICLES else 1.0 - grip_loss * road_snow
	if throttle > 0.0 and (vehicle_index != QUATTRO or gentle_driving):
		# Apply traction after the assist cap so gentle driving retains a tyre difference.
		acceleration *= tyre_traction
	if throttle < 0.0 and speed > .001:
		brake_held = true
	elif throttle >= 0.0:
		brake_held = false
	var previous_speed := speed
	var empty_mass := Mass.for_model(VEHICLE_SCENES_ALL[vehicle_index])
	var load_mass := _vehicle_payload()
	var response := Mass.road_response(empty_mass, load_mass)
	var previous_pose := ambulance.global_transform
	var previous_model_pose := vehicle_model.global_transform
	if brake_held:
		speed = move_toward(speed, 0.0, (18.0 - 2.0*weather.wet - (3.5 if winter_tyres else 8.0)*road_snow + 2.2*road_cover.y) * absf(throttle) * response * delta)
	elif throttle < 0.0:
		speed = move_toward(speed, throttle * (1.8 if gentle_driving else 4.0), 3.0 * tyre_traction * response * delta)
	else:
		speed = move_toward(speed, throttle * max_speed, acceleration * response * delta)
	steering = move_toward(steering, steer_input, (2.0 if gentle_driving else 3.4) * delta)
	if cabin_wheel:
		var angle := deg_to_rad(33.0) if vehicle_index in [SNOWMOBILE, SHOPPER] else 1.2
		cabin_wheel.basis = cabin_wheel_rest_basis * Basis(cabin_wheel_axis,-steering*angle)
		_pose_driver_arms()
	for knuckle in front_knuckles:
		var wheel_angle := steering * deg_to_rad(33.0)
		if vehicle_index == SHOPPER:
			# Both front tyres trace circles around the same point on the rear axle.
			var side_offset := ambulance.to_local(knuckle.global_position).x
			var tangent := tan(wheel_angle)
			wheel_angle = atan2(1.61 * tangent, 1.61 - side_offset * tangent)
		knuckle.rotation.y = -wheel_angle
	driving_controls.set_controls(steering, throttle > 0, brake_held, throttle < 0 and not brake_held)
	var wheelbase: float = [3.7, 2.75, 4.1, 2.975, 2.85, 4.0, 2.56, 2.64, 2.46, 2.96, 6.06, 1.65, 2.865, 2.457, 3.81, 2.495, 1.14, 3.37, 2.84, 3.1, 3.2, 2.61, 3.8, 1.01, 4.52, 1.61, 3.74, 2.224][vehicle_index]
	var yaw_rate := speed * tan(steering * deg_to_rad(33.0)) / wheelbase
	# Limit lateral acceleration at speed while retaining tight parking turns.
	var lateral_limit := 8.0 + 1.2*road_cover.y - (0.6 if winter_tyres else 1.7)*road_snow
	if vehicle_index == QUATTRO:
		lateral_limit -= 1.2*weather.wet + 2.2*road_snow
	if load_mass > 0 and vehicle_index in PARCEL_VEHICLES:
		var center_offset := _parcel_load().y / (empty_mass + load_mass)
		var half_track := player_half_size.x * .85
		# A turn loads the outside wheels. Roof freight also raises the centre of mass.
		var cg_height := (.60*empty_mass + parcel_mounts[vehicle_index].y*load_mass) / (empty_mass + load_mass)
		lateral_limit *= (.60/cg_height) * (1.0 + signf(yaw_rate*speed)*center_offset/half_track)
	var snow_grip := smoothstep(.24,.7,road_snow)
	var speed_factor := smoothstep(7.6,12.6,absf(speed)) if winter_tyres else smoothstep(6.0,10.0,absf(speed))
	var slide := 0.0
	if vehicle_index != SNOWMOBILE and bridge_jump_left <= 0.0 and not brake_held:
		var excess := maxf(0.0,absf(yaw_rate * speed) - lateral_limit * lerpf(1.0,.48,snow_grip))
		slide = signf(yaw_rate) * minf(.29,excess*.063) * snow_grip * speed_factor * (.43 if winter_tyres else 1.0)
	snow_slip_angle = move_toward(snow_slip_angle,slide,delta*(.85 if is_zero_approx(slide) else .95))
	var max_yaw_rate := lateral_limit / maxf(absf(speed), 1.0)
	var previous_extent := _player_extent()
	ambulance.rotate_y(-clampf(yaw_rate, -max_yaw_rate, max_yaw_rate) * delta)
	var extent := _player_extent()
	for span in OPEN_WATER:
		if _shore_overlap(span, ambulance.position, extent) > _shore_overlap(span, ambulance.position, previous_extent):
			ambulance.basis = previous_pose.basis
			extent = previous_extent
			break
	var obstacles := _road_obstacles()
	if not extent.is_equal_approx(previous_extent):
		var turn_obstacles := obstacles.duplicate()
		for item in traffic_data:
			turn_obstacles.append(_traffic_bounds(item))
		for obstacle in turn_obstacles:
			if _vehicle_overlap_depth(obstacle, extent, ambulance.basis) > _vehicle_overlap_depth(obstacle, previous_extent, previous_pose.basis) + .00001:
				ambulance.basis = previous_pose.basis
				extent = previous_extent
				break
	if ambulance.global_transform.basis != previous_pose.basis:
		var reach := maxf(front_reach, rear_reach)
		var corner_radius := Vector2(player_half_size.x, reach).length()
		for trunk in trunks:
			var center := Vector3(trunk.x, ambulance.position.y, trunk.z)
			if center.distance_squared_to(ambulance.position) > (corner_radius + trunk.y) ** 2:
				continue
			var gap := _trunk_gap(ambulance.to_local(center))
			if gap < trunk.y and gap < _trunk_gap(previous_pose.affine_inverse() * center):
				ambulance.basis = previous_pose.basis
				extent = previous_extent
				break
	var forward := -ambulance.global_transform.basis.z
	var travel_direction := forward.rotated(Vector3.UP,snow_slip_angle) * signf(speed)
	var leading_reach := rear_reach if speed<0 else front_reach
	var approach := forward if is_zero_approx(speed) else travel_direction
	var responding := _player_emergency_response()
	var signal_gap := street_signals.red_clearance(ambulance.position,approach,leading_reach,false,false,responding)
	var queue_gap := street_signals.junction_queue_gap(ambulance.position, approach, leading_reach,
		front_reach + rear_reach, player_half_size.x, _junction_vehicle_obstacles(ambulance), null, 0.0, responding)
	var stopping_distance := minf(queue_gap, INF if allow_red_lights and not responding else signal_gap)
	var people: Array = [shoe_owner,cat_owner,crossing_pedestrian,passenger,arriving_passenger,waiting_medic,marina_recipient,square_neighbour]
	people.append_array(bus_companions)
	people.append_array(clinic_fire_team)
	for item in walker_data:
		people.append(item.actor)
		if item.has("pet") and item.pet.is_visible_in_tree():
			var bounds: AABB = (ambulance.global_transform.affine_inverse() * item.pet.global_transform) * item.pet.BODY_BOUNDS
			if bounds.position.x < player_half_size.x+.2 and bounds.end.x > -player_half_size.x-.2:
				var ahead := -bounds.position.z if speed >= 0 else bounds.end.z
				var gap := -bounds.end.z if speed >= 0 else bounds.position.z
				if ahead > 0 and gap >= -.01:
					stopping_distance = minf(stopping_distance,maxf(0,gap-leading_reach-.4))
	for person: Node3D in people:
		if not person.visible: continue
		var offset := ambulance.to_local(person.position)
		if absf(offset.x)<player_half_size.x+.36 and -offset.z*signf(speed)>0:
			stopping_distance = minf(stopping_distance,maxf(0,absf(offset.z)-leading_reach-.65))
		if not is_zero_approx(snow_slip_angle) and not travel_direction.is_zero_approx():
			var sliding_offset := person.position - ambulance.position
			var side := travel_direction.cross(Vector3.UP)
			var ahead := sliding_offset.dot(travel_direction)
			var side_reach := absf(side.x)*extent.x + absf(side.z)*extent.y
			if ahead > 0.0 and absf(sliding_offset.dot(side)) < side_reach+.36:
				var slide_reach := absf(travel_direction.x)*extent.x + absf(travel_direction.z)*extent.y
				stopping_distance = minf(stopping_distance,maxf(0.0,ahead-slide_reach-.65))
	var margin := Vector3(extent.x, 0, extent.y)
	var lookahead := ambulance.position + travel_direction * (1.0 + speed*speed/10.0 + absf(speed)*delta)
	if not allow_crashes and not travel_direction.is_zero_approx():
		# Leave a visible gap in assisted mode, including when reversing.
		var hazards := obstacles.duplicate()
		for item in traffic_data:
			hazards.append(_traffic_bounds(item))
		for trunk in trunks:
			hazards.append(AABB(Vector3(trunk.x-trunk.y,-2,trunk.z-trunk.y),Vector3(2*trunk.y,6,2*trunk.y)))
		for hazard in hazards:
			if is_zero_approx(snow_slip_angle) and _outside_driving_strip(hazard, .35): continue
			var guard := AABB(hazard.position-margin,hazard.size+2*margin).grow(.35)
			if guard.has_point(ambulance.position):
				if _moves_deeper_into_box(guard, ambulance.position, travel_direction):
					stopping_distance = 0
			else:
				var hit = guard.intersects_segment(ambulance.position,lookahead)
				if hit != null:
					stopping_distance = minf(stopping_distance,ambulance.position.distance_to(hit))
	# Stop with the bumper on dry ground, including when approaching in reverse.
	for span in OPEN_WATER:
		var water := AABB(Vector3(55 - extent.x, -10, span.x - extent.y),
			Vector3(32 + 2*extent.x, 20, span.y - span.x + 2*extent.y))
		if water.has_point(ambulance.position):
			var depth := _shore_overlap(span, ambulance.position, extent)
			if _shore_overlap(span, ambulance.position + travel_direction*.01, extent) >= depth:
				stopping_distance = 0
		else:
			var hit = water.intersects_segment(ambulance.position, lookahead)
			if hit != null:
				stopping_distance = minf(stopping_distance, ambulance.position.distance_to(hit))
	for item in traffic_data:
		if item.has("rider"):
			var rider_offset := ambulance.to_local(item.actor.global_position)
			if absf(rider_offset.x)<player_half_size.x+.49 and -rider_offset.z*signf(speed)>0:
				stopping_distance = minf(stopping_distance,maxf(0,absf(rider_offset.z)-leading_reach-.9))
	var assisted_braking := false
	if stopping_distance < INF:
		# Reserve the current frame's travel before applying the stopping curve.
		var frame_brake := 5.0*delta
		var limit := sqrt(frame_brake*frame_brake + 10.0*maxf(0,stopping_distance-.04))-frame_brake
		assisted_braking = absf(speed)>limit
		speed = signf(speed)*minf(absf(speed),limit)
	waiting_for_clear_crossing = queue_gap <= .35 and queue_gap == stopping_distance and absf(speed) < .25
	waiting_for_signal = waiting_for_clear_crossing or ((not allow_red_lights or responding) and signal_gap <= .35 and signal_gap == stopping_distance and absf(speed) < .25)
	if waiting_for_signal and not waiting_for_clear_crossing:
		waiting_for_clear_crossing = responding or street_signals.red_clearance(ambulance.position,approach,leading_reach,false,true) > signal_gap
	slowing_for_amber = assisted_braking and signal_gap == stopping_distance and not waiting_for_signal and not allow_red_lights and not responding
	if slowing_for_amber:
		slowing_for_amber = street_signals.red_clearance(ambulance.position,approach,leading_reach,false,true) == signal_gap and street_signals.red_clearance(ambulance.position,approach,leading_reach,true) > signal_gap
	if player_brake_lens:
		_set_rear_lights(player_brake_lens, brake_held or assisted_braking or waiting_for_signal)
	var step := travel_direction * absf(speed) * delta
	# In vehicle space the sweep is straight along Z. A round trunk also
	# clears the bumper corners when passing diagonally beside a tree.
	var travel_sign := signf(step.dot(forward))
	for trunk in trunks:
		if not is_zero_approx(snow_slip_angle):
			var half_size := Vector3(extent.x+trunk.y,1,extent.y+trunk.y)
			var guard := AABB(Vector3(trunk.x,ambulance.position.y,trunk.z)-half_size,half_size*2)
			if guard.has_point(ambulance.position) and not _moves_deeper_into_box(guard,ambulance.position,step):
				continue
			var hit = guard.intersects_segment(ambulance.position,ambulance.position+step)
			if hit != null:
				step = step.limit_length(maxf(0.0,ambulance.position.distance_to(hit)-.02))
				speed = 0.0
			continue
		var relative := ambulance.to_local(Vector3(trunk.x, ambulance.position.y, trunk.z))
		var side_gap := maxf(absf(relative.x) - player_half_size.x, 0.0)
		if side_gap >= trunk.y or relative.z * travel_sign >= 0.0:
			continue
		var clearance := absf(relative.z) - leading_reach - sqrt(trunk.y * trunk.y - side_gap * side_gap)
		if clearance <= step.length():
			step = step.limit_length(maxf(0.0, clearance - 0.02))
			speed = 0.0
	for building in obstacles:
		if is_zero_approx(snow_slip_angle) and _outside_driving_strip(building, 0.0): continue
		var wall := AABB(building.position - margin, building.size + 2 * margin)
		if wall.has_point(ambulance.position):
			# A vehicle swap can enlarge the footprint beside an existing wall.
			if _moves_deeper_into_box(wall, ambulance.position, step):
				step = Vector3.ZERO
				speed = 0.0
			continue
		var contact = wall.intersects_segment(ambulance.position, ambulance.position + step)
		if contact != null:
			step = step.limit_length(maxf(0.0, ambulance.position.distance_to(contact) - 0.02))
			speed = 0.0
	var contact_distance := INF
	var contact_normal := Vector3.ZERO
	var struck_vehicle: Dictionary
	for item in traffic_data:
		var obstacle: Node3D = item.actor
		var offset := ambulance.position - obstacle.position
		var bounds := extent + _traffic_extent(item)
		var footprint := AABB(Vector3(-bounds.x, -1, -bounds.y), Vector3(bounds.x * 2, 2, bounds.y * 2))
		if footprint.has_point(offset) and not _moves_deeper_into_box(footprint, offset, step):
			continue
		var contact = footprint.intersects_segment(offset, offset + step)
		if contact != null and offset.distance_to(contact) < contact_distance:
			contact_distance = offset.distance_to(contact)
			struck_vehicle = item
			var hit: Vector3 = contact
			if bounds.x - absf(hit.x) < bounds.y - absf(hit.z):
				contact_normal = Vector3.LEFT * signf(hit.x)
			else:
				contact_normal = Vector3.FORWARD * signf(hit.z)
	if contact_distance < INF:
		step = step.limit_length(maxf(0.0, contact_distance - .02))
		if allow_crashes:
			var other: Node3D = struck_vehicle.actor
			var resulting_speeds := Mass.contact_speeds(speed, struck_vehicle.speed, forward, -other.global_basis.z.normalized(), contact_normal, empty_mass + load_mass, struck_vehicle.mass_kg)
			speed = resulting_speeds.x
			struck_vehicle.speed = resulting_speeds.y
		else:
			speed = 0.0
	var destination := ambulance.position + step
	var pos := destination
	var bounds := _play_bounds()
	pos.x = clampf(pos.x, bounds.position.x + extent.x, bounds.end.x - extent.x)
	pos.z = clampf(pos.z, bounds.position.y + extent.y, bounds.end.y - extent.y)
	if pos.x != destination.x or pos.z != destination.z:
		speed = 0.0
	if absf(speed) < .1:
		snow_slip_angle = 0.0
	pos.y = _surface_height(pos.x, pos.z)
	_update_vehicle_dirt(pos,previous_pose.origin,delta)
	if pos.y < -0.15:
		var terrain_limit := lerpf(6.0, max_speed, weather.snow) if vehicle_index == SNOWMOBILE else 6.0
		speed = clampf(speed, -3.0, terrain_limit)
	if allow_red_lights and not responding and signal_gap < INF:
		var red_gap := street_signals.red_clearance(previous_pose.origin,travel_direction,leading_reach,true)
		if red_gap >= 0 and (pos-previous_pose.origin).dot(travel_direction) > red_gap:
			message = "Red light! Stop at the line and wait for green."
			message_timer = 4.0
	if moped_speed_needle:
		# Nine graduations span 0–40 km/h on the dial.
		moped_speed_needle.rotation.y = deg_to_rad(-252.0) * clampf(absf(speed)*3.6/40.0,0.0,1.0)
	if quattro_speed_needle:
		quattro_speed_needle.rotation.z = deg_to_rad(-252.0) * clampf(absf(speed)*3.6/240.0,0.0,1.0)
	_roll_wheels(player_wheels, (pos - previous_pose.origin).dot(forward))
	# Carry a little upward momentum from the climbing ramp onto the level span.
	var eastbound := previous_pose.origin.x < HIGH_BRIDGE_X[1] and pos.x >= HIGH_BRIDGE_X[1]
	var westbound := previous_pose.origin.x > HIGH_BRIDGE_X[2] and pos.x <= HIGH_BRIDGE_X[2]
	var across_speed := absf(pos.x - previous_pose.origin.x) / maxf(delta, .00001)
	if bridge_jump_left <= 0 and absf(pos.z+48.0) <= 4.95 and (eastbound or westbound) and across_speed > 7.5:
		var ramp_length: float = HIGH_BRIDGE_X[1]-HIGH_BRIDGE_X[0] if eastbound else HIGH_BRIDGE_X[3]-HIGH_BRIDGE_X[2]
		var lift_speed := minf(2.75, (across_speed-6.0)*HIGH_BRIDGE_RISE/ramp_length)
		bridge_jump_time = 2.0*lift_speed/9.81
		bridge_jump_left = bridge_jump_time
	if bridge_jump_left > 0:
		bridge_jump_left = maxf(0, bridge_jump_left-delta)
		pos.y += 4.905*bridge_jump_left*(bridge_jump_time-bridge_jump_left)
	ambulance.global_position = pos
	_track_practice_speed((pos-previous_pose.origin).dot(forward))
	_track_practice_stop(pos,extent.x,forward.x)
	_track_practice_signal(previous_pose.origin,pos,extent.x,forward.x,delta)
	_align_model_to_bridge(ambulance, vehicle_model, wheelbase)
	var moving_on_ground := bridge_jump_left <= 0 and previous_pose.origin.distance_squared_to(pos) > .000001
	if vehicle_index == FARM_TRACTOR and is_instance_valid(spreader_particles):
		var forward_travel := (pos - previous_pose.origin).dot(forward)
		var spreading := spreader_enabled and moving_on_ground and weather.season == 4 and weather.snow >= .12 and speed > .25 and forward_travel > .0001
		_set_spreader_active(spreading)
		if spreading:
			ground_work.sweep(previous_model_pose,vehicle_model.global_transform,Vector3(-SPREADER_EDGE.x,0,SPREADER_EDGE.z),SPREADER_EDGE,false,true)
	if moving_on_ground:
		if vehicle_index == MOWER and weather.snow < .12:
			ground_work.sweep(previous_pose, ambulance.global_transform, Vector3(-.65,0,-1.04), Vector3(.65,0,-1.04), true)
		elif vehicle_index == FARM_TRACTOR and weather.season == 4 and weather.snow >= .12 and speed > 0:
			ground_work.sweep(previous_model_pose, vehicle_model.global_transform, blade_left, blade_right, false)
	if reverse_lens:
		reverse_lens.emission_energy_multiplier = 2.0 if speed < -0.01 else 0.0
	var hard_braking := brake_held and throttle < -0.7 and previous_speed > (2.0 if not skid_anchors.is_empty() else 7.0)
	var snow_trail := vehicle_index == SNOWMOBILE and road_cover.x >= .25
	if (snow_trail or absf(snow_slip_angle) > .025 or (hard_braking and pos.y > -.15)) and previous_pose.origin.distance_squared_to(pos) > .000001:
		_draw_skid(previous_pose, road_cover.x)
	else:
		_end_skid()

func _update_meadow_sign() -> void:
	var total := int(ground_work.PICNIC_MEADOW.get_area()) * ground_work.DENSITY * ground_work.DENSITY
	var percent := floori(100.0 * ground_work.meadow_pixels / total)
	meadow_sign.text = tr("Picnic meadow · %d%%") % percent if percent < 100 else tr("Ready for a picnic!")
	meadow_sign.visible = weather.snow < .12

func _update_school_plough() -> void:
	var active := weather.season == 4 and weather.snow >= .12
	var complete := active
	for flag in school_plough_flags:
		flag.visible = active and vehicle_index == FARM_TRACTOR and mode == "playing"
		if not active:
			continue
		var cleared := true
		for offset in [-.55,0.0,.55]:
			for along in [-.75,-.25,.25,.75]:
				if not ground_work.cleared_at(Vector3(flag.position.x+along,0,2.35+offset)):
					cleared = false
		flag.text = "✓" if cleared else "❄"
		flag.modulate = Color("#68e895") if cleared else Color("#bceaff")
		complete = complete and cleared
	if complete and not school_plough_open:
		message = "The road to school is clear!"
		message_timer = 5
		_refresh_status()
	school_plough_open = complete

func _build_brake_effects() -> void:
	asphalt_track_finish.shader = preload("res://environment/snow_footprint.gdshader")
	asphalt_track_finish.set_shader_parameter("asphalt_track", true)
	asphalt_track_finish.set_shader_parameter("snow_opacity", 1.0)
	ground_work.attach(asphalt_track_finish)
	var strip := PlaneMesh.new()
	strip.size = Vector2.ONE
	strip.material = asphalt_track_finish
	snow_track_finish.shader = preload("res://environment/snow_footprint.gdshader")
	ground_work.attach(snow_track_finish)
	for marks: MultiMesh in [skid_marks, snow_marks]:
		marks.transform_format = MultiMesh.TRANSFORM_3D
		marks.use_colors = true
		marks.mesh = strip
		marks.instance_count = SKID_CAPACITY
		marks.visible_instance_count = 0
		var trails := MultiMeshInstance3D.new()
		trails.multimesh = marks
		if marks == snow_marks:
			trails.material_override = snow_track_finish
		trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(trails)
	var sole := PlaneMesh.new()
	sole.size = Vector2(.145,.27)
	sole_finish.shader = preload("res://environment/snow_footprint.gdshader")
	sole_finish.set_shader_parameter("tread", preload("res://characters/sole_print.svg"))
	ground_work.attach(sole_finish)
	sole.material = sole_finish
	sole_marks.transform_format = MultiMesh.TRANSFORM_3D
	sole_marks.mesh = sole
	sole_marks.instance_count = 384
	sole_marks.visible_instance_count = 0
	var footprints := MultiMeshInstance3D.new()
	footprints.multimesh = sole_marks
	footprints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(footprints)
	var scrub := preload("res://audio/tire_scrub.wav").duplicate() as AudioStreamWAV
	scrub.loop_mode = AudioStreamWAV.LOOP_FORWARD
	scrub.loop_end = roundi(scrub.get_length() * scrub.mix_rate)
	tire_player.bus = &"Traffic and radio"
	tire_player.stream = scrub
	add_child(tire_player)

func _end_skid() -> void:
	skid_anchors.clear()
	if tire_player.playing:
		tire_player.stop()

func _draw_skid(previous_pose: Transform3D, snow_cover: float) -> void:
	var contacts := rear_tire_contacts
	if vehicle_index == SNOWMOBILE and snow_cover >= .25:
		contacts = rear_tire_contacts.duplicate()
		for ski in front_knuckles:
			contacts.append(ambulance.to_local(ski.global_position))
	var starting := skid_anchors.size() != contacts.size()
	if starting:
		skid_anchors.clear()
	# Each wheel can cross a different surface at the edge of a ploughed strip.
	var slush_color := Color("#83949b").lerp(Color("#47575c"), weather.wet)
	for wheel in contacts.size():
		var offset := contacts[wheel]
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
		var wheel_snow := 0.0 if ground_work.cleared_at(center) else weather.snow
		var track_color := Color("#1b1b1c").lerp(slush_color, wheel_snow)
		var track_width := lerpf(.19,.245,wheel_snow)
		if vehicle_index == SNOWMOBILE:
			track_width = .40 if wheel == 0 else .12
		var on_snow := wheel_snow >= .25
		var marks := snow_marks if on_snow else skid_marks
		var cursor := snow_cursor if on_snow else skid_cursor
		var direction := segment / length
		var axes := Basis(Vector3.UP.cross(direction) * track_width, Vector3.UP, direction * (length + 0.015))
		marks.set_instance_transform(cursor, Transform3D(axes, center))
		marks.set_instance_color(cursor, track_color)
		cursor = (cursor + 1) % SKID_CAPACITY
		if on_snow:
			snow_cursor = cursor
		else:
			skid_cursor = cursor
		marks.visible_instance_count = mini(SKID_CAPACITY, marks.visible_instance_count + 1)
		skid_anchors[wheel] = endpoint
	if vehicle_index != SNOWMOBILE and not AudioServer.is_bus_mute(0):
		var rolling_speed := absf(speed)
		tire_player.pitch_scale = 0.78 + clampf(rolling_speed / (250.0 / 3.6), 0, 1) * 0.45
		tire_player.volume_db = lerpf(-20.0, -8.0, clampf(rolling_speed / 22.0, 0, 1)) - 5.0*snow_cover
		if not tire_player.playing:
			tire_player.play()
	elif tire_player.playing:
		tire_player.stop()

func _taxi_stop(leg: int = taxi_leg) -> int:
	return TAXI_STOPS[leg % TAXI_STOPS.size()]

func _stop_pavement(stop: int) -> Vector3:
	if stop >= 4: return WEST_STOPS[stop-4] + Vector3.BACK*3.9
	return SCHOOL_GATE if stop == SCHOOL else WALK_TARGETS[stop]

func _stop_curb(stop: int) -> Vector3:
	if stop >= 4: return WEST_STOPS[stop-4]
	return SCHOOL_CURB if stop == SCHOOL else TARGETS[stop]

func _school_fare(leg: int) -> bool:
	var pickup := leg - leg % 2
	return SCHOOL in [_taxi_stop(pickup), _taxi_stop(pickup+1)]

func _taxi_instruction() -> String:
	if _school_fare(taxi_leg):
		return "Pick up the pupil" if taxi_leg%2==0 else "Drop off the pupil"
	return "Pick up your passenger" if taxi_leg%2==0 else "Drop off your passenger"

func _needs_mission_vehicle() -> bool:
	return walker.visible and vehicle_index in [TAXI, RECOVERY, BUS, ICE_CREAM, REFUSE]

func _mission_destination() -> Vector3:
	if _needs_mission_vehicle():
		var door := parked_cars[vehicle_index].to_global(parked_door_offset)
		door.y = _foot_height(door.x, door.z)
		return door
	var stop := _mission_stop()
	var destination := WALK_TARGETS[stop] if walker.visible else TARGETS[stop]
	if vehicle_index == 0 and mission_index == 1:
		destination = HOSPITAL_INTAKE_STOP
	elif vehicle_index == TAXI:
		destination = _stop_curb(_taxi_stop())
	elif vehicle_index == ICE_CREAM:
		destination = _stop_curb(ICE_STOPS[mission_index])
	elif vehicle_index == BUS:
		destination = _stop_curb(BUS_STOPS[bus_leg%BUS_STOPS.size()])
	elif vehicle_index == RECOVERY:
		destination = SERVICE_STOPS[recovery_leg%4]
	if vehicle_index in [TAXI,REFUSE] and destination == TARGETS[1]:
		destination.x = 2.35
	destination.y = _surface_height(destination.x,destination.z)
	return destination

func _arrival_radius() -> float:
	if vehicle_index == 0 and mission_index == 1 and not free_drive:
		return 1.25
	return 2.1 if walker.visible else 5.2

func _at_target() -> bool:
	if vehicle_index == 0 and mission_index == 1 and walker.visible:
		return false
	if walker.visible and vehicle_index in PARCEL_VEHICLES and mission_index in [1,2] and carried_parcel_leg != mission_index:
		return false
	if scooter.visible or free_drive or boating or ferry_passenger or tram_mode != 0 or (vehicle_index in [TAXI,RECOVERY,BUS,ICE_CREAM,REFUSE,SHOPPER] and walker.visible) or mission_index >= TARGETS.size(): return false
	var actor := walker if walker.visible else ambulance
	return actor.position.distance_to(_mission_destination()) < _arrival_radius()

func _update_arrival(delta: float) -> void:
	if ice_order.visible and (vehicle_index != ICE_CREAM or not _at_target() or absf(speed) >= .12): ice_order.hide()
	var stopped := walking_velocity.length() < .12 if walker.visible else absf(speed) < .12
	if practice_hose.visible:
		if vehicle_index != 2 or mission_index != 2 or not _at_target() or not stopped:
			practice_hose.hide()
			practice_spray.emitting = false
			hose_seconds = 0
			return
		hose_seconds += delta
		if hose_seconds >= 2.5:
			_help_at_target()
		return
	if gentle_driving and _at_target() and stopped:
		parked_at_target += delta
		if parked_at_target >= HELP_DURATION:
			_help_at_target()
	else:
		parked_at_target = 0.0

func _delivery_receipt() -> String:
	if vehicle_index == 0 and mission_index == 2:
		return phone.HOSPITAL_RECEIPT
	if vehicle_index == 0 and mission_index == TARGETS.size():
		return "First-aid supplies delivered to the marina. You earned 10 points and 10 coins."
	elif vehicle_index == ICE_CREAM:
		return "Ice cream served! You earned 10 points and 10 coins."
	elif _vehicle_tasks() == DELIVERY_TASKS:
		return ["Two parcels collected at the square. You earned 10 points and 10 coins.", phone.CLINIC_RECEIPT, phone.MARINA_RECEIPT][mission_index-1]
	return "Thank you for helping! You earned 10 points and 10 coins."

func _empty_refuse_bin(stop: int) -> void:
	var bin := refuse_bins[stop]
	var curb := bin.global_position
	var comb := vehicle_model.find_child("LoadingCombPivot", true, false) as Node3D
	var rest_rotation := bin.rotation
	var loading_pose := Transform3D(Basis(Vector3.UP, vehicle_model.global_rotation.y), vehicle_model.to_global(Vector3(0,.315,-3.985)))
	var bin_mount := comb.global_transform.affine_inverse() * loading_pose
	var move_comb := func(angle: float) -> void:
		comb.rotation.x = angle
		bin.global_transform = comb.global_transform * bin_mount
	bin.rotation.y = vehicle_model.global_rotation.y
	refuse_lift = bin.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if refuse_beacon:
		refuse_beacon.emission_enabled = true
		refuse_lift.finished.connect(refuse_beacon.set.bind("emission_enabled", false), CONNECT_ONE_SHOT)
	refuse_pump.global_position = loading_pose.origin
	refuse_lift.tween_property(bin,"global_position",loading_pose.origin,.65)
	refuse_lift.tween_callback(refuse_pump.play)
	var tip_angle := deg_to_rad(145.0)
	refuse_lift.tween_method(move_comb,0.0,tip_angle,.55)
	refuse_lift.tween_interval(.18)
	refuse_lift.tween_method(move_comb,tip_angle,0.0,.45)
	refuse_lift.tween_property(bin,"global_position",curb,.65)
	refuse_lift.parallel().tween_property(bin,"rotation",rest_rotation,.65)

func _show_mission_reward(kind: String, cell: int, points: int, coins: int) -> void:
	var picture := AtlasTexture.new()
	picture.atlas = MEMORY_SHEETS[kind]
	picture.region = Rect2(cell*48,0,48,48)
	var memory_id := "%s/%d" % [kind, cell]
	if not mission_memories.has(memory_id): mission_memories.append(memory_id)
	reward_badge.icon = picture
	reward_badge.text = "+" + tr_n("★ %d point","★ %d points",points) % points + "   +" + tr_n("%d coin","%d coins",coins) % coins
	reward_badge.reset_size()
	reward_badge.move_to_front()
	reward_badge.show()
	reward_seconds = 4.0

func _reward_delivery(amount: int) -> void:
	_show_mission_reward("vehicle",phone.vehicle_action,amount,amount)
	wallet += amount
	delivery_points += amount

func _help_at_target(ice_choice := -1) -> void:
	if operating_excavator: return
	if free_drive or mission_index >= TARGETS.size(): return
	if vehicle_index == BUS:
		if _at_target() and absf(speed)<.2:
			bus_leg += 1
			bus_departure_pending = true
			bus_merge_time = BUS_MERGE_SECONDS
			parked_at_target = 0
			message = "Passengers on board." if bus_leg%2 else "Bus journey complete. You earned 15 points and 15 coins."
			if bus_leg%2==0:
				_reward_delivery(15)
				phone.receive(message)
			message_timer = 3
			_update_mission_marker()
			_save_checkpoint()
			_refresh_ui()
		return
	if vehicle_index == RECOVERY:
		if _at_target() and absf(speed)<.2:
			recovery_leg+=1
			parked_at_target=0
			if recovery_leg%2==0:
				_repair_at_workshop(recovery_leg % 4 == 0)
				_reward_delivery(20)
				message = "Recovery complete. You earned 20 points and 20 coins."
				phone.receive(message)
			else:
				message = "Car loaded onto the flatbed."
			message_timer = 3.0
			_update_mission_marker()
			_save_checkpoint()
			_refresh_ui()
		return
	if vehicle_index == TAXI:
		if _at_target() and absf(speed)<.2:
			taxi_leg += 1
			if taxi_leg%2==0:
				phone.receive("Fare complete. You earned 15 points and 15 coins.")
				_reward_delivery(15)
			parked_at_target = 0
			message = "Passenger on board." if taxi_leg%2 else "Thank you for the ride!"
			if _school_fare(taxi_leg-1):
				if taxi_leg%2:
					message = "School is over! To the clinic, please." if _taxi_stop(taxi_leg-1) == SCHOOL else "The pupil is on board."
				elif _taxi_stop(taxi_leg-1) == SCHOOL:
					message = "Thanks! I can see my school!"
			message_timer = 3
			_update_mission_marker()
			_save_checkpoint()
			_refresh_ui()
		return
	if _at_target() and (walker.visible or absf(speed)<.12):
		parked_at_target = 0.0
		if vehicle_index == 2 and mission_index == 2:
			if hose_seconds < 2.5:
				practice_hose.show()
				practice_spray.emitting = true
				return
			practice_hose.hide()
			practice_spray.emitting = false
			hose_seconds = 0
		if vehicle_index == ICE_CREAM:
			var wanted := [0,4,2][mission_index] as int
			if ice_choice != wanted:
				requested_ice.texture = ice_flavours[wanted]
				if not ice_order.visible:
					ice_order.show()
					ice_order.move_to_front()
					for button in flavour_choices.get_children(): button.disabled = false
					flavour_choices.get_child(0).grab_focus()
				if ice_choice >= 0:
					flavour_choices.get_child(ice_choice).disabled = true
				return
			ice_order.hide()
		if vehicle_index == REFUSE and mission_index < 2:
			_empty_refuse_bin(mission_index)
		mission_index += 1
		if vehicle_index == ICE_CREAM:
			_honk()
		var receipt := _delivery_receipt()
		if receipt in [phone.CLINIC_RECEIPT, phone.MARINA_RECEIPT, phone.HOSPITAL_RECEIPT]:
			phone.delivery_receipts.append(receipt)
		phone.receive(receipt)
		_reward_delivery(10)
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
		_save_checkpoint()
	else:
		if _mission_stop() == 2:
			message = "Cross a bridge to the east side." if (walker.position.x if walker.visible else ambulance.position.x) < 87 else "Follow the quay to the green marker by the boats."
		else:
			message = "Follow the green mission marker."
		message_timer = 2.5
		_refresh_status()

func _build_stars() -> void:
	for id: String in STAR_SITES:
		if collected_stars.has(id): continue
		var site: Vector2 = STAR_SITES[id]
		var star := Label3D.new()
		star.text = "★"
		star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		star.modulate = Color("#ffdb5280")
		star.outline_modulate = Color("#79451080")
		star.font_size = 96
		star.pixel_size = .008
		star.position = Vector3(site.x, _surface_height(site.x, site.y) + 1.35, site.y)
		add_child(star)
		star_markers[id] = star

func _player_actor() -> Node3D:
	if operating_excavator: return excavator
	if boating: return launch
	if tram_mode > 0: return tram.sections[0]
	if ferry_passenger: return ferry
	return walker if walker.visible else ambulance

func _collect_stars(start: Vector3, finish: Vector3) -> void:
	for id: String in star_markers.keys():
		var marker: Label3D = star_markers[id]
		var target := marker.global_position - Vector3.UP * 1.35
		var nearest := start if start.is_equal_approx(finish) else Geometry3D.get_closest_point_to_segment(target, start, finish)
		if nearest.distance_squared_to(target) > 4.0: continue
		collected_stars.append(id)
		star_chime.play()
		star_markers.erase(id)
		marker.hide()
		marker.queue_free()
		_save_preferences()
		_refresh_ui()

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
	_build_west_district()
	add_child(suburban_villas)
	suburban_villas.build(self)
	add_child(dax)
	dax.build(self)
	_build_city_wall()
	_build_waterfront()
	_build_trees()
	_build_new_blocks()
	var street_parking := preload("res://environment/street_parking.gd").new()
	add_child(street_parking)
	street_parking.build(self)
	add_child(shops)
	_build_ambulance()
	_build_traffic()
	_build_pedestrians()
	_build_depot()
	_plant_park_edges()
	_build_target_marker()
	_build_camera()
	add_child(tram)
	helicopter = preload("res://vehicles/polishelikopter.glb").instantiate()
	add_child(helicopter)
	main_rotor = helicopter.find_child("MainRotor",true,false)
	tail_rotor = helicopter.find_child("TailRotor",true,false)
	add_child(medical_helicopter)
	medical_helicopter.configure(HOSPITAL_HELIPAD)
	_update_patrol(0)
	add_child(street_signals)
	practice_signal_lamps = street_signals.add_practice_head(Vector3(PRACTICE_SIGNAL_X,0,PRACTICE_STOP_LANE_Z-3.1))
	_set_practice_signal(0)
	_build_lampposts()
	_update_daylight(0)

func _build_city_wall() -> void:
	var wall := Node3D.new()
	wall.name = "CityPerimeter"
	add_child(wall)
	var stone := _noise_material(Color("#706e67"), Color("#a09b8c"), 1.1, .13)
	var middle := CITY_INTERIOR.get_center()
	for along_x in [true, false]:
		var length := CITY_INTERIOR.size.x if along_x else CITY_INTERIOR.size.y
		var half_depth := CITY_INTERIOR.size.y * .5 if along_x else CITY_INTERIOR.size.x * .5
		var tangent := Vector3.RIGHT if along_x else Vector3.BACK
		var normal := Vector3.BACK if along_x else Vector3.RIGHT
		for side in [-1, 1]:
			# Overlap the four corners and extend the foundation below the canal.
			var center: Vector3 = Vector3(middle.x,0,middle.y) + normal * side * (half_depth + .3)
			var size := tangent * (length + 1.2) + normal * .6
			var masonry := _make_box("Granitmur", size + Vector3.UP * 3.8, center + Vector3.UP * .4, Color.WHITE, true, wall)
			masonry.material_override = stone
			_make_box("Avtäckning", size + normal * .08 + Vector3.UP * .13, center + Vector3.UP * 2.365, Color("#a6a293"), false, wall)

func _build_road_network() -> void:
	marking_finish = _noise_material(Color("#ededed"), Color.WHITE, 2.3, .12)
	marking_finish.set_shader_parameter("road_paint", true)
	road_finish = _noise_material(Color("#111213"), Color("#27292b"), 4.0, .15)
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
				middle + edge * side * 3.85 + Vector3.UP * 0.015, Color("#e0dfda")).material_override = marking_finish
		for distance in range(12, int(end_distance) - 1, 6):
			if street_signals.CENTRAL_BOULEVARD_CROSSINGS.has(direction.x * distance):
				continue
			_make_box("Road marking", direction.abs() * 3.0 + edge.abs() * 0.15 + Vector3.UP * 0.025,
				direction * distance, Color("#e0dfda")).material_override = marking_finish
	# Crossings align with the pedestrians' east-west route.
	for z in [-6.35, 6.35]:
		for x in range(-4, 5):
			_make_box("Crosswalk", Vector3(0.50, 0.025, 2.1), Vector3(x, 0.016, z), Color("#eee9d9")).material_override = marking_finish

const EQUIPMENT_YARD := Rect2(-123,39,30,16)

func _build_west_district() -> void:
	var yard_center := EQUIPMENT_YARD.get_center()
	var yard := Vector3(yard_center.x,-.16,yard_center.y)
	var extent := EQUIPMENT_YARD.size
	_make_driving_surface("Equipment yard", Vector3(extent.x,.12,extent.y), yard, Color("#898378"))
	var line_width := .14
	var paint := Color("#f4ca59")
	for side in [-1, 1]:
		_make_box("Yard edge marking", Vector3(extent.x,.012,line_width), yard + Vector3(0,.068,side*(extent.y-line_width)/2), paint)
		_make_box("Yard edge marking", Vector3(line_width,.012,extent.y-2*line_width), yard + Vector3(side*(extent.x-line_width)/2,.068,0), paint)
	excavator = preload("res://vehicles/volvo_ec950f.glb").instantiate()
	excavator.position = yard + Vector3(-7,.06,-4)
	excavator.rotation.y = PI*.5
	add_child(excavator)
	_rig_excavator()
	excavator_turn_signals.fit(excavator, excavator, AABB(Vector3(-1.93, 0, -2.75), Vector3(3.86, 3.8, 5.5)))
	add_child(excavation_sand)
	excavation_sand.setup(self,bucket_joint,yard)
	excavator_wall = building_bounds.size()
	building_bounds.append(_crawler_bounds())
	var truck := preload("res://vehicles/food_truck.glb").instantiate() as Node3D
	var layby := Vector3(-85,-.16,44)
	_make_driving_surface("Food truck layby",Vector3(10,.12,8),layby,Color("#928779"))
	truck.position = layby + Vector3.UP*.06
	truck.rotation.y = PI*.5
	add_child(truck)
	# The raised hatch overhangs the pavement above head height.
	for local_box in [
		AABB(Vector3(-1.12,0,-3.40), Vector3(2.24,3.19,6.65)),
		AABB(Vector3(1.11,1.20,-3.13), Vector3(.29,.08,3.88)),
		AABB(Vector3(1.10,2.65,-3.17), Vector3(1.16,.23,3.96)),
	]:
		building_bounds.append(truck.global_transform * local_box)
	# The model carries the chalk illustrations and their prices in the centre.
	for board in [["BURGERS", .35], ["SODA", -2.70]]:
		var heading := _station_sign("MENU", Vector3(1.18, 2.55, board[1]), .0017, Color("#fff6df"), PI / 2, truck)
		var caption := _station_sign(board[0], Vector3(1.18, 1.59, board[1]), .0017, Color("#fff6df"), PI / 2, truck)
		_size_world_sign(heading, .48)
		_size_world_sign(caption, .48)
	var kitchen_lens := _material(Color("#fff0ce"), .35, true)
	for station_z in [-.55, -1.92]:
		var fixture := _make_box("Arbetsljus i köket", Vector3(.11,.035,.61), Vector3(.08,2.78,station_z),Color.WHITE,false,truck)
		fixture.material_override = kitchen_lens
		var work_light := SpotLight3D.new()
		truck.add_child(work_light)
		work_light.position = fixture.position - Vector3.UP*.04
		work_light.rotation_degrees.x = -90
		work_light.spot_range = 2.8
		work_light.spot_angle = 66
		work_light.light_color = Color("#ffe8c2")
		work_light.light_energy = 2.2
		work_light.distance_fade_enabled = true
		work_light.distance_fade_begin = 18
	for hatch_z in [-.04, -1.20, -2.36]:
		var counter_light := SpotLight3D.new()
		truck.add_child(counter_light)
		counter_light.position = Vector3(1.54, 2.62, hatch_z)
		counter_light.look_at(truck.to_global(Vector3(1.12, 1.24, hatch_z)), Vector3.UP)
		counter_light.light_color = Color("#ffdfaa")
		counter_light.light_energy = 1.4
		counter_light.spot_angle = 36
		counter_light.spot_range = 2.2
		counter_light.distance_fade_enabled = true
		counter_light.distance_fade_begin = 18
	var junction_x := PackedInt32Array([-510,-420,-330,-240,-150,-55])
	var junction_z := PackedInt32Array([-48,0,35])
	var strokes: Array[Transform3D] = []
	for z in junction_z:
		for i in range(1,junction_x.size()):
			var block_length := junction_x[i] - junction_x[i-1]
			var block_center := (junction_x[i] + junction_x[i-1]) * .5
			var median := z != 0 and block_center > tram.WEST and block_center < tram.EAST
			var paving_offset := 9.8 if median else 6.2
			if median:
				_make_driving_surface("Tram avenue", Vector3(block_length,.12,16.8),Vector3(block_center,-.078,z), Color.WHITE).material_override = road_finish
			for side in [-1,1]:
				if z == 35 and side == 1 and dax.LOCATION.x > junction_x[i-1] and dax.LOCATION.x < junction_x[i]:
					var west := dax.LOCATION.x - dax.LANE_OFFSET
					var east := dax.LOCATION.x + dax.LANE_OFFSET
					var half_lane := dax.LANE_WIDTH * .5
					for span: Vector2 in [Vector2(junction_x[i-1]+4.8, west-half_lane), Vector2(west+half_lane, east-half_lane), Vector2(east+half_lane, junction_x[i]-4.8)]:
						_make_driving_surface("Dax pavement", Vector3(span.y-span.x,.12,2.8), Vector3((span.x+span.y)*.5,.005,z+paving_offset), Color.WHITE).material_override = sidewalk_finish
					continue
				if z == 0 and side == 1 and STATION_DROP.x > junction_x[i-1] and STATION_DROP.x < junction_x[i]:
					var entry_left := STATION_DROP.x - 3.0
					var entry_right := STATION_DROP.x + 3.0
					for span: Vector2 in [Vector2(junction_x[i-1]+4.8, entry_left), Vector2(entry_right, junction_x[i]-4.8)]:
						_make_driving_surface("Station pavement", Vector3(span.y-span.x,.12,2.8), Vector3((span.x+span.y)*.5,.005,paving_offset), Color.WHITE).material_override = sidewalk_finish
					_make_driving_surface("Station driveway", Vector3(6,.12,2.8), Vector3(STATION_DROP.x,-.075,paving_offset), Color.WHITE).material_override = road_finish
					continue
				var sidewalk := _make_driving_surface("West sidewalk", Vector3(block_length-9.6,.12,2.8), Vector3(block_center,.005,z+side*paving_offset), Color.WHITE)
				sidewalk.material_override = sidewalk_finish
			if median: continue
			for x in range(junction_x[i-1]+9,junction_x[i]-7,6):
				strokes.append(Transform3D(Basis.IDENTITY,Vector3(x,-.009,z)))
	for i in junction_x.size():
		for j in range(1,junction_z.size()):
			var block_depth := junction_z[j] - junction_z[j-1]
			var middle_z := (junction_z[j] + junction_z[j-1]) * .5
			var median := junction_x[i] == tram.WEST or junction_x[i] == tram.EAST
			var paving_offset := 9.8 if median else 6.2
			if median:
				_make_driving_surface("Tram cross street", Vector3(16.8,.12,block_depth),Vector3(junction_x[i],-.077,middle_z), Color.WHITE).material_override = road_finish
			for side in [-1,1]:
				if i == junction_x.size()-1 and side == 1: continue
				# End at the inside edge of the adjoining pavement to keep the corner flush.
				var sidewalk := _make_driving_surface("West side street pavement", Vector3(2.8,.12,block_depth-15.2), Vector3(junction_x[i]+side*paving_offset,.005,middle_z), Color.WHITE)
				sidewalk.material_override = sidewalk_finish
			if i == junction_x.size()-1 or median: continue
			for z in range(junction_z[j-1]+9,junction_z[j]-7,6):
				strokes.append(Transform3D(Basis(Vector3.UP,PI/2),Vector3(junction_x[i],-.009,z)))
	var stripe := BoxMesh.new()
	stripe.size = Vector3(3,.006,.15)
	stripe.material = marking_finish
	var markings := MultiMeshInstance3D.new()
	markings.name = "WestLaneMarkings"
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markings.multimesh = MultiMesh.new()
	markings.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	markings.multimesh.mesh = stripe
	markings.multimesh.instance_count = strokes.size()
	for i in strokes.size():
		markings.multimesh.set_instance_transform(i,strokes[i])
	add_child(markings)
	_build_practice_yard()
	_make_driving_surface("West district ground", Vector3(460,.3,CITY_INTERIOR.size.y), Vector3(-290,-.35,CITY_INTERIOR.get_center().y), Color.WHITE).material_override = soil_finish
	for z in junction_z:
		_make_driving_surface("West avenue", Vector3(455,.12,9.6), Vector3(-282.5,-.08,z), Color.WHITE).material_override = road_finish
	for i in junction_x.size()-1:
		var x := junction_x[i]
		_make_driving_surface("Connecting street", Vector3(9.6,.12,92.6), Vector3(x,-.075,-6.5), Color.WHITE).material_override = road_finish
		for z in [-24,17]:
			for offset in [20,62]:
				var center := Vector3(x+offset,0,z)
				if x == -150 and offset == 20 and z == 17:
					_build_petrol_station(center)
					continue
				var buildings := [preload("res://environment/bageri.glb"), preload("res://environment/bibliotek.glb"), preload("res://environment/vardcentral.glb")]
				var home := buildings[posmod(x / 90 + offset + z, buildings.size())].instantiate() as Node3D
				home.position = center
				home.rotation.y = PI if z > 0 else 0.0
				add_child(home)
				_localize_building_sign(home)
				var bounds: AABB = home.global_transform * _model_bounds(home,home)
				building_bounds.append(bounds.expand(Vector3(center.x,-1,center.z)))
				_make_tree(center+Vector3(11,0,5),1.0)

# Fixed game prices in hundredths of the local currency per litre.
const FUEL_TARIFFS := {
	"SEK": {"95":1790, "98":1890, "D":1750},
	"NOK": {"95":1990, "98":2090, "D":1950},
	"EUR": {"95":169, "98":179, "D":165},
	"GBP": {"95":145, "98":155, "D":149}
}
const FUEL_CURRENCIES := {"sv":"SEK", "nb":"NOK", "de":"EUR", "es":"EUR", "fi":"EUR", "fr":"EUR", "en":"GBP"}

func _station_readout_text(key: String) -> String:
	var currency: String = FUEL_CURRENCIES.get(TranslationServer.get_locale().get_slice("_",0), "GBP")
	var decimal := tr(".", "decimal separator")
	if key == "volume": return "0" + decimal + "00 L"
	var grade := key.get_slice("_",1)
	var cents: int = FUEL_TARIFFS[currency].get(grade,0)
	var amount := ("%.2f" % (cents / 100.0)).replace(".",decimal)
	match currency:
		"EUR": amount += " €"
		"GBP": amount = "£" + amount
		_: amount += " kr"
	if key == "total": return amount
	if key.begins_with("tower_"): return grade + "    " + amount
	return amount + "/L"

func _station_sign(words: String, at: Vector3, size: float, tint: Color, yaw := PI, parent: Node3D = self, numeric_readout := false) -> Label3D:
	var sign_text := Label3D.new()
	sign_text.text = words
	sign_text.font_size = 64
	sign_text.pixel_size = size
	sign_text.outline_size = 0
	sign_text.modulate = tint
	sign_text.position = at
	sign_text.rotation.y = yaw
	parent.add_child(sign_text)
	if numeric_readout:
		station_readouts[sign_text] = words
		sign_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		sign_text.text = _station_readout_text(words)
	return sign_text

func _size_world_sign(label: Label3D, available_width: float) -> void:
	label.add_to_group("fitted_world_signs")
	label.set_meta("design_pixel_size", label.pixel_size)
	label.set_meta("available_width", available_width)
	_fit_world_sign(label)

func _fit_world_sign(label: Label3D) -> void:
	var font := label.font if label.font else ThemeDB.fallback_font
	var width := font.get_string_size(label.atr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
	label.pixel_size = minf(label.get_meta("design_pixel_size"), float(label.get_meta("available_width")) / maxf(width, 1.0))


func _tube_between(parent: Node3D, start: Vector3, end: Vector3, radius: float, finish: StandardMaterial3D) -> void:
	var tube := CylinderMesh.new()
	tube.top_radius = radius
	tube.bottom_radius = radius
	tube.radial_segments = 10
	tube.rings = 0
	var axis := end-start
	tube.height = axis.length()+.006
	var part := MeshInstance3D.new()
	part.mesh = tube
	part.material_override = finish
	part.position = (start+end)*.5
	part.quaternion = Quaternion(Vector3.UP,axis.normalized())
	parent.add_child(part)

func _pump_hose_with_sag(sag: float) -> Mesh:
	var original := preload("res://environment/pump_hose.obj")
	if is_zero_approx(sag):
		return original
	var arrays := original.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# Blend into the free loop below both couplings, leaving the fittings aligned.
	for i in vertices.size():
		var depth := clampf((.65 - vertices[i].y) / .42, 0, 1)
		vertices[i].y -= sag * smoothstep(0, 1, depth)
		normals[i].y /= 1.0 + sag * 6.0 * depth * (1.0 - depth) / .42
		normals[i] = normals[i].normalized()
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_pump_nozzle(face: Node3D, hose_mesh: Mesh, grip: StandardMaterial3D, rubber: StandardMaterial3D, steel: StandardMaterial3D, graphite: Color) -> void:
	_make_box("Holster back",Vector3(.018,.37,.205),Vector3(.31,1.16,-.14),Color("#182024"),false,face)
	for lip_z: float in [-.246,-.034]:
		_make_box("Holster side lip",Vector3(.10,.37,.022),Vector3(.366,1.16,lip_z),graphite,false,face)
	_make_box("Holster ledge",Vector3(.10,.024,.23),Vector3(.366,.975,-.14),graphite,false,face)
	var hose := MeshInstance3D.new()
	hose.mesh = hose_mesh
	hose.material_override = rubber
	face.add_child(hose)
	# The rising hose crosses the front panel obliquely.
	var outlet := Vector3(.418,.780,-.025)
	_make_box("Hose outlet plate", Vector3(.012,.19,.09), outlet, graphite, false, face)
	_tube_between(face, outlet, Vector3(.440,.713,-.024), .033, steel)
	_tube_between(face, Vector3(.440,.713,-.024), Vector3(.452,.666,-.023), .029, rubber)
	var heel := Vector3(.45,1.01,-.10)
	var inlet_axis := heel.direction_to(Vector3(.50,.36,-.12))
	_tube_between(face, heel, heel + inlet_axis*.049, .034, steel)
	for rib in 4:
		var sleeve_start := heel + inlet_axis*(.055 + rib*.014)
		_tube_between(face, sleeve_start, sleeve_start + inlet_axis*.007, .030-rib*.001, rubber)
	var head := Vector3(.395,1.23,-.16)
	_tube_between(face,heel,head,.043,grip)
	var hood := MeshInstance3D.new()
	var head_shell := SphereMesh.new()
	head_shell.radius = .061
	head_shell.height = .135
	head_shell.radial_segments = 16
	head_shell.rings = 8
	hood.mesh = head_shell
	hood.material_override = grip
	hood.position = head
	hood.quaternion = Quaternion(Vector3.UP, heel.direction_to(head))
	face.add_child(hood)
	_tube_between(face, head + Vector3.RIGHT*.048, head + Vector3.RIGHT*.061, .025, steel)
	var guard := Vector3(.413,1.07,-.24)
	_tube_between(face,heel,guard,.014,rubber)
	_tube_between(face,guard,head,.014,rubber)
	var elbow := Vector3(.385,1.30,-.16)
	_tube_between(face,head,elbow,.024,steel)
	var socket := Vector3(.318,1.32,-.16)
	var collar := TorusMesh.new()
	collar.inner_radius = .025
	collar.outer_radius = .046
	collar.rings = 16
	collar.ring_segments = 6
	var rim := MeshInstance3D.new()
	rim.mesh = collar
	rim.material_override = steel
	rim.position = socket
	rim.rotation.z = PI*.5
	face.add_child(rim)
	_tube_between(face,elbow,socket,.021,steel)
	_tube_between(face,head.lerp(guard,.22),guard.lerp(heel,.52),.009,steel)

func _update_vehicle_dirt(pos: Vector3, previous: Vector3, delta: float) -> void:
	var before := float(vehicle_dirt.get(vehicle_index,0.0))
	var after := before
	if absf(pos.x-wash_center.x) < 1.75 and absf(pos.z-wash_center.z) < 3.7 and absf(speed) < .5:
		after = maxf(0,before-delta*.22)
		if before > 0:
			for jet in wash_jets:
				if not jet.emitting: jet.restart()
	elif pos.y < -.15 and weather.wet > .1 and weather.snow < .2:
		after = minf(1,before+pos.distance_to(previous)*weather.wet*.035)
	if after > 0:
		mud_finish.set_shader_parameter("ground_height",pos.y)
	if before == after: return
	vehicle_dirt[vehicle_index] = after
	mud_finish.set_shader_parameter("dirt",after)
	if before == 0 or after == 0:
		_show_mud(after > 0)

func _show_mud(visible_mud: bool) -> void:
	for entry in muddy_parts:
		entry.part.set_surface_override_material(entry.surface,entry.coat if visible_mud else entry.original)

func _build_petrol_station(center: Vector3) -> void:
	wash_center = center + Vector3(-11.8,0,1.8)
	var drop := SphereMesh.new()
	drop.radius = .014
	drop.height = .028
	drop.radial_segments = 6
	drop.rings = 2
	drop.material = _material(Color("#b0e2f1"),.16)
	for side in [-1,1]:
		var edge := wash_center + Vector3(side*1.95,0,0)
		_make_box("Wash lane stripe",Vector3(.12,.025,7.4),edge,Color("#69cee1"))
		_make_roadside_solid("Wash spray column",Vector3(.24,2.15,.36),edge+Vector3.UP*1.075,Color("#256678"))
		for height: float in [.42,1.05,1.75]:
			_make_box("Wash jet nozzle",Vector3(.12,.09,.12),edge+Vector3(-side*.15,height,0),Color("#b7d8db"))
			var jet := CPUParticles3D.new()
			jet.emitting = false
			jet.one_shot = true
			jet.amount = 32
			jet.lifetime = .38
			jet.mesh = drop
			jet.direction = Vector3(-side,.04,0)
			jet.spread = 13
			jet.gravity = Vector3.DOWN*4
			jet.initial_velocity_min = 3.5
			jet.initial_velocity_max = 4.8
			add_child(jet)
			jet.position = edge + Vector3(-side*.23,height,0)
			wash_jets.append(jet)
	var gold := Color("#f6b82c")
	var cream := Color("#fffae6")
	var graphite := Color("#354246")
	var steel := _material(Color("#c7ced0"), .27, false, "brushed")
	steel.metallic = .82
	meter_backlight = _material(Color("#b5c9b4"), .35, true)
	var rubber := _material(Color("#242829"), .84, false, "rubber")
	var stucco := _material(cream, .91, false, "mineral")
	var concrete := _material(Color("#a9aa9e"), .93, false, "mineral")
	var enamel := _material(cream, .32, false, "paint")
	var gold_enamel := _material(gold, .34, false, "paint")
	var hoses := [_pump_hose_with_sag(.055), _pump_hose_with_sag(-.04), _pump_hose_with_sag(0)]
	var grip_finishes := {
		"D": _material(Color("#303338"), .42),
		"95": _material(Color("#188654"), .42),
		"98": _material(Color("#b53b29"), .42)
	}
	_make_driving_surface("Station forecourt", Vector3(27,.12,23), center+Vector3(0,-.08,-1.5), Color("#616567")).material_override = road_finish
	_make_box("Canopy underside",Vector3(16,.22,9),center+Vector3(-2,4.45,-3),cream).material_override = enamel
	_make_box("Golden fascia",Vector3(16.15,.46,9.15),center+Vector3(-2,4.73,-3),gold).material_override = gold_enamel
	_make_box("Roof flashing",Vector3(16.24,.09,9.24),center+Vector3(-2,5,-3),cream).material_override = enamel
	for yaw: float in [PI,0.0,PI*.5,-PI*.5]:
		var outward := Vector3.BACK.rotated(Vector3.UP,yaw)
		var sign_center := center+Vector3(-2,5.70,-3)+outward*(7.55 if absf(outward.x)>.5 else 4.06)
		var plaque := _make_box("Roof nameboard",Vector3(5.25,.93,.14),sign_center,Color("#802930"))
		plaque.rotation.y=yaw
		for x: float in [-1.85,1.85]:
			_make_box("Sign bracket",Vector3(.11,.28,.11),sign_center+Vector3(x,-.59,0).rotated(Vector3.UP,yaw),graphite)
		_size_world_sign(_station_sign("HARBOR FUEL",sign_center+outward*.082,.010,cream,yaw), 4.98)
	const GRADES := ["95", "D", "98", "95"]
	var tower := center+Vector3(-11.8,0,-8)
	_make_roadside_solid("Price tower",Vector3(.45,6.4,1.85),tower+Vector3.UP*3.2,graphite)
	tower_lightbox = _material(gold,.48,true)
	_make_box("Tower crown",Vector3(.51,1.18,1.97),tower+Vector3.UP*5.87,gold).material_override = tower_lightbox
	for side: float in [-1.0,1.0]:
		var yaw := side*PI*.5
		_size_world_sign(_station_sign("HARBOR FUEL",tower+Vector3(side*.27,5.87,0),.0038,graphite,yaw), 1.85)
		var listings := ["tower_95", "tower_98", "tower_D", "24 h"]
		for row in listings.size():
			var panel := tower+Vector3(side*.24,4.84-row*.62,0)
			_make_box("Tariff panel",Vector3(.035,.51,1.73),panel,Color("#172327"))
			_size_world_sign(_station_sign(listings[row],panel+Vector3(side*.024,0,0),.004,cream,yaw,self,row < 3),1.65)
		var poster := Node3D.new()
		poster.position = tower + Vector3(side*.25,1.73,0)
		poster.rotation.y = yaw
		add_child(poster)
		var panel := _make_box("Rocket ice lightbox",Vector3(1.61,1.58,.042),Vector3.ZERO,gold,false,poster)
		panel.material_override = tower_lightbox
		_size_world_sign(_station_sign("ROCKET ICE",Vector3(0,-.48,.03),.0034,graphite,0,poster), 1.49)
		_make_box("Ice stick",Vector3(.08,.24,.03),Vector3(0,-.18,.05),cream,false,poster)
		var rocket := CSGPolygon3D.new()
		rocket.polygon = PackedVector2Array([Vector2(-.22,-.13),Vector2(.22,-.13),Vector2(.22,.27),Vector2(.17,.39),Vector2(0,.61),Vector2(-.17,.39),Vector2(-.22,.27)])
		rocket.depth = .025
		rocket.position.z = .074
		rocket.material = _material(Color("#16737b"),.5)
		poster.add_child(rocket)
		_make_box("Ice cream stripe",Vector3(.44,.085,.016),Vector3(0,.20,.083),cream,false,poster)
		for fin_side: float in [-1,1]:
			var fin := _make_box("Rocket fin",Vector3(.11,.27,.04),Vector3(fin_side*.19,.01,.05),Color("#ad3640"),false,poster)
			fin.rotation.z = -fin_side*.43
	for x in [-7,3]:
		var island := center+Vector3(x,0,-3)
		_make_roadside_solid("Pump island",Vector3(1.45,.18,5.5),island+Vector3.UP*.08,Color("#a9aa9e")).material_override = concrete
		_make_roadside_solid("Canopy column",Vector3(.48,4.4,.54),island+Vector3.UP*2.2,gold).material_override = gold_enamel
		_make_box("Column impact guard",Vector3(.54,.64,.60),island+Vector3.UP*.50,graphite)
		_make_box("Column reflector",Vector3(.50,.12,.56),island+Vector3.UP*1.43,cream)
		for z in [-1.65,1.65]:
			var pump := Node3D.new()
			pump.name = "Pump"
			pump.position = island+Vector3(0,.17,z+.44)
			pump.rotation.y = PI*.5
			add_child(pump)
			var cabinet := _make_roadside_solid("Fuel dispenser",Vector3(.83,1.65,.67),Vector3.UP*.825,cream,false,pump)
			cabinet.mesh = preload("res://environment/pump_shell.obj")
			_make_roadside_solid("Rack base panel",Vector3(.89,.95,.67),Vector3(.865,.475,0),cream,false,pump)
			var fascia := CSGPolygon3D.new()
			fascia.name = "Rack upper fascia"
			var outline := PackedVector2Array()
			var crown_radius := .045
			for corner in [Vector2(.445,1.65), Vector2(-.445,1.65)]:
				var arc_center: Vector2 = corner - Vector2(signf(corner.x),1)*crown_radius
				var start_angle := 0.0 if corner.x > 0 else PI*.5
				for segment in 6:
					outline.append(arc_center + Vector2.RIGHT.rotated(start_angle + segment*PI/10)*crown_radius)
			outline.append(Vector2(-.445,1.36))
			outline.append(Vector2(.445,1.36))
			fascia.polygon = outline
			fascia.depth = .67
			fascia.position = Vector3(.865,0,.335)
			fascia.material = enamel
			pump.add_child(fascia)
			_make_box("Recess backing",Vector3(.89,.41,.38),Vector3(.865,1.155,0),graphite,false,pump)
			for edge in 4:
				_make_box("Rack upright",Vector3(.024,.41,.67),Vector3(.43+edge*.29,1.155,0),cream,false,pump)
			_make_box("Rack plinth",Vector3(.91,.38,.70),Vector3(.865,.19,0),graphite,false,pump)
			for side in [-1,1]:
				_make_box("Cabinet side cover",Vector3(.012,.43,.27),Vector3(side*.415,1.16,-side*.14),cream,false,pump)
			var number_plate := Vector3(0,1.80,0)
			var number_housing := CSGPolygon3D.new()
			number_housing.name = "Pump number"
			var rounded_plate := PackedVector2Array()
			for corner_index in 4:
				var angle := corner_index * PI / 2.0
				var diagonal := Vector2.from_angle(angle + PI / 4.0)
				var corner_center := Vector2(signf(diagonal.x) * .155, signf(diagonal.y) * .125)
				for segment in 5:
					rounded_plate.append(corner_center + Vector2.from_angle(angle + segment * PI / 8.0) * .025)
			number_housing.polygon = rounded_plate
			number_housing.depth = .22
			number_housing.position = number_plate + Vector3.BACK * .11
			number_housing.material = enamel
			pump.add_child(number_housing)
			var number := (1 if x < 0 else 3)+(0 if z < 0 else 1)
			var grade: String = GRADES[number-1]
			var grip: Color = grip_finishes[grade].albedo_color
			for yaw: float in [PI,0.0]:
				_station_sign(str(number),number_plate+Vector3.BACK.rotated(Vector3.UP,yaw)*.113,.0045,graphite,yaw,pump)
			_make_box("Pump plinth",Vector3(.86,.38,.70),Vector3.UP*.19,graphite,false,pump)
			for face_yaw: float in [0.0,PI]:
				var face := Node3D.new()
				face.rotation.y = face_yaw
				pump.add_child(face)
				_make_box("Service panel gasket",Vector3(.72,1.10,.012),Vector3(0,.97,-.337),graphite,false,face)
				_make_box("Service panel enamel",Vector3(.705,1.085,.014),Vector3(0,.97,-.343),cream,false,face).material_override = enamel
				_make_box("Lower access panel",Vector3(.705,.30,.008),Vector3(0,.58,-.354),gold,false,face).material_override = gold_enamel
				for fastener_x in [-.315,.315]:
					for fastener_y in [.46,.70]:
						var fixing := Vector3(fastener_x,fastener_y,-.358)
						_tube_between(face, fixing, fixing + Vector3.FORWARD*.005, .011, steel)
				var lcd_ink := Color("#203230")
				_make_box("Meter bezel",Vector3(.66,.42,.035),Vector3(0,1.30,-.354),graphite,false,face)
				_make_box("Transaction LCD",Vector3(.60,.19,.012),Vector3(0,1.394,-.375),meter_backlight.albedo_color,false,face).material_override = meter_backlight
				_station_sign("total",Vector3(0,1.438,-.384),.00125,lcd_ink,PI,face,true)
				_station_sign("volume",Vector3(0,1.352,-.384),.00125,lcd_ink,PI,face,true)
				_make_box("Unit price LCD",Vector3(.60,.14,.012),Vector3(0,1.194,-.375),Color("#21353a"),false,face)
				_station_sign("unit_" + grade,Vector3(0,1.194,-.384),.00175,Color("#b5f2cc"),PI,face,true)
				_make_box("Fuel grade badge",Vector3(.25,.28,.02),Vector3(-.19,.92,-.35),grip,false,face)
				_station_sign(grade,Vector3(-.19,.966,-.363),.0018,cream,PI,face)
				var fuel_name := "Diesel" if grade == "D" else "Petrol"
				var fuel_label := _station_sign(fuel_name,Vector3(-.19,.855,-.363),.00068,cream,PI,face)
				_size_world_sign(fuel_label, .23)
				var latch := Vector3(.23,.61,-.36)
				_tube_between(face, latch, latch + Vector3.FORWARD*.012, .026, steel)
				_make_box("Service lock keyway",Vector3(.005,.023,.004),latch+Vector3.FORWARD*.014,graphite,false,face)
				for slot in 6:
					_make_box("Vent slot",Vector3(.18,.010,.008),Vector3(-.18,.68-slot*.028,-.360),graphite,false,face)
				_make_box("Card reader",Vector3(.23,.29,.036),Vector3(.18,.91,-.35),graphite,false,face)
				_make_box("Reader screen",Vector3(.17,.044,.009),Vector3(.18,1.022,-.373),Color("#90bba5"),false,face)
				_make_box("Card slot surround",Vector3(.16,.032,.027),Vector3(.18,.79,-.376),Color("#88979c"),false,face)
				_make_box("Card opening",Vector3(.135,.011,.005),Vector3(.18,.792,-.391),Color("#101619"),false,face)
				var key_labels := ["1","2","3","4","5","6","7","8","9","×","0","✓"]
				for row in 4:
					for column in 3:
						var symbol: String = key_labels[row*3+column]
						var key_position := Vector3(.24-column*.06,.971-row*.04,-.377)
						var key_color := cream
						if symbol == "×": key_color = Color("#ec7166")
						elif symbol == "✓": key_color = Color("#79c791")
						_make_box("Payment key",Vector3(.049,.034,.012),key_position,key_color,false,face)
						_station_sign(symbol,key_position+Vector3.FORWARD*.008,.00044,graphite,PI,face)
				var rack_x := .865 if face_yaw == 0 else -.865
				var door_center := Vector3(rack_x,.565,-.337)
				_make_box("Hose cabinet seam",Vector3(.85,.345,.009),door_center,graphite,false,face)
				_make_box("Hose cabinet enamel",Vector3(.835,.33,.012),door_center+Vector3.FORWARD*.007,gold,false,face)
				var grades := ["95","98","D"]
				grades.erase(grade)
				grades.push_front(grade)
				for slot in grades.size():
					var fuel: String = grades[slot]
					var slot_x := rack_x + (slot-1)*.29
					var finish: StandardMaterial3D = grip_finishes[fuel]
					_make_box("Grade header",Vector3(.276,.28,.038),Vector3(slot_x,1.49,-.32),finish.albedo_color,false,face)
					_station_sign(fuel,Vector3(slot_x,1.54,-.344),.0018,cream,PI,face)
					var price_at := Vector3(slot_x,1.425,-.344)
					_make_box("Unit price strip",Vector3(.268,.078,.008),price_at,graphite,false,face)
					var price_label := _station_sign("unit_"+fuel,price_at+Vector3.FORWARD*.006,.001,Color.WHITE,PI,face,true)
					_size_world_sign(price_label,.254)
					var holder := Node3D.new()
					holder.position = Vector3(slot_x+.14,0,.083)
					holder.rotation.y = PI*.5
					face.add_child(holder)
					_add_pump_nozzle(holder,hoses[slot],finish,rubber,steel,graphite)
	for x: float in [-8,-2,4]:
		for z: float in [-5.6,-.4]:
			var mount := center+Vector3(x,4.30,z)
			_make_box("Recessed lamp surround",Vector3(.96,.10,.58),mount,graphite)
			var canopy_light := _add_entry_light(mount-Vector3.UP*.065,Vector3(.82,.04,.44),12)
			canopy_light.spot_angle = 65
			canopy_light.spot_attenuation = .55
			canopy_light.light_color = Color("#fff2dc")
	# Four flush strips follow the fascia and dim with the canopy lamps.
	for sign_side: float in [-1.0, 1.0]:
		var long_strip := _make_box("Canopy light strip", Vector3(16.16,.07,.025), center+Vector3(-2,4.56,-3+sign_side*4.58), cream)
		var end_strip := _make_box("Canopy end light strip", Vector3(.025,.07,9.16), center+Vector3(-2+sign_side*8.08,4.56,-3), cream)
		long_strip.material_override = entrance_diffuser
		end_strip.material_override = entrance_diffuser
	var kiosk := center+Vector3(-3,0,6)
	var shell := Vector3(12,3.2,4.4)
	building_bounds.append(AABB(kiosk+Vector3(-6,-1,-2.2),shell+Vector3.UP))
	_make_box("Shop back wall",Vector3(12,3.2,.16),kiosk+Vector3(0,1.6,2.12),cream).material_override = stucco
	for side in [-1,1]:
		_make_box("Shop end wall",Vector3(.18,3.2,4.4),kiosk+Vector3(side*5.91,1.6,0),cream).material_override = stucco
	_make_box("Shop tile floor",Vector3(12,.12,4.4),kiosk+Vector3.UP*.06,Color("#aca89b"))
	_make_box("Shop ceiling",Vector3(12,.15,4.4),kiosk+Vector3.UP*3.02,cream)
	_make_box("Window header",Vector3(12,.52,.2),kiosk+Vector3(0,2.75,-2.11),cream).material_override = stucco
	var glazing := _material(Color(.56,.75,.79,.20),.16)
	glazing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for span: Vector2 in [Vector2(-6,-4.95),Vector2(-2.65,-2.35),Vector2(-.05,.55),Vector2(1.69,2.25),Vector2(4.55,6)]:
		_make_box("Facade pier",Vector3(span.y-span.x,2.51,.2),kiosk+Vector3(span.x+span.y,2.51,-4.22)*.5,cream).material_override = stucco
	for x in [-3.8,-1.2,3.4]:
		_make_box("Spandrel",Vector3(2.3,.95,.20),kiosk+Vector3(x,.475,-2.11),cream).material_override = stucco
		_make_box("Window sill",Vector3(2.5,.10,.23),kiosk+Vector3(x,.94,-2.23),graphite)
		var pane := _make_box("Shop glazing",Vector3(2.30,1.55,.025),kiosk+Vector3(x,1.73,-2.12),cream)
		pane.material_override = glazing
		for offset in [-1.12,1.12]:
			_make_box("Glazing jamb",Vector3(.052,1.59,.08),kiosk+Vector3(x+offset,1.72,-2.14),graphite)
	var posters := [
		[-3.8,"DISCO RINGS","Oops! One danced away!",Color("#534077"),Color("#ffcd60")],
		[-1.2,"ROCKET ICE","3, 2, 1 ... brain freeze!",Color("#126264"),Color("#ffc193")],
		[3.4,"HOT DOG YOGA","Breathe in. Ketchup out.",Color("#932c37"),Color("#ffe079")]
	]
	for ad in posters:
		var at := kiosk+Vector3(ad[0],1.82,-2.155)
		_make_box("Window poster",Vector3(1.42,.97,.016),at,ad[3])
		var ink: Color = ad[4]
		var headline := _station_sign(ad[1],at+Vector3(0,.31,-.018),.0026,Color.WHITE)
		var slogan := _station_sign(ad[2],at+Vector3(0,-.32,-.018),.00155,Color.WHITE)
		for label: Label3D in [headline, slogan]:
			_size_world_sign(label, 1.32)
		var icon_center := at+Vector3(0,0,-.03)
		if ad[0]==-3.8:
			var ring := MeshInstance3D.new()
			var doughnut := TorusMesh.new()
			doughnut.inner_radius=.078
			doughnut.outer_radius=.168
			ring.mesh=doughnut
			ring.material_override=_material(ink)
			ring.position=icon_center
			ring.rotation.x=PI*.5
			add_child(ring)
			for side: float in [-1.0,1.0]:
				var leg := _make_box("Dancing leg",Vector3(.021,.084,.018),icon_center+Vector3(side*.09,-.15,-.025),ink)
				leg.rotation.z=side*.55
				var shoe := _make_box("Disco shoe",Vector3(.085,.035,.023),icon_center+Vector3(side*.13,-.18,-.03),Color("#ff92bc"))
				shoe.rotation.z=side*.23
				var arm := _make_box("Disco arm",Vector3(.105,.02,.018),icon_center+Vector3(side*.185,side*.07,-.025),ink)
				arm.rotation.z=.58
		elif ad[0]==-1.2:
			_make_box("Ice lolly stick",Vector3(.035,.10,.025),icon_center+Vector3.DOWN*.14,cream)
			var ice := _make_box("Rocket ice",Vector3(.16,.26,.035),icon_center,ink)
			ice.rotation.z=-.13
			for side: float in [-1.0,1.0]:
				var fin := _make_box("Ice rocket fin",Vector3(.055,.099,.025),icon_center+Vector3(side*.088,-.075,-.02),Color("#ff7965"))
				fin.rotation.z=-side*.45
				var trail := _make_box("Rocket exhaust",Vector3(.016,.075,.015),icon_center+Vector3(side*.052,-.162,-.02),gold)
				trail.rotation.z=-side*.14
		else:
			for j in 7:
				var u := (j-3)/3.0
				var dog := _make_box("Curved hot dog",Vector3(.088,.11,.035),icon_center+Vector3(u*.24,u*u*.075,0),ink)
				dog.rotation.z=u*.52
				var ketchup := _make_box("Ketchup zigzag",Vector3(.084,.019,.012),dog.position+Vector3(0,0,-.025),Color("#f33b29"))
				ketchup.rotation.z=dog.rotation.z+(.32 if j%2==0 else -.32)
			_make_box("Yoga mat",Vector3(.64,.035,.018),icon_center+Vector3.DOWN*.12,Color("#83ded0"))
	for x in [-4.9,-2.8]:
		_add_entry_light(kiosk+Vector3(x,2.77,1.14),Vector3(1.78,.035,.10),3.0)
		for level in [1.13,1.58,2.03]:
			_make_box("Grocery shelf",Vector3(1.95,.055,.47),kiosk+Vector3(x,level,1.59),cream)
			for j in 7:
				var tint: Color = [Color("#b34f30"),gold,Color("#438278")][posmod(j+roundi(level*5),3)]
				_make_box("Pantry carton",Vector3(.18,.28,.22),kiosk+Vector3(x+(j-3)*.25,level+.17,1.56),tint)
	_make_box("Checkout plinth",Vector3(2.25,1,.74),kiosk+Vector3(3.1,.57,-.70),graphite)
	_make_box("Checkout countertop",Vector3(2.39,.08,.86),kiosk+Vector3(3.1,1.11,-.70),cream)
	_make_box("Till monitor",Vector3(.48,.34,.10),kiosk+Vector3(2.75,1.32,-.56),graphite)
	_add_entry_light(kiosk+Vector3(3.1,2.87,-.70),Vector3(1.9,.04,.18),3.6)
	_make_box("Door kick plate",Vector3(1.14,.42,.07),kiosk+Vector3(1.12,.23,-2.18),graphite)
	var door_glass := _make_box("Door glazing",Vector3(1.08,2.08,.03),kiosk+Vector3(1.12,1.47,-2.18),cream)
	door_glass.material_override = glazing
	for x in [.58,1.66]:
		_make_box("Door stile",Vector3(.06,2.5,.09),kiosk+Vector3(x,1.25,-2.20),graphite)
	_make_box("Door pull",Vector3(.045,.36,.095),kiosk+Vector3(1.45,1.13,-2.35),cream)
	_make_box("Entrance awning",Vector3(3,.14,1.23),kiosk+Vector3(1.12,2.66,-2.66),gold)
	_add_entry_light(kiosk+Vector3(1.12,2.56,-2.84),Vector3(.86,.035,.16),3.3)
	_make_box("Shop cornice",Vector3(12.25,.27,4.65),kiosk+Vector3.UP*3.18,gold)
	_make_box("Recovery bay stripe",Vector3(5,.012,.09),STATION_PARKING+Vector3(0,.002,1.35),cream)
	var bay_sign := _signpost(STATION_PARKING + Vector3(3.15,0,1.35), PI)
	_make_box("Recovery bay sign",Vector3(2.8,.74,.08),Vector3(0,2.65,.07),graphite,false,bay_sign)
	var bay_label := _road_sign_text(bay_sign,"Tow drop-off",Vector3(0,2.65,.12),.0048,cream)
	bay_label.width = 2.6 / bay_label.pixel_size
	bay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_waterfront() -> void:
	var asphalt := Color("#414648")
	_make_driving_surface("Östra stranden", Vector3(92, 0.3, 174), Vector3(133, -0.35, -6), Color("#859378")).material_override = soil_finish
	var water_center := CANAL_BOUNDS.get_center()
	var canal := _make_box("Sjöstadskanalen",Vector3(CANAL_BOUNDS.size.x,.12,CANAL_BOUNDS.size.y),Vector3(water_center.x,-1.05,water_center.y),Color("#376675"))
	var water := Shader.new()
	water.code = """
	shader_type spatial;
	uniform float rain = 0.0;
	uniform vec4 bridge_limits;
	uniform vec2 bridge_rises;
	uniform vec3 ferry_center;
	uniform vec4 mooring_layout;
	uniform float mooring_tops[7];
	uniform float ferry_motion;
	uniform vec2 wake_origin;
	uniform vec2 wake_heading;
	uniform float wake_strength;
	uniform vec3 quay_lamps[16];
	uniform int quay_lamp_count;
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
		vec2 trail = p-wake_origin;
		float aft = -dot(trail,wake_heading);
		float across = abs(dot(trail,vec2(-wake_heading.y,wake_heading.x)));
		float edge = across-.43-max(aft,0.)*.23+.12*chop;
		float crests = exp(-edge*edge*7.) + .48*exp(-across*across*2.);
		float foam = wake_strength*smoothstep(-.3,.5,aft)*(1.-smoothstep(1.,3.+8.*wake_strength,aft))*crests;
		float ferry_aft = (ferry_center.z-p.y)*sign(ferry_motion)-6.4;
		float ferry_edge = abs(p.x-ferry_center.x)-1.1-max(ferry_aft,0.)*.24+.13*chop;
		float ferry_foam = abs(ferry_motion)*smoothstep(-.25,.4,ferry_aft)
			*(1.-smoothstep(1.,9.,ferry_aft))*exp(-ferry_edge*ferry_edge*3.);
		foam = max(foam,ferry_foam);
		ALBEDO = mix(ALBEDO,vec3(.62,.74,.74),clamp(foam*(.55+.22*chop+.17*fine),0.,1.));
		// Intersect the reflected sightline with the two saloon window bands.
		vec3 eye = CAMERA_POSITION_WORLD;
		vec3 incoming = normalize(vec3(p.x,-.99,p.y)-eye);
		vec3 wave_normal = normalize(vec3(slope.x,1.,slope.y));
		vec3 ray = reflect(incoming,wave_normal);
		float side = sign(eye.x-ferry_center.x);
		float face = ferry_center.x+side*1.86;
		float t = (face-p.x)/(abs(ray.x)>.001 ? ray.x : .001);
		vec2 hit = vec2(-.99+ray.y*t-ferry_center.y,p.y+ray.z*t-ferry_center.z);
		float band = smoothstep(1.42,1.57,hit.x)*(1.-smoothstep(2.15,2.32,hit.x));
		float pane = smoothstep(.03,.13,abs(fract((hit.y+4.1)/.82+.5)-.5));
		float reflection = float(t>0.)*band*(1.-smoothstep(4.,4.24,abs(hit.y)))*pane;
		// The white broadside reflects daylight beneath the darker window band.
		float bow_taper = smoothstep(4.4,6.4,abs(hit.y));
		float hull = float(t>0.)*(1.-smoothstep(6.0,6.4,abs(hit.y)))
			*smoothstep(.0,.20,hit.x)*(1.-smoothstep(1.35-.75*bow_taper,1.49-.75*bow_taper,hit.x));
		float grazing = pow(1.-clamp(dot(-incoming,wave_normal),0.,1.),2.);
		ALBEDO = mix(ALBEDO,vec3(.52,.60,.59),hull*grazing*(1.-dusk)*.60);
		// The near fascia of each canal bridge interrupts the reflected sky.
		float fascia = 0.;
		for (int bridge = 0; bridge < 2; bridge++) {
			float center_z = bridge == 0 ? -48. : 0.;
			float edge_z = center_z + (p.y < center_z ? -5.8 : 5.8);
			float bridge_t = (edge_z-p.y)*sign(ray.z)/max(abs(ray.z),.001);
			float bridge_x = p.x+ray.x*bridge_t;
			float ramp = min((bridge_x-bridge_limits.x)/(bridge_limits.y-bridge_limits.x),
				(bridge_limits.w-bridge_x)/(bridge_limits.w-bridge_limits.z));
			float deck_y = bridge_rises[bridge]*smoothstep(0.,1.,ramp)-.02;
			float below_deck = deck_y-(-.99+ray.y*bridge_t);
			float blur = clamp(fwidth(below_deck),.04,.36);
			float band_mask = smoothstep(-blur,blur,below_deck)*(1.-smoothstep(.56-blur,.56+blur,below_deck));
			bool on_span = ramp > 0.;
			bool outside_deck = abs(p.y-center_z)>=5.8;
			fascia = max(fascia,band_mask*float(on_span && outside_deck && bridge_t>0. && abs(ray.z)>.001)
				*(1.-smoothstep(35.,100.,bridge_t)));
		}
		ALBEDO = mix(ALBEDO,vec3(.014,.021,.024),fascia*grazing*(1.-clamp(foam,0.,1.))*.85);
		// Daylight reflected in the saloon windows breaks into strips across the ripples.
		vec3 pane_tint = mix(vec3(.055,.095,.11),vec3(.23,.34,.39),clamp(ray.y*2.,0.,1.));
		ALBEDO = mix(ALBEDO,pane_tint,reflection*grazing*(1.-dusk)*(1.-foam)*.75);
		// Reflect the nearest buoy in the regularly spaced row by the eastern quay.
		float buoy_dx = mooring_layout.x-p.x;
		float buoy_t = buoy_dx * sign(ray.x) / max(abs(ray.x), .001);
		float buoy_z = p.y + ray.z*buoy_t;
		float berth_index = clamp(round((buoy_z-mooring_layout.y)/mooring_layout.z), 0., mooring_layout.w-1.);
		float buoy_side = abs(buoy_z-mooring_layout.y-mooring_layout.z*berth_index);
		float buoy_height = ray.y*buoy_t;
		float buoy_top = mooring_tops[int(berth_index)] + .99;
		float cap_height = max(0.,buoy_height-buoy_top+.14);
		float buoy_radius = sqrt(max(0.,.14*.14-cap_height*cap_height));
		float nearer_ferry = float(t>0. && t<buoy_t)*max(hull,reflection);
		float buoy_reflection = float(buoy_t>0. && abs(ray.x)>.001)*(1.-smoothstep(.6*buoy_radius,buoy_radius+.035,buoy_side))
			*smoothstep(0.,.06,buoy_height)*(1.-smoothstep(buoy_top-.10,buoy_top,buoy_height));
		ALBEDO = mix(ALBEDO,vec3(.30,.024,.029),buoy_reflection*(.28+.62*grazing)*(1.-clamp(foam,0.,1.))*(1.-.82*dusk)*(1.-nearer_ferry));
		EMISSION = dusk*(vec3(.034,.058,.084)*(.75+.25*chop)+vec3(.66,.42,.21)*reflection*(.25+.75*smoothstep(-.5,.8,chop+fine*.38)));
		if (dusk > .01 && ray.y > .008) {
			for (int i=0; i<quay_lamp_count; i++) {
				vec3 lamp = quay_lamps[i];
				float distance_to_lamp = (lamp.y+.99)/ray.y;
				vec2 miss = p+ray.xz*distance_to_lamp-lamp.xz;
				float radius = .20+.014*distance_to_lamp;
				float glow = 1.-smoothstep(.12*radius,radius,length(miss));
				EMISSION += vec3(1.,.67,.37)*dusk*glow*grazing*(1.-smoothstep(45.,100.,distance_to_lamp));
			}
		}
		// Clear wave faces catch sharp highlights. Rain and aerated wake scatter them.
		ROUGHNESS = mix(.19+.16*rain,.65,clamp(foam,0.,1.));
		METALLIC = 0.;
		SPECULAR = .255;
	}
	"""
	water_finish.shader = water
	water_finish.set_shader_parameter("bridge_limits", Vector4(HIGH_BRIDGE_X[0], HIGH_BRIDGE_X[1], HIGH_BRIDGE_X[2], HIGH_BRIDGE_X[3]))
	water_finish.set_shader_parameter("mooring_layout", Vector4(EAST_QUAY_WATER_EDGE-MOORING_BUOY_OFFSET,
		MOORING_START_Z+MOORING_BUOY_Z_OFFSET, MOORING_SPACING, MOORING_COUNT))
	water_finish.set_shader_parameter("bridge_rises", Vector2(HIGH_BRIDGE_RISE, SOUTH_BRIDGE_RISE))
	canal.material_override = water_finish
	var wall_shader := Shader.new()
	wall_shader.code = """
	shader_type spatial;
	varying vec3 world_point;
	void vertex() {
		world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	}
	void fragment() {
		float row = floor((world_point.y + .10) / .36);
		vec2 grid = vec2(world_point.z / .91 + .5 * mod(row, 2.0), (world_point.y + .10) / .36);
		vec2 inset = min(fract(grid), 1.0 - fract(grid)) * vec2(.91, .36);
		float edge = min(inset.x, inset.y);
		float aa = clamp(fwidth(edge), .001, .022);
		float stone = smoothstep(.008 - aa, .014 + aa, edge);
		float block = fract(sin(dot(floor(grid), vec2(43.71, 29.49))) * 437.59);
		vec3 granite = mix(vec3(.37, .35, .31), vec3(.52, .50, .46), block);
		float grain = fract(sin(dot(floor(world_point.yz * 130.0), vec2(19.3, 37.1))) * 1427.9);
		granite *= 1.0 + (grain - .5) * .12 * (1.0 - smoothstep(.003, .012, fwidth(world_point.z)));
		float dry = smoothstep(-.99, -.66, world_point.y);
		ALBEDO = mix(vec3(.23, .22, .20), granite, stone) * mix(.61, 1.0, dry);
		ROUGHNESS = mix(.66, .93, dry);
	}
	"""
	var wall_finish := ShaderMaterial.new()
	wall_finish.shader = wall_shader
	var quay_wall_color := Color("#807b70")
	_make_box("Kajmur", Vector3(.5, 1.5, 174), Vector3(55, -.86, -6), quay_wall_color).material_override = wall_finish
	var wall_spans := [Vector2(-93, FLOATING_DOCK_ACCESS_Z - .82),
		Vector2(FLOATING_DOCK_ACCESS_Z + .82, 81)]
	for span: Vector2 in wall_spans:
		_make_box("Kajmur", Vector3(.5, 1.5, span.y - span.x),
			Vector3(EAST_QUAY_WATER_EDGE + .25, -.86, (span.x + span.y) * .5), quay_wall_color).material_override = wall_finish
	var coping := MultiMesh.new()
	coping.transform_format = MultiMesh.TRANSFORM_3D
	coping.use_colors = true
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(.37, .092, 1.0)
	var cap_finish := _material(Color.WHITE, .79)
	cap_finish.vertex_color_use_as_albedo = true
	cap_mesh.material = cap_finish
	coping.mesh = cap_mesh
	var cap_sizes := PackedInt32Array()
	var cap_count := 0
	for span: Vector2 in wall_spans:
		var count := ceili((span.y - span.x) / 1.15)
		cap_sizes.append(count)
		cap_count += count
	coping.instance_count = cap_count
	var cap_index := 0
	for i in wall_spans.size():
		var span: Vector2 = wall_spans[i]
		var step := (span.y - span.x) / cap_sizes[i]
		for j in cap_sizes[i]:
			var size := Basis.from_scale(Vector3(1, 1, step - .012))
			var center := Vector3(EAST_QUAY_WATER_EDGE + .145, -.077, span.x + (j + .5) * step)
			coping.set_instance_transform(cap_index, Transform3D(size, center))
			var shade := .70 + .07 * sin(cap_index * 2.39)
			coping.set_instance_color(cap_index, Color(shade, shade * .98, shade * .93))
			cap_index += 1
	var coping_view := MultiMeshInstance3D.new()
	coping_view.name = "Eastern quay coping stones"
	coping_view.multimesh = coping
	add_child(coping_view)
	_make_box("Quay stair foundation", Vector3(.5, 1.06, 1.64),
		Vector3(EAST_QUAY_WATER_EDGE + .25, -1.08, FLOATING_DOCK_ACCESS_Z), quay_wall_color).material_override = wall_finish
	var metal := _material(Color("#43565a"), .42, false, "brushed")
	metal.metallic = .65
	var rail_mesh := CylinderMesh.new()
	rail_mesh.top_radius = .04
	rail_mesh.bottom_radius = .04
	rail_mesh.height = 1.0
	rail_mesh.radial_segments = 12
	rail_mesh.rings = 0
	rail_mesh.material = metal
	for street_z in [0.0,-48.0]:
		var start_x := 50.0 if street_z == 0 else -4.8
		_make_driving_surface("Kajgata", Vector3(55-start_x,.12,9.6), Vector3((55+start_x)/2,-.08,street_z),asphalt).material_override = road_finish
		_build_canal_bridge(street_z, asphalt, rail_mesh)
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
	_make_driving_surface("Motorboat parking bay", Vector3(4.8,.10,9.4), LAUNCH_ROAD_STOP + Vector3(.35,-.05,0), asphalt).material_override = road_finish
	for end in [-1.0,1.0]:
		_make_box("Motorboat parking end marking", Vector3(3.2,.012,.12), LAUNCH_ROAD_STOP + Vector3(0,.015,end * 4.3), Color.WHITE).material_override = marking_finish
	_make_box("Motorboat parking edge marking", Vector3(.12,.012,8.6), LAUNCH_ROAD_STOP + Vector3(-1.6,.015,0), Color.WHITE).material_override = marking_finish
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
		if span.x < FLOATING_DOCK_ACCESS_Z and span.y > FLOATING_DOCK_ACCESS_Z:
			for section in [Vector2(span.x, FLOATING_DOCK_ACCESS_Z - .82),
					Vector2(FLOATING_DOCK_ACCESS_Z + .82, span.y)]:
				_make_driving_surface("Strandpromenad", Vector3(6, .15, section.y - section.x),
					Vector3(90, -.11, (section.x + section.y) * .5), Color.WHITE).material_override = quay_finish
			_make_driving_surface("Quay stair approach", Vector3(5.35, .15, 1.64),
				Vector3(90.325, -.11, FLOATING_DOCK_ACCESS_Z), Color.WHITE).material_override = quay_finish
		else:
			_make_driving_surface("Strandpromenad", Vector3(6, .15, span.y - span.x),
				Vector3(90, -.11, middle), Color.WHITE).material_override = quay_finish
		var rail_spans := [span]
		if span.x < LAUNCH_PIER.position.y and span.y > LAUNCH_PIER.end.y:
			rail_spans = [Vector2(span.x,LAUNCH_PIER.position.y), Vector2(LAUNCH_PIER.end.y,span.y)]
		if span.x < FLOATING_DOCK_ACCESS_Z and span.y > FLOATING_DOCK_ACCESS_Z:
			rail_spans = [Vector2(span.x, FLOATING_DOCK_ACCESS_Z - .86),
				Vector2(FLOATING_DOCK_ACCESS_Z + .86, span.y)]
		for rail_span: Vector2 in rail_spans:
			var rail_start := rail_span.x + .07
			var rail_end := rail_span.y - .07
			var intervals := ceili((rail_end - rail_start) / 2.7)
			for i in intervals + 1:
				var z := lerpf(rail_start, rail_end, float(i) / intervals)
				var post := _make_box("Quay railing post", Vector3(.077, .82, .078),
					Vector3(87.5, .393, z), Color.WHITE)
				post.material_override = metal
				var base := _make_box("Quay railing foot plate", Vector3(.18, .023, .16),
					Vector3(87.5, -.023, z), Color.WHITE)
				base.material_override = metal
				for offset_z in [-.053, .053]:
					_make_box("Quay railing anchor", Vector3(.025, .014, .025),
						Vector3(87.5, -.005, z + offset_z), Color("#858f91"))
			_add_moored_round_fitting(self, "Quay handrail",
				Vector3(87.5, .82, rail_start), Vector3(87.5, .82, rail_end), .036, metal)
			_add_moored_round_fitting(self, "Quay lower rail",
				Vector3(87.5, .33, rail_start), Vector3(87.5, .33, rail_end), .021, metal)
	var balcony_glass := StandardMaterial3D.new()
	balcony_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	balcony_glass.albedo_color = Color(.53,.72,.72,.36)
	balcony_glass.roughness = .18
	quay_stair_light = _material(Color("#d8cbbb"),.70)
	quay_stair_light.emission_enabled = true
	quay_stair_light.emission = Color("#ffaf69")
	quay_stair_light.emission_energy_multiplier = 0
	var panes := [Color("#354852"), Color("#475d68"), Color("#596971"), Color("#384e56")]
	var window_batches: Array = [[], [], [], []]
	var historic_windows := _material(Color("#576771"),.22)
	historic_windows.metallic = .30
	historic_windows.emission_enabled = true
	historic_windows.emission = Color("#ffcd98")
	historic_windows.emission_energy_multiplier = 0
	apartment_lights.append(historic_windows)
	for x: float in [-468,-378]:
		for z: float in [-24,17]:
			var home := preload("res://environment/stockholm_apartment.gd").new()
			home.build(4,z>0,Color("#d7ab76") if z>0 else Color("#bb8878"),historic_windows)
			home.position = Vector3(x,0,z)
			home.rotation.y = PI if z<0 else 0.0
			add_child(home)
			building_bounds.append(AABB(Vector3(x-7,-1,z-5),Vector3(14,13,10)))
	for row in range(3):
		for col in range(4):
			var x := 115.0 + (col % 2)*21
			var z: float = [-69, -35, -21, 17, 34, 51][row * 2 + floori(col/2.0)]
			if z == -69: continue # Hospital plot
			if x==136 and z==17: continue # School plot
			var floors := 3+(col+row)%4
			var height := floors*2.8
			building_bounds.append(AABB(Vector3(x-7,-1,z-5),Vector3(14,height+1,10)))
			if x == 136 and row != 1:
				var historic := preload("res://environment/stockholm_apartment.gd").new()
				var atlas := floors == 4
				var ochre := Color("#d7ab76") if row==0 else Color("#ceb58a")
				var rose := Color("#be8c77") if row==0 else Color("#ba765d")
				historic.build(floors,atlas,ochre if atlas else rose,historic_windows)
				historic.position = Vector3(x,0,z)
				historic.rotation.y = PI if z == -35 else 0.0
				add_child(historic)
				if atlas:
					var outward := -1.0 if z < 0 else 1.0
					var threshold := z+outward*5.0
					var kerb := -78.3 if z < 0 else 56.3
					var approach := _make_driving_surface("Atlasgårdens entrégång",
						Vector3(2.1,.16,absf(kerb-threshold)),Vector3(x,-.085,(threshold+kerb)*.5),Color.WHITE)
					approach.material_override = quay_finish
					_add_entry_light(Vector3(x,2.45,threshold+outward*.14),Vector3(.46,.04,.14),3.6)
				continue
			var house := preload("res://environment/sjostad_apartment.gd").new()
			house.position = Vector3(x,0,z)
			house.build(floors,row+col,window_batches,balcony_glass,quay_stair_light)
			add_child(house)
			if col % 2 == 0:
				var tree_z := z + 3.0 if absf(z - LAUNCH_ROAD_STOP.z - 5.0) < .01 else z
				_make_tree(Vector3(94,0,tree_z),1.25)
				_make_quay_entrance(Vector3(x-7,-.18,z-1))


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
	_build_marina(metal)

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

func _add_entry_light(lamp_position: Vector3, lens_size: Vector3, reach: float) -> SpotLight3D:
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
	return light

func _bridge_rise(x: float, z: float) -> float:
	var rise := HIGH_BRIDGE_RISE if z < -24.0 else SOUTH_BRIDGE_RISE
	return rise * smoothstep(0.0, 1.0, minf(inverse_lerp(HIGH_BRIDGE_X[0], HIGH_BRIDGE_X[1], x),
		inverse_lerp(HIGH_BRIDGE_X[3], HIGH_BRIDGE_X[2], x)))

func _align_model_to_bridge(actor: Node3D, model: Node3D, wheelbase: float) -> void:
	var pos := actor.position
	var half_span := maxf(.15, absf(actor.basis.z.x) * wheelbase * .5)
	var slope := 0.0
	if minf(absf(pos.z + 48.0), absf(pos.z)) <= 5.8 and pos.x + half_span > HIGH_BRIDGE_X[0] and pos.x - half_span < HIGH_BRIDGE_X[3]:
		slope = atan2(_bridge_rise(pos.x + half_span, pos.z) - _bridge_rise(pos.x - half_span, pos.z), 2 * half_span)
	if is_zero_approx(slope):
		if model.has_meta("level_basis"):
			model.basis = model.get_meta("level_basis")
			model.remove_meta("level_basis")
		return
	if not model.has_meta("level_basis"):
		model.set_meta("level_basis", model.basis)
	var level: Basis = model.get_meta("level_basis")
	model.basis = Basis(actor.basis.inverse() * Vector3.BACK, slope) * level

func _add_bridge_rail(mesh: CylinderMesh, center: Vector3, length: float, slope: float) -> void:
	var rail := MeshInstance3D.new()
	rail.name = "Brons rundräcke"
	rail.mesh = mesh
	rail.position = center
	rail.rotation.z = slope - PI * .5
	rail.scale.y = length
	add_child(rail)

func _build_canal_bridge(z: float, asphalt: Color, rail_mesh: CylinderMesh) -> void:
	var north := z < -24.0
	var sections: Array[float] = [HIGH_BRIDGE_X[0]]
	for i in HIGH_BRIDGE_X.size()-1:
		var start: float = HIGH_BRIDGE_X[i]
		var end: float = HIGH_BRIDGE_X[i+1]
		var count := 1 if i == 1 else ceili((end-start) / 1.25)
		for step in range(1, count+1):
			sections.append(lerpf(start, end, float(step)/count))
	var drain_stations := [59.0, 68.0, 75.0, 84.0]
	var beam_finish := _material(Color("#858683"), .87, false, "mineral")
	var drip_finish := _material(Color("#525858"), .88)
	for i in sections.size()-1:
		var x0 := sections[i]
		var x1 := sections[i+1]
		var rise := _bridge_rise(x1, z) - _bridge_rise(x0, z)
		var angle := atan2(rise, x1-x0)
		var length := Vector2(x1-x0,rise).length()
		var mid := Vector3((x0+x1)*.5, (_bridge_rise(x0, z)+_bridge_rise(x1, z))*.5-.02, z)
		var normal := Vector3.UP.rotated(Vector3.BACK,angle)
		var deck := _make_box("Norra brobanan" if north else "Södra brobanan",Vector3(length,.56,11.6),mid-normal*.28,asphalt)
		deck.add_to_group("north_bridge_deck" if north else "south_bridge_deck")
		deck.rotation.z = angle
		deck.material_override = road_finish
		for side in [-1,1]:
			var edge: Vector3 = mid + Vector3.BACK*side*5.5
			var kerb := _make_box("Brons gångkant",Vector3(length,.16,1.1),edge+normal*.08,Color("#bab6aa"))
			kerb.rotation.z = angle
			var paving := _make_box("Bridge footway paving", Vector3(length, .013, .88),
				edge + normal * .162 + Vector3.BACK * side * .025, Color.WHITE)
			paving.rotation.z = angle
			paving.material_override = quay_finish
			var fascia: Vector3 = mid + Vector3.BACK * side * 5.89
			var beam := _make_box("Bridge edge beam", Vector3(length + .016, .53, .32),
				fascia - normal * .236, Color.WHITE)
			beam.rotation.z = angle
			beam.material_override = beam_finish
			var drip := _make_box("Bridge edge drip strip", Vector3(length + .012, .039, .074),
				fascia - normal * .489 + Vector3.BACK * side * .118, Color.WHITE)
			drip.rotation.z = angle
			drip.material_override = drip_finish
			for h in [.54,1.06]:
				_add_bridge_rail(rail_mesh, edge + Vector3.UP * h, length + .015, angle)
		for drain_x: float in drain_stations:
			if drain_x < x0 or drain_x >= x1:
				continue
			var grate_y := mid.y + (drain_x - mid.x) * tan(angle)
			for side in [-1, 1]:
				var grate := _make_box("Bridge storm drain bed", Vector3(.34, .014, .22),
					Vector3(drain_x, grate_y + .004, z + side * 4.80), Color("#21272a"))
				grate.rotation.z = angle
				for bar in 7:
					_make_box("Storm grate bar", Vector3(.018, .009, .207),
						Vector3((bar - 3) * .045, .011, 0), Color.WHITE, false, grate).material_override = rail_mesh.material
				for edge in [-1, 1]:
					_make_box("Storm grate rim", Vector3(.34, .01, .017),
						Vector3(0, .011, edge * .104), Color.WHITE, false, grate).material_override = rail_mesh.material
	var outlet_lip := TorusMesh.new()
	outlet_lip.inner_radius = .043
	outlet_lip.outer_radius = .057
	outlet_lip.rings = 16
	outlet_lip.ring_segments = 8
	outlet_lip.material = rail_mesh.material
	var outlet_interior := CylinderMesh.new()
	outlet_interior.top_radius = .044
	outlet_interior.bottom_radius = .044
	outlet_interior.height = .018
	outlet_interior.radial_segments = 16
	outlet_interior.material = _material(Color("#20282b"), .96)
	for drain_x: float in drain_stations:
		var drain_y := _bridge_rise(drain_x, z) - .32
		for side in [-1, 1]:
			var outlet_z: float = z + side * 6.095
			_make_box("Bridge drain flange", Vector3(.159, .15, .036),
				Vector3(drain_x, drain_y, z + side * 6.06), Color.WHITE).material_override = rail_mesh.material
			var recess := MeshInstance3D.new()
			recess.name = "Bridge drain recess"
			recess.mesh = outlet_interior
			recess.position = Vector3(drain_x, drain_y, outlet_z - side * .018)
			recess.rotation.x = PI * .5
			add_child(recess)
			var lip := MeshInstance3D.new()
			lip.name = "Bridge drain mouth"
			lip.mesh = outlet_lip
			lip.position = Vector3(drain_x, drain_y, outlet_z)
			lip.rotation.x = PI * .5
			add_child(lip)
	for x in range(52, 99, 2):
		var slope := atan2(_bridge_rise(x + .1, z) - _bridge_rise(x - .1, z), .2)
		var along := Vector3.RIGHT.rotated(Vector3.BACK, slope)
		var up := Vector3.UP.rotated(Vector3.BACK, slope)
		for side in [-1, 1]:
			var foot := Vector3(x, _bridge_rise(x, z) + .15, z + side * 5.5)
			_make_box("Bridge railing post", Vector3(.083, .89, .083),
				foot + Vector3.UP * .445, Color.WHITE).material_override = rail_mesh.material
			var plate := _make_box("Bridge railing foot plate", Vector3(.201, .028, .157),
				foot + up * .012, Color.WHITE)
			plate.rotation.z = slope
			plate.material_override = rail_mesh.material
			for offset in [-.065, .065]:
				var anchor := _make_box("Bridge railing anchor", Vector3(.028, .019, .028),
					foot + along * offset + up * .032, Color("#909a9b"))
				anchor.rotation.z = slope
	var joint_steel := _material(Color("#747e81"), .62)
	joint_steel.metallic = .44
	for i in [0, sections.size() - 1]:
		var neighbour: int = 1 if i == 0 else i - 1
		var end_x: float = sections[i]
		var inward: float = sections[neighbour] - end_x
		var joint_x := end_x + signf(inward) * .24
		var top := lerpf(_bridge_rise(end_x, z), _bridge_rise(sections[neighbour], z),
			.24 / absf(inward)) - .017
		_make_box("Bridge expansion joint seal", Vector3(.067, .014, 9.79),
			Vector3(joint_x, top, z), Color("#25292b"))
		for side in [-1, 1]:
			_make_box("Expansion joint steel edge", Vector3(.031, .013, 9.79),
				Vector3(joint_x + side * .048, top, z), Color.WHITE).material_override = joint_steel
		for edge in [-1, 1]:
			_make_box("Footway expansion joint cover", Vector3(.11, .019, .89),
				Vector3(joint_x, top + .166, z + edge * 5.53), Color.WHITE).material_override = joint_steel
	var return_mesh := _bridge_rail_return_mesh(rail_mesh)
	for end in [-1, 1]:
		var x: float = HIGH_BRIDGE_X.front() if end < 0 else HIGH_BRIDGE_X.back()
		for side in [-1, 1]:
			var rail_return := MeshInstance3D.new()
			rail_return.name = "Bridge handrail return"
			rail_return.mesh = return_mesh
			rail_return.position = Vector3(x, _bridge_rise(x, z) + .78, z + side * 5.5)
			rail_return.rotation.y = PI if end < 0 else 0.0
			add_child(rail_return)
	var concrete := _material(Color("#918d83"), .91)
	var bearing_finish := _material(Color("#354146"), .61)
	for bank_x: float in [54.40, 87.35]:
		var deck_height := _bridge_rise(bank_x, z) - .58
		var seat_top := deck_height - .14
		var wall_height := seat_top + 1.42
		_make_box("Bridge abutment stem", Vector3(.94, wall_height, 10.84),
			Vector3(bank_x, seat_top - wall_height * .5, z), Color.WHITE).material_override = concrete
		_make_box("Bridge abutment bearing shelf", Vector3(1.20, .16, 11.10),
			Vector3(bank_x, seat_top - .045, z), Color.WHITE).material_override = concrete
		var slope := atan2(_bridge_rise(bank_x + .1, z) - _bridge_rise(bank_x - .1, z), .2)
		for bearing_z in [-4.1, -1.4, 1.4, 4.1]:
			var pad := _make_box("Abutment bearing", Vector3(.53, .113, .57),
				Vector3(bank_x, deck_height - .018, z + bearing_z), Color.WHITE)
			pad.material_override = bearing_finish
			pad.rotation.z = slope
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = .59
	cap_mesh.bottom_radius = .5
	cap_mesh.height = .15
	cap_mesh.radial_segments = 24
	cap_mesh.material = concrete
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = .51
	collar_mesh.bottom_radius = .53
	collar_mesh.height = .20
	collar_mesh.radial_segments = 24
	collar_mesh.material = _material(Color("#767971"), .84)
	for x in [63.0,80.0]:
		var height := _bridge_rise(x, z) + .70
		var shaft_mesh := CylinderMesh.new()
		shaft_mesh.top_radius = .5
		shaft_mesh.bottom_radius = .5
		shaft_mesh.height = height
		shaft_mesh.radial_segments = 24
		shaft_mesh.material = concrete
		for side in [-1,1]:
			var shaft := MeshInstance3D.new()
			shaft.name = "Rounded bridge pier"
			shaft.mesh = shaft_mesh
			shaft.position = Vector3(x,-1.5+height*.5,z+side*4.4)
			shaft.scale = Vector3(.75,1,1.1)
			add_child(shaft)
			shaft.add_to_group("north_bridge_piers" if north else "south_bridge_piers")
			var center := Vector2(shaft.position.x, shaft.position.z)
			var half_size := Vector2(.45, .65)
			bridge_pier_footprints.append(Rect2(center - half_size, half_size * 2.0))
			var cap := MeshInstance3D.new()
			cap.mesh = cap_mesh
			cap.position = Vector3.UP * (height * .5 + .075)
			shaft.add_child(cap)
			var pier_head := Vector3(x, _bridge_rise(x, z) - .615, shaft.position.z)
			var pad := _make_box("Pier neoprene bearing", Vector3(.48, .095, .58),
				pier_head, Color.WHITE)
			pad.material_override = bearing_finish
			pad.rotation.z = atan2(_bridge_rise(x + .1, z) - _bridge_rise(x - .1, z), .2)
			var collar := MeshInstance3D.new()
			collar.name = "Bridge pier waterline collar"
			collar.mesh = collar_mesh
			collar.position.y = -.94 - shaft.position.y
			shaft.add_child(collar)

func _bridge_rail_return_mesh(rail: CylinderMesh) -> ArrayMesh:
	const ARC_STEPS := 24
	const TUBE_SIDES := 12
	const BEND_RADIUS := .26
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(rail.material)
	for step in ARC_STEPS + 1:
		var angle := PI * step / ARC_STEPS
		var radial := Vector3(sin(angle), cos(angle), 0)
		for side in TUBE_SIDES:
			var ring_angle := TAU * side / TUBE_SIDES
			var normal := radial * cos(ring_angle) + Vector3.BACK * sin(ring_angle)
			surface.set_normal(normal)
			surface.add_vertex(radial * BEND_RADIUS + normal * rail.top_radius)
	for step in ARC_STEPS:
		for side in TUBE_SIDES:
			var first := step * TUBE_SIDES + side
			var next := step * TUBE_SIDES + (side + 1) % TUBE_SIDES
			for index in [first, first + TUBE_SIDES, next, next, first + TUBE_SIDES, next + TUBE_SIDES]:
				surface.add_index(index)
	return surface.commit()


func _build_quay_lane_markings() -> void:
	var dashes: Array[Transform3D] = []
	for z in [0.0, -48.0]:
		var first := 54 if z == 0 else 12
		for x in range(first, 165, 6):
			if absi(x - 102) < 7 or absi(x - 162) < 7:
				continue
			var pieces := 6 if x+1.5 >= HIGH_BRIDGE_X[0] and x-1.5 <= HIGH_BRIDGE_X[3] else 1
			for piece in pieces:
				var left := x-1.5 + 3.0*piece/pieces
				var right := left + 3.0/pieces
				var rise := _surface_height(right,z)-_surface_height(left,z)
				var slope := atan2(rise,right-left)
				var basis := Basis(Vector3.BACK,slope).scaled_local(Vector3(Vector2(right-left,rise).length()/3,1,1))
				var center := Vector3((left+right)*.5, _surface_height(left,z)+rise*.5+.032,z)
				dashes.append(Transform3D(basis, center))
		# M2 through the quay and bridge approaches: one metre painted, two clear.
		for x in range(first, 161, 3):
			if absi(x-102) < 7 or absi(x-162) < 7:
				continue
			var slope := atan2(_bridge_rise(x+.1,z)-_bridge_rise(x-.1,z),.2)
			var basis := Basis(Vector3.BACK,slope).scaled_local(Vector3(1.0/3,1,1))
			for side in [-1,1]:
				var edge_z: float = z + side*4.5
				dashes.append(Transform3D(basis,Vector3(x,_surface_height(x,edge_z)+.014,edge_z)))
	for x in [102.0, 162.0]:
		for z in range(-70, 60, 6):
			if absi(z) < 7 or absi(z + 48) < 7:
				continue
			dashes.append(Transform3D(Basis(Vector3.UP, PI/2),Vector3(x,_surface_height(x,z)+0.006,z)))
	var dash := PlaneMesh.new()
	dash.size = Vector2(3, 0.15)
	dash.material = marking_finish
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

func _deck_material(color: Color, boards_along_z := false) -> ShaderMaterial:
	var deck := ShaderMaterial.new()
	deck.shader = preload("res://environment/deck_planks.gdshader")
	deck.set_shader_parameter("timber", color)
	deck.set_shader_parameter("boards_along_z", boards_along_z)
	return deck

func _pier_section(label: String, size: Vector3, center: Vector3, color: Color, finish: Material) -> void:
	_make_box(label,size,center,color).material_override = finish
	pier_surfaces.append(AABB(center-size*.5,size))

func _pier_height(x: float,z: float) -> float:
	for section in pier_surfaces:
		if x >= section.position.x and x <= section.end.x and z >= section.position.z and z <= section.end.z:
			return section.end.y
	return NAN

func _foot_height(x: float,z: float) -> float:
	var platform := tram.platform_height(Vector3(x,0,z))
	if not is_nan(platform): return platform
	var deck := _pier_height(x,z)
	return _surface_height(x,z) if is_nan(deck) else deck

func _build_marina(rail_metal: Material) -> void:
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
	launch.position = LAUNCH_BERTH
	var landing_finish := _deck_material(Color("#ab9071"))
	var landing_center := LAUNCH_PIER.get_center()
	_pier_section("Motorboat landing",Vector3(LAUNCH_PIER.size.x,.2,LAUNCH_PIER.size.y),Vector3(landing_center.x,-.10,landing_center.y),Color("#ab9071"),landing_finish)
	ferry = (load("res://vehicles/lotten.glb") as PackedScene).instantiate()
	add_child(ferry)
	ferry_hull_bounds = _model_bounds(ferry, ferry)
	var engine_loop := preload("res://audio/loader_diesel.wav").duplicate() as AudioStreamWAV
	engine_loop.loop_end = roundi(engine_loop.get_length() * engine_loop.mix_rate)
	engine_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ferry_engine.stream = engine_loop
	ferry_engine.bus = &"Engines"
	ferry_engine.unit_size = 5
	ferry_engine.max_distance = 48
	ferry.add_child(ferry_engine)
	var windows := ferry.find_child("Continuous tinted glazing*",true,false) as MeshInstance3D
	saloon_glazing = windows.get_active_material(0).duplicate() as StandardMaterial3D
	saloon_glazing.emission_enabled = true
	saloon_glazing.emission = Color("#ffcc8c")
	windows.material_override = saloon_glazing
	_build_quay_windsock()
	ferry_boarding_chime.bus = &"Traffic and radio"
	ferry_boarding_chime.stream = preload("res://audio/ferry_boarding.wav")
	ferry_boarding_chime.max_distance = 32
	ferry_boarding_chime.unit_size = 5
	ferry_boarding_chime.volume_db = -7
	add_child(ferry_boarding_chime)
	var landing_boards := _deck_material(Color("#847968"))
	var gangway_boards := _deck_material(Color("#9d8469"), true)
	var granite := _material(Color("#b2a897"), .91, false, "mineral")
	for landing_z in FERRY_LANDINGS:
		var sign_base := Vector3(54.55,0,landing_z+1.35)
		var lamp_pos := sign_base + Vector3.UP*2.54
		_make_box("Boarding beacon base",Vector3(.28,.20,.28),lamp_pos,Color("#263b42"))
		var lens := _make_box("Boarding beacon",Vector3(.23,.23,.23),lamp_pos+Vector3.UP*.20,Color("#57ff96"))
		lens.material_override = _material(Color("#57ff96"),.32,true)
		ferry_boarding_lamps.append(lens)
		_make_roadside_solid("Landing signpost",Vector3(.07,2.35,.07),sign_base+Vector3.UP*.98,Color("#646e70"))
		_make_box("Ferry stop sign",Vector3(.09,.78,2.40),sign_base+Vector3.UP*2.05,Color("#12385b"))
		# Both landings have a bridge in the +Z direction, at -48 and 0.
		for side in [-1,1]:
			var direction := Sprite3D.new()
			direction.name = "BouleDirection"
			direction.texture = preload("res://branding/boule-direction.svg")
			direction.pixel_size = .006
			direction.double_sided = false
			direction.rotation.y = side*PI*.5
			direction.flip_h = side == 1
			direction.position = sign_base+Vector3(side*.052,1.34,0)
			add_child(direction)
			var sign_text := Label3D.new()
			sign_text.text = "LOTTEN"
			sign_text.font_size = 48
			sign_text.pixel_size = .007
			sign_text.outline_size = 0
			sign_text.position = sign_base+Vector3(side*.051,2.20,0)
			sign_text.rotation.y = side*PI*.5
			add_child(sign_text)
			var display := sign_text.duplicate() as Label3D
			display.position.y -= .34
			display.pixel_size = .0044
			add_child(display)
			ferry_displays.append(display)
		_pier_section("Ferry landing",Vector3(2.0,.20,7.5),Vector3(64.9,-.76,landing_z),Color("#847968"),landing_boards)
		for tread in 4:
			var height := -.18-.12*tread
			_pier_section("Granite tread",Vector3(.46,.22,2),Vector3(55.02+.45*tread,height-.11,landing_z),Color("#b2a897"),granite)
		_pier_section("Timber gangway",Vector3(7.46,.17,2),Vector3(60.31,-.745,landing_z),Color("#9d8469"),gangway_boards)
		for end in [-1,1]:
			_make_box("Pier pile",Vector3(.24,1.4,.24),Vector3(65.75,-.67,landing_z+end*3.4),Color("#514e41"))
	# Three tiny rubber ducks have each claimed a different landing.
	for perch in [Vector3(59.08,.32,-33.8), Vector3(58.65,-.66,-22), Vector3(85.8,-.505,-15)]:
		var duck := Node3D.new()
		add_child(duck)
		duck.position = perch
		for part in [[Vector3(0,.12,0), Vector3(.43,.24,.26), Color.GOLD], [Vector3(.14,.25,0), Vector3(.21,.21,.2), Color.GOLD], [Vector3(.25,.24,0), Vector3(.13,.055,.12), Color.CORAL]]:
			var piece := MeshInstance3D.new()
			piece.mesh = SphereMesh.new()
			piece.position = part[0]
			piece.scale = part[1]
			piece.material_override = _material(part[2], .46)
			duck.add_child(piece)
		for side in [-1,1]:
			_make_box("Duck eye", Vector3(.024,.024,.012), Vector3(.18,.275,side*.085), Color.BLACK, false, duck)
	# Boardwalk joins both ferry approaches along the sheltered bank.
	var promenade_length: float = FERRY_LANDINGS[1] - FERRY_LANDINGS[0] - 2.0
	var promenade_midpoint: float = (FERRY_LANDINGS[0] + FERRY_LANDINGS[1]) * .5
	_pier_section("Waterside boardwalk",Vector3(2.0,.18,promenade_length),Vector3(58.0,-.75,promenade_midpoint),Color("#ab9071"),_deck_material(Color("#ab9071")))
	var timber_frame := _material(Color("#625448"), .85)
	for beam_x in [57.18, 58.87]:
		var beam := _make_box("Boardwalk longitudinal beam", Vector3(.19,.28,promenade_length),
			Vector3(beam_x,-.91,promenade_midpoint), Color.WHITE)
		beam.material_override = timber_frame
	var support_positions := PackedFloat32Array()
	var south_end: float = FERRY_LANDINGS[0] + 1.0
	var rail_end := -33.8
	for i in 13:
		var post_z := lerpf(south_end, rail_end, i / 13.0)
		support_positions.append(post_z)
		_make_box("Boardwalk pile", Vector3(.14, 1.80, .14), Vector3(59.08, -.54, post_z), Color("#6b5948"))
	for height in [-.22, .25]:
		_make_box("Boardwalk rail", Vector3(.09, .11, rail_end-south_end), Vector3(59.08, height, (south_end+rail_end)*.5), Color("#877461"))
	var rope_finish := _material(Color("#c9b38e"), .95, false, "weave")
	var barrier_rope := _boardwalk_rope_mesh(rope_finish)
	for i in 8:
		var post_z := rail_end + i * 2.94
		support_positions.append(post_z)
		_make_box("Timber bollard", Vector3(.14, 1.70, .14),
			Vector3(59.08, -.53, post_z), Color("#6b5948"))
		_add_moored_round_fitting(self, "Rope guide ferrule",
			Vector3(59.08, .22, post_z - .078), Vector3(59.08, .22, post_z + .078), .033, rail_metal)
		if i < 7:
			var span := MeshInstance3D.new()
			span.name = "Boardwalk hemp rope"
			span.mesh = barrier_rope
			span.position = Vector3(59.08, .22, post_z)
			add_child(span)
	var boardwalk_edge := Color("#79634f")
	var edge_sections := ceili(promenade_length / 3.6)
	var edge_span := promenade_length / edge_sections
	for i in edge_sections:
		var z := promenade_midpoint + (i + .5 - edge_sections * .5) * edge_span
		_make_box("Boardwalk fascia plank", Vector3(.073, .186, edge_span - .012),
			Vector3(59.006, -.771, z), boardwalk_edge)
	for support_z in support_positions:
		var joist := _make_box("Boardwalk cross beam", Vector3(2.14,.16,.18),
			Vector3(58.03,-1.025,support_z), Color.WHITE)
		joist.material_override = timber_frame
		_make_box("Boardwalk pile strap", Vector3(.035, .215, .12),
			Vector3(59.156, -.798, support_z), Color.WHITE).material_override = rail_metal
		for bolt_y in [-.731, -.861]:
			_make_box("Boardwalk strap bolt", Vector3(.022, .031, .031),
				Vector3(59.174, bolt_y, support_z), Color("#8a9292"))
	var dock_color := Color("#877962")
	var floating_dock_deck := _deck_material(dock_color)
	_pier_section("Flytbrygga", Vector3(1.4, .25, 32), Vector3(85.8, -.63, -24),
		dock_color, floating_dock_deck)
	var access_z := FLOATING_DOCK_ACCESS_Z
	for tread in 4:
		var top: float = [-.105, -.19, -.33, -.45][tread]
		var tread_x := 87.50 - .30 * tread
		_pier_section("Floating dock access tread", Vector3(.302, .17, 1.64),
			Vector3(tread_x, top - .085, access_z), dock_color, floating_dock_deck)
		_make_box("Access tread nosing", Vector3(.026, .022, 1.64),
			Vector3(tread_x - .138, top - .008, access_z), Color("#576267"))
	_make_box("Dock access retaining riser", Vector3(.09, .14, 1.64),
		Vector3(87.02, -.26, access_z), Color("#726657"))
	for side in [-1.0, 1.0]:
		var rail_z: float = access_z + side * .78
		var lower := Vector3(86.60, -.45, rail_z)
		var upper := Vector3(87.61, -.105, rail_z)
		var lower_top := Vector3(lower.x, .39, rail_z)
		var upper_top := Vector3(upper.x, .82, rail_z)
		for foot in [lower, upper]:
			var rail_top := lower_top.y if foot == lower else upper_top.y
			var height: float = rail_top - foot.y
			_make_box("Dock access rail post", Vector3(.077, height, .078),
				foot + Vector3.UP * height * .5, Color.WHITE).material_override = rail_metal
			_make_box("Dock access foot plate", Vector3(.145, .024, .079),
				foot + Vector3.UP * .012, Color.WHITE).material_override = rail_metal
		_add_moored_round_fitting(self, "Dock access handrail", lower_top, upper_top, .036, rail_metal)
		_add_moored_round_fitting(self, "Handrail transition", upper_top,
			Vector3(87.5, .82, access_z + side * .93), .036, rail_metal)
		_add_moored_round_fitting(self, "Dock access lower rail", lower_top - Vector3.UP * .47,
			upper_top - Vector3.UP * .47, .021, rail_metal)
	var dock_edge := Color("#615344")
	var dock_join := Color("#535c60")
	var dock_float := CapsuleMesh.new()
	dock_float.radius = .23
	dock_float.height = 3.84
	dock_float.radial_segments = 16
	dock_float.rings = 4
	dock_float.material = _material(Color("#303b40"), .78)
	for section in 8:
		var segment_z := -38.0 + section * 4.0
		for float_x in [85.34, 86.26]:
			var pontoon := MeshInstance3D.new()
			pontoon.name = "Floating dock pontoon"
			pontoon.mesh = dock_float
			pontoon.position = Vector3(float_x, -.936, segment_z)
			pontoon.rotation.x = PI * .5
			add_child(pontoon)
		for offset in [-1.20, 1.20]:
			_make_box("Floating dock pontoon cross brace", Vector3(1.34, .085, .12),
				Vector3(85.8, -.778, segment_z + offset), dock_join)
		for edge_x in [85.11, 86.49]:
			_make_box("Floating dock rubbing strip", Vector3(.055, .11, 3.97),
				Vector3(edge_x, -.589, segment_z), dock_edge)
		if section > 0:
			var seam_z := segment_z - 2.0
			_make_box("Floating dock deck joint", Vector3(1.35, .004, .025),
				Vector3(85.8, -.504, seam_z), dock_join)
			for edge_x in [85.19, 86.41]:
				_make_box("Floating dock splice plate", Vector3(.115, .018, .24),
					Vector3(edge_x, -.498, seam_z), dock_join)
				for offset in [-.076, .076]:
					_make_box("Floating dock splice bolt", Vector3(.025, .009, .025),
						Vector3(edge_x, -.484, seam_z + offset), Color("#929b9b"))
	for end_z in [-39.98, -8.02]:
		_make_box("Floating dock end trim", Vector3(1.42, .11, .048),
			Vector3(85.8, -.589, end_z), dock_edge)
	var rope := CylinderMesh.new()
	rope.top_radius = 0.018
	rope.bottom_radius = 0.018
	rope.height = 1.0
	rope.radial_segments = 6
	rope.rings = 0
	rope.material = _material(Color("#a29a84"), 0.94)
	var eye_mesh := TorusMesh.new()
	eye_mesh.inner_radius = .034
	eye_mesh.outer_radius = .057
	eye_mesh.rings = 12
	eye_mesh.ring_segments = 8
	var galvanised := _material(Color("#797e7d"), .35)
	galvanised.metallic = .65
	eye_mesh.material = galvanised
	for anchor_z in [-38.8, -30.0, -22.0, -14.0, -8.8]:
		var wall_plate := _make_box("Quay anchor plate", Vector3(.045, .25, .28),
			Vector3(EAST_QUAY_WATER_EDGE - .018, -.57, anchor_z), Color.WHITE)
		wall_plate.material_override = galvanised
		var dock_plate := _make_box("Dock anchor plate", Vector3(.06, .17, .23),
			Vector3(86.49, -.61, anchor_z), Color.WHITE)
		dock_plate.material_override = galvanised
		for lug_z in [-.065, .065]:
			_make_box("Hinged dock tie arm", Vector3(.26, .047, .031),
				Vector3(86.62, -.605, anchor_z + lug_z), dock_join)
		for hinge_x in [86.51, 86.73]:
			_add_moored_round_fitting(self, "Dock tie hinge pin",
				Vector3(hinge_x, -.605, anchor_z - .091),
				Vector3(hinge_x, -.605, anchor_z + .091), .024, galvanised)
		for bolt_z in [-.096, .096]:
			_make_box("Quay anchor bolt head", Vector3(.022, .027, .027),
				Vector3(86.704, -.487, anchor_z + bolt_z), dock_join)
	var buoy_band := CylinderMesh.new()
	buoy_band.top_radius = MOORING_BUOY_RADIUS + .002
	buoy_band.bottom_radius = MOORING_BUOY_RADIUS + .002
	buoy_band.height = .058
	buoy_band.radial_segments = 32
	buoy_band.rings = 0
	buoy_band.material = _material(Color("#f0dfbe"), .31)
	var eye_mount_mesh := CylinderMesh.new()
	eye_mount_mesh.top_radius = .068
	eye_mount_mesh.bottom_radius = .087
	eye_mount_mesh.height = .05
	eye_mount_mesh.radial_segments = 16
	eye_mount_mesh.material = galvanised
	var fender_mesh := CapsuleMesh.new()
	fender_mesh.radius = .14
	fender_mesh.height = .51
	fender_mesh.radial_segments = 12
	fender_mesh.rings = 4
	fender_mesh.material = _material(Color("#30373b"), .86)
	var windscreen_glass := StandardMaterial3D.new()
	windscreen_glass.albedo_color = Color(.43, .68, .76, .29)
	windscreen_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	windscreen_glass.roughness = .16
	windscreen_glass.disable_receive_shadows = true
	windscreen_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var canopy_tube_material := _material(Color("#9aa4a7"), .31)
	canopy_tube_material.metallic = .7
	var windscreen_trim := Color("#323d43")
	for berth in MOORING_COUNT:
		var z := MOORING_START_Z + berth*MOORING_SPACING
		for side in [-1.0, 1.0]:
			var fender := MeshInstance3D.new()
			fender.name = "Dock fender"
			fender.mesh = fender_mesh
			fender.position = Vector3(85.07,-.69,z+.61*side)
			add_child(fender)
		var boat := Node3D.new()
		add_child(boat)
		boat.position = Vector3(82.35,-.92,z)
		boat.rotation.y = sin(berth*2.1)*.07
		# Cross sections along the keel taper to a pointed bow.
		var hull := SurfaceTool.new()
		hull.begin(Mesh.PRIMITIVE_TRIANGLES)
		var finishes := [Color("#d4d1c4"),Color("#27445b"),Color("#9c5838"),Color("#acb8b6")]
		var hull_material := _material(finishes[berth % finishes.size()],.36)
		hull_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		hull.set_material(hull_material)
		var previous: Array[Vector3] = []
		for section: Vector3 in [
			Vector3(-2.8, 0, .34), Vector3(-2.54, .32, .21),
			Vector3(-2.15, .61, .09), Vector3(-1.25, .91, 0),
			Vector3(.5, 1.02, 0), Vector3(2.55, .85, 0),
		]:
			var x := section.x
			var w := section.y
			var rake := section.z
			var ring: Array[Vector3] = [
				Vector3(x, .58, -w), Vector3(x + rake * (.50 / .76), .08, -w * .8),
				Vector3(x + rake, -.18, 0), Vector3(x + rake * (.50 / .76), .08, w * .8), Vector3(x, .58, w),
			]
			if not previous.is_empty():
				for k in 5:
					var n := (k + 1) % 5
					hull.set_smooth_group(0 if k < 4 else -1)
					for point in [previous[k], ring[n], ring[k]]:
						hull.add_vertex(point)
					if previous[k] != previous[n]:
						for point in [previous[k], previous[n], ring[n]]:
							hull.add_vertex(point)
			if x == 2.55:
				hull.set_smooth_group(-1)
				for k in range(1, 4):
					for point in [ring[0], ring[k], ring[k + 1]]:
						hull.add_vertex(point)
			previous = ring
		hull.generate_normals()
		var shell := MeshInstance3D.new()
		shell.mesh = hull.commit()
		boat.add_child(shell)
		var lower_glass := [
			Vector3(-.29, .59, -.83), Vector3(-.72, .59, -.57),
			Vector3(-.72, .59, .57), Vector3(-.29, .59, .83),
		]
		var upper_glass := [
			Vector3(-.23, 1.10, -.74), Vector3(-.55, 1.14, -.52),
			Vector3(-.55, 1.14, .52), Vector3(-.23, 1.10, .74),
		]
		var glazing := SurfaceTool.new()
		glazing.begin(Mesh.PRIMITIVE_TRIANGLES)
		glazing.set_material(windscreen_glass)
		for panel in 3:
			for corner in [lower_glass[panel], upper_glass[panel], upper_glass[panel + 1],
					lower_glass[panel], upper_glass[panel + 1], lower_glass[panel + 1]]:
				glazing.add_vertex(corner)
		glazing.generate_normals()
		var pane := MeshInstance3D.new()
		pane.name = "Vindruta"
		pane.mesh = glazing.commit()
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		boat.add_child(pane)
		for corner in 4:
			_add_moored_windscreen_trim(boat, lower_glass[corner], upper_glass[corner], windscreen_trim)
		for panel in 3:
			_add_moored_windscreen_trim(boat, lower_glass[panel], lower_glass[panel + 1], windscreen_trim)
			_add_moored_windscreen_trim(boat, upper_glass[panel], upper_glass[panel + 1], windscreen_trim)
		var hatch := Node3D.new()
		hatch.name = "Foredeck hatch"
		hatch.position = Vector3(-1.52, .58, 0)
		boat.add_child(hatch)
		_make_box("Hatch coaming", Vector3(.57, .04, .46), Vector3(0, .018, 0),
			Color("#aeb5b6"), false, hatch)
		_make_box("Hatch gasket", Vector3(.54, .016, .43), Vector3(0, .043, 0),
			Color("#20282b"), false, hatch)
		_make_box("Hatch lid", Vector3(.52, .025, .41), Vector3(0, .06, 0),
			Color("#41535b"), false, hatch)
		for hinge_z in [-.135, .135]:
			var hinge := _make_box("Hatch hinge leaf", Vector3(.084, .014, .066),
				Vector3(.252, .074, hinge_z), Color.WHITE, false, hatch)
			hinge.material_override = galvanised
			_add_moored_round_fitting(hatch, "Hatch hinge pin", Vector3(.287, .073, hinge_z - .028),
				Vector3(.287, .073, hinge_z + .028), .008, galvanised)
		_make_box("Recessed hatch handle", Vector3(.068, .004, .118), Vector3(-.17, .074, 0),
			Color("#20282b"), false, hatch)
		_make_box("Hatch pull", Vector3(.023, .012, .087), Vector3(-.17, .08, 0),
			Color("#aeb5b6"), false, hatch)
		var cover := [Color("#253b51"),Color("#b7afa0"),Color("#365b64")][berth%3] as Color
		if berth % 3 == 2:
			_add_moored_boat_helm(boat, galvanised)
			_add_moored_outboard(boat, galvanised)
			for seat_x in [.10, 1.36]:
				var frame_color := Color("#3b4244")
				var piping_color := Color("#987e64")
				for foot_z in [-.49, .49]:
					_make_box("Bench mounting plate", Vector3(.28, .024, .13),
						Vector3(seat_x, .592, foot_z), frame_color, false, boat)
					_make_box("Bench pedestal", Vector3(.19, .19, .082),
						Vector3(seat_x, .675, foot_z), frame_color, false, boat)
				_make_box("Bench base", Vector3(.44, .055, 1.42),
					Vector3(seat_x, .758, 0), frame_color, false, boat)
				var backrest := Node3D.new()
				backrest.name = "Bench backrest"
				backrest.position = Vector3(seat_x + .18, .788, 0)
				backrest.rotation.z = -.14
				boat.add_child(backrest)
				_make_box("Backrest shell", Vector3(.055, .34, 1.42),
					Vector3(.042, .17, 0), frame_color, false, backrest)
				for seat_z in [-.47, 0.0, .47]:
					_make_box("Seat cushion piping", Vector3(.417, .02, .451),
						Vector3(seat_x - .01, .796, seat_z), piping_color, false, boat)
					_make_box("Seat cushion", Vector3(.40, .077, .434),
						Vector3(seat_x - .01, .832, seat_z), Color("#d7c2a9"), false, boat)
					_make_box("Backrest piping", Vector3(.047, .317, .451),
						Vector3(-.01, .178, seat_z), piping_color, false, backrest)
					_make_box("Backrest cushion", Vector3(.066, .30, .434),
						Vector3(-.035, .178, seat_z), Color("#c8b094"), false, backrest)
		else:
			var fabric := SurfaceTool.new()
			fabric.begin(Mesh.PRIMITIVE_TRIANGLES)
			var canvas := _material(cover,.88, false, "weave")
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
						for pt: Vector3 in [last[k],arch[k],arch[k+1],last[k],arch[k+1],last[k+1]]:
							fabric.set_uv(Vector2(pt.x, pt.z))
							fabric.add_vertex(pt)
				frames.append(arch)
			fabric.generate_normals()
			var canopy := MeshInstance3D.new()
			canopy.mesh = fabric.commit()
			boat.add_child(canopy)
			for frame_index in [1, 2]:
				var arch: Array[Vector3] = []
				for corner: Vector3 in frames[frame_index]:
					arch.append(corner - Vector3.UP * .045)
				for segment in 4:
					_add_moored_round_fitting(boat, "Canopy support tube", arch[segment],
						arch[segment + 1], .017, canopy_tube_material)
				for edge in [0, 4]:
					var corner: Vector3 = arch[edge]
					var foot := Vector3(corner.x + .13, .61, corner.z * .91)
					_add_moored_round_fitting(boat, "Canopy support tube", foot, corner, .017, canopy_tube_material)
					_make_box("Canopy mounting plate", Vector3(.12, .034, .075), foot,
						Color("#3d494e"), false, boat)
		var buoy := MeshInstance3D.new()
		var float_mesh := CapsuleMesh.new()
		float_mesh.radius=MOORING_BUOY_RADIUS
		float_mesh.height=MOORING_BUOY_HEIGHT
		buoy.mesh=float_mesh
		buoy.material_override=_material(Color("#c82c38"),.38)
		buoy.name = "Mooring buoy"
		buoy.position = Vector3(EAST_QUAY_WATER_EDGE-MOORING_BUOY_OFFSET,-.73,z+MOORING_BUOY_Z_OFFSET)
		buoy.rotation.z=.13*sin(berth)
		add_child(buoy)
		var band := MeshInstance3D.new()
		band.name = "Mooring buoy visibility band"
		band.mesh = buoy_band
		band.position.y = .226
		buoy.add_child(band)
		var eye_mount := MeshInstance3D.new()
		eye_mount.name = "Mooring eye mount"
		eye_mount.mesh = eye_mount_mesh
		eye_mount.position.y = MOORING_BUOY_HEIGHT * .5
		buoy.add_child(eye_mount)
		var eye := MeshInstance3D.new()
		eye.name = "Mooring eye"
		eye.mesh = eye_mesh
		eye.position.y = .49
		eye.rotation.x = PI * .5
		buoy.add_child(eye)
		var lines: Array[MeshInstance3D] = []
		for i in range(3):
			var line := MeshInstance3D.new()
			line.mesh = rope
			add_child(line)
			lines.append(line)
		var cleats: Array[Node3D] = []
		for side in [-1.0, 1.0]:
			var cleat := _make_box("Mooring cleat base", Vector3(.13,.04,.21),
				Vector3(85.28,-.485,z+1.35*side), Color.WHITE)
			cleat.material_override = galvanised
			for offset in [-.07,.07]:
				var foot := _make_box("Mooring cleat foot", Vector3(.048,.067,.048),
					Vector3(0,.046,offset), Color.WHITE, false, cleat)
				foot.material_override = galvanised
			var bar := _make_box("Mooring cleat horns", Vector3(.058,.034,.28),
				Vector3(0,.09,0), Color.WHITE, false, cleat)
			bar.material_override = galvanised
			var anchor := Marker3D.new()
			anchor.position.y = .062
			cleat.add_child(anchor)
			cleats.append(anchor)
		var hull_bounds := _model_bounds(boat, boat)
		var bow_cleat := _make_box("Bow cleat mounting plate", Vector3(.145, .025, .105),
			Vector3(-2.54, .59, 0), Color.WHITE, false, boat)
		bow_cleat.material_override = galvanised
		for x in [-.045, .045]:
			var foot := _make_box("Bow cleat foot", Vector3(.039, .055, .034),
				Vector3(x, .031, 0), Color.WHITE, false, bow_cleat)
			foot.material_override = galvanised
		var horns := _make_box("Bow cleat horns", Vector3(.195, .029, .041),
			Vector3(0, .061, 0), Color.WHITE, false, bow_cleat)
		horns.material_override = galvanised
		var bow_line := Marker3D.new()
		bow_line.position = Vector3(-.027, .046, 0)
		bow_cleat.add_child(bow_line)
		moorings.append({"boat":boat, "buoy":buoy, "eye":eye, "cleats":cleats, "bow_line":bow_line, "lines":lines, "phase":berth*1.7,
			"heading":boat.rotation.y, "hull_bounds":hull_bounds})
	_update_moorings(0.0)

func _boardwalk_rope_mesh(finish: Material) -> ArrayMesh:
	const LENGTH := 2.94
	const SAG := .60
	const SIDES := 10
	const SEGMENTS := 18
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(finish)
	for station in SEGMENTS + 1:
		var t := float(station) / SEGMENTS
		var center := Vector3(0, -SAG * t * (1.0 - t), LENGTH * t)
		var across := Vector3(0, LENGTH, SAG * (1.0 - 2.0 * t)).normalized()
		for side in SIDES:
			var angle := TAU * side / SIDES
			var normal := Vector3.RIGHT * cos(angle) + across * sin(angle)
			surface.set_normal(normal)
			surface.add_vertex(center + normal * .019)
	for station in SEGMENTS:
		for side in SIDES:
			var first := station * SIDES + side
			var next := station * SIDES + (side + 1) % SIDES
			for index in [first, first + SIDES, next, next, first + SIDES, next + SIDES]:
				surface.add_index(index)
	return surface.commit()


func _add_moored_windscreen_trim(boat: Node3D, start: Vector3, end: Vector3, color: Color) -> void:
	var span := end - start
	var frame := _make_box("Windscreen frame", Vector3(.031, .031, span.length() + .023),
		(start + end) * .5, color, false, boat)
	frame.basis = Basis.looking_at(span)

func _add_moored_boat_helm(boat: Node3D, metal: Material) -> void:
	var helm := Node3D.new()
	helm.name = "Small boat helm"
	helm.position = Vector3(-.49, .58, -.47)
	boat.add_child(helm)
	var graphite := Color("#29373d")
	_make_box("Helm pedestal", Vector3(.16, .31, .32), Vector3(-.02, .155, 0),
		Color("#c6c0ad"), false, helm)
	_make_box("Instrument panel", Vector3(.19, .15, .34), Vector3(-.027, .31, 0),
		graphite, false, helm)
	for dial_z in [-.097, .097]:
		_add_moored_round_fitting(helm, "Gauge bezel", Vector3(.064, .344, dial_z),
			Vector3(.073, .344, dial_z), .044, metal)
		_make_box("Gauge face", Vector3(.005, .050, .048), Vector3(.093, .344, dial_z),
			graphite, false, helm)
		_make_box("Gauge needle", Vector3(.004, .026, .004), Vector3(.098, .347, dial_z),
			Color("#e7b97d"), false, helm).rotation.x = -.56
	var wheel := MeshInstance3D.new()
	wheel.name = "Helm wheel rim"
	var rim := TorusMesh.new()
	rim.inner_radius = .107
	rim.outer_radius = .125
	rim.rings = 24
	rim.ring_segments = 10
	rim.material = _material(graphite, .75)
	wheel.mesh = rim
	wheel.rotation.z = PI * .5
	wheel.position = Vector3(.17, .245, 0)
	helm.add_child(wheel)
	var hub := wheel.position
	_add_moored_round_fitting(helm, "Steering column", Vector3(.045, hub.y, 0),
		hub + Vector3(.016, 0, 0), .026, metal)
	for i in 3:
		var angle := TAU * i / 3.0
		var spoke_tip := hub + Vector3(0, -cos(angle), sin(angle)) * .112
		_add_moored_round_fitting(helm, "Wheel spoke", hub, spoke_tip, .009, metal)


func _add_moored_outboard(boat: Node3D, metal: Material) -> void:
	var motor := Node3D.new()
	motor.name = "Stern outboard"
	motor.position = Vector3(2.55, .57, 0)
	boat.add_child(motor)
	var graphite := Color("#2d373d")
	for clamp_z in [-.12, .12]:
		_make_box("Transom clamp", Vector3(.14, .15, .055),
			Vector3(.004, -.052, clamp_z), graphite, false, motor)
		_make_box("Clamp pad", Vector3(.083, .035, .078),
			Vector3(-.052, .017, clamp_z), Color.WHITE, false, motor).material_override = metal
	_add_moored_round_fitting(motor, "Outboard hinge", Vector3(.063, .018, -.143),
		Vector3(.063, .018, .143), .027, metal)
	var leg := _make_box("Outboard leg", Vector3(.082, .26, .10),
		Vector3(.124, -.088, 0), graphite, false, motor)
	leg.rotation.z = .25
	_make_box("Anti-ventilation plate", Vector3(.20, .019, .18),
		Vector3(.144, -.196, 0), graphite, false, motor)
	_add_moored_round_fitting(motor, "Gearcase", Vector3(.064, -.238, 0),
		Vector3(.199, -.238, 0), .031, metal)
	var cowl := MeshInstance3D.new()
	cowl.name = "Outboard cowl"
	var shell := CapsuleMesh.new()
	shell.radius = .135
	shell.height = .39
	shell.radial_segments = 20
	shell.rings = 6
	shell.material = _material(graphite, .34)
	cowl.mesh = shell
	cowl.scale = Vector3(.80, .68, 1)
	cowl.position = Vector3(.106, .127, 0)
	motor.add_child(cowl)
	_make_box("Cowl seam", Vector3(.172, .018, .238), Vector3(.106, .063, 0),
		Color("#60717a"), false, motor)


func _add_moored_round_fitting(parent: Node3D, part_name: String, start: Vector3, end: Vector3,
		radius: float, material: Material) -> void:
	var span := end - start
	var tube := CylinderMesh.new()
	tube.top_radius = radius
	tube.bottom_radius = radius
	tube.height = span.length() + radius
	tube.radial_segments = 10
	tube.material = material
	var support := MeshInstance3D.new()
	support.name = part_name
	support.mesh = tube
	support.position = (start + end) * .5
	support.quaternion = Quaternion(Vector3.UP, span.normalized())
	parent.add_child(support)


func _build_quay_windsock() -> void:
	var foot := Vector3(54.6,0,-16.5)
	_make_roadside_solid("Windsock mast",Vector3(.085,3.8,.085),foot+Vector3.UP*1.9,Color("#798183"))
	quay_windsock.name = "QuayWindsock"
	quay_windsock.position = foot+Vector3.UP*3.76
	add_child(quay_windsock)
	_make_box("Swivel bracket",Vector3(.37,.045,.045),Vector3(.15,0,0),Color("#6d7777"),false,quay_windsock)
	for stripe in 5:
		var tube := CylinderMesh.new()
		tube.bottom_radius = .25-.029*stripe
		tube.top_radius = tube.bottom_radius-.029
		tube.height = .32
		tube.rings = 0
		tube.radial_segments = 20
		tube.cap_top = false
		tube.cap_bottom = false
		var fabric := MeshInstance3D.new()
		fabric.mesh = tube
		var tint := Color("#ee572b") if stripe%2 == 0 else Color("#fff4da")
		var finish := _material(tint,.92,false,"cotton_jersey").duplicate() as StandardMaterial3D
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		fabric.material_override = finish
		fabric.rotation.z = -PI*.5-.14
		fabric.position = Vector3(.32,0,0)+fabric.basis.y*(stripe+.5)*tube.height
		quay_windsock.add_child(fabric)

func _ferry_clock() -> float:
	return wave_time - ferry_delay

func _ferry_position_z(trip_time: float) -> float:
	var half_trip := fposmod(trip_time, 58.0)
	var crossing := smoothstep(5.0, 29.0, fmod(half_trip, 29.0))
	return lerpf(FERRY_LANDINGS[0], FERRY_LANDINGS[1], crossing if half_trip < 29.0 else 1.0 - crossing)

func _update_moorings(delta: float) -> void:
	wave_time += delta
	var obstructed := false
	if boating and delta > 0.0:
		# Leave room ahead and astern without widening the ferry's lane.
		var hull := _launch_footprint(launch.position, launch.rotation.y).grow_individual(0.0, .65, 0.0, .65)
		var bounds := ferry.global_transform * ferry_hull_bounds
		var footprint := Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)
		var next := footprint
		next.position.y += _ferry_position_z(_ferry_clock()) - ferry.position.z
		obstructed = next.intersection(hull).get_area() > footprint.intersection(hull).get_area()
	# Resume the trip from rest, keeping the wake and motor sound in step with the ferry.
	ferry_speed_factor = 0.0 if obstructed else move_toward(ferry_speed_factor, 1.0, delta * 1.25)
	var trip_delta := delta * ferry_speed_factor
	ferry_delay += delta - trip_delta
	var trip_time := _ferry_clock()
	var stop := _ferry_stop()
	var signal_on := stop >= 0 and fmod(trip_time,29.0) >= 2.0
	for i in ferry_boarding_lamps.size():
		ferry_boarding_lamps[i].visible = signal_on and i == stop
	if signal_on and trip_delta > 0 and floori((trip_time-2.0)/29.0) > floori((trip_time-trip_delta-2.0)/29.0):
		ferry_boarding_chime.position = ferry_boarding_lamps[stop].position
		ferry_boarding_chime.play()
	quay_windsock.rotation.y = -weather.wind_angle
	_update_ferry_displays()
	var heading := Vector2(-sin(launch.rotation.y),-cos(launch.rotation.y))
	var course := heading*signf(launch_speed)
	var trailing_end := 2.50 if launch_speed < 0 else 2.12
	var wake_origin := Vector2(launch.position.x,launch.position.z)-course*trailing_end
	water_finish.set_shader_parameter("wake_origin",wake_origin)
	water_finish.set_shader_parameter("wake_heading",course)
	water_finish.set_shader_parameter("wake_strength",clampf(absf(launch_speed)/6.0,0,1) if boating else 0.0)
	# A double-ended ferry can reverse away from either landing without turning.
	# Each crossing includes a five-second stop and gentle acceleration.
	var half_trip := fmod(trip_time,58.0)
	var progress := clampf((fmod(half_trip,29.0)-5.0)/24.0,0,1)
	# Normalized speed of the smoothstep crossing, signed toward the current landing.
	var motion := 4.0 * progress * (1.0 - progress) * ferry_speed_factor
	ferry_engine.pitch_scale = lerpf(.66, .87, motion)
	ferry_engine.volume_db = lerpf(-22, -14, motion)
	if mode == "playing" and not paused and not ferry_engine.playing:
		ferry_engine.play()
	water_finish.set_shader_parameter("ferry_motion",-motion if half_trip >= 29.0 else motion)
	ferry.position = Vector3(68,-.97+.024*sin(wave_time*1.1),_ferry_position_z(trip_time))
	water_finish.set_shader_parameter("ferry_center",ferry.position)
	ferry.rotation.z = (288.0 / Mass.FERRY_KG)*sin(wave_time*.88)
	if ferry_passenger:
		walker.position = ferry.to_global(Vector3(-.55,.66,5.1))
		if ferry_exit_requested and _ferry_stop() >= 0:
			_change_seat()
		_update_entry_button()
	var buoy_tops := PackedFloat32Array()
	for berth in moorings:
		var boat: Node3D = berth.boat
		var buoy: Node3D = berth.buoy
		var phase: float = wave_time*1.25 + berth.phase
		boat.position.y = -0.92 + 0.035*sin(phase)
		boat.rotation = Vector3(0.016*sin(phase+0.7), berth.heading, 0.009*cos(phase))
		buoy.position.y = -0.73 + 0.049*sin(phase+0.5)
		buoy.rotation.z = 0.085*sin(phase+0.9)
		var cap_center := MOORING_BUOY_HEIGHT*.5 - MOORING_BUOY_RADIUS
		buoy_tops.append(buoy.to_global(Vector3.UP*cap_center).y + MOORING_BUOY_RADIUS)
		for i in range(3):
			var side := -1.0 if i == 1 else 1.0
			var start := boat.to_global(Vector3(2.44,.56,.71*side))
			var end: Vector3
			if i > 0:
				end = berth.cleats[i-1].global_position
			if i == 0:
				start = berth.bow_line.global_position
				end = berth.eye.global_position
			var axis := end-start
			var line: MeshInstance3D = berth.lines[i]
			line.transform = Transform3D(Basis(Quaternion(Vector3.UP,axis.normalized())).scaled_local(Vector3(1,axis.length(),1)),(start+end)*.5)
	water_finish.set_shader_parameter("mooring_tops", buoy_tops)


func _build_school_clock(school: Node3D) -> void:
	var face := Node3D.new()
	face.name = "SchoolClock"
	school.add_child(face)
	face.position = Vector3(0, 5.5, -3.69)
	face.rotation.y = PI
	for layer in 2:
		var disc := CylinderMesh.new()
		disc.top_radius = 1.03 if layer == 0 else .94
		disc.bottom_radius = disc.top_radius
		disc.height = .08
		var dial := MeshInstance3D.new()
		dial.mesh = disc
		dial.material_override = _material(Color("#30544e") if layer == 0 else Color("#fff0ce"))
		dial.rotation.x = PI / 2
		dial.position.z = layer * .06
		face.add_child(dial)
	var ink := Color("#282d33")
	for hour in 12:
		var angle := hour * TAU / 12
		var tick := _make_box("HourMark", Vector3(.065, .16, .025), Vector3(sin(angle)*.8, cos(angle)*.8, .12), ink, false, face)
		tick.rotation.z = -angle
	for hand in [school_hour_hand, school_minute_hand]:
		face.add_child(hand)
		var length := .69 if hand == school_minute_hand else .47
		_make_box("Hand", Vector3(.07, length, .035), Vector3(0, length/2, .18 if hand == school_minute_hand else .15), ink, false, hand)

func _build_city_blocks() -> void:
	var school := preload("res://environment/school.glb").instantiate() as Node3D
	add_child(school)
	school.position = Vector3(136,-.12,17)
	building_bounds.append(AABB(Vector3(125,-1,13.2),Vector3(22,10,7.6)))
	_make_driving_surface("School courtyard",Vector3(22,.12,9),Vector3(136,-.09,9),Color("#aaa198"))
	# Mark the shared school pickup point from the approaching driver's side.
	for i in 8:
		var x := SCHOOL_CURB.x - (7-i)*2.0
		var flag := _station_sign("❄", Vector3(x,1.05,4.82), .009, Color.WHITE)
		flag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		flag.hide()
		school_plough_flags.append(flag)
	var pickup_post := _make_roadside_solid("School pickup post",Vector3(.08,1.95,.08),SCHOOL_CURB+Vector3(-3, .97,2.1),Color("#626d72"))
	var taxi_sign := _make_box("School taxi sign",Vector3(.06,.42,1.02),Vector3.UP*.82,Color("#eac451"),false,pickup_post)
	for side in [-1,1]:
		var lettering := Label3D.new()
		lettering.text = "Taxi"
		lettering.uppercase = true
		lettering.font_size = 50
		lettering.pixel_size = .0046
		lettering.outline_size = 0
		lettering.modulate = Color("#22282a")
		lettering.double_sided = false
		lettering.rotation.y = side*PI/2
		lettering.position.x = side*.035
		taxi_sign.add_child(lettering)
	var school_name := Label3D.new()
	school_name.text = "HARBOR TOWN SCHOOL"
	school_name.rotation.y = PI
	school_name.position = Vector3(0,3.06,-3.61)
	school_name.pixel_size = .006
	school.add_child(school_name)
	_size_world_sign(school_name, 5.4)
	_build_school_clock(school)
	for stop in BUS_STOPS:
		var gate: Vector3 = _stop_pavement(stop)
		var post := _make_roadside_solid("Bus stop",Vector3(.08,2.65,.08),gate+Vector3(.9,1.32,0),Color("#52636c"))
		var plate := _make_box("Bus stop flag",Vector3(1.55,.72,.06),Vector3(0,1.15,0),Color("#263c51"),false,post)
		# Each face points along the street so the name reads correctly on approach.
		plate.rotation.y = PI*.5 if stop in [0,SCHOOL,4,5] else 0.0
		for side in [-1,1]:
			var route := Label3D.new()
			route.name = "StopNameFront" if side==1 else "StopNameBack"
			route.set_meta("stop_name", BUS_STOP_NAMES[stop])
			route.add_to_group("bus_stop_labels")
			_update_stop_label(route)
			route.double_sided = false
			route.rotation.y = PI if side==-1 else 0.0
			route.position.z = side*.035
			plate.add_child(route)
	var plots := [
		[Vector3(-34,0,-15),Vector3(13,6.4,9),Color("#835143"),"Polisstationen"],
		[Vector3(-15, 0, -15), Vector3(13, 8, 11.6), Color("#d5c4a4"), "Bageriet"],
		[Vector3(16, 0, -15), Vector3(13.8, 11, 13), Color("#bdcfc5"), "Vårdcentralen"],
		[Vector3(-16, 0, 17), Vector3(16.4, 9, 14), Color("#d8c0b5"), "Brandstationen"],
		[Vector3(16, 0, 18), Vector3(13.6, 7, 13), Color("#d8d0b7"), "Biblioteket"]
	]
	for plot in plots:
		_build_building(plot[0], plot[1], plot[2], plot[3])
	var hospital := preload("res://environment/hospital.gd").new()
	add_child(hospital)
	hospital.build(self)
	_make_driving_surface("Police forecourt",Vector3(9,.10,6.5),Vector3(-34,-.12,-7.75),Color("#a6a29a"))
	# Låg kantsten och planteringar runt torget.
	_make_driving_surface("Square paving", Vector3(14, 0.24, 13), Vector3(30, -0.09, 16), Color("#cbbf9f"), true)
	christmas_spruce.position = Vector3(30,.03,16)
	add_child(christmas_spruce)
	midsummer_pole.position = christmas_spruce.position
	add_child(midsummer_pole)
	field_fountain.position = Vector3(41,-.18,45)
	add_child(field_fountain)
	_make_driving_surface("Fountain foundation",Vector3(10,.08,10),field_fountain.position,Color("#809480"),true)
	for p in [Vector3(25, 0, 12), Vector3(35, 0, 12), Vector3(25, 0, 20), Vector3(35, 0, 20)]:
		var granite := Color("#878782")
		_make_roadside_solid("Planter base",Vector3(1.3,.29,1.3),p+Vector3.UP*.12,granite,true)
		_make_box("Planting soil",Vector3(1.10,.025,1.10),p+Vector3.UP*.274,Color("#4c4034"))
		for side in [-1,1]:
			_make_box("Granite coping",Vector3(1.34,.08,.12),p+Vector3(0,.303,side*.61),granite)
			_make_box("Granite coping",Vector3(.12,.08,1.10),p+Vector3(side*.61,.303,0),granite)
		_make_tree(p,0.9,"",.286)

	for x in [29.25,30.75]:
		for z in [21.54,21.86]:
			_make_box("Bench leg",Vector3(.075,.51,.075),Vector3(x,.28,z),Color("#434e4b"))
		_make_box("Seat support",Vector3(.10,.07,.46),Vector3(x,.51,21.7),Color("#434e4b"))
		_make_box("Backrest upright",Vector3(.065,.81,.065),Vector3(x,.90,21.99),Color("#434e4b"))
		_make_box("Seat bearer",Vector3(.085,.12,.45),Vector3(x,.595,21.7),Color("#434e4b"))
	for i in 4:
		_make_roadside_solid("Seat board",Vector3(2.0,.055,.10),Vector3(30,.663,21.53+i*.113),Color("#926e4e"),true)
	for i in 3:
		_make_box("Paint swatch",Vector3(.18,.015,.23),Vector3(29.75+.22*i,.70,21.7),BENCH_COLOURS[i])
	for i in 3:
		_make_box("Backrest board",Vector3(2.0,.135,.065),Vector3(30,.86+i*.17,21.927),Color("#926e4e"),true)

func _build_building(center: Vector3, size: Vector3, _color: Color, sign_text: String) -> void:
	if sign_text != "Brandstationen":
		building_bounds.append(AABB(Vector3(center.x-size.x/2,-1,center.z-size.z/2), size+Vector3.UP))
	var packed: PackedScene = load(BUILDING_SCENES[sign_text])
	var model := packed.instantiate() as Node3D
	model.name = sign_text.replace(" ", "_")
	model.position = Vector3(center.x, 0.0, center.z)
	# Blender -Y (the signed entrance facade) imports as Godot +Z.
	if center.z > 0.0:
		model.rotation.y = PI
	add_child(model)
	_localize_building_sign(model)
	if sign_text == "Brandstationen":
		_build_fire_station_bay(model)
	elif sign_text == "Bageriet":
		_close_bakery_gables(model)
		var door := model.find_child("Bakery glazed door", true, false) as MeshInstance3D
		var glass := model.find_child("Door glass", true, false) as MeshInstance3D
		var door_drop := .255
		door.position.y -= door_drop
		glass.position.y -= door_drop
		_make_box("Bakery entrance threshold", Vector3(1.66, .045, .46), Vector3(0, .024, 6.02), Color("#777a72"), false, model)
		var casing := Color("#eee1c8")
		for side in [-1.0, 1.0]:
			_make_box("Bakery entrance jamb", Vector3(.095,2.49,.13), Vector3(side*.80,1.29,5.99), casing, false, model)
		_make_box("Bakery entrance lintel", Vector3(1.70,.105,.13), Vector3(0,2.57,5.99), casing, false, model)
		var entrance_lamp := _add_entry_light(model.to_global(Vector3(0,2.68,6.24)), Vector3(.62,.05,.16), 4.6)
		entrance_lamp.name = "Bakery entrance light"
		entrance_lamp.look_at(model.to_global(Vector3(0,.024,6.03)), model.global_basis.z)
		var handle_finish := _material(Color("#a19069"), .32)
		handle_finish.metallic = .45
		for height in [1.03, 1.32]:
			var mount := _make_box("Bakery door handle mount", Vector3(.044,.048,.082), Vector3(.59,height-door_drop,6.05), Color.WHITE, false, model)
			mount.material_override = handle_finish
		var pull := _make_box("Bakery door pull", Vector3(.034,.35,.036), Vector3(.59,1.175-door_drop,6.098), Color.WHITE, false, model)
		pull.material_override = handle_finish
		_build_bakery_cup(model)

func _localize_building_sign(model: Node3D) -> void:
	const SIGNS := {
		"polisstation": ["Station name", "Police station"],
		"bageri": ["Bakery sign", "Bakery & Coffee"],
		"vardcentral": ["Clinic sign", "Clinic"],
		"bibliotek": ["Library sign", "Library"],
	}
	var site := model.scene_file_path.get_file().get_basename()
	if not SIGNS.has(site):
		return
	var entry: Array = SIGNS[site]
	var baked := model.find_child(entry[0], true, false) as MeshInstance3D
	if not baked:
		return
	var rect := (model.global_transform.affine_inverse() * baked.global_transform) * baked.get_aabb()
	var at := rect.get_center()
	at.z = rect.end.z + .025
	var finish := baked.get_active_material(0) as StandardMaterial3D
	baked.hide()
	var letters := _station_sign(entry[1], at, rect.size.y / 64.0, finish.albedo_color, 0, model)
	letters.name = "Localized venue name"
	letters.double_sided = false
	_size_world_sign(letters, rect.size.x * 1.1)

func _close_bakery_gables(model: Node3D) -> void:
	var wall := model.find_child("Timber house shell", true, false) as MeshInstance3D
	var timber := wall.get_active_material(0)
	var gables := SurfaceTool.new()
	gables.begin(Mesh.PRIMITIVE_TRIANGLES)
	gables.set_material(timber)
	for side in [-1.0, 1.0]:
		var z: float = side * 5.65
		var corners := PackedVector3Array([
			Vector3(-6.35,5.98,z), Vector3(-6.35,6.13,z), Vector3(0,8.25,z),
			Vector3(6.35,6.13,z), Vector3(6.35,5.98,z),
		])
		var order := [0,1,2,0,2,4,4,2,3] if side > 0 else [2,1,0,4,2,0,3,2,4]
		for index in order:
			var point := corners[index]
			gables.set_normal(Vector3(0,0,side))
			gables.set_uv(Vector2(point.x,point.y)*.25)
			gables.add_vertex(point)
		var eave := _make_box("Bakery eave infill", Vector3(.03,.16,11.30),
			Vector3(side*6.335,6.05,0), Color.WHITE, false, model)
		eave.material_override = timber
	var infill := MeshInstance3D.new()
	infill.name = "Bakery timber gables"
	infill.mesh = gables.commit()
	model.add_child(infill)

func _build_bakery_cup(model: Node3D) -> void:
	var bracket := _make_box("Bakery sign arm",Vector3(.12,.15,2.8),Vector3(0,5.86,7.15),Color("#414544"),false,model)
	_make_box("Hanging rod",Vector3(.06,1.64,.06),Vector3(0,-.82,1.31),Color("#414544"),false,bracket)
	var cup := MeshInstance3D.new()
	cup.name = "Hanging coffee cup"
	var bowl := CylinderMesh.new()
	bowl.top_radius = .55
	bowl.bottom_radius = .34
	bowl.height = .76
	bowl.cap_top = false
	var porcelain := _material(Color("#ffeed1"),.23)
	bowl.material = porcelain
	cup.mesh = bowl
	bracket.add_child(cup)
	cup.position = Vector3(0,-2.05,1.31)
	cup.scale = Vector3.ONE*1.15
	var rim := MeshInstance3D.new()
	var lip := TorusMesh.new()
	lip.inner_radius = .520
	lip.outer_radius = .550
	lip.material = porcelain
	rim.mesh = lip
	rim.position.y = .375
	cup.add_child(rim)

	var inside := porcelain.duplicate() as StandardMaterial3D
	inside.cull_mode = BaseMaterial3D.CULL_FRONT
	var liner := CylinderMesh.new()
	liner.cap_top = false
	liner.cap_bottom = false
	liner.top_radius = .520
	liner.bottom_radius = .435
	liner.height = .29
	liner.material = inside
	var lining := MeshInstance3D.new()
	lining.mesh = liner
	lining.position.y = .23
	cup.add_child(lining)

	var coffee := CylinderMesh.new()
	coffee.top_radius = .446
	coffee.bottom_radius = .437
	coffee.height = .024
	coffee.material = _material(Color("#422a1e"), .48)
	var filling := MeshInstance3D.new()
	filling.mesh = coffee
	filling.position.y = .092
	cup.add_child(filling)
	var handle := MeshInstance3D.new()
	var loop_mesh := TorusMesh.new()
	loop_mesh.inner_radius = .19
	loop_mesh.outer_radius = .29
	loop_mesh.material = porcelain
	handle.mesh = loop_mesh
	cup.add_child(handle)
	handle.rotation.x = PI*.5
	handle.position = Vector3(.54,.01,0)
	var saucer := MeshInstance3D.new()
	var dish := CylinderMesh.new()
	dish.top_radius = .66
	dish.bottom_radius = .51
	dish.height = .10
	dish.material = porcelain
	saucer.mesh = dish
	cup.add_child(saucer)
	saucer.position.y = -.42

func _build_fire_station_bay(model: Node3D) -> void:
	for part: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var title := String(part.name)
		if title in ["Station foundation","Red brick fire station"] or (absf(part.position.x)<2 and (title.begins_with("Garage") or title.begins_with("Roller door"))):
			part.hide()
	model.find_child("Fire house sign",true,false).hide()
	var nameplate := _make_box("Fire station nameplate",Vector3(8.2,.82,.14),Vector3(0,7.83,6.98),Color("#472022"),false,model)
	fire_sign_face = _material(Color("#472022"),.48,true)
	fire_sign_face.emission = Color("#9b2520")
	nameplate.material_override = fire_sign_face
	var letters := _road_sign_text(nameplate,"FIRE AND RESCUE",Vector3(0,0,.078),.018,Color("#fff6dc"))
	_size_world_sign(letters,7.85)
	# A two-sided blade sign faces drivers approaching along the street.
	var blade := _make_box("Fire station projecting sign",Vector3(.14,1.65,1.55),Vector3(5.8,5.9,8.10),Color("#682625"),false,model)
	for height in [-.54,.54]:
		_make_box("Sign wall bracket",Vector3(.12,.10,.58),Vector3(0,height,-.97),Color("#42474a"),false,blade)
	var flame_outline := PackedVector2Array([Vector2(-.03,.66),Vector2(.04,.32),Vector2(.24,.13),
		Vector2(.30,.31),Vector2(.49,-.05),Vector2(.45,-.36),Vector2(.24,-.54),
		Vector2(-.06,-.60),Vector2(-.34,-.48),Vector2(-.49,-.26),Vector2(-.48,.03),
		Vector2(-.31,.27),Vector2(-.27,.04),Vector2(-.15,.23)])
	var flame := CSGPolygon3D.new()
	flame.name = "Illuminated flame"
	flame.polygon = flame_outline
	flame.depth = .17
	flame.rotation.y = PI*.5
	flame.position.x = .085
	flame.material = _material(Color("#ffb340"),.46,true)
	blade.add_child(flame)
	var facade := model.find_child("Red brick fire station",true,false) as MeshInstance3D
	var foundation := model.find_child("Station foundation",true,false) as MeshInstance3D
	var warning := model.find_child("Garage warning stripe",true,false) as MeshInstance3D
	var brick := facade.get_active_material(0)
	for side in [-1,1]:
		var wing := facade.duplicate() as MeshInstance3D
		model.add_child(wing)
		wing.scale.x *= 5.8/16.0
		wing.position.x = side*5.1
		wing.show()
		var base := foundation.duplicate() as MeshInstance3D
		model.add_child(base)
		base.scale.x *= 6.0/16.4
		base.position.x = side*5.2
		base.show()
		var wing_bounds := (wing.global_transform*wing.get_aabb()).merge(base.global_transform*base.get_aabb())
		building_bounds.append(wing_bounds.expand(wing_bounds.position-Vector3.UP))
		var jamb := warning.duplicate() as MeshInstance3D
		model.add_child(jamb)
		jamb.position = Vector3(side*2.26,2.29,7.04)
		jamb.scale.y *= 4.6/3.25
	var back := _make_box("Appliance bay rear wall",Vector3(4.4,8,.25),Vector3(0,3,-6.7),Color.WHITE,false,model)
	back.material_override = brick
	building_bounds.append((back.global_transform*back.get_aabb()).grow(.02))
	var lintel := _make_box("Door lintel",Vector3(4.4,2.45,.3),Vector3(0,5.85,6.70),Color.WHITE,false,model)
	lintel.material_override = brick
	fire_station_shutter = _make_box("Appliance bay shutter",Vector3(4.4,4.7,.10),Vector3(0,2.25,6.95),Color.WHITE,false,model)
	var original_door := model.find_child("Roller door",true,false) as MeshInstance3D
	fire_station_shutter.material_override = original_door.get_active_material(0)
	for rib in 17:
		_make_box("Shutter slat",Vector3(4.35,.035,.025),Vector3(0,-2.18+rib*.27,.06),Color("#828b8e"),false,fire_station_shutter)
	fire_door_bounds = (fire_station_shutter.global_transform*fire_station_shutter.get_aabb()).grow(.25)
	fire_door_index = building_bounds.size()
	building_bounds.append(fire_door_bounds)

func _update_fire_station_door(delta: float) -> void:
	var player_body := ambulance.global_transform*AABB(Vector3(-player_half_size.x,-.1,-front_reach),
		Vector3(player_half_size.x*2,3.8,front_reach+rear_reach))
	var approach := fire_door_bounds.grow(2.2)
	var requested := vehicle_index == 2 and ambulance.visible and approach.intersects(player_body)
	if parked_cars[2].visible:
		requested = requested or approach.intersects(_parked_bounds(2))
	if not requested and fire_door_open == 0: return
	var occupied := requested or _fire_door_occupied(fire_door_bounds.grow(.5),player_body)
	fire_door_open = move_toward(fire_door_open,1.0 if occupied else 0.0,delta)
	fire_station_shutter.scale.y = lerpf(1,.025,fire_door_open)
	fire_station_shutter.position.y = 4.60-2.35*fire_station_shutter.scale.y
	var barrier := fire_door_bounds
	if fire_door_open >= .99: barrier.position.y += 6
	building_bounds[fire_door_index] = barrier

func _fire_door_occupied(opening: AABB, player_body: AABB) -> bool:
	if ambulance.visible and opening.intersects(player_body): return true
	if walker.visible and opening.has_point(walker.position+Vector3.UP): return true
	for i in parked_cars.size():
		if parked_cars[i].visible and opening.intersects(_parked_bounds(i)): return true
	for item in traffic_data:
		if opening.intersects(_traffic_bounds(item)): return true
	for item in walker_data:
		if item.actor.visible and opening.has_point(item.actor.position+Vector3.UP): return true
	return false


func _build_trees() -> void:
	for x in range(-40, 45, 8):
		if absf(x) < 7: continue
		if x != -16: # Keep the bakery entrance clear.
			_make_tree(Vector3(x, 0, -8.6), 0.95)
		var tree_x: float = x + 3.2
		if absf(tree_x-FIRE_RETURN_BAY.x)<2.2: tree_x -= 3.0
		_make_tree(Vector3(tree_x, 0, 8.6), 0.82)
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

func _plant_park_edges() -> void:
	var foliage := ShaderMaterial.new()
	foliage.shader = preload("res://environment/foliage.gdshader")
	foliage.set_shader_parameter("leaf_grain", preload("res://art/surfaces/leaf.png"))
	foliage.set_shader_parameter("leaf_color", Color("#55763d"))
	var crown := SphereMesh.new()
	crown.radial_segments = 10
	crown.rings = 5
	crown.material = foliage
	var planted := 0
	for z in [43,64,73,34,56]:
		for x in [-46,-33,-17,17,30,46]:
			var footprint := AABB(Vector3(x-2,-.3,z-2), Vector3(4,6,4))
			var clear := true
			for bounds in building_bounds + roadside_solids + driving_surfaces:
				if bounds.end.y > -.19 and footprint.intersects(bounds):
					clear = false
					break
			for trunk in trunks:
				if Vector2(x-trunk.x,z-trunk.z).length_squared() < 16:
					clear = false
			if not clear: continue
			if planted % 3 == 0:
				_make_tree(Vector3(x,0,z), .75 + .06*(planted%5))
			else:
				var shrub := Node3D.new()
				shrub.name = "ParkShrub%d" % planted
				add_child(shrub)
				shrub.position = Vector3(x,-.2,z)
				shrub.rotation.y = planted*2.4
				for offset in [-1,0,1]:
					var lobe := MeshInstance3D.new()
					lobe.mesh = crown
					lobe.scale = Vector3(1.25,1.45-.45*abs(offset),1.2)
					lobe.position = Vector3(offset*.49,lobe.scale.y*.42,offset*offset*.18)
					shrub.add_child(lobe)
			planted += 1

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
					foliage.set_shader_parameter("leaf_grain", preload("res://art/surfaces/leaf.png"))
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
	var canopy := AABB()
	for branch: MeshInstance3D in tree.find_children("*", "MeshInstance3D", true, false):
		if branch == distant: continue
		var bounds := branch.global_transform * branch.get_aabb()
		canopy = bounds if not canopy.has_volume() else canopy.merge(bounds)
	if canopy.has_volume():
		var crown_base := canopy.position.y + canopy.size.y * .30
		canopy_camera_bounds.append(AABB(Vector3(canopy.position.x, crown_base, canopy.position.z), Vector3(canopy.size.x, canopy.end.y - crown_base, canopy.size.z)))
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
	# The striped stack makes the workshop recognizable above the surrounding roofs.
	for band in 5:
		var stack := MeshInstance3D.new()
		stack.name = "WorkshopChimneyBand%d" % band
		var section := CylinderMesh.new()
		section.height = 1.5
		section.bottom_radius = .8 - band * .065
		section.top_radius = section.bottom_radius - .065
		section.radial_segments = 24
		section.rings = 0
		stack.mesh = section
		stack.material_override = _material(Color("#ad513c") if band % 2 == 0 else Color("#e4dacc"))
		stack.position = p + Vector3(6, 6.25 + band * section.height, -2.8)
		add_child(stack)
	var beacon_mount := MeshInstance3D.new()
	beacon_mount.name = "WorkshopChimneyBeaconMount"
	var collar := CylinderMesh.new()
	collar.top_radius = .20
	collar.bottom_radius = .24
	collar.height = .11
	collar.radial_segments = 24
	beacon_mount.mesh = collar
	beacon_mount.material_override = _material(Color("#34393b"), .61)
	beacon_mount.position = p + Vector3(6, 13.055, -2.8)
	add_child(beacon_mount)
	var beacon := MeshInstance3D.new()
	beacon.name = "WorkshopChimneyBeacon"
	var lens := SphereMesh.new()
	lens.radius = .18
	lens.height = .36
	beacon.mesh = lens
	beacon.position = p + Vector3(6,13.25,-2.8)
	chimney_beacon = _material(Color("#551119"),.28)
	chimney_beacon.emission = Color("#ff1310")
	chimney_beacon.emission_energy_multiplier = 4.0
	beacon.material_override = chimney_beacon
	add_child(beacon)
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
	workshop_name.text = "HARBOR TOWN GARAGE"
	workshop_name.pixel_size=.012
	workshop_name.font_size=48
	workshop_name.outline_size=0
	workshop_name.position=p+Vector3(0,4.57,-5.23)
	workshop_name.rotation.y=PI
	add_child(workshop_name)
	_size_world_sign(workshop_name, 13.7)
	var tyre_post := _signpost(STATION_DROP+Vector3(3.8,0,2.6),PI)
	_make_box("Tyre service sign",Vector3(2.8,.62,.08),Vector3(0,2.55,.06),Color("#244750"),false,tyre_post)
	var tyre_sign := _road_sign_text(tyre_post,"Tyre service",Vector3(0,2.55,.11),.0045,Color("#edf7f7"))
	_size_world_sign(tyre_sign,2.55)
	var tyre_rack := STATION_DROP + Vector3(5.3,0,3.8)
	var rack_finish := Color("#344d4d")
	for x in [-.97,.97]:
		for z in [-.31,.31]:
			_make_box("Tyre rack upright",Vector3(.065,1.94,.065),tyre_rack+Vector3(x,.97,z),rack_finish)
	var rubber := _material(Color("#171a1b"),.91,false,"rubber")
	var casing := TorusMesh.new()
	casing.inner_radius = .19
	casing.outer_radius = .34
	casing.rings = 32
	casing.ring_segments = 12
	for shelf in [.17,1.04]:
		for z in [-.24,.24]:
			_make_box("Tyre rack beam",Vector3(2,.07,.085),tyre_rack+Vector3(0,shelf,z),rack_finish)
		for slot in 6:
			var tyre := MeshInstance3D.new()
			tyre.name = "Tyre casing"
			tyre.mesh = casing
			tyre.material_override = rubber
			tyre.rotation.z = PI*.5
			tyre.position = tyre_rack+Vector3(-.76+slot*.30,shelf+.30,0)
			add_child(tyre)
	var crossings: Array = street_signals.EAST_CROSSINGS.duplicate()
	for x in street_signals.CENTRAL_BOULEVARD_CROSSINGS:
		crossings.append(Vector3(x,0,0))
	for crossing in crossings:
		for stripe in range(-4,5):
			_make_box("Zebra crossing",Vector3(2.4,.014,.52),crossing+Vector3(0,_surface_height(crossing.x,crossing.z)+.014,stripe),Color("#eee9d9")).material_override = marking_finish

func _update_daylight(delta: float) -> void:
	if time_mode == 2:
		if mode == "playing" and not paused:
			day_phase = fmod(day_phase+delta/DAY_CYCLE_SECONDS,1.0)
	# Phase zero is noon and phase one half is midnight.
	var clock_hours := 0.0 if time_mode == 1 else (12.0 + day_phase * 24.0 if time_mode == 2 else 12.0)
	school_hour_hand.rotation.z = -clock_hours * TAU / 12
	school_minute_hand.rotation.z = -fmod(clock_hours, 1.0) * TAU
	var night := 1.0 if time_mode == 1 else (smoothstep(-.4,.4,-cos(day_phase*TAU)) if time_mode == 2 else 0.0)
	if night >= .5:
		if calm_mode:
			chimney_beacon_phase = 0.0
		elif not paused:
			chimney_beacon_phase = fmod(chimney_beacon_phase + delta, 2.0)
		chimney_beacon.emission_enabled = chimney_beacon_phase < .5
	else:
		chimney_beacon_phase = 0.0
		chimney_beacon.emission_enabled = false
	suburban_villas.update_lights(weather.season == 4, night, weather.snow)
	dax.update_lights(night)
	christmas_spruce.update_lights(weather.season == 4 and weather.snow > .02, night)
	shops.candy_blade_glow.emission_enabled = night >= .35
	midsummer_pole.set_summer(weather.season == 2)
	midsummer_pole.move_wreaths(weather.wind_time, weather.wind_angle)
	field_fountain.set_season(weather.season)
	var cloud := weather.cloud_cover*(1.0-night)
	city_sun.light_energy = lerpf(.73,.17,night)*(1.0-.52*cloud)
	city_sun.shadow_opacity = 1.0-.48*cloud
	var sunlight := Color("#fff1df").lerp(Color("#9db5eb"),night)
	if time_mode == 2:
		var height := cos(day_phase*TAU)
		var elevation := 5.0 + absf(height)*(43.0 if height >= 0 else 22.0)
		city_sun.rotation = Vector3(-deg_to_rad(elevation),-day_phase*TAU,0)
		var twilight := 1.0-smoothstep(.02,.42,absf(height))
		sunlight = sunlight.lerp(Color("#ffc08b"),twilight*.7)
	else:
		city_sun.rotation_degrees = Vector3(-48+21*night,-28+73*night,0)
	city_sun.light_color = sunlight
	# Always settle on full day or full night after the gradual transition.
	if night == last_night or (night > 0.0 and night < 1.0 and absf(night-last_night) < .006):
		return
	last_night = night
	if bus_plate_finish:
		bus_plate_finish.emission_energy_multiplier = .28 * night
		bus_plate_lamp_finish.emission_energy_multiplier = 1.1 * night
	_update_bus_ceiling_lights(night)
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
	quattro_glazing.set_shader_parameter("night",night)
	if bus_glazing: bus_glazing.set_shader_parameter("night",night)
	_update_quattro_gauge_light(night)
	city_env.ambient_light_energy = lerpf(.38,.28,night)
	city_env.ambient_light_color = Color("#c4d5d1").lerp(Color("#9cb1d3"),night)
	city_fill.light_energy = .45*(1-night)
	var entrance_glow := smoothstep(.15,.85,night)
	quay_stair_light.emission_energy_multiplier = entrance_glow*1.05
	entrance_diffuser.emission_energy_multiplier = entrance_glow*2.0
	tower_lightbox.emission_energy_multiplier = entrance_glow*.85
	fire_sign_face.emission_energy_multiplier = entrance_glow*.8
	meter_backlight.emission_energy_multiplier = entrance_glow*.48
	for lamp in entrance_lights:
		lamp.visible = entrance_glow > .001
		lamp.light_energy = entrance_glow*2.1
	for lamp in street_lights:
		lamp.visible = night>.05
		lamp.light_energy = night*3.2
	lamp_glass.emission_energy_multiplier = .1+night*3.0
	for lens in traffic_running_lenses:
		lens.emission_energy_multiplier = 3.0*night
	for beam in traffic_headlights:
		beam.visible = night>.05
		beam.light_energy = 2.8*night
	if projector_finish:
		projector_finish.emission_energy_multiplier = 3.0*night
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
			# Clear the parking bays and their approach on Södra kajgatan.
			var verge := 7.92 if z == 60 and x != 150 else 4.1
			sites.append(Vector3(x,0,z+verge))
	for x in [-55,48]:
		for z in [-37,-18,14,22]:
			sites.append(Vector3(x-6.0,0,z))
	for x in [-43,-24,-8,13,34]:
		sites.append(Vector3(x,0,39.3))
		sites.append(Vector3(x,0,-52.3))
	for block_x in [-510,-420,-330,-240,-150]:
		for avenue_z in [-48,0,35]:
			for offset in [10,34,57,80]:
				var verge := 9.8 if avenue_z != 0 and block_x >= tram.WEST and block_x < tram.EAST else 5.65
				if offset in [34,80]: verge = -verge
				sites.append(Vector3(block_x+offset,0,avenue_z+verge))
		for side_street_z in [-34,-14,17]:
			var verge := 9.8 if block_x in [tram.WEST,tram.EAST] else 5.65
			sites.append(Vector3(block_x-verge,0,side_street_z))
	var course_lamps: Array[Vector3] = []
	for x in [-121,-99,-77]:
		for z in [PRACTICE_YARD.position.y-1, PRACTICE_YARD.end.y+1]:
			course_lamps.append(Vector3(x,0,z))
	sites.append_array(course_lamps)
	var housing_mesh := SphereMesh.new()
	housing_mesh.radial_segments = 24
	housing_mesh.rings = 10
	housing_mesh.material = _material(Color("#45524e"), .63)
	var lens_mesh := SphereMesh.new()
	lens_mesh.radial_segments = 24
	lens_mesh.rings = 8
	lens_mesh.material = lamp_glass
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = .048
	post_mesh.bottom_radius = .08
	post_mesh.height = 4.43
	post_mesh.radial_segments = 16
	post_mesh.rings = 0
	post_mesh.material = housing_mesh.material
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = .036
	arm_mesh.bottom_radius = .054
	arm_mesh.height = .81
	arm_mesh.radial_segments = 16
	arm_mesh.rings = 0
	arm_mesh.material = housing_mesh.material
	var anchor_nut := CylinderMesh.new()
	anchor_nut.top_radius = .019
	anchor_nut.bottom_radius = .019
	anchor_nut.height = .022
	anchor_nut.radial_segments = 6
	anchor_nut.rings = 0
	var nut_finish := _material(Color("#899293"), .51)
	nut_finish.metallic = .65
	anchor_nut.material = nut_finish
	var footing_finish := _material(Color("#929087"), .9, false, "mineral")
	for p in sites:
		var on_course := p in course_lamps
		p.y = _surface_height(p.x,p.z)
		var street := navigator.closest_street_point(Vector2(p.x, p.z))
		var inward := Vector3(street.x - p.x, 0, street.y - p.z).normalized()
		if on_course:
			inward = Vector3.BACK if p.z < PRACTICE_YARD.get_center().y else Vector3.FORWARD
		var post := MeshInstance3D.new()
		post.name = "Lamp post"
		post.mesh = post_mesh
		post.position = p + Vector3.UP * 2.215
		add_child(post)
		roadside_solids.append(AABB(p - Vector3(.08, 2.0, .08), Vector3(.16, 6.5, .16)))
		_make_box("Lamp post concrete footing", Vector3(.32, .069, .32), p + Vector3.UP * .014,
			Color.WHITE).material_override = footing_finish
		_make_box("Lamp post foot plate", Vector3(.267, .026, .267), p + Vector3.UP * .061,
			Color.WHITE).material_override = post_mesh.material
		for anchor in [Vector2(-.099, -.099), Vector2(.099, -.099),
				Vector2(-.099, .099), Vector2(.099, .099)]:
			var nut := MeshInstance3D.new()
			nut.name = "Lamp post anchor nut"
			nut.mesh = anchor_nut
			nut.position = p + Vector3(anchor.x, .084, anchor.y)
			add_child(nut)
		var yaw := atan2(inward.x, inward.z)
		var hatch := _make_box("Lamp service hatch gasket", Vector3(.081, .236, .024),
			p + Vector3.UP * .69 + inward * .074, Color("#222d2d"))
		hatch.rotation.y = yaw
		_make_box("Lamp service hatch", Vector3(.071, .218, .015),
			Vector3(0, 0, .015), Color.WHITE, false, hatch).material_override = post_mesh.material
		for screw_y in [-.085, .085]:
			_make_box("Lamp service hatch screw", Vector3(.013, .013, .006),
				Vector3(0, screw_y, .023), Color.WHITE, false, hatch).material_override = nut_finish
		var arm := MeshInstance3D.new()
		arm.name = "Lamp arm"
		arm.mesh = arm_mesh
		arm.position = p + Vector3.UP * 4.35 + inward * .36
		arm.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * .5)
		add_child(arm)
		var fixture := p + Vector3.UP * 4.32 + inward * .73
		var housing := MeshInstance3D.new()
		housing.name = "Lamp housing"
		housing.mesh = housing_mesh
		housing.position = fixture
		housing.rotation.y = yaw
		housing.scale = Vector3(.33, .145, .60)
		add_child(housing)
		var lens := MeshInstance3D.new()
		lens.name = "Lamp diffuser"
		lens.mesh = lens_mesh
		lens.position = fixture - Vector3.UP * .061
		lens.rotation.y = yaw
		lens.scale = Vector3(.243, .055, .468)
		add_child(lens)
		var light := SpotLight3D.new()
		light.position = lens.position-Vector3.UP*.12
		light.basis = Basis.looking_at(inward * 2.5 + Vector3.DOWN * 4.24, Vector3.UP)
		light.light_color = Color("#ffdbad")
		light.spot_range = 17
		light.spot_angle = 63
		light.shadow_enabled = streetlamp_shadows
		shadow_streetlamps.append(light)
		light.distance_fade_enabled = true
		light.distance_fade_begin = 34
		light.distance_fade_shadow = 24
		add_child(light)
		street_lights.append(light)

	# Lower lanterns keep light near the benches and the water's edge.
	var park_sites := [Vector3(27,0,21.6),Vector3(34,0,16),Vector3(27,0,10.5)]
	for z in range(-38,-6,9):
		park_sites.append(Vector3(92,0,z))
	for z in [-71,-62,13,22,31,40,49,58]:
		park_sites.append(Vector3(92,0,z))
	for z in [-32,-24,-16]:
		park_sites.append(Vector3(58.8,0,z))
	park_sites.append(Vector3(LAUNCH_LANDING.x + 1.4,0,LAUNCH_PIER.end.y - .25))
	var reflected_lamps := PackedVector3Array()
	var diffuser := CylinderMesh.new()
	diffuser.radial_segments = 16
	diffuser.rings = 0
	diffuser.top_radius = .19
	diffuser.bottom_radius = .11
	diffuser.height = .28
	diffuser.material = lamp_glass
	var cap := CylinderMesh.new()
	cap.radial_segments = 16
	cap.rings = 0
	cap.bottom_radius = .245
	cap.top_radius = .045
	cap.height = .11
	var iron := Color("#384845")
	cap.material = _material(iron)
	var collar := CylinderMesh.new()
	collar.radial_segments = 16
	collar.rings = 0
	collar.bottom_radius = .077
	collar.top_radius = .135
	collar.height = .082
	collar.material = cap.material
	var rim := CylinderMesh.new()
	rim.radial_segments = 16
	rim.rings = 0
	rim.bottom_radius = .193
	rim.top_radius = .243
	rim.height = .037
	rim.material = cap.material
	var pedestal := CylinderMesh.new()
	pedestal.radial_segments = 16
	pedestal.top_radius = .074
	pedestal.bottom_radius = .124
	pedestal.height = .31
	pedestal.material = cap.material
	var finial := CylinderMesh.new()
	finial.radial_segments = 12
	finial.top_radius = .015
	finial.bottom_radius = .036
	finial.height = .065
	finial.material = cap.material
	for point: Vector3 in park_sites:
		point.y = _foot_height(point.x,point.z)
		_make_roadside_solid("Park lantern post",Vector3(.12,2.55,.12),point+Vector3.UP*1.275,Color("#384845"))
		var plinth := MeshInstance3D.new()
		plinth.name = "Park lantern pedestal"
		plinth.mesh = pedestal
		plinth.position = point + Vector3.UP * .155
		add_child(plinth)
		var socket := MeshInstance3D.new()
		socket.name = "Park lantern socket"
		socket.mesh = collar
		socket.position = point + Vector3.UP * 2.517
		add_child(socket)
		var globe := MeshInstance3D.new()
		globe.mesh = diffuser
		globe.position = point+Vector3.UP*2.68
		add_child(globe)
		var hood := MeshInstance3D.new()
		hood.mesh = cap
		hood.position = point+Vector3.UP*2.875
		add_child(hood)
		var crown := MeshInstance3D.new()
		crown.name = "Park lantern finial"
		crown.mesh = finial
		crown.position = point + Vector3.UP * 2.957
		add_child(crown)
		var hood_rim := MeshInstance3D.new()
		hood_rim.name = "Park lantern hood rim"
		hood_rim.mesh = rim
		hood_rim.position = point + Vector3.UP * 2.813
		add_child(hood_rim)
		for support in 3:
			var direction := Vector3(cos(TAU * support / 3.0), 0, sin(TAU * support / 3.0))
			_tube_between(self, point + Vector3.UP * 2.552 + direction * .116,
				point + Vector3.UP * 2.811 + direction * .194, .011, cap.material)
		var lantern := SpotLight3D.new()
		lantern.position = point+Vector3.UP*2.51
		lantern.rotation.x = -PI/2
		lantern.spot_range = 8
		lantern.spot_angle = 70
		lantern.light_color = Color("#ffce96")
		lantern.distance_fade_enabled = true
		lantern.distance_fade_begin = 32
		add_child(lantern)
		street_lights.append(lantern)
		if point.x > 55:
			reflected_lamps.append(globe.position)
	water_finish.set_shader_parameter("quay_lamps",reflected_lamps)
	water_finish.set_shader_parameter("quay_lamp_count",reflected_lamps.size())

func _apply_player_appearance() -> void:
	var colour := Color("#a85641") if play_as_alma else Color("#648faa")
	if jacket_palette >= 0: colour = BENCH_COLOURS[jacket_palette]
	var jacket_style: int = shops.MENUS[5].find(boutique_jacket)
	if jacket_style in [0,1] and int(purchases.get(boutique_jacket,0)) > 0:
		colour = Color("#467c75") if jacket_style == 0 else Color("#724467")
	else:
		jacket_style = -1
	var jacket := _material(colour, .83, false, "avatar_jacket_twill")
	for figure: Node3D in [walker,skipper,road_driver]:
		figure.scale = Vector3.ONE*(.88 if play_as_alma else 1.0)
		figure.get_node("Face").mesh = preload("res://characters/AlmaFace.obj") if play_as_alma else preload("res://characters/Face.obj")
		figure.get_node("AxelPortrait").visible = not play_as_alma
		figure.get_node("AlmaPortrait").visible = play_as_alma
		figure.get_node("Hair").mesh = preload("res://characters/Bob.obj") if play_as_alma else preload("res://characters/Hair.obj")
		var torso: MeshInstance3D = figure.get_node("Jacket")
		torso.material_override = jacket
		var trim := torso.get_node_or_null("BoutiqueLapels") as Node3D
		if not trim and jacket_style >= 0:
			trim = Node3D.new()
			trim.name = "BoutiqueLapels"
			torso.add_child(trim)
			for side in [-1,1]:
				_make_box("Woven lapel",Vector3(.036,.36,.022),Vector3(side*.063,.047,-.15),Color("#efd9af"),false,trim)
			_make_box("Goreum tie",Vector3(.043,.13,.025),Vector3(.076,-.095,-.15),Color("#bc869d"),false,trim).rotation.z = -.4
		if trim:
			trim.visible = jacket_style >= 0
			var angle := .42 if jacket_style == 1 else .13
			trim.get_child(0).rotation.z = -angle
			trim.get_child(1).rotation.z = angle
			trim.get_child(2).visible = jacket_style == 1
		wardrobe.set_colours(figure.get_node("Jacket/WeatherClothing"), colour)
		for arm in figure.get_meta("arms"):
			arm.get_child(0).material_override = jacket
			if figure == road_driver:
				arm.get_node("Forearm").material_override = jacket
	# Keep the hips on the cushion as the selected driver's height changes.
	road_driver.scale *= .78
	road_driver.position = Vector3(-.32, .88 - .87 * road_driver.scale.y, -.04)

func _build_driving_legs(pose_name: String, right_knee: Vector3, right_ankle: Vector3) -> void:
	var riding_legs := Node3D.new()
	riding_legs.name = pose_name
	road_driver.add_child(riding_legs)
	for leg: Node3D in road_driver.get_meta("legs"):
		var side := signf(leg.position.x)
		var hip := leg.position
		var knee := Vector3(side*right_knee.x, right_knee.y, right_knee.z)
		var ankle := Vector3(side*right_ankle.x, right_ankle.y, right_ankle.z)
		var trouser_material: Material = leg.get_child(0).material_override
		for endpoints in [[hip,knee,.105],[knee,ankle,.083]]:
			var start: Vector3 = endpoints[0]
			var end: Vector3 = endpoints[1]
			var segment := MeshInstance3D.new()
			var cloth := CapsuleMesh.new()
			cloth.radius = endpoints[2]
			cloth.height = start.distance_to(end) + cloth.radius
			segment.mesh = cloth
			segment.material_override = trouser_material
			segment.position = (start+end)*.5
			segment.quaternion = Quaternion(Vector3.DOWN,(end-start).normalized())
			riding_legs.add_child(segment)
		var boot := leg.get_child(1).duplicate() as MeshInstance3D
		boot.position = ankle + Vector3(0,-.045,-.05)
		riding_legs.add_child(boot)
	riding_legs.hide()

func _pose_driver_arms() -> void:
	if not road_driver.visible:
		return
	var arms: Array = road_driver.get_meta("arms")
	for index in arms.size():
		var shoulder: Node3D = arms[index]
		var grip := cabin_wheel.to_global(Vector3.RIGHT * grip_radius * (-1 if index == 0 else 1))
		if not shopper_grip_points.is_empty():
			grip = cabin_wheel.to_global(shopper_grip_points[index])
		_fit_driver_arm(shoulder,grip)

func _fit_driver_arm(shoulder: Node3D, grip: Vector3) -> void:
	var hand: Node3D = shoulder.get_node("Hand")
	var reach := shoulder.to_local(grip) - hand.basis * PALM_GRIP
	# Bend the elbow down and slightly out, keeping the wrist on the rim.
	var axis := reach.normalized()
	var outward := Vector3(signf(shoulder.position.x)*.25,-1,0)
	var bend := outward.slide(axis).normalized()
	var half_reach := reach.length() * .5
	var offset := sqrt(maxf(0.0, .37 * .37 - half_reach * half_reach))
	var elbow := reach * .5 + bend * offset
	var upper := shoulder.get_child(0) as MeshInstance3D
	var lower := shoulder.get_node("Forearm") as MeshInstance3D
	_fit_driver_sleeve(upper, Vector3.ZERO, elbow)
	_fit_driver_sleeve(lower, elbow, reach)
	hand.position = reach

func _fit_driver_sleeve(sleeve: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var segment := end - start
	sleeve.position = (start + end) * .5
	sleeve.quaternion = Quaternion(Vector3.DOWN, segment.normalized())
	sleeve.scale.y = (segment.length() + .045) / .65

# Each row opens directly onto the adjacent avenue. Slots are spaced for door access.
const DISTRICT_PARKING := [
	[Vector2(-201,52), [3, 6, 15]],
	[Vector2(-288,-65), [7, 8, 9]],
	[Vector2(-382,52), [12, 13, 19]],
	[Vector2(-465,-65), [11, 17, 18]],
	[Vector2(-73,52), [14, 16, 22]],
]

func _depot_bay(i: int) -> Vector2:
	for lot in DISTRICT_PARKING:
		var slot: int = lot[1].find(i)
		if slot >= 0:
			var center: Vector2 = lot[0]
			return center + Vector2((slot - 1) * 6, 0)
	if i == 2: return Vector2(FIRE_RETURN_BAY.x,FIRE_RETURN_BAY.z)
	if i == WHEEL_LOADER: return Vector2(-101,47)
	if i == SHOPPER: return Vector2(-67,60)
	if i == REFUSE: return Vector2(-101,56)
	if i == MOWER: return Vector2(-24,28)
	if i == DAM_PICKUP: return Vector2(-12,28)
	if i == QUATTRO: return Vector2(-32,15)
	if i == FARM_TRACTOR: return Vector2(-18,28)
	if i == RECOVERY: return Vector2(-45,25)
	if i == BUS: return Vector2(-34,25.4)
	return Vector2(-47+5*i,15)

func _update_tractor_footprint() -> void:
	var bounds := tractor_plough_bounds if weather.season == 4 else tractor_bare_bounds
	parked_footprints[FARM_TRACTOR] = Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z)
	parked_sizes[FARM_TRACTOR] = Vector2(maxf(-bounds.position.x,bounds.end.x),maxf(-bounds.position.z,bounds.end.z))
	if vehicle_index == FARM_TRACTOR:
		player_half_size = parked_sizes[FARM_TRACTOR]
		front_reach = -bounds.position.z
		rear_reach = bounds.end.z

func _fit_plough(model: Node3D) -> void:
	var blade := preload("res://vehicles/tractor_snow_blade.glb").instantiate() as Node3D
	model.add_child(blade)
	blade.position.z = 2.88
	blade.rotation.y = deg_to_rad(13)
	blade.visible = weather.season == 4
	if model == vehicle_model:
		var edge := blade.find_child("Rubber cutting edge*", true, false) as MeshInstance3D
		var bounds := edge.get_aabb()
		var centre := bounds.get_center()
		var half_width := Vector3.RIGHT * bounds.size.x * .5
		blade_left = model.to_local(edge.to_global(centre - half_width))
		blade_right = model.to_local(edge.to_global(centre + half_width))
	ploughs.append(blade)
	blade.tree_exiting.connect(func(): ploughs.erase(blade), CONNECT_ONE_SHOT)
	_fit_spreader(model)

func _fit_spreader(model: Node3D) -> void:
	var spreader := Node3D.new()
	spreader.name = "Grit and salt spreader"
	spreader.position = Vector3(0,.78,-2.54)
	spreader.visible = weather.season == 4
	model.add_child(spreader)
	var enamel := Color("#51843b")
	var steel := Color("#353b3c")
	_make_box("Hitch crossmember",Vector3(1.32,.12,.65),Vector3(0,-.10,.36),steel,false,spreader)
	var hitch_finish := _material(steel, .55)
	var pin_finish := _material(Color("#a7aca6"), .42)
	pin_finish.metallic = .65
	for side in [-1.0,1.0]:
		var clevis := Vector3(side*.53,-.085,.60)
		var tractor_joint := Vector3(side*.39,-.16,1.02)
		_tube_between(spreader, clevis, tractor_joint, .042, hitch_finish)
		for joint in [clevis,tractor_joint]:
			_make_box("Lower hitch clevis",Vector3(.085,.11,.12),joint,steel,false,spreader)
			_tube_between(spreader, joint-Vector3.RIGHT*.064, joint+Vector3.RIGHT*.064,
				.021, pin_finish)
	var top_link := Vector3(0,.36,.33)
	_make_box("Top link bracket",Vector3(.17,.16,.15),top_link,steel,false,spreader)
	_tube_between(spreader, top_link, Vector3(0,.09,1.03), .031, hitch_finish)
	_tube_between(spreader, top_link-Vector3.RIGHT*.10, top_link+Vector3.RIGHT*.10,
		.024, pin_finish)
	_make_box("Metering roller cover",Vector3(1.66,.06,.30),Vector3(0,.065,-.28),steel,false,spreader)
	for edge in [-1.0,1.0]:
		_make_box("Outlet skirt",Vector3(1.66,.14,.045),Vector3(0,-.012,-.28+edge*.125),
			steel,false,spreader)
		_make_box("Roller end plate",Vector3(.061,.16,.30),Vector3(edge*.80,-.015,-.28),
			steel,false,spreader)
	_tube_between(spreader,Vector3(-.78,-.007,-.28),Vector3(.78,-.007,-.28),.055,pin_finish)
	_make_box("Hopper floor",Vector3(1.48,.08,.50),Vector3(0,.10,.04),enamel,false,spreader)
	for end in [-1,1]:
		var wall := _make_box("Folded hopper wall",Vector3(1.93,.61,.061),Vector3(0,.39,end*.30),enamel,false,spreader)
		wall.rotation.x = end * .32
		_make_box("Rolled rim",Vector3(1.98,.057,.068),Vector3(0,.69,end*.396),enamel,false,spreader)
		var cheek := _make_box("Hopper end cheek",Vector3(.055,.60,.70),Vector3(end*.896,.39,0),enamel,false,spreader)
		cheek.rotation.z = -end*.23
		if end < 0:
			for side in [-1.0,1.0]:
				var center := Vector3(side*.77,-.14,-.039)
				_make_box("Reflector backing",Vector3(.215,.091,.023),center,steel,false,wall)
				var lens := _make_box("Rear reflector lens",Vector3(.160,.062,.011),
					center+Vector3.FORWARD*.016,Color("#b82320"),false,wall)
				lens.material_override = _material(Color("#b82320"),.38)
				for offset in [-.093,.093]:
					var screw := center + Vector3(offset,0,0)
					_tube_between(wall,screw+Vector3.FORWARD*.009,
						screw+Vector3.FORWARD*.014,.006,pin_finish)
	var payload := _make_box("Grit and salt load",Vector3(1.66,.10,.54),Vector3(0,.53,0),Color("#aaa38b"),false,spreader)
	payload.material_override = _noise_material(Color("#514a39"),Color("#e1ddd0"),18.0,.75)
	ploughs.append(spreader)
	spreader.tree_exiting.connect(func(): ploughs.erase(spreader), CONNECT_ONE_SHOT)
	if model != vehicle_model:
		return
	spreader_particles = CPUParticles3D.new()
	spreader_particles.name = "Falling road grit"
	spreader_particles.position = Vector3(0,-.092,-.31)
	spreader_particles.emitting = false
	spreader_particles.amount = 90
	spreader_particles.lifetime = .27
	spreader_particles.local_coords = false
	spreader_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spreader_particles.emission_box_extents = Vector3(.78,.02,.07)
	spreader_particles.direction = Vector3(0,-.85,-.65)
	spreader_particles.spread = 46
	spreader_particles.initial_velocity_min = 1.0
	spreader_particles.initial_velocity_max = 3.0
	var grit := BoxMesh.new()
	grit.size = Vector3(.031,.018,.025)
	# Vary individual grains between dark gravel and pale road salt.
	var mixture := Gradient.new()
	mixture.offsets = PackedFloat32Array([0.0, .42, .76, 1.0])
	mixture.colors = PackedColorArray([Color("#5f574b"), Color("#8c806c"), Color("#b3a795"), Color("#f3efdf")])
	var grain_finish := _material(Color.WHITE, .84).duplicate() as StandardMaterial3D
	grain_finish.vertex_color_use_as_albedo = true
	grit.material = grain_finish
	spreader_particles.color_initial_ramp = mixture
	spreader_particles.mesh = grit
	spreader.add_child(spreader_particles)
	var gravel := preload("res://audio/grit_spreader.wav").duplicate() as AudioStreamWAV
	gravel.loop_mode = AudioStreamWAV.LOOP_FORWARD
	gravel.loop_end = roundi(gravel.get_length()*gravel.mix_rate)
	spreader_audio = AudioStreamPlayer3D.new()
	spreader_audio.name = "Spreader rattle"
	spreader_audio.stream = gravel
	spreader_audio.bus = &"Engines"
	spreader_audio.volume_db = -13.0
	spreader_audio.unit_size = 3.0
	spreader_audio.max_distance = 18.0
	spreader_audio.position = spreader_particles.position
	spreader.add_child(spreader_audio)

func _set_spreader_active(active: bool) -> void:
	if not is_instance_valid(spreader_particles):
		return
	spreader_particles.emitting = active
	if active and sound_on:
		if not spreader_audio.playing:
			spreader_audio.play()
	elif spreader_audio.playing:
		spreader_audio.stop()


func _park_at_home(body: Node3D, index: int) -> void:
	var bay := _depot_bay(index)
	body.position = Vector3(bay.x, _surface_height(bay.x, bay.y), bay.y)
	# The northern bays open southwards onto the avenue.
	body.rotation = Vector3(0, PI if body.position.z < -48 or index == FARM_TRACTOR else 0.0, 0)

func _road_sign_text(post: Node3D, words: String, at: Vector3, pixel: float, color: Color) -> Label3D:
	var letters := Label3D.new()
	letters.text = words
	letters.position = at
	letters.pixel_size = pixel
	letters.font_size = 48
	letters.modulate = color
	letters.outline_size = 0
	post.add_child(letters)
	return letters

func _signpost(at: Vector3, heading: float) -> Node3D:
	var post := Node3D.new()
	add_child(post)
	post.position = at
	post.rotation.y = heading
	_make_roadside_solid("Signpost", Vector3(.09,2.85,.09), Vector3.UP*1.425, Color("#879398"), false, post)
	var footing := _material(Color("#9b9990"), .94, false, "mineral")
	_make_box("Signpost concrete footing", Vector3(.28, .16, .28),
		Vector3(0, -.036, 0), Color.WHITE, false, post).material_override = footing
	_make_box("Signpost socket plate", Vector3(.173, .018, .173),
		Vector3.UP * .050, Color("#657175"), false, post)
	for corner in [Vector2(-.064, -.064), Vector2(-.064, .064), Vector2(.064, -.064), Vector2(.064, .064)]:
		_make_box("Signpost footing anchor", Vector3(.025, .014, .025),
			Vector3(corner.x, .064, corner.y), Color("#929da0"), false, post)
	return post

func _add_sign_mount(post: Node3D, rail_y: float, width: float, aluminium: Material) -> void:
	_make_box("Sign rear mounting channel", Vector3(width, .043, .026),
		Vector3(0, rail_y, -.011), Color.WHITE, false, post).material_override = aluminium
	_make_box("Signpost clamp", Vector3(.177, .063, .034),
		Vector3(0, rail_y, -.047), Color("#657175"), false, post)
	for bolt_x in [-.073, .073]:
		_make_box("Signpost clamp bolt", Vector3(.025, .025, .016),
			Vector3(bolt_x, rail_y, -.069), Color.WHITE, false, post).material_override = aluminium

func _speed_sign(at: Vector3, heading: float, limit: int) -> void:
	var post := _signpost(at, heading)
	var aluminium := _material(Color("#929da0"), .54, false, "brushed")
	aluminium.metallic = .53
	var backing_mesh := CylinderMesh.new()
	backing_mesh.top_radius = .55
	backing_mesh.bottom_radius = .55
	backing_mesh.height = .023
	backing_mesh.radial_segments = 64
	backing_mesh.rings = 0
	backing_mesh.material = aluminium
	var backing := MeshInstance3D.new()
	backing.name = "Speed sign aluminium back"
	backing.mesh = backing_mesh
	backing.rotation.x = PI * .5
	backing.position = Vector3(0, 2.58, .010)
	post.add_child(backing)
	for rail_y in [2.38, 2.76]:
		_add_sign_mount(post, rail_y, .60, aluminium)
	for inner in [false,true]:
		var disc := CylinderMesh.new()
		disc.top_radius = .46 if inner else .55
		disc.bottom_radius = disc.top_radius
		disc.height = .025 if inner else .06
		var plate := MeshInstance3D.new()
		plate.mesh = disc
		plate.rotation.x = PI*.5
		plate.position = Vector3(0,2.58,.09 if inner else .05)
		plate.material_override = _material(Color("#ffdc59") if inner else Color("#bc292e"))
		post.add_child(plate)
	_road_sign_text(post,str(limit),Vector3(0,2.58,.11),.010,Color("#191c20"))

func _add_rectangular_sign_back(post: Node3D, width: float, height: float,
		center_y: float, aluminium: Material) -> void:
	_make_box("Sign aluminium back", Vector3(width, height, .024),
		Vector3(0, center_y, .010), Color.WHITE, false, post).material_override = aluminium
	for edge in [-1, 1]:
		_add_sign_mount(post, center_y + edge * height * .24, width - .13, aluminium)

func _build_road_signs() -> void:
	var aluminium := _material(Color("#a4adaf"), .65)
	aluminium.metallic = .42
	for direction in [-1,1]:
		var x: float = STATION_DROP.x - direction * 16.0
		var z := 5.4 * float(direction)
		var post := _signpost(Vector3(x,_surface_height(x,z),z), -direction * PI*.5)
		_make_box("Station direction board",Vector3(2.75,.72,.08),Vector3(0,2.45,.06),Color.WHITE,false,post)
		_make_box("Station direction panel",Vector3(2.68,.65,.03),Vector3(0,2.45,.11),Color("#215997"),false,post)
		_add_rectangular_sign_back(post, 2.75, .72, 2.45, aluminium)
		var caption := "Harbor Fuel  →" if direction == 1 else "←  Harbor Fuel"
		_size_world_sign(_road_sign_text(post,caption,Vector3(0,2.45,.134),.0062,Color.WHITE), 2.52)
	for zone in [[-101,30],[-210,50],[-431,30]]:
		for direction in [-1,1]:
			var x: float = zone[0] + direction * 6
			var z := 5.1 * float(direction)
			_speed_sign(Vector3(x,_surface_height(x,z),z), -direction * PI*.5, zone[1])
	var ice_bay := _depot_bay(ICE_CREAM)
	var post_position := Vector3(ice_bay.x,0,ice_bay.y+5.7)
	post_position.y = _surface_height(post_position.x,post_position.z)
	var depot_sign := _signpost(post_position,PI)
	depot_sign.name = "IceCreamDepotSign"
	_make_box("Depot sign border",Vector3(2.8,.68,.08),Vector3(0,2.62,.06),Color.WHITE,false,depot_sign)
	_make_box("Depot sign face",Vector3(2.74,.62,.03),Vector3(0,2.62,.11),Color("#205786"),false,depot_sign)
	_size_world_sign(_road_sign_text(depot_sign,"Ice cream depot",Vector3(0,2.62,.14),.006,Color.WHITE),2.55)
	_add_rectangular_sign_back(depot_sign, 2.8, .68, 2.62, aluminium)
	var rules := ["Ducks park free", "Hats on wheels only", "Save a spot for a snail", "Park with a smile", "Bananas need a ticket"]
	for index in DISTRICT_PARKING.size():
		var center: Vector2 = DISTRICT_PARKING[index][0]
		var side := signf(center.y)
		var at := Vector3(center.x+9.8,0,center.y-side*6)
		at.y = _surface_height(at.x,at.z)
		var post := _signpost(at,PI if side>0 else 0.0)
		_make_box("Parking sign", Vector3(.84,.94,.08), Vector3(0,2.65,.06), Color.WHITE,false,post)
		_make_box("Blue parking panel", Vector3(.77,.87,.03), Vector3(0,2.65,.11), Color("#215997"),false,post)
		_road_sign_text(post,"P",Vector3(0,2.65,.133),.016,Color.WHITE)
		_make_box("Parking rule", Vector3(2.55,.54,.08), Vector3(0,1.89,.06), Color("#fff8df"),false,post)
		_add_rectangular_sign_back(post, .84, .94, 2.65, aluminium)
		_add_rectangular_sign_back(post, 2.55, .54, 1.89, aluminium)
		var rule_label := _road_sign_text(post,rules[index],Vector3(0,1.89,.11),.0035,Color("#182531"))
		rule_label.width = 2.42 / rule_label.pixel_size
		rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _add_parked_moped_stand(body: Node3D) -> void:
	var stand := Node3D.new()
	stand.name = "CentralStand"
	body.add_child(stand)
	var steel := _material(Color("#42484a"), .48)
	for side: float in [-1,1]:
		var hinge := Vector3(side*.078,.235,.14)
		var foot := Vector3(side*.105,.012,.22)
		_tube_between(stand, hinge, foot, .011, steel)
		_tube_between(stand, foot+Vector3.FORWARD*.018, foot+Vector3.BACK*.025, .012, steel)
	_tube_between(stand, Vector3(-.095,.095,.19), Vector3(.095,.095,.19), .009, steel)
	_tube_between(stand, Vector3(-.10,.05,.205), Vector3(-.175,.065,.25), .007, steel)

func _add_recycling_labels(bin: Node3D, paper: bool) -> void:
	var ink := Color("#154063") if paper else Color("#165038")
	for side in 4:
		var face := Node3D.new()
		bin.add_child(face)
		face.rotation.y = side * PI / 2
		face.position = face.basis.z * (.292 if side % 2 == 0 else .337) + Vector3.UP * .58
		_make_box("Sorting label",Vector3(.44,.45,.009),Vector3.ZERO,Color("#fffbe9"),false,face)
		if paper:
			_make_box("Stack of paper",Vector3(.24,.29,.01),Vector3(-.018,-.012,.010),ink,false,face)
			_make_box("Top sheet",Vector3(.24,.29,.01),Vector3(.012,.018,.018),ink.lightened(.15),false,face)
			for line in 3:
				_make_box("Print line",Vector3(.16,.018,.006),Vector3(.012,.095-line*.062,.027),Color.WHITE,false,face)
		else:
			_make_box("Bottle body",Vector3(.145,.20,.012),Vector3(0,-.05,.012),ink,false,face)
			_make_box("Bottle shoulder",Vector3(.115,.038,.012),Vector3(0,.065,.012),ink,false,face)
			_make_box("Bottle neck",Vector3(.066,.10,.012),Vector3(0,.118,.012),ink,false,face)
			_make_box("Bottle lip",Vector3(.09,.021,.012),Vector3(0,.172,.012),ink,false,face)

func _build_depot() -> void:
	refuse_pump.bus = &"Engines"
	refuse_pump.stream = preload("res://audio/bin_lift.wav")
	refuse_pump.volume_db = -8
	refuse_pump.unit_size = 4
	add_child(refuse_pump)
	for i in 2:
		var bin := Node3D.new()
		add_child(bin)
		bin.position = _stop_pavement(i)
		if i == 0: bin.position.z = 6.35
		bin.position.y = _foot_height(bin.position.x, bin.position.z)
		_make_box("Recycling bin",Vector3(.67,.84,.58),Vector3.UP*.51,Color("#20548a") if i == 0 else Color("#245d48"),false,bin)
		_make_box("Hinged lid",Vector3(.72,.08,.64),Vector3.UP*.97,Color("#509be3") if i == 0 else Color("#74ab54"),false,bin)
		_add_recycling_labels(bin,i == 0)
		for side in [-1,1]:
			_make_box("Bin wheel",Vector3(.08,.16,.16),Vector3(side*.29,.09,.21),Color("#242a29"),false,bin)
		refuse_bins.append(bin)
		bin.hide()
	_build_road_signs()
	for lot in DISTRICT_PARKING:
		var center: Vector2 = lot[0]
		var street_z := 35.0 if center.y > 0 else -48.0
		var inner_edge := street_z + signf(center.y - street_z) * 4.8
		var outer_edge := center.y + signf(center.y - street_z) * 6.0
		_make_driving_surface("Neighbourhood parking", Vector3(19,.10,absf(outer_edge-inner_edge)),
			Vector3(center.x,-.15,(outer_edge+inner_edge)*.5),Color("#565c5a"))
	_make_driving_surface("Motor pool", Vector3(30,.1,11), Vector3(-34.5,-.18,15), Color("#565c5a"))
	_make_driving_surface("Recovery apron",Vector3(8.4,.10,9.8),Vector3(-45,-.18,25.4),Color("#565c5a"))
	_make_driving_surface("Visitor parking",Vector3(30,.10,9),Vector3(-21.5,-.12,28),Color("#565c5a"))
	_make_driving_surface("Bus bay extension",Vector3(5,.10,4.6),Vector3(-34,-.12,21.2),Color("#565c5a"))
	# A continuous pedestrian route from the parking bays to Stationsallén.
	for span in [Vector2(20.5,31.3),Vector2(38.7,42.5)]:
		_make_driving_surface("Depot footpath",Vector3(2.3,.08,span.y-span.x),
			Vector3(-39,-.09,(span.x+span.y)*.5),Color("#afa99b"))
	_make_driving_surface("Shop pavement",Vector3(37,.08,2.5),Vector3(-24.9,-.09,41.25),Color("#afa99b"))
	for i in 8:
		_make_box("Stationsallén crossing",Vector3(2.25,.014,.48),Vector3(-39,-.028,31.85+i*.90),Color("#edece1"))
	var meadow: Rect2 = ground_work.PICNIC_MEADOW
	for x in [meadow.position.x,meadow.end.x]:
		for z in [meadow.position.y,meadow.end.y]:
			_make_box("Meadow stake",Vector3(.075,.70,.075),Vector3(x,.15,z),Color("#966b42"))
			_make_box("Meadow pennant",Vector3(.30,.16,.02),Vector3(x+.13,.42,z),Color("#ebc75c"))
	meadow_sign = _station_sign("",Vector3(meadow.get_center().x,1.15,meadow.end.y+.6),.006,Color.WHITE)
	meadow_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_update_meadow_sign()
	var waypost := Vector3(-37.65,0,21.2)
	_make_roadside_solid("Footpath signpost",Vector3(.085,1.9,.085),waypost+Vector3.UP*.9,Color("#758384"))
	_make_box("Shop direction sign",Vector3(2.0,.49,.08),waypost+Vector3.UP*1.68,Color("#20554c"))
	var directions := Label3D.new()
	directions.text = "↑  Café · Snack kiosk"
	directions.position = waypost+Vector3(0,1.68,-.047)
	directions.rotation.y = PI
	directions.font_size = 34
	directions.pixel_size = .0048
	add_child(directions)
	_size_world_sign(directions, 1.88)
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
		if i == BUS:
			_fit_bus_exterior(model)
			_add_bus_destination_boards(model)
		if i == QUATTRO:
			_fit_quattro_glazing(model)
		if i == SCHOOL_CAR:
			_add_school_car_sign(model)
		_park_at_home(body, i)
		if i == 2:
			parked_fire_locker = FireLocker.new()
			parked_fire_locker.fit(model)
		for lamp in model.find_children("Flash*", "MeshInstance3D", true, false):
			lamp.visible = false
		parked_cars.append(body)
		var bounds := _model_bounds(body,model)
		var mount := Vector3(bounds.get_center().x,bounds.end.y,bounds.get_center().z)
		if i == MINI_CABRIO:
			mount = Vector3(mount.x,bounds.position.y+bounds.size.y*.58,bounds.end.z*.72)
		elif i == DAM_PICKUP:
			var floor_mesh := model.find_child("Cargo bed floor",true,false) as MeshInstance3D
			var rib := model.find_child("Cargo floor rib*",true,false) as MeshInstance3D
			var floor_center := body.to_local(floor_mesh.to_global(floor_mesh.get_aabb().get_center()))
			var rib_bounds := (body.global_transform.affine_inverse() * rib.global_transform) * rib.get_aabb()
			mount = Vector3(floor_center.x,rib_bounds.end.y,floor_center.z)
		parcel_mounts.append(mount)
		parked_footprints.append(Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z))
		parked_sizes.append(Vector2(maxf(-bounds.position.x,bounds.end.x),maxf(-bounds.position.z,bounds.end.z)))
		if i == FARM_TRACTOR:
			tractor_bare_bounds = bounds
			_fit_plough(model)
			tractor_plough_bounds = _model_bounds(body,model)
			_update_tractor_footprint()
		if i == PUCH_DAKOTA:
			_add_parked_moped_stand(body)
			for side in [-1,1]:
				_make_box("Moped bay stripe",Vector3(.07,.019,3.3),body.position+Vector3(side*.91,.015,0),Color("#deddd1")).material_override = marking_finish
		elif i == BUS:
			for side in [-1,1]:
				_make_box("Bus bay stripe",Vector3(.10,.025,11.6),body.position+Vector3(side*2.3,.014,0),Color("#deddd1")).material_override = marking_finish
		elif i == 2:
			for side in [-1,1]:
				_make_box("Fire bay sideline",Vector3(.13,.025,9.8),body.position+Vector3(side*2.15,.02,0),Color.WHITE).material_override = marking_finish
			_make_box("Fire bay rear line",Vector3(4.43,.025,.13),body.position+Vector3(0,.02,4.9),Color.WHITE).material_override = marking_finish
			var number := _road_sign_text(self,"711",body.position+Vector3(0,.045,-4.3),.022,Color.WHITE)
			number.rotation = Vector3(-PI*.5,PI,0)
		elif i == RECOVERY:
			for side in [-1,1]:
				_make_box("Recovery bay stripe",Vector3(.1,.025,9.3),body.position+Vector3(side*2.5,.014,.45),Color("#deddd1")).material_override = marking_finish
		else:
			for side in [-1,1]:
				_make_box("Parking stripe",Vector3(.10,.025,7.8),body.position+Vector3(side*2.35,.014,0),Color("#deddd1")).material_override = marking_finish
	_make_walker("Player on foot",0,0,1,Color("#648faa"),Color("#30414d"))
	walker = walker_data.pop_back().actor
	# Restore quest props once both the recipients and the player's hands exist.
	_place_courier_parcel()
	_place_cake_box()
	_place_lost_figurine()
	_place_umbrella()
	_place_thermos()
	walker.add_child(scooter)
	shops.show_carried_toy()
	_make_walker("BMW driver",0,0,1,Color("#648faa"),Color("#30414d"))
	road_driver = walker_data.pop_back().actor
	road_driver.reparent(ambulance,false)
	road_driver.rotation = Vector3.ZERO
	road_driver.add_child(moped_pose)
	moped_pose.hide()
	for avatar in [walker, road_driver]:
		var lip: MeshInstance3D = avatar.get_meta("lip")
		var smile := Node3D.new()
		smile.name = "Smile"
		avatar.add_child(smile)
		smile.position = lip.position
		for side in [-1,1]:
			var corner := MeshInstance3D.new()
			corner.mesh = lip.mesh
			corner.material_override = lip.material_override
			corner.scale = Vector3(.050,.011,.020)
			corner.position = Vector3(side*.024,.003,.003)
			corner.rotation.z = side*.43
			corner.rotation.y = -side*.24
			smile.add_child(corner)
		smile.hide()
	for leg: Node3D in road_driver.get_meta("legs"):
		leg.hide()
	_build_driving_legs("CarLegs",Vector3(.16,.77,-.35),Vector3(.15,.40,-.55))
	_build_driving_legs("RidingLegs",Vector3(.46,.55,-.30),Vector3(.48,.18,-.19))
	for alma in [false,true]:
		var scale_y := .78 * (.88 if alma else 1.0)
		var origin_y := 1.505 - .87 * scale_y
		# Boot centre and sole lie 9.8 cm below the ankle in character space.
		var ankle_height := (1.02-origin_y)/scale_y + .098
		_build_driving_legs("AlmaCabLegs" if alma else "AxelCabLegs",Vector3(.14,.74,-.37),Vector3(.15,ankle_height,-.47))
		# Place each sole on the mower footboard, ahead of the seat.
		var mower_origin_y := .79 - .77 * scale_y
		var mower_ankle := Vector3(.28, .395-mower_origin_y, -.46) / scale_y + Vector3(0,.098,.05)
		_build_driving_legs("AlmaMowerLegs" if alma else "AxelMowerLegs",Vector3(.30,.69,-.38),mower_ankle)
		var shopper_origin_y := .64 - .77 * scale_y
		var shopper_ankle := Vector3(.17, .243-shopper_origin_y, -.49) / scale_y + Vector3(0,.098,.05)
		_build_driving_legs("AlmaShopperLegs" if alma else "AxelShopperLegs",Vector3(.22,.68,-.40),shopper_ankle)
	for arm in road_driver.get_meta("arms"):
		var forearm := arm.get_child(0).duplicate() as MeshInstance3D
		forearm.name = "Forearm"
		forearm.scale = Vector3(.82,1,.82)
		arm.add_child(forearm)
		var hand := MeshInstance3D.new()
		hand.name = "Hand"
		hand.mesh = preload("res://characters/GrippingHand.obj")
		hand.scale.x = signf(arm.position.x)
		hand.material_override = road_driver.get_node("Face").material_override
		arm.add_child(hand)
	road_driver.hide()
	_make_walker("Helmsperson",0,0,1,Color("#648faa"),Color("#30414d"))
	skipper = walker_data.pop_back().actor
	skipper.reparent(launch,false)
	skipper.rotation = Vector3.ZERO
	skipper.position = Vector3(-.21,-.16,.56)
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

func _feet_supported(p: Vector3) -> bool:
	# Sample the corners of the walking footprint across connected deck surfaces.
	for dx in [-.18, .18]:
		for dz in [-.18, .18]:
			var x := p.x + float(dx)
			var z := p.z + float(dz)
			if x > 55 and x < 87 and absf(z)>5.4 and absf(z+48)>5.4 and is_nan(_pier_height(x,z)):
				return false
	return true

func _on_foot_clear(p: Vector3) -> bool:
	if is_instance_valid(workshop_car) and workshop_car.visible and WORKSHOP_CAR_BOUNDS.grow(.2).has_point(p): return false
	if is_instance_valid(casualty) and casualty.visible and casualty.get_parent()==self and AABB(casualty.position-Vector3(2.35,1,1.1),Vector3(4.7,3,2.2)).has_point(p): return false
	if not _play_bounds().grow(-.25).has_point(Vector2(p.x,p.z)):
		return false
	for body in tram.car_bounds():
		if body.grow(.22).has_point(p+Vector3.UP): return false
	if not _feet_supported(p):
		return false
	for wall in building_bounds:
		if wall.grow(.25).has_point(p+Vector3.UP):
			return false
	for solid in roadside_solids:
		if solid.grow(.22).has_point(p+Vector3.UP): return false
	if _near_parked_vehicle(p,.22): return false
	for item in traffic_data:
		var offset: Vector3 = item.actor.to_local(p)
		if absf(offset.z) < float(item.length)+.28 and absf(offset.x) < float(item.width)+.28:
			return false
	for trunk in trunks:
		if Vector2(p.x-trunk.x,p.z-trunk.z).length_squared() < pow(trunk.y+.22,2):
			return false
	return true

func _ferry_wait_seconds(landing: int) -> int:
	return ceili(fposmod(29.0 * landing - _ferry_clock(), 58.0))

func _update_ferry_displays() -> void:
	var second := floori(_ferry_clock())
	var locale := TranslationServer.get_locale()
	if second == ferry_display_second and locale == ferry_display_locale:
		return
	ferry_display_second = second
	ferry_display_locale = locale
	for i in ferry_displays.size():
		var landing := floori(i / 2.0)
		var boarding := _ferry_stop() == landing
		ferry_displays[i].text = tr("Boarding") if boarding else tr("Lotten in %d s") % _ferry_wait_seconds(landing)
		ferry_displays[i].modulate = Color("#acffc1") if boarding else Color("#ffe49d")

func _ferry_stop() -> int:
	var cycle := fmod(_ferry_clock(),58)
	if fmod(cycle,29) >= 5:
		return -1
	return 0 if cycle < 29 else 1

func _near_ferry_landing() -> int:
	for i in FERRY_LANDINGS.size():
		if absf(walker.position.x-64.9) <= 1.0 and absf(walker.position.z-FERRY_LANDINGS[i]) <= 3.5:
			return i
	return -1

func _toggle_scooter() -> void:
	if walk_jump_left > 0 or boule_seated: return
	if mode != "playing" or paused or not walker.visible or boating or tram_mode != 0 or ferry_passenger: return
	if phone.handset.is_visible_in_tree() or shops.inside >= 0: return
	if scooter.visible:
		scooter.dismount(walker)
	else:
		if not scooter.can_stand(self,walker.position,walker.rotation.y,walker.scale.y):
			message = "Find clear ground to unfold the scooter."
			message_timer = 3.0
			return
		_animate_steps(walker, 0.0, 1.0)
		scooter.mount(walker)
	walking_velocity = Vector3.ZERO
	_refresh_ui()

func _rig_excavator() -> void:
	var parts := excavator.find_children("*", "MeshInstance3D", true, false)
	excavator.add_child(cab_turntable)
	cab_turntable.add_child(boom_joint)
	boom_joint.position = Vector3(-.12,2.16,.90)
	boom_joint.add_child(stick_joint)
	stick_joint.position = Vector3(0,3.27,5.11)
	stick_joint.add_child(bucket_joint)
	bucket_joint.position = Vector3(0,-4.25,.82)
	for part in parts:
		var label := String(part.name).to_lower().replace(" ","").replace("_","")
		if label.begins_with("continuouscrawler"):
			var belt := CrawlerBelt.new()
			excavator.add_child(belt)
			belt.position.x = excavator.to_local(part.global_position).x
			belt.configure(part)
			crawler_belts.append(belt)
			continue
		if label.begins_with("track") or label.begins_with("continuous") or label.begins_with("bearing") or label.begins_with("lowerroller") or label.begins_with("finaldrive") or label.begins_with("crosscarriage") or label.begins_with("swingbearing"): continue
		var joint := cab_turntable
		for prefix in ["boom","hardened","highpressure"]:
			if label.begins_with(prefix): joint = boom_joint
		for prefix in ["bucket","dipper","cylinderport","swaged"]:
			if label.begins_with(prefix): joint = stick_joint
		if label.begins_with("hardened") and excavator.to_local(part.global_position).z > 6.5:
			joint = stick_joint
		for prefix in ["digging","bucketcheek","bucketbell","heel","cheekwear","replaceable"]:
			if label.begins_with(prefix): joint = bucket_joint
		if label.begins_with("boomlift") or label.begins_with("stickcylinder") or label.begins_with("bucketcylinder"):
			var mount := excavator.to_local(part.global_position)
			var lift := boom_lifts[int(mount.x > 0)]
			var moving_joint := boom_joint
			var base_pin := mount.y < boom_joint.position.y
			joint = cab_turntable
			if label.begins_with("stickcylinder"):
				lift = stick_cylinder
				joint = boom_joint
				moving_joint = stick_joint
				base_pin = mount.z < 4
			elif label.begins_with("bucketcylinder"):
				lift = bucket_cylinder
				joint = stick_joint
				moving_joint = bucket_joint
				base_pin = mount.y > 4
			if "pivot" in label:
				if base_pin:
					lift.foot = part
				else:
					lift.head = part
					joint = moving_joint
			elif "barrel" in label:
				lift.barrel = part
				lift.barrel_length = part.get_aabb().size.y
			elif "gland" in label:
				lift.gland = part
				lift.gland_length = part.get_aabb().size.y
			else:
				lift.rod = part
				lift.rod_length = part.get_aabb().size.y
		part.reparent(joint,true)
		if joint == bucket_joint:
			for surface in part.mesh.get_surface_count():
				var vertices: PackedVector3Array = part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					var local: Vector3 = part.transform * vertex
					bucket_profile.append(Vector2(local.y,local.z))
	bucket_profile = Geometry2D.convex_hull(bucket_profile)

func _bucket_clearance() -> float:
	var pose := bucket_joint.global_transform
	var lowest := INF
	for point in bucket_profile:
		lowest = minf(lowest,pose.origin.y + pose.basis.y.y*point.x + pose.basis.z.y*point.y)
	return lowest - excavator.global_position.y

func _support_bucket() -> void:
	if _bucket_clearance() >= 0: return
	var lowered := boom_joint.rotation.x
	var raised := -.82
	for iteration in 12:
		boom_joint.rotation.x = (lowered + raised)*.5
		if _bucket_clearance() < 0:
			lowered = boom_joint.rotation.x
		else:
			raised = boom_joint.rotation.x
	boom_joint.rotation.x = raised

func _crawler_bounds() -> AABB:
	return excavator.global_transform * AABB(Vector3(-1.93,0,-2.75),Vector3(3.86,3.8,5.5))

func _near_excavator() -> bool:
	return is_instance_valid(excavator) and walker.visible and walker.position.distance_to(excavator.position)<4.4

func _crawler_clear() -> bool:
	var hull := _crawler_bounds()
	if not EQUIPMENT_YARD.encloses(Rect2(hull.position.x,hull.position.z,hull.size.x,hull.size.z)):
		return false
	for i in building_bounds.size():
		if i != excavator_wall and hull.intersects(building_bounds[i]): return false
	for i in parked_cars.size():
		if parked_cars[i].visible and hull.intersects(_parked_bounds(i)): return false
	return true

func _drive_excavator(delta: float) -> void:
	var old := excavator.transform
	var controls_available := _world_controls_available()
	var steer := 0.0
	var drive := 0.0
	if controls_available:
		steer = Input.get_axis("ui_left","ui_right") + int(_movement_pressed(KEY_D))-int(_movement_pressed(KEY_A))
		if is_zero_approx(steer): steer = mouse_steering
		if _keyboard_pedals_available():
			drive = Input.get_axis("ui_down","ui_up") + int(_movement_pressed(KEY_W))-int(_movement_pressed(KEY_S))
		if mouse_gas: drive = 1
		if mouse_brake or brake_pedal_held: drive = -1
	driving_controls.set_controls(steer, drive > 0, drive < 0, drive < 0)
	if steer != 0:
		excavator.rotate_y(-clampf(steer,-1,1)*delta)
		if not _crawler_clear(): excavator.basis = old.basis
	excavator_turn_signals.advance(steer, delta, calm_mode or steady_player_lights)
	var target_speed := clampf(drive, -1, 1) * 1.8
	var previous_speed := crawler_speed
	crawler_speed = move_toward(crawler_speed, target_speed, (276000.0 if is_zero_approx(drive) else 1104000.0) / Mass.EXCAVATOR_KG * delta)
	var motion := excavator.basis.z * (previous_speed + crawler_speed) * .5 * delta
	for step in [Vector3(motion.x,0,0),Vector3(0,0,motion.z)]:
		if step.is_zero_approx(): continue
		var before := excavator.position
		excavator.position += step
		if not _crawler_clear(): excavator.position = before
	if not motion.is_zero_approx() and excavator.position == old.origin:
		crawler_speed = 0.0
	if excavator.transform != old:
		var travel := (excavator.position - old.origin).dot(excavator.basis.z)
		var turn := old.basis.z.signed_angle_to(excavator.basis.z,Vector3.UP)
		for belt in crawler_belts:
			belt.advance(travel - turn*belt.position.x)
	building_bounds[excavator_wall] = _crawler_bounds()
	var previous_slew := cab_turntable.rotation.y
	var previous_arm := Vector3(boom_joint.rotation.x, stick_joint.rotation.x, bucket_joint.rotation.x)
	if controls_available:
		cab_turntable.rotate_y((int(Input.is_key_pressed(KEY_Q))-int(Input.is_key_pressed(KEY_E)))*delta)
		boom_joint.rotation.x = clampf(boom_joint.rotation.x + (int(Input.is_key_pressed(KEY_K))-int(Input.is_key_pressed(KEY_I)))*delta*.50,-.82,0)
		stick_joint.rotation.x = clampf(stick_joint.rotation.x + (int(Input.is_key_pressed(KEY_Y))-int(Input.is_key_pressed(KEY_G)))*delta*.65,-.62,.65)
		bucket_joint.rotation.x = clampf(bucket_joint.rotation.x + (int(Input.is_key_pressed(KEY_O))-int(Input.is_key_pressed(KEY_L)))*delta*.85,-.95,.95)
	_support_bucket()
	excavation_sand.move_bucket(bucket_joint, bucket_joint.rotation.x - previous_arm.z)
	var arm_pose := Vector3(boom_joint.rotation.x, stick_joint.rotation.x, bucket_joint.rotation.x)
	var working := not excavator.transform.is_equal_approx(old) or not is_equal_approx(previous_slew, cab_turntable.rotation.y) or not arm_pose.is_equal_approx(previous_arm)
	siren_player.pitch_scale = move_toward(siren_player.pitch_scale, 1.18 if working else 0.78, delta * 1.5)
	for lift in boom_lifts: lift.update_pose()
	stick_cylinder.update_pose()
	bucket_cylinder.update_pose()
	walker.position = excavator.position
	_update_entry_button()

func _swing_shopper(model: Node3D, open: bool) -> void:
	var hinge := model.find_child("EntryHinge",true,false) as Node3D
	var closed := Quaternion.IDENTITY
	# A diagonal hinge axis tips the shell towards the nose and the passenger side.
	var lifted := Quaternion(Vector3(.82,0,-.57).normalized(),deg_to_rad(53))
	hinge.quaternion = closed if open else lifted
	var motion := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(hinge,"quaternion",lifted if open else closed,.55)
	await motion.finished

func _step_through_shopper(car: Node3D, landing: Vector3, entering: bool) -> void:
	var side := signf(car.to_local(landing).x)
	var standing_scale := .88 if play_as_alma else 1.0
	var riding_scale := standing_scale*.78
	var seat := car.to_global(Vector3(0,.64-.77*riding_scale,-.04))
	var start_yaw := walker.rotation.y if entering else car.rotation.y
	_animate_steps(walker,0.0,.1)
	var gait: Gait = walker.get_meta("gait")
	var pose := func(t: float):
		var settle := smoothstep(.16,.95,t)
		walker.position = landing.lerp(seat,t) + Vector3.UP*.085*sin(PI*t)
		walker.scale = Vector3.ONE*lerpf(standing_scale,riding_scale,settle)
		walker.rotation.y = lerp_angle(start_yaw,car.rotation.y,t) + side*.85*sin(PI*t)
		for i in 2:
			var leading := signf(gait.hip_centres[i]) == -side
			var step := smoothstep(.03 if leading else .28,.78 if leading else .98,t)
			var ankle_down := lerpf(Gait.THIGH+Gait.SHIN-.002,(.64-.243)/riding_scale-Gait.SOLE_HEIGHT,step)
			var forward := step*(.49-.04)/riding_scale
			ankle_down -= .10*sin(PI*step)
			var reach := Vector2(forward,ankle_down).length()
			var thigh := atan2(forward,ankle_down)+acos(clampf((Gait.THIGH**2+reach**2-Gait.SHIN**2)/(2*Gait.THIGH*reach),-1,1))
			var bend := acos(clampf((reach**2-Gait.THIGH**2-Gait.SHIN**2)/(2*Gait.THIGH*Gait.SHIN),-1,1))
			gait.legs[i].rotation = Vector3(thigh,0,0)
			gait.knees[i].set_bone_pose_rotation(1,Quaternion(Vector3.RIGHT,-bend))
			gait.knees[i].set_bone_pose_rotation(2,Quaternion(Vector3.RIGHT,-bend*.5))
			gait.shoes[i].position = Vector3.DOWN*Gait.THIGH + (Vector3.DOWN*Gait.SHIN).rotated(Vector3.RIGHT,-bend)
			gait.shoes[i].basis = gait.legs[i].basis.inverse()
	pose.call(0.0 if entering else 1.0)
	var motion := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_method(pose,0.0 if entering else 1.0,1.0 if entering else 0.0,.85)
	await motion.finished
	walker.scale = Vector3.ONE*standing_scale
	if not entering: _animate_steps(walker,0.0,.1)

func _change_seat() -> void:
	if shopper_boarding: return
	if walk_jump_left > 0 or bridge_jump_left > 0: return
	if scooter.visible:
		_toggle_scooter()
		return
	if mode != "playing" or paused: return
	if boating or _at_launch_landing():
		var landing := Vector3(LAUNCH_LANDING.x,_foot_height(LAUNCH_LANDING.x,LAUNCH_LANDING.y),LAUNCH_LANDING.y)
		if not _launch_at_berth() or not _on_foot_clear(landing): return
		boating = not boating
		if boating: release_pedal_keys = _keyboard_pedal_pressed()
		walker.position = landing
		walker.visible = not boating
		walking_velocity = Vector3.ZERO
		launch_speed = 0.0
		_release_mouse_pedals()
		listener.reparent(launch if boating else walker,false)
		listener.position = Vector3.UP * (1.3 if boating else 1.6)
		_update_camera(0,true)
		_update_route_arrows()
		_update_siren()
		_refresh_ui()
		return
	if _at_boule_bench():
		_set_boule_seated(not boule_seated)
		return
	if _near_boule_ring():
		if not boule_guest_turn:
			boule_join_requested = not boule_join_requested
			_update_entry_button()
		return
	if operating_excavator or (_near_excavator() and tram_mode == 0 and not ferry_passenger):
		if operating_excavator:
			var landed := false
			for angle in [0, PI/4, -PI/4, PI/2, -PI/2, 3*PI/4, -3*PI/4, PI]:
				var doorway := Vector3(3.8,0,1.0).rotated(Vector3.UP,angle)
				var door := cab_turntable.to_global(doorway)
				door.y = _foot_height(door.x,door.z)
				if _on_foot_clear(door):
					walker.position = door
					landed = true
					break
			if not landed: return
			walker.show()
		else:
			walker.hide()
		_release_mouse_pedals()
		crawler_speed = 0.0
		operating_excavator = not operating_excavator
		if operating_excavator: release_pedal_keys = _keyboard_pedal_pressed()
		listener.reparent(cab_turntable if operating_excavator else walker, false)
		listener.position = Vector3.UP * (2.5 if operating_excavator else 1.6)
		_update_siren()
		walking_velocity = Vector3.ZERO
		_refresh_ui()
		_update_entry_button()
		return
	var open_stop := tram.open_station()
	if tram_mode != 0:
		if open_stop < 0:
			if tram_mode == 2:
				tram_driver_exit_requested = true
				_update_entry_button()
			return
		var station: Node3D = tram.stations[open_stop]
		var landing := station.to_global(Vector3(2.75,.29,.15))
		if not _on_foot_clear(landing): return
		if ambulance.visible:
			parked_cars[vehicle_index].transform = ambulance.transform
			parked_cars[vehicle_index].visible = true
			ambulance.hide()
		_release_mouse_pedals()
		tram_mode = 0
		tram_driver_exit_requested = false
		walker.position = landing
		walker.show()
		walking_velocity = Vector3.ZERO
		walk_basis = station.basis
		listener.reparent(walker,false)
		listener.position = Vector3.UP*1.6
		_update_camera(0,true)
		_refresh_ui()
		return
	if walker.visible and not ferry_passenger and open_stop >= 0 and tram.platform_at(walker.position)==open_stop:
		tram_mode = 1
		walker.hide()
		walking_velocity = Vector3.ZERO
		listener.reparent(tram.sections[1],false)
		listener.position = Vector3.UP*1.6
		_update_camera(0,true)
		_refresh_ui()
		return
	var stop := _ferry_stop()
	if ferry_passenger:
		if stop < 0:
			ferry_exit_requested = not ferry_exit_requested
			_update_entry_button()
			return
		var z: float = FERRY_LANDINGS[stop]
		var landing := Vector3(64.9,_foot_height(64.9,z),z)
		if not _on_foot_clear(landing): return
		ferry_passenger = false
		walker.position = landing
		_update_route_arrows()
		walk_basis = Basis(Vector3.UP, PI*.5)
		walker.rotation.y = walk_basis.get_euler().y
		listener.global_basis = walk_basis
		_update_camera(0,true)
		_refresh_ui()
		get_viewport().gui_release_focus()
		return
	if walker.visible and stop >= 0 and _near_ferry_landing() == stop:
		ferry_passenger = true
		_update_route_arrows()
		ferry_exit_requested = false
		walking_velocity = Vector3.ZERO
		walker.rotation.y = -PI*.5
		_update_moorings(0)
		_animate_steps(walker,0,.1)
		_refresh_ui()
		get_viewport().gui_release_focus()
		return
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
		if vehicle_index == SHOPPER:
			shopper_boarding = true
			speed = 0
			old_car.hide()
			await _swing_shopper(vehicle_model,true)
			old_car.show()
		carried_parcel_leg = mission_index
		parked_door_offset = old_car.to_local(door)
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
		_release_mouse_pedals()
		_end_skid()
		parked_sound_settings[vehicle_index] = sound_on
		parked_light_settings[vehicle_index] = lights_on
		siren_player.stop()
		if vehicle_index == SHOPPER:
			var parked_hinge := old_car.find_child("EntryHinge",true,false) as Node3D
			parked_hinge.quaternion = (vehicle_model.find_child("EntryHinge",true,false) as Node3D).quaternion
			var landing := walker.position
			await _step_through_shopper(old_car,landing,false)
			await _swing_shopper(old_car,false)
			shopper_boarding = false
	else:
		var next := _nearest_car()
		if next < 0: return
		if next == SHOPPER:
			shopper_boarding = true
			var parked := parked_cars[next]
			await _swing_shopper(parked,true)
			await _step_through_shopper(parked,walker.position,true)
		release_pedal_keys = _keyboard_pedal_pressed()
		_change_mission_vehicle(next)
		sound_on = parked_sound_settings[next]
		lights_on = parked_light_settings[next]
		_mark_selected_vehicle(next)
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
		if next == SHOPPER:
			_refresh_ui()
			await _swing_shopper(vehicle_model,false)
			(parked_cars[next].find_child("EntryHinge",true,false) as Node3D).quaternion = Quaternion.IDENTITY
			shopper_boarding = false
	message_timer = 0
	parked_at_target = 0
	_update_mission_marker()
	_refresh_ui()
	get_viewport().gui_release_focus()
	if shopper_recovery_requested:
		shopper_recovery_requested = false
		_recover_position()

func _rest_seconds() -> int:
	return ceili((60.0-run_reserve)/3.0) if winded else 0

func _movement_pressed(default_key: Key) -> bool:
	if number_movement:
		for key: Key in NUMBER_MOVEMENT[default_key]:
			if Input.is_key_pressed(key):
				return true
		return false
	return Input.is_key_pressed(default_key)

func _movement_hint(text: String) -> String:
	var keys := {"up":"8","left":"4","down":"5","right":"6"} if number_movement else {"up":"W","left":"A","down":"S","right":"D"}
	keys["seat"] = "F / F3" if seat_f3 else "F"
	keys["horn"] = "H / F4" if horn_f4 else "H"
	keys["pause"] = "P / F7" if pause_f7 else "P"
	keys["help"] = tr("Space") + (" / " + tr("Insert") if insert_help else "")
	return text.format(keys)

func _with_recovery_hint(controls: String) -> String:
	return _movement_hint(controls) + "   ·   " + _recovery_hint()

func _recovery_hint() -> String:
	return tr("Stuck? Press %s") % OS.get_keycode_string(recovery_key)

func _walking_hint() -> String:
	if winded:
		return tr("Walk or rest · Run again in %d s") % _rest_seconds()
	var run_key := tr("Ctrl") if ctrl_run else tr("Shift")
	if run_ready_hint_time > 0:
		return tr("Ready to run again! Hold {run} and walk forward.").replace("{run}",run_key)
	return tr("{up}/{down} Walk · {left}/{right} Turn · {run} + {up} Run · {seat} Enter · {scooter} Scooter").replace("{run}",run_key).replace("{scooter}",OS.get_keycode_string(scooter_key)) + "   ·   " + (tr("%s Jump") % OS.get_keycode_string(jump_key)) + "   ·   " + tr("9 Raise camera · 3 Lower camera" if number_camera else "PgUp Raise camera · PgDn Lower camera") + "\n" + (tr("Hold %s and move the mouse to look around") % OS.get_keycode_string(look_key))

func _walk(delta: float) -> void:
	if boule_guest_turn or boule_seated: return
	if shopper_boarding: return
	var keys := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	keys += Vector2(int(_movement_pressed(KEY_D))-int(_movement_pressed(KEY_A)),int(_movement_pressed(KEY_S))-int(_movement_pressed(KEY_W)))
	if phone.handset.is_visible_in_tree():
		keys = Vector2.ZERO
		walking_velocity = Vector3.ZERO
	if scooter.visible:
		scooter.ride(self,-clampf(keys.y,-1,1),clampf(keys.x,-1,1),delta)
		return
	if _world_controls_available():
		var raise_camera := Input.is_key_pressed(KEY_PAGEUP)
		var lower_camera := Input.is_key_pressed(KEY_PAGEDOWN)
		if number_camera:
			raise_camera = Input.is_key_pressed(KEY_9) or Input.is_key_pressed(KEY_KP_9)
			lower_camera = Input.is_key_pressed(KEY_3) or Input.is_key_pressed(KEY_KP_3)
		var height_input := int(raise_camera) - int(lower_camera)
		walk_camera_height = clampf(walk_camera_height + height_input*delta*2.0,-1.5,3.5)
	walker.rotate_y(-clampf(keys.x,-1,1)*2.5*delta)
	walk_basis = Basis(Vector3.UP,walker.rotation.y)
	var running := Input.is_key_pressed(KEY_CTRL if ctrl_run else KEY_SHIFT) and not winded and keys.y < 0
	var desired := walk_basis.z * clampf(keys.y,-1,1) * (Gait.RUN_SPEED if running else Gait.WALK_SPEED)
	desired.y = 0
	var horizontal := Vector3(walking_velocity.x,0,walking_velocity.z)
	var acceleration := 14.0 if keys.is_zero_approx() else 9.0
	var motion := horizontal.move_toward(desired, acceleration * delta) * delta
	var next := walker.position
	for step in [Vector3(motion.x,0,0),Vector3(0,0,motion.z)]:
		var pieces := maxi(1, ceili(step.length()/.16))
		var stride: Vector3 = step / pieces
		for piece in pieces:
			if tram.crosses_boarding_edge(next, next + stride):
				_change_seat()
				if tram_mode == 1: return
			if not _on_foot_clear(next+stride) or not street_signals.pedestrian_may_enter(next,next+stride): break
			next += stride
	var landed := walk_jump_left > 0 and walk_jump_left <= delta
	walk_jump_left = maxf(0, walk_jump_left - delta)
	var jump_phase := walk_jump_left / WALK_JUMP_TIME
	next.y = _foot_height(next.x,next.z) + 2.0 * jump_phase * (1.0 - jump_phase)
	var travel := next-walker.position
	var ground_distance := Vector2(travel.x, travel.z).length()
	var previous_rest := _rest_seconds()
	var showed_ready := run_ready_hint_time > 0
	run_ready_hint_time = maxf(0, run_ready_hint_time - delta)
	if running and ground_distance > 0.0:
		run_reserve = maxf(0,run_reserve-delta)
		if run_reserve < 0.000001:
			run_reserve = 0.0
			winded = true
	else:
		run_reserve = minf(60,run_reserve+3*delta)
		if 60.0 - run_reserve < 0.000001:
			run_reserve = 60.0
			if winded: run_ready_hint_time = 3.0
			winded = false
	if _rest_seconds() != previous_rest or showed_ready != (run_ready_hint_time > 0):
		driving_hints.text = _with_recovery_hint(_walking_hint())
	walker.position = next
	var near_bench := Vector2(next.x-30,next.z-20).length() < 1.2
	if near_bench and not at_colour_bench:
		boutique_jacket = ""
		jacket_palette = (jacket_palette + 1) % BENCH_COLOURS.size()
		_apply_player_appearance()
	at_colour_bench = near_bench
	walking_velocity = travel / maxf(delta,.00001)
	listener.global_basis = walk_basis
	# Turning or sliding along a wall can spend part of the travel sideways.
	var signed_distance := -travel.dot(walk_basis.z)
	_animate_steps(walker, 0.0 if landed else signed_distance, delta)
	if landed:
		var gait = walker.get_meta("gait")
		var landed_in_snow := false
		for i in gait.shoes.size():
			var shoe: Node3D = gait.shoes[i]
			if _snow_underfoot(shoe.global_position):
				_stamp_snow_step(shoe, i == 0)
				landed_in_snow = true
		footstep.stream = SNOW_STEP if landed_in_snow else DRY_STEP
		footstep.volume_db = -10.0
		footstep.pitch_scale = .79
		footstep.play()
	_update_entry_button()

func _build_boule_choices() -> void:
	ui.add_child(boule_choices)
	boule_choices.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boule_choices.position += Vector2(-120,95)
	boule_choices.custom_minimum_size.x = 240
	var caption := Label.new()
	caption.text = "Aim at the jack"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boule_choices.add_child(caption)
	boule_aim.min_value = -1.2
	boule_aim.max_value = 1.2
	boule_aim.step = .1
	boule_aim.custom_minimum_size.y = 32
	boule_choices.add_child(boule_aim)
	boule_aim.value_changed.connect(func(offset: float):
		if boule_guest_turn:
			walker.rotation.y = -atan2(offset,8)
	)
	boule_choices.add_child(boule_throw_buttons)
	for index in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(76,54)
		boule_throw_buttons.add_child(button)
		button.draw.connect(func():
			var span := 24.0+index*17
			var points := PackedVector2Array()
			for sample in 17:
				var t := sample/16.0
				points.append(Vector2(8+span*t,39-(13+index*5)*4*t*(1-t)))
			button.draw_polyline(points,Color.WHITE,2,true)
			button.draw_circle(points[16],4,Color("#ffcf58"),true,-1,true)
		)
		button.pressed.connect(func():
			if boule_guest_turn and not paused:
				boule_throw_length = index
				boule_choices.hide()
		)
	# Keep keyboard navigation on the four controls for the current throw.
	var last_throw := boule_throw_buttons.get_child(-1) as Button
	last_throw.focus_next = last_throw.get_path_to(boule_aim)
	boule_aim.focus_previous = boule_aim.get_path_to(last_throw)
	_translate_boule_controls()
	boule_choices.hide()

func _translate_boule_controls() -> void:
	boule_aim.accessibility_name = tr("Aim at the jack")
	for button: Button in boule_throw_buttons.get_children():
		button.tooltip_text = tr(["Short throw","Medium throw","Long throw"][button.get_index()])
		button.accessibility_name = button.tooltip_text

func _near_boule_ring() -> bool:
	return walker.visible and not scooter.visible and tram_mode == 0 and not ferry_passenger and not operating_excavator and walker.position.distance_to(BOULE_CENTRE+Vector3.BACK*4) < 3.2

func _set_boule_seated(seated: bool) -> void:
	boule_seated = seated
	walking_velocity = Vector3.ZERO
	walker.rotation.y = PI/2
	walk_basis = walker.basis.orthonormalized()
	if boule_seated:
		_animate_steps(walker, 0.0, 1.0)
		var gait: Gait = walker.get_meta("gait")
		walker.position = BOULE_BENCH + Vector3.UP*(.50-gait.legs[0].position.y*walker.scale.y)
		gait.sit()
	else:
		walker.position = BOULE_BENCH_APPROACH
		walker.position.y = _foot_height(walker.position.x,walker.position.z)
		_animate_steps(walker, 0.0, 1.0)
	_update_entry_button()

func _at_boule_bench() -> bool:
	return walker.visible and not scooter.visible and not ferry_passenger and tram_mode == 0 and not operating_excavator and (boule_seated or walker.position.distance_to(BOULE_BENCH) < 1.65)

func _update_entry_button() -> void:
	_set_entry_action()
	if seat_f3 and not seat_button.disabled:
		seat_button.text = tr(seat_button.text) + " / F3"

func _at_launch_landing() -> bool:
	return walker.visible and not ferry_passenger and tram_mode == 0 and not operating_excavator and Vector2(walker.position.x,walker.position.z).distance_to(LAUNCH_LANDING) < 1.0

func _launch_at_berth() -> bool:
	return absf(launch_speed) <= .2 and Vector2(launch.position.x,launch.position.z).distance_to(Vector2(LAUNCH_BERTH.x,LAUNCH_BERTH.z)) <= 1.0

func _set_entry_action() -> void:
	if boating or _at_launch_landing():
		entry_marker.hide()
		seat_button.disabled = not _launch_at_berth()
		seat_button.text = "Step ashore · F" if boating else (tr("Enter %s") % tr("Motorboat")) + " · F"
		return
	if _at_boule_bench():
		entry_marker.hide()
		seat_button.disabled = false
		seat_button.text = "Stand up · F" if boule_seated else "Watch boule from the bench · F"
		return
	if _near_boule_ring():
		entry_marker.hide()
		seat_button.disabled = boule_guest_turn
		seat_button.text = "Cancel boule turn · F" if boule_join_requested else "Join the boule round · F"
		return
	if scooter.visible:
		entry_marker.visible = false
		seat_button.disabled = false
		seat_button.text = "Fold scooter · F"
		return
	if operating_excavator or _near_excavator():
		entry_marker.visible = false
		seat_button.disabled = false
		seat_button.text = tr("Exit excavator · F") if operating_excavator else tr("Drive excavator · F")
		return
	if tram_mode != 0:
		entry_marker.visible = false
		seat_button.disabled = tram.open_station() < 0 and (tram_mode != 2 or tram_driver_exit_requested)
		seat_button.text = "Stop requested" if tram_driver_exit_requested and seat_button.disabled else "Get off tram · F"
		return
	if walker.visible:
		var station := tram.platform_at(walker.position)
		if station >= 0:
			entry_marker.visible = false
			seat_button.disabled = tram.open_station()!=station
			seat_button.text = "Wait for the tram" if seat_button.disabled else "Board tram · F"
			return
	var landing := _near_ferry_landing()
	if ferry_passenger or landing >= 0:
		var stop := _ferry_stop()
		entry_marker.visible = false
		seat_button.disabled = not ferry_passenger and stop != landing
		if ferry_passenger:
			if stop >= 0:
				seat_button.text = "Step ashore · F"
			else:
				seat_button.text = "Stay on board · F" if ferry_exit_requested else "Get off at next landing · F"
		else:
			if stop == landing:
				seat_button.text = "Board Lotten · F"
			else:
				var wait_seconds := _ferry_wait_seconds(landing)
				seat_button.text = tr("Lotten in %d s") % wait_seconds
		return
	var nearest := _nearest_car()
	entry_marker.visible = nearest >= 0 and mode == "playing" and not paused
	if entry_marker.visible:
		var car := parked_cars[nearest]
		var side := signf(car.to_local(walker.position).x)
		entry_marker.global_position = car.to_global(Vector3(side * parked_sizes[nearest].x, 2.05, -parked_sizes[nearest].y * .27))
		entry_marker.text = tr("{key} · Enter {vehicle}").format({"key": "F / F3" if seat_f3 else "F", "vehicle": tr(VEHICLE_NAMES_ALL[nearest])})
	seat_button.disabled = nearest < 0
	seat_button.text = (tr("Enter %s") % tr(VEHICLE_NAMES_ALL[nearest])) + " · F" if nearest >= 0 else tr("Walk to a vehicle")

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

func _build_traffic() -> void:
	_spawn_traffic("res://vehicles/a_traktor.glb", 51, 2.35, 1, 3.2, 1)
	# Two-way, steady traffic on both sides of the main street.
	_spawn_traffic("res://vehicles/traffic_bmw_blue.glb", -40.0, 2.35, 1.0, 6.4)
	_spawn_traffic("res://environment/cyklist.glb", -24.0, 4.18, 1.0, 2.7, 0.72)
	_spawn_traffic("res://environment/cyklist.glb", 26.0, -4.18, -1.0, 2.45, 0.72)
	_spawn_traffic("res://vehicles/raggarbil.glb",68,2.35,1,4.75,.89)
	_spawn_emergency_traffic(0, -19.0, 2.35, 1.0)
	_spawn_emergency_traffic(1, 19.0, -2.35, -1.0)
	_spawn_emergency_traffic(2, 77.0, 2.35, 1.0)
	_spawn_emergency_traffic(XC60_POLICE, -68.0, -2.35, -1.0)
	var moped := _spawn_traffic(VEHICLE_SCENES_ALL[PUCH_DAKOTA], -30, 2.35, 1, 5.3, 1.0)
	_make_walker("Dakota rider",0,0,1,Color("#c77e4a"),Color("#35444c"))
	var rider: Node3D = walker_data.pop_back().actor
	rider.reparent(moped,false)
	rider.rotation = Vector3.ZERO
	rider.scale = Vector3.ONE*.96
	var pose := MopedRider.new()
	rider.add_child(pose)
	for limb: Node3D in rider.get_meta("arms") + rider.get_meta("legs"):
		limb.hide()
	pose.fit_to(moped.get_child(0))
	traffic_data.back().rider = rider
	# Separate neighbourhood circuits share intersections and stay entirely on paved streets.
	var blocks := [
		Rect2(0,-48,102,48), Rect2(102,-48,60,48), Rect2(-55,0,55,35),
		Rect2(102,0,60,60), Rect2(-150,0,95,35), Rect2(-55,-48,55,48),
		Rect2(-510,0,90,35), Rect2(-150,-48,95,48), Rect2(102,-82,60,34),
		Rect2(0,0,48,35),
	]
	for i in traffic_data.size():
		var item: Dictionary = traffic_data[i]
		var block: Rect2 = blocks[i % blocks.size()]
		var lane := absf(item.actor.position.z)
		var curve := _traffic_circuit(block,lane,item.direction > 0)
		item.route = curve
		item.distance = curve.get_baked_length()*fmod(.28+i*.382,1.0)
		_place_traffic(item)

func _traffic_circuit(block: Rect2,lane: float,outside: bool) -> Curve3D:
	var edges := block.grow(lane if outside else -lane)
	var corners := [edges.position,Vector2(edges.position.x,edges.end.y),edges.end,Vector2(edges.end.x,edges.position.y)]
	if not outside: corners.reverse()
	var route := Curve3D.new()
	var radius := 5.0 if outside else 2.2
	for i in 4:
		var corner: Vector2 = corners[i]
		var incoming := (corner-Vector2(corners[(i+3)%4])).normalized()
		var outgoing := (Vector2(corners[(i+1)%4])-corner).normalized()
		for j in 13:
			var t := j/12.0
			var point := corner-incoming*radius*(1-t)*(1-t)+outgoing*radius*t*t
			route.add_point(Vector3(point.x,0,point.y))
	route.add_point(route.get_point_position(0))
	return route

func _place_traffic(item: Dictionary) -> void:
	var route: Curve3D = item.route
	var actor: Node3D = item.actor
	var pos := route.sample_baked(item.distance)
	var next := route.sample_baked(fposmod(float(item.distance)+.12,route.get_baked_length()))
	var forward := pos.direction_to(next)
	actor.rotation.y = atan2(-forward.x,-forward.z)
	pos += actor.basis.x * float(item.get("yield_offset", 0.0))
	actor.position = Vector3(pos.x, _surface_height(pos.x, pos.z), pos.z)
	_align_model_to_bridge(actor, item.model, item.length * 1.25)

func _traffic_bounds(item: Dictionary) -> AABB:
	var half := _traffic_extent(item)
	return AABB(item.actor.position - Vector3(half.x, 1, half.y), Vector3(half.x * 2, 3, half.y * 2))

func _traffic_extent(item: Dictionary) -> Vector2:
	var heading: Vector3 = item.actor.transform.basis.z.abs()
	return Vector2(heading.x*item.length+heading.z*item.width,heading.z*item.length+heading.x*item.width)

func _traffic_gap(item: Dictionary, point: Vector3, extent: Vector2) -> float:
	var actor: Node3D = item.actor
	var offset := point-actor.position
	var ahead := -actor.basis.z.dot(offset)
	if ahead<=0 or absf(actor.basis.x.dot(offset))>=float(item.width)+absf(actor.basis.x.x)*extent.x+absf(actor.basis.x.z)*extent.y:
		return INF
	return ahead-float(item.length)-absf(actor.basis.z.x)*extent.x-absf(actor.basis.z.z)*extent.y

func _spawn_emergency_traffic(index: int, x: float, lane: float, direction: float) -> void:
	var actor := _spawn_traffic(VEHICLE_SCENES_ALL[index], x, lane, direction, 9.0, 1.0)
	traffic_data.back().emergency = true
	var lamps: Array[MeshInstance3D] = []
	var blue := _material(Color("#1679ff"), 0.2, true)
	for node in actor.find_children("Flash*", "MeshInstance3D", true, false):
		var lamp := node as MeshInstance3D
		lamp.material_override = blue
		lamp.visible = false
		lamps.append(lamp)
	# One local light per responding vehicle keeps the night-time spill affordable.
	var spill := OmniLight3D.new()
	spill.position.y = 2.38 if index==XC60_POLICE else [2.8,1.7,3.1][index]
	spill.light_color = Color("#3879ff")
	spill.light_energy = 2.6
	spill.omni_range = 6.0
	spill.distance_fade_enabled = true
	spill.distance_fade_begin = 24
	spill.distance_fade_length = 12
	spill.visible = false
	actor.add_child(spill)
	var siren := AudioStreamPlayer3D.new()
	siren.bus = &"Traffic and radio"
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
		var lit := active and (traffic_light_mode != 2 and (calm_mode or traffic_light_mode == 1 or pulse))
		unit.spill.visible = lit
		for lamp: MeshInstance3D in unit.lamps:
			lamp.visible = lit and (calm_mode or traffic_light_mode == 1 or lamp.name.begins_with("FlashBlue") == (float(unit.phase) < .5))
		var siren: AudioStreamPlayer3D = unit.siren
		if active and traffic_siren_volume > 0 and not AudioServer.is_bus_mute(0):
			var traffic: Dictionary = unit.traffic
			var towards_listener := siren.global_position.direction_to(listener.global_position)
			var source_velocity: Vector3 = -traffic.actor.basis.z * float(traffic.speed)
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
	var is_bus := scene_path == VEHICLE_SCENES_ALL[BUS]
	if is_bus:
		_fit_bus_exterior(model)
		_add_bus_destination_boards(model)
	var half_size := _vehicle_half_size(actor, model)
	var is_bicycle := scene_path.ends_with("cyklist.glb")
	if not is_bicycle:
		var beam_origins: Array[Vector3] = []
		if is_bus:
			var emitter := _material(Color("#fff1dc"),.28,true)
			emitter.emission_energy_multiplier = 3.0*maxf(last_night,0.0)
			traffic_running_lenses.append(emitter)
			for lens: MeshInstance3D in model.find_children("Bus headlight lens*", "MeshInstance3D", true, false):
				lens.set_surface_override_material(0,emitter)
				if absf(lens.position.x) > .89:
					beam_origins.append(actor.to_local(lens.to_global(lens.get_aabb().get_center())) + Vector3.FORWARD * .035)
		else:
			# A shared beam represents the overlapping light pools on ordinary traffic.
			beam_origins.append(Vector3(0,.7,-half_size.y))
		for origin in beam_origins:
			var beam := SpotLight3D.new()
			beam.name = "Dipped beam"
			beam.position = origin
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
			traffic_running_lenses.append(finish)
	var traffic_horn := AudioStreamPlayer3D.new()
	traffic_horn.bus = &"Traffic and radio"
	var voice: String = {"cyklist": "bicycle", "a_traktor": "a_traktor", "raggarbil": "raggarbil", "puch_dakota": "saab96"}.get(scene_path.get_file().get_basename(), "bmw")
	var emergency_index := VEHICLE_SCENES.find(scene_path)
	if emergency_index >= 0:
		voice = HORNS[emergency_index]
	elif scene_path == VEHICLE_SCENES_ALL[XC60_POLICE]:
		voice = "police"
	traffic_horn.stream = load("res://audio/horn_%s.wav" % voice)
	traffic_horn.volume_db = -9
	traffic_horn.unit_size = 5
	traffic_horn.max_distance = 45
	actor.add_child(traffic_horn)
	var turn_signals := preload("res://scripts/turn_indicators.gd").new()
	if is_bicycle:
		var left: Array[Vector3] = [
			Vector3(-.18, 1.08, -.687) * model_scale,
			Vector3(-.14, 1.09, .437) * model_scale,
		]
		var right: Array[Vector3] = [
			Vector3(.18, 1.08, -.687) * model_scale,
			Vector3(.14, 1.09, .437) * model_scale,
		]
		_make_box("Front turn signal bar", Vector3(.36, .026, .044) * model_scale,
			Vector3(0, 1.08, -.66) * model_scale, Color("#303539"), false, actor)
		_make_box("Rear turn signal bar", Vector3(.28, .026, .044) * model_scale,
			Vector3(0, 1.09, .41) * model_scale, Color("#303539"), false, actor)
		turn_signals.fit_anchors(actor, left, right, Vector3(.074, .058, .031) * model_scale)
	else:
		turn_signals.fit(actor, model, _model_bounds(actor, model))
	var pedals = preload("res://scripts/bicycle_pedals.gd").new(self,model) if is_bicycle else null
	traffic_data.append({"pedals":pedals,"mass_kg": Mass.for_model(scene_path), "tractor":scene_path.ends_with("a_traktor.glb"), "horn":traffic_horn, "greeted":false, "actor": actor, "model": model, "direction": direction, "cruise": speed_value, "wheels": _rig_wheels(model), "brake_lens": _brake_lens(model),
		"speed": speed_value, "length": half_size.y,
		"width": half_size.x, "turn_signals": turn_signals})
	return actor

func _traffic_turn_intent(route: Curve3D, distance: float, direction: float, right: Vector3, preview: float) -> float:
	var length := route.get_baked_length()
	if length < .25:
		return 0.0
	var start := distance + direction * (preview - .25)
	var end := distance + direction * (preview + .25)
	if route.get_point_position(0).is_equal_approx(route.get_point_position(route.point_count - 1)):
		start = fposmod(start, length)
		end = fposmod(end, length)
	var upcoming := route.sample_baked(start).direction_to(route.sample_baked(end))
	var sideways := right.dot(upcoming)
	return signf(sideways) if absf(sideways) > .12 else 0.0

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

const OPEN_WATER := [Vector2(-93,-52.9), Vector2(-43.1,-4.9), Vector2(4.9,81)]

func _shore_overlap(span: Vector2, point: Vector3, extent: Vector2) -> float:
	var across := minf(point.x - 55 + extent.x, 87 - point.x + extent.x)
	var along := minf(point.z - span.x + extent.y, span.y - point.z + extent.y)
	return maxf(0, minf(across, along))

func _outside_driving_strip(obstacle: AABB, extra: float) -> bool:
	var lateral := ambulance.global_basis.x.normalized()
	var half_width := (absf(lateral.x)*obstacle.size.x + absf(lateral.z)*obstacle.size.z)*.5
	return absf((obstacle.get_center()-ambulance.position).dot(lateral)) > player_half_size.x + half_width + extra

static func _moves_deeper_into_box(box: AABB, point: Vector3, motion: Vector3) -> bool:
	var offset := point - box.get_center()
	var x_depth := box.size.x * .5 - absf(offset.x)
	var z_depth := box.size.z * .5 - absf(offset.z)
	var inward_x := offset.x * motion.x < 0
	var inward_z := offset.z * motion.z < 0
	if is_equal_approx(x_depth, z_depth):
		return inward_x and inward_z
	return inward_x if x_depth < z_depth else inward_z

func _vehicle_overlap_depth(obstacle: AABB, extent: Vector2, orientation: Basis) -> float:
	var center := ambulance.position
	if center.y < obstacle.position.y or center.y > obstacle.end.y:
		return 0.0
	var dx := minf(center.x - obstacle.position.x, obstacle.end.x - center.x) + extent.x
	var dz := minf(center.z - obstacle.position.z, obstacle.end.z - center.z) + extent.y
	var depth := minf(dx, dz)
	if depth <= 0: return 0
	var offset := obstacle.get_center() - center
	for axis: Vector3 in [orientation.x, orientation.z]:
		var half_span := (absf(axis.x)*obstacle.size.x + absf(axis.z)*obstacle.size.z)*.5
		var reach := player_half_size.x if axis == orientation.x else player_half_size.y
		depth = minf(depth, reach + half_span - absf(offset.dot(axis)))
	return maxf(0, depth)

func _trunk_gap(local_center: Vector3) -> float:
	var side := maxf(absf(local_center.x) - player_half_size.x, 0)
	var end := maxf(maxf(-front_reach - local_center.z, local_center.z - rear_reach), 0)
	return Vector2(side, end).length()

func _player_extent() -> Vector2:
	var heading := ambulance.transform.basis.z.abs()
	return Vector2(heading.x * player_half_size.y + heading.z * player_half_size.x,
		heading.z * player_half_size.y + heading.x * player_half_size.x)

func _player_emergency_response() -> bool:
	return mode == "playing" and not walker.visible and not boating and tram_mode == 0 \
		and (vehicle_index < 3 or vehicle_index == XC60_POLICE) and (lights_on or sound_on)

func _responding_road_vehicles() -> Array[Node3D]:
	var responding: Array[Node3D] = []
	if _player_emergency_response():
		responding.append(ambulance)
	for item in traffic_data:
		if item.get("emergency", false):
			responding.append(item.actor)
	return responding

func _emergency_yield(item: Dictionary, responding: Array[Node3D]) -> float:
	var actor: Node3D = item.actor
	if street_signals.vehicle_in_junction(_traffic_bounds(item)):
		item.yield_target = 0.0
		return INF
	var forward := -actor.basis.z
	var clearance := INF
	var pull_over := false
	for unit in responding:
		var heading := -unit.basis.z
		var offset := unit.position - actor.position
		var lead := offset.dot(forward)
		var alignment := forward.dot(heading)
		if alignment > .85 and lead >= -24.0 and lead <= 5.0 and absf(offset.dot(actor.basis.x)) < 4.2:
			pull_over = true
		elif absf(alignment) < .45:
			var side := forward.cross(Vector3.UP)
			var unit_distance := -offset.dot(side) / heading.dot(side)
			var crossing_distance := lead + unit_distance * alignment
			if unit_distance > -4.0 and unit_distance < 24.0 and crossing_distance >= float(item.length) + 4.0:
				clearance = minf(clearance, crossing_distance - float(item.length) - 4.0)
	item.yield_target = float(item.width) + 1.65 if pull_over else 0.0
	return clearance

func _move_traffic_yield(item: Dictionary, delta: float) -> void:
	var offset := float(item.get("yield_offset", 0.0))
	var next_offset := move_toward(offset, float(item.get("yield_target", 0.0)), delta * 2.3)
	if is_equal_approx(next_offset, offset):
		return
	var actor: Node3D = item.actor
	var position := actor.position + actor.basis.x * (next_offset - offset)
	var extent := _traffic_extent(item)
	for span: Vector2 in OPEN_WATER:
		if _shore_overlap(span, position, extent) > .01:
			return
	var bounds := AABB(position - Vector3(extent.x, .3, extent.y), Vector3(extent.x * 2, 2.0, extent.y * 2))
	for obstacle in _road_obstacles(actor):
		if bounds.intersects(obstacle):
			return
	if walker.visible and bounds.grow(.35).has_point(walker.position):
		return
	for trunk in trunks:
		var tree := Vector3(trunk.x, position.y, trunk.z)
		if bounds.grow(trunk.y).has_point(tree):
			return
	for other in traffic_data:
		if other.actor != actor and bounds.intersects(_traffic_bounds(other)):
			return
	if ambulance.visible:
		var player_extent := _player_extent()
		var player_bounds := AABB(ambulance.position - Vector3(player_extent.x, .3, player_extent.y),
			Vector3(player_extent.x * 2, 2.0, player_extent.y * 2))
		if bounds.intersects(player_bounds):
			return
	item.yield_offset = next_offset

func _junction_vehicle_obstacles(exclude: Node3D) -> Array[AABB]:
	var bounds: Array[AABB] = []
	for item in traffic_data:
		if item.actor != exclude:
			bounds.append(_traffic_bounds(item))
	for i in parked_cars.size():
		if parked_cars[i].visible:
			bounds.append(_parked_bounds(i))
	if ambulance != exclude and ambulance.visible:
		var half := _player_extent()
		bounds.append(AABB(ambulance.position - Vector3(half.x, 1, half.y), Vector3(half.x * 2, 3, half.y * 2)))
	if casualty.visible and casualty.get_parent() == self:
		bounds.append(AABB(casualty.position - Vector3(2.1, 1, .9), Vector3(4.2, 3, 1.8)))
	return bounds

func _update_traffic(delta: float) -> void:
	if vehicle_index != BUS or walker.visible or free_drive:
		bus_merge_time = 0
		bus_departure_pending = false
	if bus_departure_pending and speed > .2:
		bus_departure_pending = false
	if not bus_departure_pending:
		bus_merge_time = maxf(0, bus_merge_time - delta)
	if driven_turn_signals:
		var turn := 0.0
		if not walker.visible and not boating and tram_mode == 0 and not operating_excavator and ambulance.visible:
			turn = steering
			if bus_merge_time > 0 and speed >= -.12 and absf(turn) < .12:
				turn = -1.0
		driven_turn_signals.advance(turn, delta, calm_mode or steady_player_lights)
	if not operating_excavator:
		excavator_turn_signals.advance(0.0, delta, false)
	var weather_pace := 1.0-.12*weather.wet-.23*weather.snow
	var player_size := _player_extent()
	var pedestrians: Array = [walker, passenger, arriving_passenger, waiting_medic, marina_recipient, square_neighbour, crossing_pedestrian, shoe_owner, cat_owner]
	pedestrians.append_array(bus_companions)
	pedestrians.append_array(clinic_fire_team)
	for entry in walker_data:
		pedestrians.append(entry.actor)
	pedestrians = pedestrians.filter(func(person: Node3D): return person.is_visible_in_tree())
	var responding := _responding_road_vehicles()
	for item in traffic_data:
		var actor: Node3D = item.actor
		var emergency: bool = item.get("emergency", false)
		var clearance := street_signals.red_clearance(actor.position, -actor.basis.z, float(item.length), false, false, emergency) + 1.0
		if not emergency:
			clearance = minf(clearance, _emergency_yield(item, responding))
			_move_traffic_yield(item, delta)
			if float(item.get("yield_offset", 0.0)) > .001:
				clearance = minf(clearance, 1.0)
		var queue_gap := street_signals.junction_queue_gap(actor.position, -actor.basis.z, float(item.length),
			2.0 * float(item.length), float(item.width), _junction_vehicle_obstacles(actor), item.route, float(item.distance), emergency)
		clearance = minf(clearance, queue_gap + 1.0)
		var tractor_gap := INF
		for other in traffic_data:
			if item.actor == other.actor: continue
			var gap := _traffic_gap(item,other.actor.position,_traffic_extent(other))
			if other.tractor: tractor_gap=minf(tractor_gap,gap)
			clearance=minf(clearance,gap)
		if casualty.visible and casualty.get_parent()==self:
			clearance=minf(clearance,_traffic_gap(item,casualty.position,Vector2(2.1,.9)))
		if ambulance.visible:
			clearance=minf(clearance,_traffic_gap(item,ambulance.position,player_size))
			if bus_merge_time > 0 and speed >= -.12 and driven_turn_signals.direction < 0 and actor.basis.z.dot(ambulance.basis.z) > .85 and ambulance.to_local(actor.position).z > player_half_size.y:
				var merge_center := ambulance.position-ambulance.basis.x*2.0
				clearance=minf(clearance,_traffic_gap(item,merge_center,player_size)-3.0)
		for i in parked_cars.size():
			if not parked_cars[i].visible: continue
			var bounds := _parked_bounds(i)
			clearance=minf(clearance,_traffic_gap(item,bounds.get_center(),Vector2(bounds.size.x,bounds.size.z)*.5))
		for person: Node3D in pedestrians:
			clearance=minf(clearance,_traffic_gap(item,person.position,Vector2(.45,.45)))
			if person==walker:
				clearance=minf(clearance,_traffic_gap(item,person.position+walking_velocity*.8,Vector2(.45,.45)))
		if tractor_gap <= clearance and tractor_gap<8 and not item.tractor and item.speed>1:
			if not item.greeted:
				item.horn.play()
				item.greeted = true
		elif tractor_gap>15:
			item.greeted = false
		var free_space := maxf(0.0, clearance - 1.0)
		var target := minf(float(item.cruise)*weather_pace, free_space * .95*weather_pace)
		if free_space < 0.1:
			target = 0
		var previous_speed := float(item.speed)
		var snow_under_wheels := 0.0
		var grit_coverage := 0.0
		if not item.has("rider") and weather.snow > .01:
			if ground_work.has_ploughed or ground_work.has_gritted:
				for side in [-1.0,1.0]:
					for axle in [-1.0,1.0]:
						var contact := Vector3(side*float(item.width)*.78,0,axle*float(item.length)*.61)
						var wheel_position := actor.to_global(contact)
						if not ground_work.cleared_at(wheel_position):
							snow_under_wheels += .25 * weather.snow
						if ground_work.gritted_at(wheel_position):
							grit_coverage += .25
			else:
				snow_under_wheels = weather.snow
		var acceleration := 2.2 - .65 * snow_under_wheels + .35 * grit_coverage
		if target < previous_speed:
			acceleration = 6.5 - .7 * weather.wet - 1.92 * snow_under_wheels + 1.68 * grit_coverage
		var next_speed := move_toward(previous_speed,target,acceleration*Mass.road_response(item.mass_kg)*delta)
		var travel := minf(next_speed * delta, free_space)
		item.speed = travel / delta if delta > 0.0 else previous_speed
		if item.brake_lens:
			var braking := float(item.speed) < previous_speed - .0001 or target == 0.0
			_set_rear_lights(item.brake_lens, braking)
		_roll_wheels(item.wheels, travel)
		if item.get("pedals"): item.pedals.advance(travel)
		item.distance = fposmod(float(item.distance)+travel,item.route.get_baked_length())
		_place_traffic(item)
		var turn := _traffic_turn_intent(item.route, item.distance, 1.0, actor.basis.x, clampf(float(item.cruise) * 2.0, 6.0, 16.0))
		item.turn_signals.advance(turn, delta, calm_mode or steady_player_lights)

# Centre of the channel between the bent fingers and thumb in GrippingHand.obj.
const PALM_GRIP := Vector3(-.024,-.027,0)

func _make_grocery_bag(parent: Node3D) -> Node3D:
	var bag := Node3D.new()
	parent.add_child(bag)
	var paper := Color("#bc8956")
	_make_box("Paper grocery bag",Vector3(.23,.32,.30),Vector3.UP*.16,paper,false,bag)
	for side in [-1,1]:
		for end in [-1,1]:
			_make_box("Loop side",Vector3(.016,.10,.016),Vector3(end*.060,.36,side*.096),paper,false,bag)
		_make_box("Loop grip",Vector3(.136,.017,.016),Vector3(0,.410,side*.096),paper,false,bag)
	var loaf := _make_box("Bread loaf",Vector3(.080,.22,.09),Vector3(-.046,.34,0),Color("#d9a252"),false,bag)
	loaf.rotation.z = .15
	_make_box("Milk carton",Vector3(.087,.13,.081),Vector3(.049,.34,-.034),Color("#e2f1ef"),false,bag)
	return bag

func _attach_pet(pet: Node3D) -> void:
	var owner: Dictionary = walker_data.back()
	var palm: MeshInstance3D = owner.actor.get_meta("arms")[1].get_child(1)
	palm.mesh = preload("res://characters/GrippingHand.obj")
	pet.hand = Node3D.new()
	palm.add_child(pet.hand)
	pet.hand.position = PALM_GRIP
	owner.actor.add_child(pet)
	owner.pet = pet
	pet.advance(0.0)

func _build_pedestrians() -> void:
	greeting.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_apply_reading_size()
	greeting.font_size = 64
	greeting.modulate = Color("#1f3040")
	greeting.outline_size = 0
	greeting.render_priority = 2
	bubble_back.texture = preload("res://characters/speech_bubble.svg")
	bubble_back.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble_back.pixel_size = greeting.pixel_size
	bubble_back.render_priority = 1
	bubble_back.offset.y = -13
	greeting.add_child(bubble_back)
	greeting.visible = false
	add_child(greeting)
	_make_walker("Neighbour with a missing shoe", 16, 6.8, 1, Color("#427cab"), Color("#48455a"))
	shoe_owner = walker_data.pop_back().actor
	add_child(lost_shoe)
	lost_shoe.position = Vector3(33, _foot_height(33, 6.8), 6.8)
	add_child(shoe_trail)
	shoe_trail.hide()
	var sole := SphereMesh.new()
	var print_finish := _material(Color("#a42e42"))
	for i in 13:
		var x := lost_shoe.position.x - 1.1*(13-i)
		var z := lost_shoe.position.z + (.16 if i%2 else -.16)
		for heel in [false,true]:
			var mark := MeshInstance3D.new()
			mark.mesh = sole
			mark.material_override = print_finish
			mark.scale = Vector3(.12,.018,.092) if heel else Vector3(.21,.018,.115)
			mark.position = Vector3(x-(.16 if heel else 0.0),_foot_height(x,z)+.016,z)
			shoe_trail.add_child(mark)
	var shoe_curve := SphereMesh.new()
	shoe_curve.radius = .5
	shoe_curve.height = 1.0
	shoe_curve.radial_segments = 24
	shoe_curve.rings = 12
	for layer in [
		["Rubber sole",Vector3(.24,.066,.47),Vector3(0,.033,0),Color.IVORY,"rubber"],
		["Toe box",Vector3(.224,.13,.38),Vector3(0,.095,-.041),Color.CRIMSON,"denim_fabric_04"],
		["Heel counter",Vector3(.206,.19,.245),Vector3(0,.122,.098),Color.CRIMSON,"denim_fabric_04"],
		["Padded collar",Vector3(.164,.025,.154),Vector3(0,.206,.111),Color("#76263c"),"cotton_jersey"],
		["Shoe opening",Vector3(.118,.018,.109),Vector3(0,.217,.115),Color("#332c36"),"cotton_jersey"]
	]:
		var piece := MeshInstance3D.new()
		piece.name = layer[0]
		piece.mesh = shoe_curve
		piece.scale = layer[1]
		piece.position = layer[2]
		piece.material_override = _material(layer[3], .88, false, layer[4])
		lost_shoe.add_child(piece)
	var tongue := _make_box("Tongue",Vector3(.097,.021,.16),Vector3(0,.167,-.016),Color("#ad2541"),false,lost_shoe)
	tongue.material_override = _material(Color("#ad2541"), .9, false, "denim_fabric_04")
	tongue.rotation.x = -.35
	for row in 3:
		for side: float in [-1,1]:
			var lace := _make_box("Lace",Vector3(.10,.010,.013),Vector3(0,.164+row*.012,-.066+row*.034),Color.IVORY,false,lost_shoe)
			lace.rotation.y = side*.30
	for leg: Node3D in shoe_owner.get_meta("legs"):
		var ankle := leg.get_child(1) as MeshInstance3D
		ankle.mesh = null
		var trainer := lost_shoe.duplicate() as Node3D
		trainer.position = Vector3(0,-.075,-.035)
		trainer.scale = Vector3.ONE * .56
		ankle.add_child(trainer)
		if leg.position.x > 0:
			returned_trainer = trainer
			returned_trainer.hide()
			socked_foot = MeshInstance3D.new()
			socked_foot.mesh = shoe_curve
			socked_foot.scale = Vector3(.111,.098,.215)
			socked_foot.position = Vector3(0,-.026,-.031)
			socked_foot.material_override = _material(Color("#e8d8aa"),.95, false, "cotton_jersey")
			ankle.add_child(socked_foot)
	lost_shoe.hide()
	_make_walker("Cat owner", -18, -6.8, 1, Color("#76984b"), Color("#36485b"))
	cat_owner = walker_data.pop_back().actor
	add_child(lost_cat)
	cat_meow.stream = preload("res://audio/cat_meow.wav")
	cat_meow.volume_db = -8
	cat_meow.unit_size = 10
	cat_meow.max_distance = 65
	lost_cat.add_child(cat_meow)
	lost_cat.position = Vector3(-35, _foot_height(-35,-6.8), -6.8)
	var ginger := Color("#da8348")
	var fur_mesh := SphereMesh.new()
	fur_mesh.radius = .5
	fur_mesh.height = 1
	fur_mesh.radial_segments = 20
	fur_mesh.rings = 10
	var fur_patch := func(label: String, size: Vector3, at: Vector3, color: Color):
		var patch := MeshInstance3D.new()
		patch.name = label
		patch.mesh = fur_mesh
		patch.material_override = _material(color,.93)
		patch.scale = size
		patch.position = at
		lost_cat.add_child(patch)
		return patch
	fur_patch.call("Body",Vector3(.24,.27,.47),Vector3(0,.235,0),ginger)
	fur_patch.call("Head",Vector3(.25,.23,.22),Vector3(0,.395,-.183),ginger)
	for side: float in [-1,1]:
		var ear := CSGPolygon3D.new()
		ear.polygon = PackedVector2Array([Vector2(-.049,0),Vector2(.049,0),Vector2(side*.024,.115)])
		ear.depth = .052
		ear.material = _material(ginger)
		ear.position = Vector3(side*.074,.465,-.153)
		lost_cat.add_child(ear)
		fur_patch.call("Eye",Vector3(.036,.04,.021),Vector3(side*.060,.418,-.276),Color("#263529"))
		fur_patch.call("Muzzle",Vector3(.072,.055,.043),Vector3(side*.029,.366,-.277),Color.IVORY)
		for z: float in [-.13,.13]:
			var hip := Node3D.new()
			lost_cat.add_child(hip)
			hip.position = Vector3(side*.075,.20,z)
			cat_legs.append(hip)
			var leg: MeshInstance3D = fur_patch.call("Leg",Vector3(.077,.17,.090),Vector3(side*.075,.130,z),ginger)
			leg.reparent(hip)
			var sock: MeshInstance3D = fur_patch.call("White sock",Vector3(.081,.112,.10),Vector3(side*.075,.072,z),Color.IVORY)
			sock.reparent(hip)
			var paw: MeshInstance3D = fur_patch.call("White paw",Vector3(.093,.064,.132),Vector3(side*.075,.034,z-.016),Color.IVORY)
			paw.reparent(hip)
	fur_patch.call("Nose",Vector3(.034,.024,.025),Vector3(0,.387,-.299),Color("#ae6f65"))
	var tail: MeshInstance3D = fur_patch.call("Tail",Vector3(.072,.36,.077),Vector3(0,.336,.244),ginger)
	tail.rotation.x = .33
	var tail_tip: MeshInstance3D = fur_patch.call("Tail tip",Vector3(.063,.115,.07),Vector3(0,.478,.292),Color("#9e5531"))
	tail_tip.rotation.x = .33
	_make_walker("Child",12,6.42,1,Color("#568f86"),Color("#404c59"))
	walker_data.back().actor.scale = Vector3.ONE*.72
	_make_walker("Parent",10.9,6.42,1,Color("#876681"),Color("#424850"))
	walker_data.back().speed = walker_data[-2].speed
	var shopper_hand: MeshInstance3D = walker_data.back().actor.get_meta("arms")[1].get_child(1)
	shopper_hand.mesh = preload("res://characters/GrippingHand.obj")
	var shopping_bag := _make_grocery_bag(shopper_hand)
	shopping_bag.rotation.y = PI*.5
	shopping_bag.position = PALM_GRIP - shopping_bag.basis*Vector3(0,.410,-.096)
	_make_walker("Scooter neighbour",-36.0,-7.22,1.0,Color("#c78653"),Color("#424957"))
	var neighbour: Dictionary = walker_data.back()
	var local_scooter := Scooter.new()
	neighbour.actor.add_child(local_scooter)
	_animate_steps(neighbour.actor,0.0,1.0)
	local_scooter.mount(neighbour.actor)
	neighbour.scooter = local_scooter
	neighbour.stretch = Vector2(-43,-8)
	neighbour.speed = 2.9
	_make_walker("JoggingNeighbour", -31.0, -6.32, 1.0, Color("#344e63"), Color("#4c514a"))
	_make_walker("WalkingNeighbour", 31.0, 6.32, -1.0, Color("#9a5836"), Color("#33424a"))
	shepherd = preload("res://characters/shepherd.gd").new()
	_attach_pet(shepherd)

	_make_walker("ParkVisitor", -18.0, 6.42, 1.0, Color("#d1a33f"), Color("#38474a"))
	komodo = preload("res://characters/komodo.gd").new()
	_attach_pet(komodo)
	komodo.hide()
	var ball := SphereMesh.new()
	ball.radius = .17
	ball.height = .34
	dog_ball.mesh = ball
	dog_ball.material_override = _material(Color("#398ee8"))
	add_child(dog_ball)
	dog_ball.position = Vector3(40,_foot_height(40,6.75)+.17,6.75)
	dog_ball.hide()
	add_child(lizard_mat)
	lizard_mat.position = Vector3(30,_foot_height(30,20.4)+.02,20.4)
	_make_box("Picnic mat",Vector3(1.4,.025,.84),Vector3.ZERO,Color("#de9948"),false,lizard_mat)
	for stripe in [-1,1]:
		_make_box("Mat stripe",Vector3(.08,.008,.84),Vector3(stripe*.53,.017,0),Color("#fff1c6"),false,lizard_mat)
	lizard_mat.hide()



	_make_walker("Neighbour with pushchair",-26,-6.7,1,Color("#87633f"),Color("#465662"))
	_equip_walker(preload("res://environment/barnvagn.glb"),.97,Vector2(-43,-16),Vector3(.205,.948,-.32))
	_make_walker("Neighbour with rollator",22,7.0,-1,Color("#567375"),Color("#51495b"))
	_equip_walker(preload("res://environment/rullator.glb"),.61,Vector2(12,40),Vector3(.26,.90,-.36))
	var senior: Node3D=walker_data.back().actor
	senior.get_node("Hair").material_override=_material(Color("#bcbab3"))
	_make_walker("Santa",26,6.65,-1,Color("#b12531"),Color("#89202b"))
	santa = walker_data.back().actor
	walker_data.back().stretch = Vector2(10,42)
	walker_data.back().speed = 1.15
	preload("res://characters/santa_costume.gd").dress(santa, _material(Color("#ae2030"),.94,false,"cotton_jersey"), _material(Color("#fff2df"),.98,false,"cotton_jersey"), _material(Color("#332621")), _material(Color("#edb346")))
	santa.hide()
	_make_walker("CrossingNeighbour",-12,-6.32,1,Color("#bb703d"),Color("#465663"))
	crossing_pedestrian = walker_data.pop_back().actor
	# Cross the boulevard at the marked east-side tram junction.
	_make_walker("Tram crossing jogger",tram.EAST-10.8,street_signals.ZEBRA_OFFSET,1,Color("#589598"),Color("#4b4e59"))
	walker_data.back().stretch = Vector2(tram.EAST-10.8,tram.EAST+10.8)
	walker_data.back().speed = 3.6
	for i in 5:
		var start_x := -510.0 + i*90.0
		var pavement_z := [-41.3,6.7,28.3][i%3] as float
		if start_x >= tram.WEST and start_x < tram.EAST:
			if i%3==0: pavement_z = tram.NORTH+9.8
			if i%3==2: pavement_z = tram.SOUTH-9.8
		var coat: Color = [Color("#874e46"),Color("#547184"),Color("#81733e")][i%3]
		_make_walker("West resident", start_x+27+i*4, pavement_z, 1 if i%2==0 else -1, coat, Color("#404757"))
		walker_data.back().stretch = Vector2(start_x+9,start_x+81)
		walker_data.back().actor.position.y = _foot_height(start_x+27+i*4,pavement_z)

	_build_lost_umbrella()
	_build_birthday_delivery()
	_build_courier_delivery()
	var boutique_x := shops.storefront_x(5)
	_make_walker("Boutique owner",boutique_x,48.55,1,Color("#685284"),Color("#48515c"))
	boutique_owner = walker_data.pop_back().actor
	boutique_owner.rotation.y = 0
	lost_figurine = shops._boutique_toy(Vector3.ZERO,true)
	_build_boule_court()

func _build_courier_delivery() -> void:
	add_child(courier)
	courier.position = Vector3(shops.storefront_x(0)+2.6,0,40.4)
	courier.rotation.y = PI*.5
	courier.add_child(preload("res://environment/cyklist.glb").instantiate())
	add_child(courier_parcel)
	_make_box("Courier parcel",Vector3(.38,.25,.28),Vector3.UP*.125,Color("#ca9862"),false,courier_parcel)
	for x in [-.09,.09]:
		_make_box("Parcel stripe",Vector3(.045,.252,.282),Vector3(x,.125,0),Color("#295870"),false,courier_parcel)

func _place_courier_parcel() -> void:
	if not courier_parcel.is_inside_tree(): return
	var holder: Node3D = self
	var pos := Vector3(shops.storefront_x(4),1.07,47.6)
	if courier_stage == FootQuest.RETURNING:
		holder = walker
		pos = Vector3(0,.98,-.38)
	elif courier_stage == FootQuest.FINISHED:
		holder = courier
		pos = Vector3(0,.72,-.64)
	if courier_parcel.get_parent() != holder: courier_parcel.reparent(holder,false)
	courier_parcel.position = pos

func _update_courier_delivery() -> void:
	if not walker.visible or ferry_passenger or boating or tram_mode != 0: return
	match courier_stage:
		FootQuest.WAITING:
			if walker.position.distance_to(courier.position) > 1.9: return
			courier_stage = FootQuest.SEARCHING
			_say(courier,COURIER_REQUEST,"courier_request")
			phone.receive(COURIER_REQUEST)
		FootQuest.SEARCHING:
			if cake_stage == FootQuest.RETURNING: return
			if shops.inside != 4 or walker.position.distance_to(courier_parcel.position) > 1.9: return
			courier_stage = FootQuest.RETURNING
			phone.receive(COURIER_RETURN)
		FootQuest.RETURNING:
			if walker.position.distance_to(courier.position) > 1.9: return
			courier_stage = FootQuest.FINISHED
		_: return
	_place_courier_parcel()
	_refresh_dispatch()
	_save_preferences()

func _build_birthday_delivery() -> void:
	_make_walker("Birthday host",33,18,1,Color("#418789"),Color("#614955"))
	birthday_host = walker_data.pop_back().actor
	birthday_host.rotation.y = 0
	_animate_steps(birthday_host,0,0)
	var top := Vector3(33,.84,17.4)
	_make_roadside_solid("Birthday table",Vector3(1.4,.08,.75),top,Color("#a1cdb7"),false)
	for x in [-.55,.55]:
		for z in [-.26,.26]:
			_make_box("Table leg",Vector3(.06,.8,.06),top+Vector3(x,-.44,z),Color("#885936"),false)
	add_child(cake_box)
	var card := Color("#e8b7be")
	_make_box("Cake board",Vector3(.47,.018,.47),Vector3.ZERO,card,false,cake_box)
	for side in [-1,1]:
		_make_box("Carton side",Vector3(.012,.16,.47),Vector3(.23*side,.08,0),card,false,cake_box)
		_make_box("Carton end",Vector3(.47,.16,.012),Vector3(0,.08,.23*side),card,false,cake_box)
	cake_box.add_child(cake_lid)
	cake_lid.position = Vector3(0,.16,.235)
	_make_box("Bakery lid",Vector3(.48,.018,.48),Vector3(0,.009,-.235),card.lightened(.18),false,cake_lid)
	_make_box("Ribbon",Vector3(.046,.004,.48),Vector3(0,.020,-.235),Color("#a34264"),false,cake_lid)
	var cake := shops._turned("Birthday cake",Vector3.ZERO,.208,.208,.13,Color("#fff2ce"))
	cake.reparent(cake_box,false)
	cake.position.y = .08
	for i in 7:
		var angle := TAU*i/7
		var berry := shops._turned("Raspberry",Vector3.ZERO,.017,.012,.022,Color("#ac2348"))
		berry.reparent(cake_box,false)
		berry.position = Vector3(.15*cos(angle),.148,.15*sin(angle))

func _place_cake_box() -> void:
	if not cake_box.is_inside_tree(): return
	var holder: Node3D = walker if cake_stage == FootQuest.RETURNING else self
	if cake_box.get_parent() != holder: cake_box.reparent(holder,false)
	match cake_stage:
		FootQuest.WAITING: cake_box.position = Vector3(-14,.05,-8.6)
		FootQuest.RETURNING: cake_box.position = Vector3(0,.98,-.38)
		FootQuest.FINISHED: cake_box.position = Vector3(33,.89,17.4)
	cake_lid.rotation.x = 1.95 if cake_stage == FootQuest.FINISHED else 0.

func _update_birthday_delivery(delta: float) -> void:
	if cake_stage == FootQuest.FINISHED:
		if cake_lid.rotation.x < 1.95:
			cake_lid.rotation.x = move_toward(cake_lid.rotation.x,1.95,delta*1.6)
			var gait: Gait = birthday_host.get_meta("gait")
			gait.reach_with_hand(1,cake_lid.to_global(Vector3(.17,0,-.45)))
			if cake_lid.rotation.x >= 1.95: _animate_steps(birthday_host,0,0)
		return
	if not walker.visible or ferry_passenger or tram_mode != 0: return
	if cake_stage == FootQuest.WAITING and walker.position.distance_to(cake_box.position) < 1.3:
		if courier_stage == FootQuest.RETURNING: return
		cake_stage = FootQuest.RETURNING
		phone.receive(CAKE_ROUTE)
	elif cake_stage == FootQuest.RETURNING and walker.position.distance_to(birthday_host.position) < 1.8:
		cake_stage = FootQuest.FINISHED
	else: return
	_place_cake_box()
	cake_lid.rotation.x = 0
	_refresh_dispatch()
	_save_preferences()

func _place_lost_figurine() -> void:
	if not is_instance_valid(lost_figurine): return
	var holder: Node3D = shops
	var position_in_holder := Vector3(shops.storefront_x(3),.025,40.8)
	if figurine_stage == FootQuest.RETURNING:
		holder = walker.get_meta("arms")[1].get_child(1)
		position_in_holder = PALM_GRIP
	elif figurine_stage == FootQuest.FINISHED:
		position_in_holder = Vector3(shops.storefront_x(5)-.6,1.07,47.6)
	if lost_figurine.get_parent() != holder:
		lost_figurine.reparent(holder,false)
	lost_figurine.position = position_in_holder

func _update_lost_figurine() -> void:
	if not walker.visible or ferry_passenger or tram_mode != 0: return
	if figurine_stage == FootQuest.WAITING and walker.global_position.distance_to(lost_figurine.global_position) < 1.4:
		figurine_stage = FootQuest.RETURNING
		phone.receive(FIGURINE_RETURN)
	elif figurine_stage == FootQuest.RETURNING and shops.inside == 5 and walker.position.distance_to(boutique_owner.position) < 2.4:
		figurine_stage = FootQuest.FINISHED
		_say(boutique_owner,FIGURINE_THANKS,"figurine_returned")
	else: return
	_place_lost_figurine()
	_refresh_dispatch()
	_save_preferences()

func _build_lost_umbrella() -> void:
	_make_walker("Waiting umbrella owner",54,-14,1,Color("#e8ae36"),Color("#454657"))
	umbrella_owner = walker_data.pop_back().actor
	umbrella_owner.position.y = _foot_height(54,-14)
	add_child(umbrella)
	_tube_between(umbrella,Vector3.DOWN*.08,Vector3.UP*1.17,.014,_material(Color("#999da2"),.28))
	_tube_between(umbrella,Vector3.DOWN*.10,Vector3.UP*.06,.024,_material(Color("#6f4532")))
	umbrella.add_child(canopy)
	canopy.position.y = 1.16
	var fabric := _material(Color("#af2848"),.7)
	fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 8:
		var a := Vector3.RIGHT.rotated(Vector3.UP,i*TAU/8)
		var b := Vector3.RIGHT.rotated(Vector3.UP,(i+1)*TAU/8)
		var mesh := SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh.set_material(fabric)
		for vertex: Vector3 in [Vector3.ZERO,a*.45+Vector3.DOWN*.10,b*.45+Vector3.DOWN*.10,
				a*.45+Vector3.DOWN*.10,a*.64+Vector3.DOWN*.28,b*.64+Vector3.DOWN*.28,
				a*.45+Vector3.DOWN*.10,b*.64+Vector3.DOWN*.28,b*.45+Vector3.DOWN*.10]:
			mesh.add_vertex(vertex)
		mesh.generate_normals()
		var panel := MeshInstance3D.new()
		panel.mesh = mesh.commit()
		canopy.add_child(panel)
		_tube_between(canopy,a*.45+Vector3.DOWN*.10,a*.64+Vector3.DOWN*.28,.008,_material(Color("#6c2637")))

func _place_umbrella() -> void:
	if not umbrella.is_inside_tree(): return
	_animate_steps(umbrella_owner,0,0)
	if umbrella_stage == FootQuest.FINISHED:
		var gait: Gait = umbrella_owner.get_meta("gait")
		gait.reach_with_hand(1,umbrella_owner.to_global(Vector3(.24,1.13,-.24)))
	var holder: Node3D = self
	if umbrella_stage == FootQuest.RETURNING:
		holder = walker.get_meta("arms")[1].get_child(1)
	elif umbrella_stage == FootQuest.FINISHED:
		holder = umbrella_owner.get_meta("arms")[1].get_child(1)
	if umbrella.get_parent() != holder:
		umbrella.reparent(holder,false)
	umbrella.basis = Basis.IDENTITY
	umbrella.position = Vector3(54,_foot_height(54,-18)+.10,-18) if holder == self else PALM_GRIP
	var spread := 1.0 if umbrella_stage == FootQuest.FINISHED and weather.intensity.x > .15 else .10
	canopy.scale = Vector3(spread,lerpf(2.8,1.0,spread),spread)

func _update_lost_umbrella(delta: float) -> void:
	if umbrella_stage == FootQuest.FINISHED:
		var spread := move_toward(canopy.scale.x,1.0 if weather.intensity.x > .15 else .10,delta*1.6)
		canopy.scale = Vector3(spread,lerpf(2.8,1.0,spread),spread)
		umbrella.global_basis = Basis.IDENTITY
		return
	if not walker.visible or ferry_passenger or tram_mode != 0: return
	if umbrella_stage == FootQuest.WAITING and walker.position.distance_to(umbrella.position)<1.4:
		umbrella_stage = FootQuest.RETURNING
		phone.receive(UMBRELLA_RETURN)
	elif umbrella_stage == FootQuest.RETURNING and walker.position.distance_to(umbrella_owner.position)<1.8:
		umbrella_stage = FootQuest.FINISHED
		_reward_foot_quest(6)
	else: return
	_place_umbrella()
	canopy.scale = Vector3(.1,2.62,.1)
	_refresh_dispatch()
	_save_preferences()

func _build_boule_court() -> void:
	boule_impact.stream = preload("res://audio/boule_gravel.wav")
	boule_impact.max_distance = 18
	boule_impact.unit_size = 3
	boule_impact.volume_db = -8
	add_child(boule_impact)
	boule_clink.stream = preload("res://audio/boule_steel.wav")
	boule_clink.max_distance = 18
	boule_clink.unit_size = 3
	boule_clink.volume_db = -8
	add_child(boule_clink)
	var wood := _material(Color("#94704c"), .79, false, "wood")
	for slat in 4:
		var slat_x := (slat - 1.5) * .12
		_make_box("Bench seat slat", Vector3(.105, .07, 1.85),
			BOULE_BENCH + Vector3(slat_x, .43, 0), Color.WHITE).material_override = wood
		for end in [-.68, .68]:
			_make_box("Bench seat fastener", Vector3(.019, .007, .019),
				BOULE_BENCH + Vector3(slat_x, .464, end), Color("#676b62"))
	for height in [.68, .85]:
		_make_box("Bench backrest", Vector3(.075, .14, 1.85),
			BOULE_BENCH + Vector3(.23, height, 0), Color.WHITE).material_override = wood
		for end in [-.68, .68]:
			_make_box("Bench backrest fastener", Vector3(.007, .019, .019),
				BOULE_BENCH + Vector3(.193, height, end), Color("#676b62"))
	for end in [-.68, .68]:
		# Preserve the original driving clearance around the open leg frame.
		roadside_solids.append(AABB(BOULE_BENCH + Vector3(-.21, -1.995, end - .035),
			Vector3(.42, 2.39, .07)))
		for leg_x in [-.17, .17]:
			var foot := BOULE_BENCH + Vector3(leg_x * 1.16, 0, end)
			var leg := _make_box("Bench splayed leg", Vector3(.049, .38, .055),
				foot.lerp(BOULE_BENCH + Vector3(leg_x, .38, end), .5), Color("#394944"))
			leg.rotation.z = atan2(leg_x * .16, .38)
			_make_box("Bench foot plate", Vector3(.088, .018, .094),
				foot + Vector3.UP * .009, Color("#394944"))
			for bolt_z in [-.032, .032]:
				_make_box("Bench foot anchor", Vector3(.015, .009, .015),
					foot + Vector3(0, .021, bolt_z), Color("#676b62"))
		_make_box("Seat support crossbar", Vector3(.47, .042, .106),
			BOULE_BENCH + Vector3(0, .380, end), Color("#394944"))
		_make_box("Back support", Vector3(.06, .65, .06),
			BOULE_BENCH + Vector3(.23, .57, end), Color("#394944"))
	var gravel := _make_driving_surface("Boule gravel", Vector3(3.8,.12,14), BOULE_CENTRE-Vector3.UP*.06, Color("#baa781"))
	gravel.material_override = _noise_material(Color("#9f8d72"), Color("#c0ac88"), 118.0, .36)
	var edging_finish := _material(Color("#77644b"), .86, false, "wood")
	var clip_finish := _material(Color("#646963"), .74)
	for side in [-1, 1]:
		_make_box("Court end timber", Vector3(3.86, .10, .10),
			BOULE_CENTRE + Vector3(0, 0, side * 6.95), Color.WHITE).material_override = edging_finish
		for segment in 4:
			_make_box("Court side timber", Vector3(.10, .10, 3.442),
				BOULE_CENTRE + Vector3(side * 1.88, 0, (segment - 1.5) * 3.45),
				Color.WHITE).material_override = edging_finish
		for end in [-1, 1]:
			var corner := BOULE_CENTRE + Vector3(side * 1.88, .051, end * 6.95)
			_make_box("Court corner strap", Vector3(.08, .009, .24),
				corner - Vector3.BACK * end * .08, Color.WHITE).material_override = clip_finish
			_make_box("Court corner strap return", Vector3(.174, .009, .08),
				corner - Vector3.RIGHT * side * .126, Color.WHITE).material_override = clip_finish
			for offset: Vector3 in [Vector3(0, .006, -.153 * end), Vector3(-.161 * side, .006, 0)]:
				_make_box("Court corner fixing", Vector3(.019, .009, .019),
					corner + offset, Color("#94948a"))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .28
	torus.outer_radius = .31
	torus.rings = 64
	torus.ring_segments = 12
	ring.name = "Boule throwing ring"
	ring.mesh = torus
	ring.position = BOULE_CENTRE + Vector3(0, .012, 4)
	ring.material_override = _material(Color("#bc402e"), .83, false, "rubber")
	add_child(ring)
	var joint_finish := _material(Color("#87352a"), .84)
	_tube_between(ring, Vector3(.295, 0, -.036), Vector3(.295, 0, .036), .017, joint_finish)
	for seam_z in [-.026, .026]:
		_tube_between(ring, Vector3(.295, 0, seam_z - .003),
			Vector3(.295, 0, seam_z + .003), .018, joint_finish)
	boule_jack = _boule_ball(.024, _material(Color("#ffb73c"), .72, false, "wood"))
	var boule_shader := Shader.new()
	boule_shader.code = """
	shader_type spatial;
	varying float latitude;
	void vertex() {
		latitude = NORMAL.y;
	}
	void fragment() {
		float row = abs(latitude);
		float distance_to_groove = min(abs(row - .24), abs(row - .34));
		float blur = max(fwidth(row), .003);
		float groove = (1.0 - smoothstep(.008, .014 + blur, distance_to_groove))
			* (1.0 - smoothstep(.03, .16, blur));
		ALBEDO = mix(vec3(.59, .61, .61), vec3(.19, .21, .21), groove);
		METALLIC = .84;
		ROUGHNESS = mix(.26, .54, groove);
	}
	"""
	var boule_steel := ShaderMaterial.new()
	boule_steel.shader = boule_shader
	boule_jack.position = BOULE_CENTRE+Vector3(0,.024,-4)
	var result_mesh := TorusMesh.new()
	result_mesh.inner_radius = .071
	result_mesh.outer_radius = .095
	result_mesh.rings = 24
	result_mesh.ring_segments = 8
	var gold := _material(Color("#ffdc43"))
	for i in 3:
		var jacket: Color = [Color("#656f47"),Color("#45627c"),Color("#965a46")][i]
		_make_walker("Boule player %d" % (i+1), 0, 0, 1, jacket, Color("#4e4942"))
		var player: Node3D = walker_data.pop_back().actor
		player.position = _boule_waiting_spot(i)
		player.rotation.y = 0
		player.get_node("Hair").material_override = _material([Color("#bcbab0"),Color("#817970"),Color("#d3c8ae")][i])
		boule_players.append(player)
		_animate_steps(player,0,0)
		var ball := _boule_ball(.044, boule_steel)
		ball.hide()
		boules.append(ball)
		var marker := MeshInstance3D.new()
		marker.mesh = result_mesh
		marker.material_override = gold
		marker.position.y = -.031
		ball.add_child(marker)
		marker.hide()
		boule_result_rings.append(marker)
		boule_grounded.append(false)
		boule_velocity.append(Vector3.ZERO)

	add_child(thermos)
	var steel := _material(Color("#b8bfba"), .32, false, "brushed")
	steel.metallic = .64
	var enamel := _material(Color("#257559"), .37)
	var gasket := _material(Color("#25332f"), .89)
	_tube_between(thermos, Vector3.UP * .012, Vector3.UP * .244, .052, enamel)
	_tube_between(thermos, Vector3.ZERO, Vector3.UP * .022, .053, steel)
	_tube_between(thermos, Vector3.UP * .231, Vector3.UP * .250, .051, steel)
	_tube_between(thermos, Vector3.UP * .247, Vector3.UP * .258, .050, gasket)
	_tube_between(thermos, Vector3.UP * .255, Vector3.UP * .294, .051, steel)
	_tube_between(thermos, Vector3.UP * .294, Vector3.UP * .30, .047, steel)
	for rib in 16:
		var angle := TAU * rib / 16.0
		var radial := Vector3(cos(angle), 0, sin(angle))
		var groove := _make_box("Thermos cup grip rib", Vector3(.005, .028, .008),
			radial * .050 + Vector3.UP * .274, Color.WHITE, false, thermos)
		groove.rotation.y = -angle
		groove.material_override = steel


func _place_thermos() -> void:
	if not thermos.is_inside_tree(): return
	var holder: Node3D = self
	if thermos_stage == FootQuest.RETURNING:
		holder = walker.get_meta("arms")[0].get_child(1)
	elif thermos_stage == FootQuest.FINISHED:
		holder = boule_players[0].get_meta("arms")[0].get_child(1)
	if thermos.get_parent() != holder:
		thermos.reparent(holder,false)
	thermos.position = BOULE_BENCH+Vector3(.15,0,-1.15) if holder == self else PALM_GRIP-Vector3.UP*.12

func _update_thermos() -> void:
	if not walker.visible or boule_guest_turn or boule_seated or thermos_stage == FootQuest.FINISHED: return
	var near_owner := walker.position.distance_to(boule_players[0].position)<2
	match thermos_stage:
		FootQuest.WAITING:
			if not boule_match_finished or not near_owner: return
			thermos_stage = FootQuest.SEARCHING
			phone.receive(THERMOS_REQUEST)
		FootQuest.SEARCHING:
			if walker.position.distance_to(thermos.global_position)>1.3: return
			thermos_stage = FootQuest.RETURNING
			phone.receive(THERMOS_RETURN)
		FootQuest.RETURNING:
			if not near_owner: return
			thermos_stage = FootQuest.FINISHED
			_reward_foot_quest(7)
	_place_thermos()
	_refresh_dispatch()
	_save_preferences()

func _boule_ball(radius: float, finish: Material) -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = 2*radius
	ball.mesh = mesh
	ball.material_override = finish
	add_child(ball)
	return ball

func _boule_waiting_spot(index: int) -> Vector3:
	return BOULE_CENTRE + Vector3((index-1)*1.15,0,5.85)

func _update_boule(delta: float) -> void:
	if not _near_boule_ring() or mode != "playing":
		boule_join_requested = false
		boule_guest_turn = false
		boule_choices.hide()
	if boule_clock == 0 and boule_collector < 0 and boule_join_requested:
		boule_guest_turn = true
		boule_join_requested = false
		walker.position = BOULE_CENTRE+Vector3.BACK*4
		walker.rotation.y = 0
		walk_basis = Basis.IDENTITY
		walking_velocity = Vector3.ZERO
		boule_throw_length = -1
		boule_aim.value = 0
		boule_choices.show()
		boule_aim.grab_focus()
		_update_entry_button()
	if boule_guest_turn and boule_throw_length < 0:
		return
	boule_clock += delta
	if boule_collector >= 0:
		_collect_boule(delta)
		return
	var player := walker if boule_guest_turn else boule_players[boule_turn]
	var arm: Node3D = player.get_meta("arms")[1]
	var hand: Node3D = arm.get_child(1)
	var ball := boules[boule_turn]
	var target := BOULE_CENTRE + Vector3([-.22,-.19,.12][boule_turn], .044, -4+[.35,.03,-.28][boule_turn])
	if boule_guest_turn:
		target = boule_jack.position + Vector3(boule_aim.value,.020,(1-boule_throw_length)*1.5)
	var weight := smoothstep(0,1.4,boule_clock)*(1-smoothstep(4.5,6, boule_clock))
	var previous := player.position
	if not boule_guest_turn:
		player.position = _boule_waiting_spot(boule_turn).lerp(BOULE_CENTRE+Vector3(0,0,4),weight)
	_animate_steps(player, previous.distance_to(player.position), delta)
	arm.rotation.x = -.68*smoothstep(1.5,2.3,boule_clock)+1.75*smoothstep(2.3,2.66,boule_clock)-1.07*smoothstep(2.9,3.6,boule_clock)
	if boule_clock < 2.66:
		boule_grounded[boule_turn] = false
		boule_velocity[boule_turn] = Vector3.ZERO
		ball.show()
		ball.position = hand.to_global(PALM_GRIP)
		boule_release = ball.position
	else:
		var flight := clampf((boule_clock-2.66)/1.22,0,1)
		var landing := target+Vector3.BACK*.80
		if flight < 1:
			ball.position = boule_release.lerp(landing,flight)+Vector3.UP*6.4*flight*(1-flight)
		elif not boule_grounded[boule_turn]:
			boule_grounded[boule_turn] = true
			ball.position = landing
			boule_velocity[boule_turn] = Vector3.FORWARD * (1.6/.78)
			boule_impact.position = landing
			boule_impact.pitch_scale = [1.0,.95,1.06][boule_turn]
			boule_impact.play()
		if boule_grounded[boule_turn]:
			_roll_boules(minf(delta,boule_clock-3.88))
	var final_throw := boule_turn == boules.size()-1
	if final_throw and boule_clock >= 5 and boule_clock-delta < 5:
		_show_boule_result()
	if boule_clock >= (10.0 if final_throw else 6.5):
		if boule_guest_turn:
			boule_guest_turn = false
			walker.position = BOULE_CENTRE+Vector3(2.4,0,4)
			_update_entry_button()
		for ring in boule_result_rings:
			ring.hide()
		if final_throw:
			boule_collector = 0
			boule_pickup_spot = boules[0].position
		boule_turn = (boule_turn+1)%boule_players.size()
		boule_clock = 0

func _collect_boule(delta: float) -> void:
	var player := boule_players[boule_collector]
	var ball := boules[boule_collector]
	var home := _boule_waiting_spot(boule_collector)
	var stop := Vector3(boule_pickup_spot.x-.24,home.y,boule_pickup_spot.z+.40)
	var returning := boule_clock >= 7
	var previous := player.position
	var fraction := smoothstep(0,6,boule_clock)*(1-smoothstep(8,14,boule_clock))
	player.position = home.lerp(stop,fraction)
	var heading := stop-home
	var yaw := atan2(-heading.x,-heading.z)
	player.rotation.y = (yaw + PI*smoothstep(7.3,8,boule_clock))*(1-smoothstep(14,14.5,boule_clock))
	var crouch := smoothstep(6,6.9,boule_clock)*(1-smoothstep(7,7.7,boule_clock))
	var gait: Gait = player.get_meta("gait")
	gait.advance(previous.distance_to(player.position),delta,false,0,crouch)
	var palm := gait.palms[1]
	if crouch > 0:
		gait.reach_with_hand(1,palm.global_position.lerp(boule_pickup_spot,crouch))
	if returning:
		boule_grounded[boule_collector] = false
		ball.position = palm.to_global(PALM_GRIP)
	if boule_clock >= 14.5:
		player.rotation.y = 0
		ball.position = palm.to_global(PALM_GRIP)
		boule_collector += 1
		if boule_collector < boules.size():
			boule_pickup_spot = boules[boule_collector].position
		else:
			boule_collector = -1
		boule_clock = 0

func _show_boule_result() -> void:
	boule_match_finished = true
	var distances := PackedFloat64Array()
	for ball in boules:
		distances.append(ball.position.distance_squared_to(boule_jack.position))
	var nearest := distances[0]
	for distance in distances:
		nearest = minf(nearest,distance)
	for i in distances.size():
		boule_result_rings[i].visible = distances[i] == nearest

func _roll_boules(duration: float) -> void:
	# Keep travel per step smaller than a ball radius, even on slow frames.
	while duration > 0:
		var step := minf(duration,1.0/120)
		duration -= step
		for i in boules.size():
			if not boule_grounded[i]: continue
			var slowed := boule_velocity[i].move_toward(Vector3.ZERO,2.63*step)
			boules[i].position += (boule_velocity[i]+slowed)*(.5*step)
			boule_velocity[i] = slowed
		for i in boules.size():
			if not boule_grounded[i]: continue
			for j in range(i+1,boules.size()):
				if not boule_grounded[j]: continue
				var offset := boules[j].position-boules[i].position
				var distance := offset.length()
				if distance >= .088: continue
				var normal := offset/distance if distance > .00001 else Vector3.RIGHT
				var correction := normal*(.088-distance)*.5
				boules[i].position -= correction
				boules[j].position += correction
				var approach := (boule_velocity[i]-boule_velocity[j]).dot(normal)
				if approach <= 0: continue
				var impulse := normal*approach*.89
				boule_velocity[i] -= impulse
				boule_velocity[j] += impulse
				if approach > .10:
					boule_clink.position = (boules[i].position+boules[j].position)*.5
					boule_clink.play()

func _equip_walker(scene: PackedScene, pace: float, stretch: Vector2, right_grip: Vector3) -> void:
	var neighbour: Dictionary = walker_data.back()
	var person: Node3D = neighbour.actor
	var aid := scene.instantiate() as Node3D
	person.add_child(aid)
	var wheels: Array[Node3D] = []
	var pieces := aid.find_children("*","MeshInstance3D",true,false)
	for tyre: MeshInstance3D in pieces:
		if not str(tyre.name).begins_with("Tyre"): continue
		var axle := Node3D.new()
		tyre.get_parent().add_child(axle)
		axle.position = tyre.position
		# Each wheel centre sits one radius above the ground in the imported rig.
		axle.set_meta("radius",axle.position.y)
		for piece: MeshInstance3D in pieces:
			if piece == tyre or ((str(piece.name).begins_with("Wheel dish") or str(piece.name).begins_with("Hub")) and piece.global_position.distance_to(axle.global_position)<.06):
				piece.reparent(axle,true)
		var valve_x := signf(axle.position.x)*.039
		_make_box("Valve stem",Vector3(.015,.025,.012),Vector3(valve_x,axle.position.y*.73,0),Color("#393631"),false,axle)
		wheels.append(axle)
	neighbour.wheels = wheels
	neighbour.speed = pace
	neighbour.stretch = stretch
	neighbour.pushing = true
	person.set_meta("aid_right_grip", right_grip)
	if scene.resource_path == "res://environment/rullator.glb":
		person.set_meta("aid_grip_pitch", -atan2(.08,.10))
	for shoulder: Node3D in person.get_meta("arms"):
		var palm := shoulder.get_child(1) as MeshInstance3D
		palm.mesh = preload("res://characters/GrippingHand.obj")

func _advance_crossing(delta: float) -> void:
	crossing_wait = maxf(0,crossing_wait-delta)
	var step := 0.0
	if crossing_wait <= 0.0:
		step = minf(delta*1.25,absf(6.32*crossing_direction-crossing_pedestrian.position.z))*crossing_direction
		var next := crossing_pedestrian.position+Vector3.BACK*step
		var car_offset := ambulance.to_local(next)
		var player_blocks := ambulance.visible and absf(car_offset.x)<player_half_size.x+.4 and absf(car_offset.z)<player_half_size.y+.4
		if player_blocks or _near_parked_vehicle(next,.4) or not street_signals.pedestrian_may_enter(crossing_pedestrian.position,next):
			step = 0.0
		for item in traffic_data:
			var offset: Vector3 = item.actor.to_local(next)
			if absf(offset.z)<float(item.length)+.5 and absf(offset.x)<float(item.width)+.5:
				step = 0.0
				break
		crossing_pedestrian.position.z += step
		if absf(crossing_pedestrian.position.z-6.32*crossing_direction)<.01:
			crossing_direction *= -1
			crossing_wait = 12.0
	crossing_pedestrian.rotation.y = rotate_toward(crossing_pedestrian.rotation.y, PI if crossing_direction>0 else 0.0, delta*4.8)
	crossing_pedestrian.position.y = _foot_height(crossing_pedestrian.position.x, crossing_pedestrian.position.z)
	_animate_steps(crossing_pedestrian, absf(step), delta)

func _animate_steps(person: Node3D, distance: float, delta: float, pushing := false, phase := 0.0) -> void:
	var gait: Gait = person.get_meta("gait") if person.has_meta("gait") else null
	if gait == null:
		gait = Gait.new(person, phase, _foot_height if person == walker else Callable())
		person.set_meta("gait", gait)
	var carried_box: Node3D
	if person == walker:
		if courier_parcel.get_parent() == walker:
			carried_box = courier_parcel
		elif cake_box.get_parent() == walker:
			carried_box = cake_box
		elif mission_index in [1,2] and delivery_parcels.size() >= mission_index and walker.is_ancestor_of(delivery_parcels[mission_index-1]):
			carried_box = delivery_parcels[mission_index-1]
	var left_stance := gait.phase < 0.5
	var tuck := sin(PI * walk_jump_left / WALK_JUMP_TIME) if person == walker else 0.0
	gait.advance(distance / person.scale.y if tuck <= 0 else 0.0, delta, pushing or carried_box != null, tuck)
	if pushing:
		var right_grip: Vector3 = person.get_meta("aid_right_grip")
		for i in 2:
			var grip := Vector3(-right_grip.x if i == 0 else right_grip.x, right_grip.y, right_grip.z)
			gait.reach_with_hand(i, person.to_global(grip))
			if person.has_meta("aid_grip_pitch"):
				gait.palms[i].global_basis = person.global_basis * Basis(Vector3.RIGHT,float(person.get_meta("aid_grip_pitch"))) * gait.palm_rest[i].basis
	if person == walker:
		if left_stance != (gait.phase < 0.5) and not is_zero_approx(distance):
			var shoe := gait.shoes[0 if gait.phase < .5 else 1]
			var snowy := _snow_underfoot(shoe.global_position)
			if snowy:
				_stamp_snow_step(shoe, gait.phase < .5)
			footstep.stream = SNOW_STEP if snowy else DRY_STEP
			var impact := smoothstep(Gait.WALK_SPEED, Gait.RUN_SPEED, absf(distance) / maxf(delta, .00001))
			footstep.volume_db = lerpf(-13.0, -9.0, impact)
			footstep.pitch_scale = (0.94 if left_stance else 1.06) * lerpf(1.0, 0.94, impact)
			footstep.play()
		if carried_box:
			for i in 2:
				gait.reach_with_hand(i, carried_box.to_global(Vector3((-1 if i == 0 else 1)*(.19 if carried_box == courier_parcel else .24),.09,0)))

func _snow_underfoot(point: Vector3) -> bool:
	if weather.snow < .12 or walk_jump_left > 0 or shops.customer_is_indoors() or scooter.visible or ferry_passenger or tram_mode != 0:
		return false
	return not ground_work.cleared_at(point) and is_nan(_pier_height(point.x, point.z)) and is_nan(tram.platform_height(point))

func _stamp_snow_step(shoe: Node3D, left: bool) -> void:
	var point := shoe.global_position
	point.y = _surface_height(point.x, point.z) + .012
	var basis := Basis(Vector3.UP, walker.global_rotation.y)
	if minf(absf(point.z + 48.0), absf(point.z)) <= 5.8 and point.x > HIGH_BRIDGE_X[0] and point.x < HIGH_BRIDGE_X[3]:
		var slope := (_bridge_rise(point.x + .05, point.z) - _bridge_rise(point.x - .05, point.z)) / .1
		basis = Basis(Vector3.BACK, atan(slope)) * basis
	if not left:
		basis.x = -basis.x
	sole_marks.set_instance_transform(sole_cursor, Transform3D(basis.scaled(Vector3.ONE * walker.scale.y), point))
	sole_cursor = (sole_cursor + 1) % sole_marks.instance_count
	sole_marks.visible_instance_count = mini(sole_marks.visible_instance_count + 1, sole_marks.instance_count)

const AvatarDetails = preload("res://characters/avatar_details.gd")

func _make_walker(label: String, start_x: float, lane_z: float, direction: float, shirt: Color, trousers: Color) -> void:
	var person := Node3D.new()
	person.name = label
	person.position = Vector3(start_x, 0.04, lane_z)
	person.rotation.y = -direction * PI * 0.5
	add_child(person)
	var torso := MeshInstance3D.new()
	torso.mesh = preload("res://characters/Jacket.obj")
	torso.position = Vector3(0, 1.13, 0)
	torso.material_override = _material(shirt, 0.92, false, "cotton_jersey")
	torso.name="Jacket"
	person.add_child(torso)
	torso.add_child(preload("res://characters/JacketTrim.glb").instantiate())
	# Portrait meshes share a local origin at the centre of the face.
	var head_origin := Vector3(0, 1.635, -.003)
	var is_avatar := label in ["Player on foot", "Helmsperson", "BMW driver"]
	if is_avatar:
		AvatarDetails.add_jacket_details(torso)
	var complexion: Array[Color] = [Color("#c58e6d"), Color("#a87355"), Color("#d8a888"), Color("#885f4b")]
	var hair_colours: Array[Color] = [Color("#48362e"), Color("#342b29"), Color("#876c4e"), Color("#644536")]
	var variant := 0 if is_avatar else posmod(label.hash(), complexion.size())
	var skin := _material(complexion[variant], .86, false, "skin")
	if is_avatar:
		skin.uv2_scale = Vector3.ONE * 12.0
	var head := MeshInstance3D.new()
	head.mesh = preload("res://characters/Face.obj")
	head.name = "Face"
	head.position = head_origin
	head.material_override = skin
	person.add_child(head)
	var features := preload("res://characters/Portrait.glb").instantiate() as Node3D
	features.position = head_origin
	person.add_child(features)
	if is_avatar:
		features.name = "AxelPortrait"
		var alma_features := preload("res://characters/AlmaPortrait.glb").instantiate() as Node3D
		alma_features.name = "AlmaPortrait"
		alma_features.position = head_origin
		alma_features.hide()
		person.add_child(alma_features)
	wardrobe.add_person(torso, shirt)
	var hair := MeshInstance3D.new()
	hair.name = "Hair"
	hair.mesh = preload("res://characters/Bob.obj") if variant == 1 else preload("res://characters/Hair.obj")
	hair.position = head_origin
	hair.material_override = _material(hair_colours[variant], .85)
	person.add_child(hair)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = .17
	head_mesh.height = .34
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		ear.mesh = head_mesh
		ear.scale = Vector3(.076, .165, .099)
		ear.rotation.x = -.15
		ear.position = head_origin + Vector3(side * .103, -.007, .010)
		ear.material_override = skin
		person.add_child(ear)
		if is_avatar:
			AvatarDetails.add_ear_details(ear, side, complexion[variant])
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = .049
	neck_mesh.bottom_radius = .065
	neck_mesh.height = .113
	neck.mesh = neck_mesh
	neck.position = head_origin + Vector3(0, -.146, .014)
	neck.material_override = skin
	person.add_child(neck)
	# The portrait includes neutral lips. This anchor locates the animated smile.
	var lip := MeshInstance3D.new()
	lip.mesh = head_mesh
	lip.position = head_origin + Vector3(0, -.065, -.115)
	lip.material_override = _material(Color("#995f51"))
	lip.hide()
	person.add_child(lip)
	person.set_meta("lip", lip)
	var hips := MeshInstance3D.new()
	hips.name = "TrouserSeat"
	var seat_mesh := SphereMesh.new()
	seat_mesh.radius = .5
	seat_mesh.height = 1.0
	hips.mesh = seat_mesh
	hips.scale = Vector3(.355,.244,.232)
	hips.position = Vector3(0,.762,.009)
	hips.material_override = _material(trousers,.94, false, "denim_fabric_04")
	person.add_child(hips)
	for side in [-1.0, 1.0]:
		var leg_pivot := Node3D.new()
		leg_pivot.position = Vector3(side * 0.115, 0.77, 0)
		person.add_child(leg_pivot)
		var leg := MeshInstance3D.new()
		leg.mesh = preload("res://characters/Trouser.obj")
		leg.position.y = -0.36
		leg.material_override = _material(trousers, 0.94, false, "denim_fabric_04")
		leg_pivot.add_child(leg)
		var shoe := MeshInstance3D.new()
		shoe.mesh = preload("res://characters/Trainer.obj")
		shoe.position = Vector3(0,-.695,-.025)
		for surface in shoe.mesh.get_surface_count():
			if shoe.mesh.surface_get_name(surface) == "Canvas":
				shoe.set_surface_override_material(surface, _material(Color("#514b49"), .92, false, "denim_fabric_04"))
			else:
				shoe.set_surface_override_material(surface, _material(Color("#353332"), .84, false, "rubber"))
		leg_pivot.add_child(shoe)
		if is_avatar:
			AvatarDetails.add_trainer_details(shoe, Color("#879aa1"))
		var arm_pivot := Node3D.new()
		arm_pivot.position = Vector3(side * (.22 if label == "BMW driver" else .188), 1.38, 0)
		person.add_child(arm_pivot)
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.075
		arm_mesh.height = 0.65
		arm.mesh = arm_mesh if label == "BMW driver" else preload("res://characters/Sleeve.obj")
		arm.position.y = -.29 if label == "BMW driver" else -.296
		arm.material_override = _material(shirt, 0.9, false, "cotton_jersey")
		arm_pivot.add_child(arm)
		if label != "BMW driver":
			var palm := MeshInstance3D.new()
			palm.mesh = preload("res://characters/RelaxedHand.obj")
			palm.scale.x = side
			palm.position = Vector3(0,-.688,-.025)
			palm.material_override = head.material_override
			arm_pivot.add_child(palm)
		if not person.has_meta("legs"): person.set_meta("legs", [])
		if not person.has_meta("arms"): person.set_meta("arms", [])
		person.get_meta("legs").append(leg_pivot)
		person.get_meta("arms").append(arm_pivot)
	walker_data.append({"actor": person, "direction": direction, "speed": 1.15 + randf() * 0.45, "phase": randf() * TAU})

func _apply_reading_size() -> void:
	driving_hints.add_theme_font_size_override("font_size", 22 if large_text else 16)
	if is_instance_valid(tyre_service_button):
		tyre_service_button.add_theme_font_size_override("font_size", 22 if large_text else 16)
	shops.set_large_text(large_text)
	phone.set_large_text(large_text)
	greeting.pixel_size = .0042 if large_text else .003
	bubble_back.pixel_size = greeting.pixel_size

func _show_speech_bubble(speaker: Node3D, phrase: String) -> void:
	if greeting.get_parent() != speaker:
		greeting.reparent(speaker, false)
	greeting.position = Vector3.UP * (.97 if speaker == lost_cat else 2.48)
	var lines := PackedStringArray([""])
	var font := greeting.font if greeting.font else ThemeDB.fallback_font
	var max_line_width := 12.0 * greeting.font_size
	for word in phrase.split(" ", false):
		var candidate := (lines[-1] + " " + word).strip_edges()
		var candidate_width := font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, greeting.font_size).x
		if candidate_width > max_line_width and not lines[-1].is_empty():
			lines.append(word)
		else:
			lines[-1] = candidate
	greeting.text = "\n".join(lines)
	var width := 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, greeting.font_size).x)
	bubble_back.scale.x = (width + 88.0) / bubble_back.texture.get_width()
	bubble_back.scale.y = 1.0 + (lines.size() - 1) * .9
	greeting.position.y += (lines.size() - 1) * .14
	bubble_time = maxf(3.5, phrase.length() * .1) * (2.0 if extra_reading_time else 1.0)
	greeting.show()

func _say(speaker: Node3D, phrase: String, clip: String) -> void:
	speech_key = phrase
	speech_clip = clip
	speech_locale = TranslationServer.get_locale()
	_show_speech_bubble(speaker, tr(phrase))
	greeting_voice.stop()
	greeting_voice.stream = null if clip.is_empty() else preload("res://audio/voices/santa.wav") if clip == "santa" else L10n.media("res://audio/voices/%s_" + clip + ".wav", TranslationServer.get_locale())
	if greeting_voice.stream != null:
		bubble_time = maxf(bubble_time, greeting_voice.stream.get_length() + (3.5 if extra_reading_time else .4))
		if not AudioServer.is_bus_mute(0) and not phone.job_voice.playing:
			greeting_voice.play()
			greeting_voice.stream_paused = paused
	greeting_timer = maxf(7.5, bubble_time)

func _hold_lost_shoe() -> void:
	var hand: Node3D = walker.get_meta("arms")[1].get_child(1)
	lost_shoe.reparent(hand, false)
	lost_shoe.scale = Vector3.ONE * .56
	lost_shoe.rotation.x = -.85
	lost_shoe.position = Vector3(.035,-.105,-.08)

func _update_shoe_quest(delta: float) -> void:
	if not walker.visible or shops.inside >= 0 or shoe_quest == FootQuest.FINISHED:
		return
	var distance := walker.position.distance_to(shoe_owner.position)
	match shoe_quest:
		FootQuest.WAITING:
			if distance > 8 or absf(walker.position.z - 6.8) > 1.4:
				return
			if distance > 2.1:
				var previous_x := shoe_owner.position.x
				var target_x := clampf(walker.position.x, 8.0, 24.0)
				shoe_owner.position.x = move_toward(previous_x, target_x, 1.5 * delta)
				var step := shoe_owner.position.x - previous_x
				if not is_zero_approx(step):
					shoe_owner.rotation.y = -signf(step) * PI * .5
					shoe_owner.position.y = _foot_height(shoe_owner.position.x, shoe_owner.position.z)
			else:
				shoe_quest = FootQuest.SEARCHING
				lost_shoe.show()
				_say(shoe_owner, "Can you find my red shoe? I lost it farther along the pavement.", "lost_shoe")
				_refresh_dispatch()
				phone.receive("Find the red shoe on the pavement.")
		FootQuest.SEARCHING:
			if walker.position.distance_to(lost_shoe.position) < 1.6:
				shoe_quest = FootQuest.RETURNING
				_hold_lost_shoe()
				star_chime.play()
				_refresh_dispatch()
				phone.receive("Bring the red shoe back to the neighbour.")
				message = "Bring the red shoe back to the neighbour."
				message_timer = 5
				_refresh_status()
		FootQuest.RETURNING:
			if distance < 2.3:
				shoe_quest = FootQuest.FINISHED
				lost_shoe.hide()
				socked_foot.hide()
				returned_trainer.show()
				_say(shoe_owner, "My shoe! Now I won’t have to hop home. Thank you!", "shoe_returned")
				_reward_foot_quest(1)

const CAT_PAVEMENT := Vector2(-36, -8)

func _update_cat_quest(delta: float) -> void:
	if not walker.visible or shops.inside >= 0 or cat_quest == FootQuest.FINISHED:
		return
	var distance := walker.position.distance_to(cat_owner.position)
	match cat_quest:
		FootQuest.WAITING:
			if distance > 8 or absf(walker.position.z + 6.8) > 1.4:
				return
			if distance > 2.1:
				cat_owner.rotation.y = -signf(walker.position.x - cat_owner.position.x) * PI * .5
				cat_owner.position.x = move_toward(cat_owner.position.x, clampf(walker.position.x, CAT_PAVEMENT.x, CAT_PAVEMENT.y), delta * 1.5)
			else:
				cat_quest = FootQuest.SEARCHING
				_say(cat_owner, "Can you find my cat? Look for white paws along this pavement.", "lost_cat")
				_refresh_dispatch()
				phone.receive("Find the cat with white paws.")
		FootQuest.SEARCHING:
			if walker.position.distance_to(lost_cat.position) < 1.6:
				cat_quest = FootQuest.RETURNING
				cat_meow.play()
				_say(lost_cat, "Meow!", "")
				message = "Walk back to the neighbour with the cat."
				message_timer = 5
				_refresh_dispatch()
				phone.receive(message)
				_refresh_status()
		FootQuest.RETURNING:
			# Socks waits on her pavement if the player takes a detour.
			var previous_x := lost_cat.position.x
			var target := clampf(walker.position.x, CAT_PAVEMENT.x, CAT_PAVEMENT.y)
			if absf(walker.position.z - lost_cat.position.z) <= 1.4 and absf(lost_cat.position.x - target) > .75:
				lost_cat.rotation.y = -signf(target - lost_cat.position.x) * PI * .5
				lost_cat.position.x = move_toward(lost_cat.position.x, target, 3.5 * delta)
				lost_cat.position.y = _foot_height(lost_cat.position.x, lost_cat.position.z)
			var travel := absf(lost_cat.position.x - previous_x)
			cat_stride = fmod(cat_stride + travel * TAU / .86, TAU)
			var reunited := distance < 2.3 and lost_cat.position.distance_to(cat_owner.position) < 2.7
			for i in cat_legs.size():
				var diagonal := 1.0 if i in [0,3] else -1.0
				var swing := diagonal * sin(cat_stride) * .42 if travel > 0 else 0.0
				cat_legs[i].rotation.x = 0.0 if reunited else move_toward(cat_legs[i].rotation.x, swing, delta * 12)
			if reunited:
				cat_quest = FootQuest.FINISHED
				_say(cat_owner, "There you are, Socks! Thank you for bringing her home.", "cat_returned")
				_reward_foot_quest(3)

func _reward_foot_quest(cell: int) -> void:
	_show_mission_reward("foot",cell,POINTS_PER_FOOT_QUEST,10)
	wallet += 10
	foot_quest_points += POINTS_PER_FOOT_QUEST
	phone.receive("Thank you for helping! You earned 10 points and 10 coins.")
	_save_preferences()
	_refresh_ui()

func _greet_nearby_player(person: Node3D) -> void:
	var nearby := person.is_visible_in_tree() and walker.visible and walker.position.distance_to(person.position)<2.9
	if nearby and not person.get_meta("greeted",false) and greeting_timer==0:
		var index := greeting_number % 3
		var clip: String = ["hello", "how_are_you", "hi_there"][index]
		var phrase: String = ["Hello!", "How are you?", "Hi there!"][index]
		if person.name == "Marina attendant" and jacket_palette >= 0:
			clip = "ducks"
			phrase = "The ducks voted. They love your jacket!"
		greeting_number += 1
		_say(person, phrase, clip)
		person.set_meta("greeted", true)
	if walker.position.distance_to(person.position)>8:
		person.set_meta("greeted", false)

func _update_santa_encounters() -> void:
	var people := [walker, shoe_owner, cat_owner, crossing_pedestrian, square_neighbour, waiting_medic, marina_recipient, passenger, arriving_passenger] + bus_companions + clinic_fire_team
	for entry in walker_data:
		if entry.actor != santa: people.append(entry.actor)
	var observer := walker.position if walker.visible else camera.global_position
	if observer.distance_to(santa.position) > 24 or shops.inside >= 0:
		santa_encounters.clear()
		return
	var greeted := false
	for person: Node3D in people:
		if not is_instance_valid(person): continue
		var gap := santa.global_position.distance_to(person.global_position)
		if not person.is_visible_in_tree() or gap > 5:
			santa_encounters.erase(person)
		elif gap < 3 and not santa_encounters.has(person) and bubble_time <= 0:
			santa_encounters[person] = true
			greeted = true
	if greeted:
		_say(santa, "Ho ho ho", "santa")

func _update_small_talk(delta: float) -> void:
	chat_wait = maxf(chat_wait-delta,0.0)
	var observer := walker.global_position if walker.visible else camera.global_position
	if not chat_pair.is_empty():
		var speaker := chat_pair[1 if chat_reply else 0]
		if greeting.get_parent() != speaker or observer.distance_to(speaker.position) > 24.0:
			chat_pair.clear()
			chat_wait = 15.0
		elif bubble_time <= 0.0:
			if chat_reply:
				chat_pair.clear()
				chat_wait = 24.0
			else:
				chat_reply = true
				_say(chat_pair[1],SMALL_TALK[chat_topic][2],SMALL_TALK[chat_topic][3])
		return
	if chat_wait > 0 or greeting_timer > 0 or shops.inside >= 0: return
	chat_wait = .4
	for i in walker_data.size():
		var first: Dictionary = walker_data[i]
		var a: Node3D = first.actor
		if a == santa or first.has("scooter") or observer.distance_to(a.position) > 16.0: continue
		for j in range(i+1,walker_data.size()):
			var second: Dictionary = walker_data[j]
			var b: Node3D = second.actor
			var gap := b.position.x-a.position.x
			if b == santa or second.has("scooter") or first.direction == second.direction or gap*float(first.direction) <= .85: continue
			if a.position.distance_to(b.position) > 2.3 or absf(a.position.z-b.position.z) > 1.1: continue
			chat_pair.assign([a,b])
			chat_reply = false
			var topics := [1,2]
			if weather.intensity.x > .15: topics.append(0)
			if a.name == "WalkingNeighbour" or b.name == "WalkingNeighbour": topics.append(3)
			topics.erase(chat_topic)
			chat_topic = topics.pick_random()
			_say(a, SMALL_TALK[chat_topic][0], SMALL_TALK[chat_topic][1])
			return

func _update_pet_jobs() -> void:
	if not walker.visible or shops.inside >= 0: return
	for i in 2:
		var pet := shepherd if i == 0 else komodo
		if not pet.is_visible_in_tree() or pet_stages[i] == FootQuest.FINISHED: continue
		var near_owner := walker.global_position.distance_to(pet.get_parent_node_3d().global_position) < 2.2
		match pet_stages[i]:
			FootQuest.WAITING:
				if not near_owner: continue
				pet_stages[i] = FootQuest.SEARCHING
				dog_ball.visible = pet_stages[0] == FootQuest.SEARCHING
				phone.receive(PET_REQUESTS[i])
			FootQuest.SEARCHING:
				var target := dog_ball.position if i == 0 else lizard_mat.position
				if walker.position.distance_to(target) > 1.7: continue
				if i == 0:
					dog_ball.hide()
					pet_stages[i] = FootQuest.RETURNING
					phone.receive("Bring the ball back to the dog.")
				else:
					lizard_mat.show()
					pet_stages[i] = FootQuest.FINISHED
					_reward_foot_quest(5)
			FootQuest.RETURNING:
				if not near_owner: continue
				pet_stages[i] = FootQuest.FINISHED
				_reward_foot_quest(4)
		_refresh_dispatch()

func _update_search_hints() -> void:
	var searching := mode == "playing" and walker.visible and shops.inside < 0 and not paused
	cat_hint.visible = searching and cat_quest == FootQuest.SEARCHING
	shoe_hint.visible = searching and shoe_quest == FootQuest.SEARCHING
	if not shoe_hint.visible:
		shoe_hint.set_pressed_no_signal(false)
	shoe_trail.visible = shoe_hint.visible and shoe_hint.button_pressed

func _update_pedestrians(delta: float) -> void:
	_update_boule(delta)
	_advance_crossing(delta)
	greeting_timer = maxf(0,greeting_timer-delta)
	bubble_time = maxf(0, bubble_time - delta)
	greeting.visible = bubble_time > 0
	if greeting.visible:
		var view := get_viewport().get_camera_3d()
		if view:
			# Keep distant speech readable while preserving its size up close.
			var depth := -view.to_local(greeting.global_position).z
			var viewport_height := get_viewport().get_visible_rect().size.y
			var metres_per_pixel := 2.0 * maxf(depth, 0.0) * tan(deg_to_rad(view.fov * .5)) / maxf(viewport_height, 1.0)
			var target_pixels := 25.0 if large_text else 18.0
			var natural_height := greeting.font_size * greeting.pixel_size * greeting.get_parent_node_3d().global_basis.y.length()
			greeting.scale = Vector3.ONE * maxf(1.0, target_pixels * metres_per_pixel / natural_height)
	var shoe_owner_x := shoe_owner.position.x
	var cat_owner_x := cat_owner.position.x
	_update_shoe_quest(delta)
	_update_thermos()
	_update_lost_umbrella(delta)
	_update_lost_figurine()
	_update_courier_delivery()
	_update_birthday_delivery(delta)
	_update_cat_quest(delta)
	_update_search_hints()
	_update_pet_jobs()
	_animate_steps(shoe_owner, absf(shoe_owner.position.x - shoe_owner_x), delta)
	_animate_steps(cat_owner, absf(cat_owner.position.x - cat_owner_x), delta)
	for person: Node3D in [square_neighbour, waiting_medic, marina_recipient, passenger, arriving_passenger] + bus_companions + clinic_fire_team:
		if is_instance_valid(person):
			_greet_nearby_player(person)
	passenger_wave_time = fmod(passenger_wave_time + delta, TAU / 5.2)
	for person: Node3D in [square_neighbour, passenger]:
		if person.visible:
			_animate_steps(person, 0, delta)
			person.get_meta("gait").wave(passenger_wave_time, person == passenger or mission_index == 0, delta)
	santa.visible = weather.season == 4 and weather.snow > .02
	if santa.visible:
		_update_santa_encounters()
	else:
		santa_encounters.clear()
		if greeting.get_parent() == santa and greeting.visible:
			greeting_voice.stop()
			greeting.hide()
			bubble_time = 0
	_update_small_talk(delta)
	for item in walker_data:
		var person: Node3D = item["actor"]
		if person == santa:
			if not santa.visible: continue
		else:
			_greet_nearby_player(person)
		if person in chat_pair:
			var other := chat_pair[1] if person == chat_pair[0] else chat_pair[0]
			var relative := other.position-person.position
			person.rotation.y = rotate_toward(person.rotation.y,atan2(-relative.x,-relative.z),delta*3.0)
			_animate_steps(person,0,delta,item.get("pushing",false))
			if item.has("pet") and item.pet.visible: item.pet.advance(0)
			continue
		var direction: float = item["direction"]
		var heading := -direction * PI * .5
		var previous_heading := person.rotation.y
		person.rotation.y = rotate_toward(person.rotation.y, heading, delta * 4.8)
		var alignment := maxf(0.0, cos(person.rotation.y - heading))
		var next := person.position
		next.x += direction * float(item.speed) * delta * alignment
		var stretch: Vector2 = item.get("stretch", Vector2(-44,44))
		if next.x < stretch.x or next.x > stretch.y:
			next.x = clampf(next.x,stretch.x,stretch.y)
			item.direction = -direction
		var local := ambulance.to_local(next)
		var blocked := ambulance.visible and absf(local.x) < player_half_size.x+.4 and local.z > -front_reach-.4 and local.z < rear_reach+.4
		blocked = blocked or not street_signals.pedestrian_may_enter(person.position,next) or _near_parked_vehicle(next,.4)
		if item.get("pushing",false):
			var front := next-person.basis.z*.88
			var relative := ambulance.to_local(front)
			blocked = blocked or (ambulance.visible and absf(relative.x)<player_half_size.x+.36 and relative.z > -front_reach-.4 and relative.z < rear_reach+.4)
			blocked = blocked or _near_parked_vehicle(front,.38)
		var distance := 0.0
		if not blocked:
			distance = minf(absf(next.x-person.position.x), float(item.speed)*delta)
			next.y = _foot_height(next.x,next.z)
			person.position = next
		if item.has("scooter"):
			var turn := -angle_difference(previous_heading, person.rotation.y) / maxf(delta, .00001)
			item.scooter.turn_signals.advance(turn, delta, calm_mode or steady_player_lights)
			item.scooter.roll(distance,person.scale.y)
			person.position.y = _foot_height(person.position.x,person.position.z) + Scooter.DECK_HEIGHT*person.scale.y
			continue
		if distance > 0 and item.has("wheels"):
			for axle: Node3D in item.wheels:
				axle.rotate_x(-distance / float(axle.get_meta("radius")))
		_animate_steps(person, distance, delta, item.get("pushing",false), float(item.phase)/TAU)
		if item.has("pet") and item.pet.visible: item.pet.advance(distance)

func _rig_wheels(model: Node3D) -> Array[Node3D]:
	var pivots: Array[Node3D] = []
	for axle: Node3D in model.find_children("Wheel_*","Node3D",true,false):
		if axle.find_child("Rounded tire casing*",true,false):
			axle.set_meta("radius",.85)
			pivots.append(axle)
	if not pivots.is_empty(): return pivots
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
		for prefix in ["Mower tread", "Bicycle spoke", "Wheel hub", "Five double spokes", "Fälghål", "Wheel bolt", "Rear axle alloy", "Sidewall ring", "Alloy wheel", "Front axle hub cover", "Center cap", "Aluminiumfälg", "Diamond cut rim", "Anthracite wheel barrel", "Brake disc", "Red brake caliper", "Centre cap", "Blue hub enamel", "Pressed steel wheel", "Wheel centre dish", "Raised hub cap", "Wheel lug nut"]:
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
			if original.resource_name.begins_with("Emergency red lens"):
				matches = part.name.begins_with("Ruby tail lens") or part.name.begins_with("Rear lamp") or part.name.begins_with("Tail lamp")
			if reversing:
				matches = original.resource_name.begins_with("Reverse lamp") or part.name.begins_with("Reversing lens") or (part.name.begins_with("Kombinationslykta") and original.resource_name.begins_with("Glass reflection"))
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
	if wiper_pivots.is_empty() and shopper_wiper_parts.is_empty(): return
	var precipitation := maxf(weather.intensity.x,weather.intensity.y)
	if precipitation < .06 and is_zero_approx(wiper_phase): return
	var next_phase := wiper_phase + delta*lerpf(2.0,5.4,precipitation)
	wiper_phase = 0.0 if precipitation < .06 and next_phase >= TAU else fmod(next_phase,TAU)
	var sweep := .64*(1.0-cos(wiper_phase))
	for pivot in wiper_pivots:
		var axis: Vector3 = pivot.get_meta("sweep_axis")
		pivot.basis = Basis(axis,sweep)

	# Follow the Shopper's curved acrylic in the opening shell's local space.
	if not shopper_wiper_parts.is_empty():
		var angle := -.46*(1.0-cos(wiper_phase))
		for i in shopper_wiper_parts.size():
			var a: Vector2 = SHOPPER_WIPER_SEGMENTS[i][0]
			var b: Vector2 = SHOPPER_WIPER_SEGMENTS[i][1]
			var part := shopper_wiper_parts[i]
			var rest: Transform3D = part.get_meta("parked_transform")
			var rest_start := _shopper_screen_point(a,0)
			var rest_end := _shopper_screen_point(b,0)
			var original := rest_end-rest_start
			var start := _shopper_screen_point(a,angle)
			var end := _shopper_screen_point(b,angle)
			var axis := end-start
			part.basis = Basis(Quaternion(original.normalized(),axis.normalized())) * rest.basis
			part.basis.y *= axis.length()/original.length()
			part.position = rest.origin + (start+end-rest_start-rest_end)*.5

func _shopper_screen_point(uv: Vector2, angle: float) -> Vector3:
	# Rotate in metres on the sloping pane, then project onto build_shopper.py's surface.
	var spindle := Vector2(-.58,1)
	var dimensions := Vector2(.405,.687)
	var projected := spindle + ((uv-spindle)*dimensions).rotated(angle)/dimensions
	var u := projected.x
	var t := projected.y
	return Vector3(u*(.418-.026*t), .916+.603*t-.018*u*u, .448-.33*t-.09*u*u)

func _update_bus_ceiling_lights(night: float) -> void:
	if not bus_ceiling_diffuser:
		return
	var glow := smoothstep(.05,.75,night)
	bus_ceiling_diffuser.emission_energy_multiplier = glow*1.55
	for lamp in bus_ceiling_lights:
		lamp.visible = glow > .001
		lamp.light_energy = glow*1.1
	if bus_dashboard_backlight:
		bus_dashboard_backlight.emission_energy_multiplier = glow * .42

func _add_bus_destination_boards(model: Node3D) -> Array[Label3D]:
	var bus_board := Label3D.new()
	bus_board.outline_size = 0
	bus_board.modulate=Color("#ffbb47")
	var fascia := model.find_child("Front destination fascia", true, false) as MeshInstance3D
	fascia.scale.x *= 1.075
	fascia.scale.y *= 1.19
	var imported_board := model.find_child("Destination board", true, false) as MeshInstance3D
	imported_board.hide()
	var front_panel := _make_box("Front destination mask", Vector3(1.96,.31,.014),
		Vector3(0,2.68,5.262), Color("#0e1517"), false, model)
	bus_board.position = Vector3(0,0,.010)
	front_panel.add_child(bus_board)
	var rear_panel := _make_box("Rear destination panel",Vector3(1.88,.34,.08),Vector3(0,2.68,-5.22),Color("#182126"),false,model)
	var rear_bus_board := bus_board.duplicate() as Label3D
	rear_bus_board.name = "RearDestination"
	rear_bus_board.position = Vector3(0,0,-.046)
	rear_bus_board.rotation.y = PI
	rear_panel.add_child(rear_bus_board)
	var side_panel := _make_box("Door-side destination panel",Vector3(1.65,.30,.07),Vector3(-1.175,2.72,2.77),Color("#182126"),false,model)
	side_panel.rotation.y = -PI*.5
	var side_bus_board := bus_board.duplicate() as Label3D
	side_bus_board.name = "SideDestination"
	side_bus_board.position = Vector3(0,0,.041)
	side_panel.add_child(side_bus_board)
	bus_board.text = BUS_DESTINATION
	var pixels := ThemeDB.fallback_font.get_string_size(BUS_DESTINATION,HORIZONTAL_ALIGNMENT_LEFT,-1,bus_board.font_size)
	bus_board.pixel_size = minf(1.62/pixels.x,.25/pixels.y)
	rear_bus_board.text = BUS_DESTINATION
	rear_bus_board.pixel_size = bus_board.pixel_size
	side_bus_board.text = BUS_DESTINATION
	side_bus_board.pixel_size = minf(bus_board.pixel_size,1.49/pixels.x)
	return [bus_board,rear_bus_board,side_bus_board]

func _fit_bus_rear_bench(model: Node3D) -> void:
	for pattern in ["Seat cushion*", "Seat back shell*", "Seat back upholstery*"]:
		var sample: MeshInstance3D
		for part: MeshInstance3D in model.find_children(pattern, "MeshInstance3D", true, false):
			if sample == null or part.position.z < sample.position.z:
				sample = part
		if sample == null:
			continue
		for column in [-.72, -.24, .24, .72]:
			var seat := sample.duplicate() as MeshInstance3D
			seat.name = "Rear bench " + pattern.trim_suffix("*").trim_prefix("Seat ").to_lower()
			sample.get_parent().add_child(seat, true)
			seat.position.x = column
			seat.position.z -= 1.43
			seat.position.y += .13
	var podium := _make_box("Rear bench plinth", Vector3(1.98,.23,.56), Vector3(0,1.48,-4.65), Color("#303638"), false, model)
	podium.material_override = _material(Color("#303638"), .81)

func _fit_quattro_glazing(model: Node3D) -> void:
	if quattro_glazing == null:
		quattro_glazing = ShaderMaterial.new()
		quattro_glazing.shader = preload("res://environment/quattro_glazing.gdshader")
		quattro_glazing.set_shader_parameter("skyline",preload("res://environment/portland_landing_pad.exr"))
	for pane: MeshInstance3D in model.find_children("*glass*","MeshInstance3D",true,false):
		for surface in pane.mesh.get_surface_count():
			var finish := pane.get_active_material(surface)
			if finish != null and finish.resource_name == "Blue-green laminated glazing":
				pane.set_surface_override_material(surface,quattro_glazing)

func _fit_quattro_gauges(model: Node3D) -> void:
	if quattro_gauge_marks == null:
		quattro_gauge_marks = _material(Color("#d7d4b7"),.56,true)
		quattro_gauge_marks.emission = Color("#f0d89d")
		quattro_gauge_needle = _material(Color("#c62c22"),.43,true)
		quattro_gauge_needle.emission = Color("#ff5340")
	for part: MeshInstance3D in model.find_children("Gauge tick*","MeshInstance3D",true,false) + model.find_children("Speed scale numeral*","MeshInstance3D",true,false):
		part.material_override = quattro_gauge_marks
	for needle: MeshInstance3D in model.find_children("Gauge needle*","MeshInstance3D",true,false):
		needle.material_override = quattro_gauge_needle
	_update_quattro_gauge_light(maxf(last_night,0.0))

func _update_quattro_gauge_light(night: float) -> void:
	if quattro_gauge_marks:
		quattro_gauge_marks.emission_energy_multiplier = lerpf(.06,.67,night)
		quattro_gauge_needle.emission_energy_multiplier = lerpf(.02,.51,night)

func _fit_bus_exterior(model: Node3D) -> void:
	_fit_bus_rear_bench(model)
	var badge := _station_sign("SKANIA", Vector3(0,1.04,5.287), .002, Color("#dce0df"), 0, model)
	badge.name = "Bus front badge"
	badge.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	badge.rotation.x = -atan(.057 / .25)
	_size_world_sign(badge, .42)
	var window_seal := _material(Color("#151c1e"), .53)
	var lower_door_finish := _material(Color("#283337"), .37)
	lower_door_finish.metallic = .15
	for panel: MeshInstance3D in model.find_children("Passenger door lower panel*", "MeshInstance3D", true, false):
		panel.material_override = lower_door_finish
	var door_jamb := _material(Color("#0e1517"), .79)
	var tread := _material(Color("#545e61"), .72)
	var step_edge := _material(Color("#d9b747"), .78)
	var button_cap := CylinderMesh.new()
	button_cap.top_radius = .026
	button_cap.bottom_radius = .026
	button_cap.height = .012
	button_cap.radial_segments = 16
	button_cap.material = _material(Color("#9bce52"), .48)
	for door_center in [4.4, -.30, -4.11]:
		var seal := _make_box("Passenger door centre gasket", Vector3(.024, 2.25, .043),
			Vector3(-1.272, 1.58, door_center), door_jamb.albedo_color, false, model)
		seal.material_override = door_jamb
		var threshold := _make_box("Passenger door threshold", Vector3(.072, .036, 1.04),
			Vector3(-1.262, .447, door_center), tread.albedo_color, false, model)
		threshold.material_override = tread
		var nosing := _make_box("Passenger door step edge", Vector3(.018, .014, 1.0),
			Vector3(-1.296, .460, door_center), step_edge.albedo_color, false, model)
		nosing.material_override = step_edge
		# Bring the solid lower edge of the door glass up to the adjacent window belt.
		for leaf_offset in [-.267, .267]:
			var sill := _make_box("Passenger door window sill", Vector3(.048, .180, .490),
				Vector3(-1.249, 1.402, door_center + leaf_offset), window_seal.albedo_color, false, model)
			sill.material_override = window_seal
		if door_center < 0.0:
			var housing := _make_box("Passenger door request housing", Vector3(.028, .11, .093),
				Vector3(-1.267, 1.12, door_center + .38), Color("#1b2427"), false, model)
			var button := MeshInstance3D.new()
			button.name = "Passenger door request button"
			button.mesh = button_cap
			button.position.x = -.018
			button.rotation.z = PI * .5
			housing.add_child(button)
	if not bus_side_marker_finish:
		bus_side_marker_finish = _material(Color("#a6561d"),.32,true)
		bus_side_marker_finish.emission = Color("#ffaa43")
		bus_side_marker_finish.emission_energy_multiplier = 3.0 * maxf(last_night,0)
		traffic_running_lenses.append(bus_side_marker_finish)
	if not bus_rear_marker_finish:
		bus_rear_marker_finish = _material(Color("#7e1723"), .32, true)
		bus_rear_marker_finish.emission = Color("#ff2338")
		bus_rear_marker_finish.emission_energy_multiplier = 3.0 * maxf(last_night, 0)
		traffic_running_lenses.append(bus_rear_marker_finish)
	for side in [-1.0,1.0]:
		for z in [-3.15,1.0,3.5]:
			var marker := _make_box("Bus side marker lens",Vector3(.025,.064,.152),Vector3(side*1.25,1.13,z),Color.WHITE,false,model)
			marker.material_override = bus_side_marker_finish
		var repeater := BUS_SIDE_INDICATOR
		repeater.x *= side
		_make_box("Bus side indicator housing", Vector3(.028, .072, .15), repeater, window_seal.albedo_color, false, model)
		repeater.x += side * .016
		_make_box("Bus side indicator amber lens", Vector3(.014, .048, .124), repeater, Color("#9b581b"), false, model)
		var housing := _make_box("Bus rear upper marker housing", Vector3(.15,.074,.058), Vector3(side*1.02,2.955,-5.083), window_seal.albedo_color, false, model)
		var lens := _make_box("Bus rear upper marker lens", Vector3(.115,.042,.012), Vector3(0,0,-.033), Color.WHITE, false, housing)
		lens.material_override = bus_rear_marker_finish
	var brake_housing := _make_box("Bus centre brake housing",Vector3(.58,.078,.028),Vector3(0,1.395,-5.249),window_seal.albedo_color,false,model)
	var brake_glass := _make_box("Centre brake lamp",Vector3(.51,.038,.012),Vector3(0,0,-.017),Color("#921517"),false,brake_housing)
	var brake_finish := brake_glass.material_override as StandardMaterial3D
	brake_finish.resource_name = "Tail lamp centre strip"
	brake_glass.mesh.material = brake_finish
	brake_glass.material_override = null
	for pattern in ["Window pillar*", "Roof rail*", "Window sill graphite trim*", "Windscreen outer seal*", "Lower windscreen gasket*", "Passenger door upright*", "Passenger door cross rail*", "Passenger doorway header*"]:
		for trim: MeshInstance3D in model.find_children(pattern, "MeshInstance3D", true, false):
			trim.material_override = window_seal
			if trim.name.begins_with("Window pillar"):
				trim.scale.z *= 1.32
			elif trim.name.begins_with("Window sill graphite trim"):
				trim.scale.y *= 1.7
			elif trim.name.begins_with("Windscreen outer seal"):
				trim.scale.x *= 1.35
			elif trim.name.begins_with("Lower windscreen gasket"):
				trim.scale.y *= 1.45
			elif trim.name.begins_with("Passenger door upright"):
				trim.scale.z *= 1.28
			elif trim.name.begins_with("Passenger doorway header"):
				trim.scale.y *= 1.4
			if trim.name.begins_with("Roof rail") and trim.position.z < -4.9:
				trim.scale = Vector3(.70,1,.70)
	for side in [-1.0,1.0]:
		var trim := _make_box("Upper side window seal",Vector3(.049,.139,9.96),Vector3(side*1.174,2.875,.01),window_seal.albedo_color,false,model)
		trim.material_override = window_seal
	for edge in [Vector3(0,2.92,5.006),Vector3(0,2.92,-4.99),Vector3(0,1.451,-5.205)]:
		var trim := _make_box("Cross-window seal",Vector3(2.27,.047,.034),edge,window_seal.albedo_color,false,model)
		trim.material_override = window_seal
	# Close the tapered gap between the last side pillar and the sloping rear seal.
	for side in [-1.0, 1.0]:
		var corner := SurfaceTool.new()
		corner.begin(Mesh.PRIMITIVE_TRIANGLES)
		corner.set_material(window_seal)
		var x: float = side * 1.151
		var vertices := PackedVector3Array([
			Vector3(x, 1.45, -4.944), Vector3(x, 1.45, -5.209),
			Vector3(x, 2.91, -5.001), Vector3(x, 2.91, -4.944),
		])
		var indices := [2, 1, 0, 3, 2, 0] if side > 0 else [0, 1, 2, 0, 2, 3]
		for index in indices:
			corner.set_normal(Vector3(side, 0, 0))
			corner.add_vertex(vertices[index])
		var trim := MeshInstance3D.new()
		trim.name = "Rear window corner infill"
		trim.mesh = corner.commit()
		model.add_child(trim)
	var heater_color := Color("#68534a")
	# The rear glazing slopes inward toward the top of the cabin.
	var rear_glass_slope := .23 / (2.945 - 1.465)
	var lower_border := _make_box("Rear window lower border", Vector3(2.23, .115, .013),
		Vector3(0, 1.516, -5.207), window_seal.albedo_color, false, model)
	lower_border.rotation.x = atan(rear_glass_slope)
	lower_border.material_override = window_seal
	for side in [-1.0, 1.0]:
		var seal := _make_box("Rear window edge seal", Vector3(.065, 1.48, .037),
			Vector3(side * 1.118, 2.184, -5.106), window_seal.albedo_color, false, model)
		seal.rotation.x = atan(rear_glass_slope)
		seal.material_override = window_seal
	var bottom_wire_z := -5.204 + (1.66 - 1.465) * rear_glass_slope
	for row in 6:
		var rise := row * .12
		_make_box("Rear window heating wire", Vector3(1.92,.0035,.003),
			Vector3(0,1.66+rise,bottom_wire_z+rise*rear_glass_slope), heater_color, false, model)
	for side in [-1.0, 1.0]:
		var busbar := _make_box("Rear window heater busbar", Vector3(.010,.625,.004),
			Vector3(side*.958,1.96,bottom_wire_z+.30*rear_glass_slope), heater_color, false, model)
		busbar.rotation.x = atan(rear_glass_slope)
		_make_box("Rear window heater terminal", Vector3(.024,.029,.008),
			Vector3(side*.958,1.645,bottom_wire_z-.015*rear_glass_slope), window_seal.albedo_color, false, model)
	var hinge_finish := _material(Color("#41494d"), .42)
	hinge_finish.metallic = .58
	for side in [-1.0, 1.0]:
		var hinge := _make_box("Engine hatch hinge", Vector3(.136,.043,.024), Vector3(side*.48,1.26,-5.265), Color.WHITE, false, model)
		hinge.material_override = hinge_finish
		var pin := _make_box("Engine hatch hinge pin", Vector3(.15,.016,.018), Vector3(0,.012,-.017), Color.WHITE, false, hinge)
		pin.material_override = hinge_finish
	var plate := _make_box("Bus rear number plate",Vector3(.46,.105,.018),Vector3(0,.57,-5.282),Color("#eeeee4"),false,model)
	if not bus_plate_finish:
		bus_plate_finish = _material(Color("#eeeee4"),.55,true)
		bus_plate_lamp_finish = _material(Color("#7c807b"),.4,true)
		bus_plate_lamp_finish.emission = Color("#fff1d1")
		bus_plate_finish.emission_energy_multiplier = .28 * maxf(last_night,0)
		bus_plate_lamp_finish.emission_energy_multiplier = 1.1 * maxf(last_night,0)
	plate.material_override = bus_plate_finish
	var front_plate := model.find_child("Front number plate", true, false) as MeshInstance3D
	var imported_number := model.find_child("Bus fleet registration", true, false) as MeshInstance3D
	if front_plate and imported_number:
		front_plate.material_override = bus_plate_finish
		imported_number.hide()
		var front_number := _station_sign(BUS_REGISTRATION, Vector3(.018, 0, .014), .0014, Color("#162028"), 0, front_plate)
		front_number.name = "Bus front registration"
		front_number.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_size_world_sign(front_number, .36)
	for side in [-1.0,1.0]:
		var lamp := _make_box("Bus rear plate lamp",Vector3(.061,.012,.024),Vector3(side*.15,.061,-.012),Color.WHITE,false,plate)
		lamp.material_override = bus_plate_lamp_finish
	_make_box("Bus rear plate country band",Vector3(.045,.094,.006),Vector3(.203,0,-.012),Color("#254883"),false,plate)
	var number := _station_sign(BUS_REGISTRATION,Vector3(-.016,0,-.013),.0014,Color("#162028"),PI,plate)
	number.name = "Bus rear registration"
	number.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_size_world_sign(number,.36)
	for pocket in model.find_children("Wraparound headlamp pocket*", "MeshInstance3D", true, false):
		pocket.position.z -= .025
		pocket.scale.z *= .72
	var optic_ring := TorusMesh.new()
	optic_ring.inner_radius = .033
	optic_ring.outer_radius = .039
	optic_ring.rings = 24
	optic_ring.ring_segments = 8
	var optic_finish := _material(Color("#858f93"), .27)
	optic_finish.metallic = .72
	optic_ring.material = optic_finish
	for lens: MeshInstance3D in model.find_children("Bus headlight lens*", "MeshInstance3D", true, false):
		lens.position.z -= .036
		var surround := MeshInstance3D.new()
		surround.name = "Bus round headlamp optic"
		surround.mesh = optic_ring
		surround.rotation.x = PI / 2
		surround.position.z = lens.get_aabb().end.z
		lens.add_child(surround)
	# The imported shells sit below the replacement mirror assemblies.
	for shell: MeshInstance3D in model.find_children("Mirror*", "MeshInstance3D", true, false):
		shell.hide()
	var mirror_glass := _material(Color("#9bacb3"), .17)
	mirror_glass.metallic = .78
	for side in [-1.0,1.0]:
		var mirror_center := Vector3(side * 1.39, 1.91, 5.07)
		var side_name := "left" if side > 0 else "right"
		var housing_finish := Color("#202629")
		for height in [-.19,.15]:
			var mount := mirror_center + Vector3(-side * .19,height,0)
			_make_box("Bus mirror mounting foot",Vector3(.06,.11,.13),mount - Vector3(side * .071,0,0),housing_finish,false,model)
			_make_box("Bus mirror support arm",Vector3(.24,.045,.07),mount,housing_finish,false,model)
		_make_box("Bus mirror housing " + side_name,Vector3(.19,.46,.15),mirror_center,housing_finish,false,model)
		for pane in [Vector2(.064,.286),Vector2(-.148,.104)]:
			var pane_name := "upper" if pane.x > 0 else "lower"
			var glass := _make_box("Bus mirror glass " + side_name + " " + pane_name,Vector3(.145,pane.y,.012),mirror_center + Vector3(0,pane.x,-.077),Color.WHITE,false,model)
			glass.material_override = mirror_glass

	if bus_glazing == null:
		bus_glazing = ShaderMaterial.new()
		bus_glazing.shader = preload("res://environment/quattro_glazing.gdshader")
		bus_glazing.set_shader_parameter("skyline",preload("res://environment/portland_landing_pad.exr"))
		bus_glazing.set_shader_parameter("glass_tint", Color(.12, .20, .21))
		bus_glazing.set_shader_parameter("glass_opacity", Vector2(.27, .37))
	var cabin := model.find_child("Cabin",true,false) as MeshInstance3D
	for surface in cabin.mesh.get_surface_count():
		var finish := cabin.get_active_material(surface)
		if finish.resource_name.begins_with("Smoked blue glazing"):
			cabin.set_surface_override_material(surface,bus_glazing)
	for pane: MeshInstance3D in model.find_children("Passenger door tinted glazing*", "MeshInstance3D", true, false):
		pane.material_override = bus_glazing

func _fit_bus_interior() -> void:
	bus_ceiling_diffuser = _material(Color("#ded9c9"),.42,true)
	for z in [-2.55,0.0,2.15]:
		var fitting := _make_box("Saloon ceiling light",Vector3(.29,.045,1.12),Vector3(0,2.89,z),Color("#404b4d"),false,vehicle_model)
		var diffuser := _make_box("Saloon light diffuser",Vector3(.23,.018,1.05),Vector3.DOWN*.026,Color("#ded9c9"),false,fitting)
		diffuser.material_override = bus_ceiling_diffuser
		var lamp := SpotLight3D.new()
		fitting.add_child(lamp)
		lamp.position.y = -.045
		lamp.rotation.x = -PI*.5
		lamp.spot_range = 2.35
		lamp.spot_angle = 51
		lamp.light_color = Color("#fff4df")
		bus_ceiling_lights.append(lamp)
	_update_bus_ceiling_lights(maxf(last_night,0.0))
	var panel := _make_box("Interior stop display",Vector3(1.72,.30,.065),Vector3(0,2.60,3.54),Color("#172124"),false,vehicle_model)
	next_bus_stop_board = Label3D.new()
	next_bus_stop_board.rotation.y = PI
	next_bus_stop_board.position.z = -.035
	next_bus_stop_board.double_sided = false
	next_bus_stop_board.outline_size = 0
	next_bus_stop_board.modulate = Color("#ffd46c")
	panel.add_child(next_bus_stop_board)
	if not is_instance_valid(seated_bus_riders):
		seated_bus_riders = Node3D.new()
		add_child(seated_bus_riders)
		for shirt in [Color("#724e74"),Color("#668d9c")]:
			_make_walker("Bus rider",0,0,1,shirt,Color("#343c48"))
			var rider: Node3D = walker_data.pop_back().actor
			rider.reparent(seated_bus_riders,false)
			rider.rotation.y = PI
			rider.position = Vector3(-.78 if seated_bus_riders.get_child_count()==1 else .78, .90,1.1)
			for leg: Node3D in rider.get_meta("legs"):
				leg.rotation.x = 1.15
	for side in [-1,1]:
		_make_box("Passenger cushion",Vector3(.53,.13,.58),Vector3(side*.78,1.54,1.1),Color("#3f6378"),false,vehicle_model)
		_make_box("Passenger backrest",Vector3(.53,.69,.11),Vector3(side*.78,1.91,.84),Color("#3f6378"),false,vehicle_model)
	seated_bus_riders.reparent(vehicle_model,false)
	var rider := seated_bus_riders.get_child(0) as Node3D
	bus_request_arm = rider.get_meta("arms")[0]
	bus_request_arm.rotation.x = PI/2
	var contact := rider.transform * bus_request_arm.transform * (bus_request_arm.get_child(1) as Node3D).position
	bus_request_arm.rotation.x = 0
	_make_box("Passenger handrail",Vector3(.045,1.65,.045),Vector3(contact.x,1.84,contact.z+.05),Color("#eabc4e"),false,vehicle_model)
	var button_housing := _make_box("Stop button housing", Vector3(.085,.095,.046), contact, Color("#24282a"), false, vehicle_model)
	var stop_button := MeshInstance3D.new()
	stop_button.name = "Stop button"
	var cap := CylinderMesh.new()
	cap.top_radius = .030
	cap.bottom_radius = .030
	cap.height = .010
	cap.radial_segments = 16
	stop_button.mesh = cap
	stop_button.rotation.x = PI * .5
	stop_button.position.z = -.026
	button_housing.add_child(stop_button)
	var button_finish := _material(Color("#a52c32"), .43, true).duplicate() as StandardMaterial3D
	button_finish.emission = Color("#ff4036")
	button_finish.emission_energy_multiplier = 0.0
	stop_button.material_override = button_finish
	var request_panel := _make_box("Stop request panel",Vector3(.76,.19,.055),Vector3(0,2.34,3.54),Color("#291c20"),false,vehicle_model)
	bus_stop_request = Label3D.new()
	bus_stop_request.text = "Stop requested"
	bus_stop_request.rotation.y = PI
	bus_stop_request.position.z = -.032
	bus_stop_request.pixel_size = .0025
	bus_stop_request.modulate = Color("#ff604b")
	bus_stop_request.outline_size = 0
	request_panel.add_child(bus_stop_request)
	_size_world_sign(bus_stop_request,.70)
	bus_stop_request.hide()
	var request_signal := bus_stop_request
	request_signal.visibility_changed.connect(func():
		button_finish.emission_energy_multiplier = .95 if request_signal.visible else 0.0
	)
	bus_press_time = 0

func _update_bus_stop_request(delta: float) -> void:
	if bus_press_time < .4:
		if walker.visible:
			return
		if ambulance.position.distance_to(_mission_destination()) > 28:
			bus_press_time = 0.0
			bus_request_arm.rotation.x = 0.0
			return
	bus_press_time = minf(1.2,bus_press_time+delta)
	bus_request_arm.rotation.x = PI/2 * smoothstep(0,.4,bus_press_time) * (1-smoothstep(.65,1.2,bus_press_time))
	var requested := bus_press_time >= .4
	if bus_stop_request.visible != requested:
		bus_stop_request.visible = requested
		_update_driver_bus_stop_board()


func _load_vehicle_model() -> void:
	snow_slip_angle = 0.0
	bus_merge_time = 0
	bus_departure_pending = false
	bus_departure_lamps.clear()
	wiper_pivots.clear()
	shopper_wiper_parts.clear()
	wiper_phase = 0.0
	cockpit_view = false
	cockpit_look = Vector2.ZERO
	if is_instance_valid(vehicle_model):
		if is_instance_valid(seated_bus_riders) and seated_bus_riders.get_parent() == vehicle_model:
			seated_bus_riders.reparent(self,false)
			seated_bus_riders.hide()
		vehicle_model.queue_free()
	blue_light_meshes.clear()
	red_light_meshes.clear()
	var packed: PackedScene = load(VEHICLE_SCENES_ALL[vehicle_index])
	vehicle_model = packed.instantiate() as Node3D
	if vehicle_index == QUATTRO:
		_fit_quattro_glazing(vehicle_model)
		_fit_quattro_gauges(vehicle_model)
	driven_fire_locker = null
	if vehicle_index == 2:
		driven_fire_locker = FireLocker.new()
		driven_fire_locker.fit(vehicle_model)
	bus_ceiling_lights.clear()
	bus_ceiling_diffuser = null
	bus_dashboard_backlight = null
	bus_board = null
	driver_bus_stop_board = null
	rear_bus_board = null
	if vehicle_index == BUS:
		_fit_bus_exterior(vehicle_model)
		_fit_bus_interior()
		var boards := _add_bus_destination_boards(vehicle_model)
		bus_board = boards[0]
		rear_bus_board = boards[1]
		side_bus_board = boards[2]
		_update_bus_board()
	vehicle_model.name = VEHICLE_NAMES_ALL[vehicle_index] + "_BlenderModel"
	vehicle_model.rotation.y = PI
	ambulance.add_child(vehicle_model)
	if vehicle_index == SCHOOL_CAR:
		_add_school_car_sign(vehicle_model)
	muddy_parts.clear()
	mud_finish = ShaderMaterial.new()
	mud_finish.shader = preload("res://environment/road_mud.gdshader")
	var coats := {}
	for part: MeshInstance3D in vehicle_model.find_children("*","MeshInstance3D",true,false):
		if part.mesh == null or part.material_override: continue
		for surface in part.mesh.get_surface_count():
			var finish := part.get_active_material(surface)
			if finish == null or finish.next_pass: continue
			if not coats.has(finish):
				coats[finish] = null
				for term in ["enamel","paint","lacquer","rubber","tyre","tire","cladding","ceramic white","moulded shell","white gloss","watermelon coral","construction yellow","candy apple","melting silver","vermilion","sidewall"]:
					if term in finish.resource_name.to_lower():
						var coat := finish.duplicate() as Material
						coat.next_pass = mud_finish
						coats[finish] = coat
						break
			if coats[finish]:
				muddy_parts.append({"part":part,"surface":surface,"original":part.get_surface_override_material(surface),"coat":coats[finish]})
	if vehicle_dirt.get(vehicle_index,0.0) > 0:
		_show_mud(true)
		mud_finish.set_shader_parameter("dirt",vehicle_dirt[vehicle_index])
	dash_direction = null
	dash_speed = null
	reverse_feed = null
	reverse_monitor = null
	reverse_camera = null
	cabin_wheel = null
	shopper_grip_points.clear()
	if vehicle_index == BUS:
		var display := _make_box("Bus dashboard screen",Vector3(.355,.173,.017),Vector3(.58,1.745,4.70),Color("#14272b"),false,vehicle_model)
		bus_dashboard_backlight = _material(Color("#14272b"), .74, true).duplicate() as StandardMaterial3D
		bus_dashboard_backlight.emission = Color("#254750")
		display.material_override = bus_dashboard_backlight
		_update_bus_ceiling_lights(maxf(last_night, 0.0))
		display.rotation.x = -2.20
		display.rotate_object_local(Vector3.BACK,PI)
		var housing := Color("#252a2d")
		_make_box("Bus display housing", Vector3(.388,.206,.041), Vector3(0,0,-.024), housing, false, display)
		_make_box("Bus display sun visor", Vector3(.394,.022,.065), Vector3(0,.094,.005), housing, false, display)
		for side in [-1.0, 1.0]:
			_make_box("Bus display bezel", Vector3(.018,.185,.036), Vector3(side * .187,0,.001), housing, false, display)
		_make_box("Bus display lower bezel", Vector3(.388,.023,.038), Vector3(0,-.092,0), housing, false, display)
		dash_speed = _station_sign("",Vector3(0,-.004,.011),.00135,Color("#def4f7"),0,display)
		dash_speed.font_size = 44
		dash_direction = _station_sign("",Vector3(0,.051,.011),.00115,Color("#def4f7"),0,display)
		dash_direction.font_size = 32
		_size_world_sign(dash_speed,.31)
		_size_world_sign(dash_direction,.235)
		driver_bus_stop_board = _station_sign("",Vector3(0,-.055,.011),.00086,Color("#ffd46c"),0,display)
		driver_bus_stop_board.font_size = 31
		_size_world_sign(driver_bus_stop_board,.31)
		_update_bus_board()
	if vehicle_index == SHOPPER:
		for part_name in ["Wiper arm","Wiper blade lower","Wiper blade upper"]:
			var part := vehicle_model.find_child(part_name,true,false) as MeshInstance3D
			part.set_meta("parked_transform",part.transform)
			shopper_wiper_parts.append(part)
	if vehicle_index in [2, 3]:
		var fire := vehicle_index == 2
		var arms := vehicle_model.find_children("Cab wiper linkage*" if fire else "Wiper arm*","MeshInstance3D",true,false)
		var blades := vehicle_model.find_children("Crew cab wiper blade*" if fire else "Windscreen wiper blade*","MeshInstance3D",true,false)
		var spindles := vehicle_model.find_children("Cab wiper spindle cap*","MeshInstance3D",true,false)
		for i in mini(arms.size(),blades.size()):
			var arm := arms[i] as MeshInstance3D
			var bounds := arm.get_aabb()
			var pivot := Node3D.new()
			arm.get_parent().add_child(pivot)
			if fire:
				var spindle := spindles[i] as MeshInstance3D
				pivot.global_position = spindle.to_global(spindle.get_aabb().get_center())
				pivot.set_meta("sweep_axis", Vector3(0,.15,1).normalized() * signf(pivot.position.x))
			else:
				pivot.global_position = arm.to_global(Vector3(bounds.position.x,bounds.position.y,bounds.end.z))
				pivot.set_meta("sweep_axis", Vector3(0,.77,.64).normalized())
			arm.reparent(pivot)
			blades[i].reparent(pivot)
			wiper_pivots.append(pivot)
	if vehicle_index == BUS:
		var arms := vehicle_model.find_children("Windscreen wiper arm*","MeshInstance3D",true,false)
		var blades := vehicle_model.find_children("Windscreen wiper blade*","MeshInstance3D",true,false)
		var spindles := vehicle_model.find_children("Windscreen wiper mounting cap*","MeshInstance3D",true,false)
		for spindle: MeshInstance3D in spindles:
			var side := signf(spindle.position.x)
			var pivot := Node3D.new()
			spindle.get_parent().add_child(pivot)
			pivot.global_position = spindle.to_global(spindle.get_aabb().get_center())
			pivot.set_meta("sweep_axis",Vector3.BACK*side)
			for part: MeshInstance3D in arms+blades:
				if signf(part.position.x) == side:
					part.reparent(pivot)
			wiper_pivots.append(pivot)
	if vehicle_index in [DAM_PICKUP, QUATTRO]:
		var pickup := vehicle_index == DAM_PICKUP
		var pattern := "PickupWiperPivot_*" if pickup else "QuattroWiperPivot_*"
		var axis := Vector3(0,.44,.56) if pickup else Vector3(0,.495,.425)
		for pivot: Node3D in vehicle_model.find_children(pattern,"Node3D",true,false):
			pivot.set_meta("sweep_axis", axis.normalized())
			wiper_pivots.append(pivot)
	if vehicle_index in [2, 3, PORSCHE, MOWER, BUS, QUATTRO]:
		var rim_name := "Steering wheel" if vehicle_index == MOWER else "Steering wheel rim*"
		if vehicle_index == 2: rim_name = "Crew cab steering rim*"
		if vehicle_index == BUS: rim_name = "Bus steering wheel"
		var rim := vehicle_model.find_child(rim_name,true,false) as MeshInstance3D
		if rim:
			cabin_wheel = Node3D.new()
			vehicle_model.add_child(cabin_wheel)
			cabin_wheel.global_transform = Transform3D(ambulance.global_basis,rim.to_global(rim.get_aabb().get_center()))
			cabin_wheel_rest_basis = cabin_wheel.basis
			# Fit the rim's tilt in the vehicle's vertical/longitudinal plane.
			# Measure the exported rim so the hand positions also fit a lower sports-car cockpit.
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
			var spoke_name := "Wheel spoke*" if vehicle_index == MOWER else "*steering spoke*"
			for part in vehicle_model.find_children(spoke_name, "MeshInstance3D",true,false) + vehicle_model.find_children("Steering wheel*", "MeshInstance3D",true,false):
				part.reparent(cabin_wheel)
			if vehicle_index == BUS:
				for part in vehicle_model.find_children("Bus steering wheel*","MeshInstance3D",true,false):
					part.reparent(cabin_wheel)
			if vehicle_index == 2:
				rim.reparent(cabin_wheel)
				vehicle_model.find_child("Crew steering crossbar*",true,false).reparent(cabin_wheel)

	if vehicle_index in [3, PORSCHE]:
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
			dash_speed.text = tr("%d km/h") % 0
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
	driven_turn_signals = TurnIndicators.new()
	driven_turn_signals.fit(ambulance, vehicle_model, _model_bounds(ambulance, vehicle_model))
	if vehicle_index == BUS:
		bus_departure_lamps = driven_turn_signals.left
		var display := dash_speed.get_parent() as Node3D
		for side in [-1, 1]:
			var lamps := driven_turn_signals.left if side < 0 else driven_turn_signals.right
			var lamp := lamps[0]
			var arrow := _station_sign("◀" if side < 0 else "▶", Vector3(side * .144,.063,.012), .00068, Color("#80ec8c"), 0, display)
			arrow.name = "Dashboard left indicator" if side < 0 else "Dashboard right indicator"
			arrow.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			arrow.visible = lamp.visible
			lamp.visibility_changed.connect(func(): arrow.visible = lamp.visible)
	for beam in headlights:
		beam.queue_free()
	headlights.clear()
	projector_finish = null
	tractor_beacon = null
	refuse_beacon = null
	if vehicle_index == REFUSE:
		for lens: MeshInstance3D in vehicle_model.find_children("Roof beacon*", "MeshInstance3D", true, false):
			if not refuse_beacon:
				refuse_beacon = lens.get_active_material(0).duplicate() as StandardMaterial3D
				refuse_beacon.emission = Color("#ff9a15")
				refuse_beacon.emission_energy_multiplier = 3.0
			lens.set_surface_override_material(0, refuse_beacon)
	if vehicle_index == FARM_TRACTOR:
		_fit_plough(vehicle_model)
		_update_tractor_footprint()
		for body: MeshInstance3D in vehicle_model.find_children("Tractor body*", "MeshInstance3D", true, false):
			for surface in body.mesh.get_surface_count():
				var finish := body.get_active_material(surface)
				if finish != null and finish.resource_name == "Amber beacon lens":
					tractor_beacon = finish.duplicate() as StandardMaterial3D
					tractor_beacon.emission = Color("#ff9a15")
					body.set_surface_override_material(surface, tractor_beacon)
	var beam_origins: Array[Vector3] = []
	if vehicle_index in [2, SNOWMOBILE, PORSCHE, FARM_TRACTOR, SHOPPER, REFUSE, BUS, DAM_PICKUP, QUATTRO]:
		var lens_pattern: String = {2:"Swept transparent headlamp cover*", PORSCHE:"Headlight lens*", SNOWMOBILE:"Headlight strip*", FARM_TRACTOR:"Projector lens*", SHOPPER:"Headlight lens*", REFUSE:"Headlight lens*", BUS:"Bus headlight lens*", DAM_PICKUP:"Projector lens*", QUATTRO:"Headlight lens*"}[vehicle_index]
		var lenses := vehicle_model.find_children(lens_pattern, "MeshInstance3D", true, false)
		for lens: MeshInstance3D in lenses:
			var center := ambulance.to_local(lens.to_global(lens.get_aabb().get_center()))
			if vehicle_index != BUS or absf(center.x) > .89:
				beam_origins.append(center + Vector3.FORWARD * .035)
		if vehicle_index != SNOWMOBILE:
			var emitters := lenses
			if vehicle_index == 2:
				emitters = vehicle_model.find_children("Cab projector*", "MeshInstance3D", true, false)
			elif vehicle_index == QUATTRO:
				emitters = vehicle_model.find_children("Headlamp reflector*", "MeshInstance3D", true, false)
			for emitter: MeshInstance3D in emitters:
				if not projector_finish:
					projector_finish = emitter.get_active_material(0).duplicate() as StandardMaterial3D
					if vehicle_index == SHOPPER:
						projector_finish.vertex_color_use_as_albedo = true
					projector_finish.emission_enabled = true
					projector_finish.emission = Color("#fff0d9")
					projector_finish.emission_energy_multiplier = 3.0*maxf(last_night,0)
				emitter.set_surface_override_material(0,projector_finish)
	if vehicle_index == FARM_TRACTOR and projector_finish:
		for guide: MeshInstance3D in vehicle_model.find_children("Upper running light*", "MeshInstance3D", true, false):
			guide.set_surface_override_material(0, projector_finish)
	if vehicle_index == PUCH_DAKOTA:
		beam_origins.append(Vector3(0,.793,-.58))
	if beam_origins.is_empty():
		for side in [-1,1]:
			beam_origins.append(Vector3(side*player_half_size.x*.72,.87,-front_reach-.03))
	for origin in beam_origins:
		var beam := SpotLight3D.new()
		beam.position = origin
		beam.rotation.x = deg_to_rad(-7.0)
		beam.spot_range = 28
		beam.spot_angle = 26
		beam.light_color = Color("#fff0d9")
		beam.light_energy = 4.5*maxf(last_night,0.0)
		beam.visible = last_night>.05
		ambulance.add_child(beam)
		headlights.append(beam)
	moped_speed_needle = vehicle_model.find_child("SpeedNeedle",true,false) if vehicle_index == PUCH_DAKOTA else null
	quattro_speed_needle = vehicle_model.find_child("QuattroSpeedNeedle",true,false) if vehicle_index == QUATTRO else null
	player_wheels = _rig_wheels(vehicle_model)
	_end_skid()
	rear_tire_contacts.clear()
	front_knuckles.clear()
	if vehicle_index == SHOPPER:
		var bar := vehicle_model.find_child("Handlebar",true,false) as MeshInstance3D
		var column := vehicle_model.find_child("Steering column",true,false) as MeshInstance3D
		var grips := vehicle_model.find_children("Handle grip*", "MeshInstance3D",true,false)
		cabin_wheel = Node3D.new()
		vehicle_model.add_child(cabin_wheel)
		cabin_wheel.global_transform = Transform3D(ambulance.global_basis,bar.global_position)
		cabin_wheel_rest_basis = cabin_wheel.basis
		cabin_wheel_axis = -cabin_wheel.to_local(column.global_position).normalized()
		for grip: MeshInstance3D in grips:
			shopper_grip_points.append(cabin_wheel.to_local(grip.to_global(grip.get_aabb().get_center())))
		shopper_grip_points.sort_custom(func(a: Vector3,b: Vector3): return a.x < b.x)
		bar.reparent(cabin_wheel)
		for grip in grips: grip.reparent(cabin_wheel)
	if vehicle_index == FOOD_TRUCK:
		cabin_wheel = vehicle_model.find_child("SteeringPivot",true,false)
		cabin_wheel_rest_basis = cabin_wheel.basis
		cabin_wheel_axis = Vector3(0,.09,-.153).normalized()
		grip_radius = -.18
	if vehicle_index == SNOWMOBILE:
		rear_tire_contacts.append(Vector3(0, 0, 1.14))
		for joint in vehicle_model.find_children("SkiPivot*", "Node3D", true, false):
			front_knuckles.append(joint)
		cabin_wheel = vehicle_model.find_child("HandlebarPivot", true, false)
		cabin_wheel_rest_basis = cabin_wheel.basis
		cabin_wheel_axis = Vector3.UP
		# The imported model faces the opposite direction to the driver root.
		grip_radius = -.29
	for pivot in player_wheels:
		var hub := ambulance.to_local(pivot.global_position)
		if hub.z < 0.0 and not front_knuckles.has(pivot.get_parent()):
			front_knuckles.append(pivot.get_parent())
		elif hub.z > 0.0:
			rear_tire_contacts.append(Vector3(hub.x, 0.0, hub.z))
	player_brake_lens = _brake_lens(vehicle_model)
	reverse_lens = _brake_lens(vehicle_model, true)
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

func _parked_in_fire_bay() -> bool:
	if vehicle_index != 2 or walker.visible or absf(speed) >= .12 or ambulance.basis.z.z <= 0:
		return false
	var footprint := parked_footprints[2]
	for x in [footprint.position.x,footprint.end.x]:
		for z in [footprint.position.y,footprint.end.y]:
			var corner := ambulance.to_global(Vector3(x,0,z))-FIRE_RETURN_BAY
			if absf(corner.x)>2.15 or absf(corner.z)>4.9:
				return false
	return true

func _launch_pier_exit_path(start: Vector2) -> PackedVector2Array:
	var quay := Vector2(LAUNCH_PIER.end.x + .5, LAUNCH_LANDING.y)
	return PackedVector2Array([start, Vector2(start.x, quay.y), quay])

func _ferry_pier_exit_path(start: Vector2) -> PackedVector2Array:
	var landing_z: float = FERRY_LANDINGS[0] if start.y < (FERRY_LANDINGS[0] + FERRY_LANDINGS[1]) * .5 else FERRY_LANDINGS[1]
	return PackedVector2Array([start, Vector2(start.x, landing_z), Vector2(48, landing_z)])

func _launch_walking_path(start: Vector2) -> PackedVector2Array:
	if LAUNCH_PIER.has_point(start):
		return PackedVector2Array([start, Vector2(start.x, LAUNCH_LANDING.y), LAUNCH_LANDING])
	var quay := Vector2(LAUNCH_PIER.end.x + .5, LAUNCH_LANDING.y)
	var path := PackedVector2Array([start])
	if parked_cars[vehicle_index].visible and start.distance_to(Vector2(LAUNCH_ROAD_STOP.x, LAUNCH_ROAD_STOP.z)) < 8.0:
		var car := _parked_bounds(vehicle_index).grow(.40)
		if start.x <= car.position.x and absf(start.y - quay.y) < 2.0:
			return PackedVector2Array([start, Vector2(quay.x, start.y), quay, LAUNCH_LANDING])
		if start.x > car.get_center().x and start.y > car.position.z and start.y < car.end.z:
			var bypass_z := car.position.z if start.y - car.position.z < car.end.z - start.y else car.end.z
			path.append(Vector2(start.x, bypass_z))
			path.append(Vector2(car.position.x, bypass_z))
			path.append(Vector2(car.position.x, quay.y))
			path.append(quay)
			path.append(LAUNCH_LANDING)
			return path
	path.append_array(navigator.path(start, quay))
	path.append(LAUNCH_LANDING)
	return path

func _is_villa_driveway_approach(start: Vector2, goal: Vector2) -> bool:
	return map_goal == suburban_villas.MAP_STOP and absf(start.x - goal.x) < 1.5 and start.distance_to(goal) < 7.0

func _update_route_arrows() -> void:
	turn_preview.hide()
	for arrow in route_arrows: arrow.visible = false
	if ferry_passenger or tram_mode != 0 or mode!="playing" or boating or operating_excavator: return
	if (free_drive and map_goal == Vector3.INF) or (not free_drive and mission_index >= TARGETS.size()): return
	var origin := walker.position if walker.visible else ambulance.position
	var target := map_goal if free_drive else _mission_destination()
	var grill_destination := free_drive and target == shops.grill_counter()
	var walking_to_grill := grill_destination and walker.visible
	var arrived := shops.at_grill_counter(origin) if walking_to_grill else origin.distance_to(target) < _arrival_radius()
	var bench_destination := free_drive and target == BOULE_BENCH_APPROACH
	var fountain_destination := free_drive and target == FOUNTAIN_APPROACH
	var launch_destination := free_drive and target == LAUNCH_MAP_STOP
	var villa_destination := free_drive and target == suburban_villas.MAP_STOP
	if villa_destination:
		arrived = origin.distance_to(target) < 1.8
	if launch_destination:
		if walker.visible:
			arrived = _at_launch_landing()
		else:
			target = LAUNCH_ROAD_STOP
			arrived = origin.distance_to(target) < 2.0
	if fountain_destination and walker.visible:
		arrived = origin.distance_to(target) < 1.6
	var shop_destination := -1
	if free_drive:
		for shop_name: String in MAP_STOREFRONTS:
			if target == shops.storefront_entrance(shop_name):
				shop_destination = shops.SHOPS.find(shop_name)
				break
	var is_shop_destination := shop_destination >= 0
	if is_shop_destination and walker.visible:
		arrived = shops.inside == shop_destination
	if bench_destination and walker.visible:
		arrived = _at_boule_bench()
	if free_drive and target == FIRE_RETURN_BAY:
		arrived = _parked_in_fire_bay()
	if free_drive and arrived:
		if walker.visible or not (grill_destination or bench_destination or is_shop_destination or fountain_destination or launch_destination):
			map_goal = Vector3.INF
			if target == FIRE_RETURN_BAY and is_instance_valid(driven_fire_locker):
				driven_fire_locker.set_destination("")
			_save_checkpoint()
		return
	var start := Vector2(origin.x, origin.z)
	var points := PackedVector2Array()
	if walker.visible and LAUNCH_PIER.has_point(start) and not launch_destination:
		points = _launch_pier_exit_path(start)
		start = points[-1]
	elif walker.visible and not is_nan(_pier_height(start.x, start.y)):
		points = _ferry_pier_exit_path(start)
		start = points[-1]
	var goal := Vector2(target.x, target.z)
	if villa_destination and _is_villa_driveway_approach(start, goal):
		# Once lined up with the driveway, continue in instead of snapping back to the avenue.
		points = PackedVector2Array([start, goal])
	elif walker.visible:
		navigator.remaining_lane.clear()
		var near_counter := walking_to_grill and origin.z <= shops.FRONT_Z
		var near_bench := bench_destination and origin.x <= BOULE_BENCH.x
		if launch_destination:
			points.append_array(_launch_walking_path(start))
		elif is_shop_destination and origin.z <= shops.FRONT_Z and start.distance_to(goal) <= 5.0:
			# Approach along the pavement, then turn through the open doorway.
			points = PackedVector2Array([start, Vector2(goal.x, start.y), goal])
		elif (near_counter or near_bench) and start.distance_to(goal) <= 5.0:
			points = PackedVector2Array([start, goal])
		else:
			points.append_array(navigator.path(start, goal))
	else:
		var forward := -ambulance.global_basis.z
		var needs_wide_turns := vehicle_index in [2, RECOVERY, BUS, REFUSE]
		points = navigator.driving_path(start, goal, Vector2(forward.x, forward.z).normalized(), needs_wide_turns)
	var car_forward := Vector2(-ambulance.global_basis.z.x, -ambulance.global_basis.z.z).normalized()
	if not walker.visible and not paused and not boating and not operating_excavator:
		turn_preview.text = navigator.turn_preview(points, car_forward, show_turn_street)
		turn_preview.visible = not turn_preview.text.is_empty()
	var close_guide := villa_destination or (walker.visible and (grill_destination or bench_destination or is_shop_destination or fountain_destination or launch_destination))
	var gap := minf(3.5, start.distance_to(goal) * .5) if close_guide else 3.5
	var used := 0
	for i in range(1,points.size()):
		var segment := points[i]-points[i-1]
		var length := segment.length()
		var direction := segment.normalized()
		# Reveal the return lane as the driver turns into it.
		if not walker.visible and direction.dot(car_forward) < -0.15: break
		while gap<length and used<route_arrows.size():
			var point := points[i-1]+direction*gap
			var arrow := route_arrows[used]
			var height := _foot_height(point.x,point.y) if walker.visible else _surface_height(point.x,point.y)
			arrow.position = Vector3(point.x,height+.07,point.y)
			arrow.rotation.y = atan2(-direction.x,-direction.y)
			arrow.visible=true
			used+=1
			gap+=6
		gap-=length
		if used==route_arrows.size(): break

func _update_hazard_lights() -> void:
	var lit := warning_triangle.is_visible_in_tree() and (traffic_light_mode != 2 and (calm_mode or traffic_light_mode == 1 or hazard_phase < .5))
	for lens in hazard_lenses:
		lens.material_override = hazard_amber if lit else null

func _sync_ice_crates() -> void:
	if not ice_crates.is_inside_tree(): return
	var bay := _depot_bay(ICE_CREAM)
	ice_crates.visible = crate_stage != CrateStage.IN_VAN
	ice_crates.position = Vector3(bay.x-2.1,.04,bay.y) if crate_stage == CrateStage.AT_DEPOT else Vector3(shops.storefront_x(1)+1,.04,41)

func _update_crate_return() -> void:
	if not free_drive or vehicle_index != ICE_CREAM or walker.visible or boating or operating_excavator or tram_mode != 0 or ferry_passenger or absf(speed) >= .12: return
	var bay := _depot_bay(ICE_CREAM)
	if crate_stage == CrateStage.AT_KIOSK and ambulance.position.distance_to(Vector3(shops.storefront_x(1),0,37.5)) < 3.2:
		crate_stage = CrateStage.IN_VAN
		phone.receive(CRATE_RETURN)
	elif crate_stage == CrateStage.IN_VAN and ambulance.position.distance_to(Vector3(bay.x,0,bay.y)) < 3:
		crate_stage = CrateStage.AT_DEPOT
		phone.receive(CRATE_DONE)
	else: return
	_sync_ice_crates()
	_refresh_dispatch()
	_save_preferences()

func _update_flour_delivery() -> void:
	if not free_drive or vehicle_index != RECOVERY or walker.visible or absf(speed) >= .12: return
	if flour_stage == FlourStage.AT_SQUARE:
		var hour := fposmod(12.0+day_phase*24.0,24.0)
		if time_mode != 2 or hour < 5 or hour >= 12 or ambulance.position.distance_to(TARGETS[0]) > 4.8: return
		flour_stage = FlourStage.ON_TRUCK
		phone.receive(FLOUR_ROUTE)
	elif flour_stage == FlourStage.ON_TRUCK and ambulance.position.distance_to(FLOUR_CURB) < 4.8:
		flour_stage = FlourStage.AT_BAKERY
		phone.delivery_receipts.append(phone.FLOUR_RECEIPT)
		phone.receive(phone.FLOUR_RECEIPT)
	else: return
	_sync_flour_sacks()
	_refresh_dispatch()
	_save_preferences()

func _sync_flour_sacks() -> void:
	if not flour_sacks.is_inside_tree(): return
	var holder: Node3D = self
	var place := Vector3(30,.08,7)
	if flour_stage == FlourStage.ON_TRUCK:
		holder = ambulance if vehicle_index == RECOVERY and ambulance.visible and not walker.visible else parked_cars[RECOVERY]
		place = Vector3(0,1.25,1.59)
	elif flour_stage == FlourStage.AT_BAKERY:
		place = Vector3(-16.3,.04,-8.8)
	if flour_sacks.get_parent() != holder: flour_sacks.reparent(holder,false)
	flour_sacks.position = place
	flour_sacks.visible = free_drive or flour_stage == FlourStage.AT_BAKERY

func _sync_recovery() -> void:
	_sync_flour_sacks()
	var active := vehicle_index==RECOVERY and not free_drive
	var loaded := recovery_leg%2==1
	workshop_car.visible = recovery_leg >= 2
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
	_update_hazard_lights()
	bonnet_smoke.emitting=active and recovery_leg%4==0

func _repair_at_workshop(replace_wheel: bool) -> void:
	if repair_tween:
		repair_tween.kill()
	workshop_car.position = STATION_PARKING
	workshop_wheel.position = wheel_rest
	workshop_tool.visible = not replace_wheel
	workshop_smoke.emitting = not replace_wheel
	repair_tween = workshop_car.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if replace_wheel:
		var side := signf(workshop_car.to_local(workshop_wheel.global_position).x)
		workshop_wheel.position.x += side * 1.3
		repair_tween.tween_property(workshop_car,"position:y",STATION_PARKING.y+.35,.6)
		repair_tween.tween_property(workshop_wheel,"position",wheel_rest,1.3)
		repair_tween.tween_property(workshop_car,"position:y",STATION_PARKING.y,.6)
	else:
		for stroke in 3:
			repair_tween.tween_property(workshop_tool,"rotation:z",.55,.32)
			repair_tween.tween_property(workshop_tool,"rotation:z",-.28,.32)
		repair_tween.tween_callback(workshop_smoke.set.bind("emitting",false))
		repair_tween.tween_callback(workshop_tool.hide)

func _build_target_marker() -> void:
	var roadside_model := preload("res://vehicles/traffic_bmw_silver.glb")
	workshop_car=roadside_model.instantiate()
	add_child(workshop_car)
	workshop_car.position=STATION_PARKING
	workshop_car.scale=Vector3.ONE*.79
	workshop_car.rotation.y=PI/2
	workshop_car.hide()
	casualty=roadside_model.instantiate()
	add_child(casualty)
	casualty.scale=Vector3.ONE*.79
	hazard_amber = _material(Color("#ffad26"),.24,true)
	for pattern in ["Daytime LED chevron*", "Upper ruby light guide*"]:
		for lens in casualty.find_children(pattern,"MeshInstance3D",true,false):
			hazard_lenses.append(lens)
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
	workshop_smoke = bonnet_smoke.duplicate()
	workshop_car.add_child(workshop_smoke)
	workshop_smoke.emitting = false
	workshop_wheel = _rig_wheels(workshop_car)[0]
	wheel_rest = workshop_wheel.position
	workshop_car.add_child(workshop_tool)
	workshop_tool.position = Vector3(.42,1.12,1.65)
	var chrome := Color("#bfced2")
	_make_box("Spanner handle",Vector3(.09,.55,.07),Vector3.UP*.31,chrome,false,workshop_tool)
	_make_box("Spanner jaw",Vector3(.24,.09,.09),Vector3.UP*.58,chrome,false,workshop_tool)
	for side in [-1,1]:
		_make_box("Spanner prong",Vector3(.065,.14,.09),Vector3(side*.09,.66,0),chrome,false,workshop_tool)
	workshop_tool.hide()
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
	for shirt in [Color("#668d9c"),Color("#b37056")]:
		_make_walker("Bus passenger",0,0,1,shirt,Color("#343c48"))
		bus_companions.append(walker_data.pop_back().actor)
	add_child(ice_crates)
	for i in 2:
		var level := Vector3.UP*i*.26
		var plastic := Color("#367ea1")
		_make_box("Crate floor",Vector3(.54,.028,.38),level,plastic,false,ice_crates)
		for side in [-1,1]:
			for corner in [-1,1]:
				_make_box("Crate corner",Vector3(.03,.25,.03),level+Vector3(side*.255,.125,corner*.175),plastic,false,ice_crates)
			for rail in [.06,.15,.24]:
				_make_box("Crate side",Vector3(.54,.036,.025),level+Vector3(0,rail,side*.178),plastic,false,ice_crates)
				_make_box("Crate end",Vector3(.025,.036,.38),level+Vector3(side*.258,rail,0),plastic,false,ice_crates)
	_sync_ice_crates()
	add_child(flour_sacks)
	for i in 3:
		var bag := MeshInstance3D.new()
		var body := SphereMesh.new()
		body.radius = .31
		body.height = .76
		bag.mesh = body
		bag.material_override = _material(Color("#d5bb8c"),.94,false,"cotton_jersey")
		flour_sacks.add_child(bag)
		bag.position = Vector3((i-1)*.58,.35,.11 if i==1 else 0.)
		bag.scale = Vector3(1,1,.76)
		_make_box("Folded sack seam",Vector3(.31,.09,.055),Vector3.UP*.37,Color("#c4a572"),false,bag)
		# A single ear of wheat printed on the front of each sack.
		var ink := _material(Color("#73512d"),.95)
		_tube_between(bag,Vector3(0,-.12,.30),Vector3(0,.14,.30),.008,ink)
		for j in 3:
			for side in [-1,1]:
				var y := -.09+j*.068
				_tube_between(bag,Vector3(0,y,.30),Vector3(side*.055,y+.068,.30),.016,ink)
	for i in 2:
		var bag := _make_grocery_bag(self)
		grocery_bags.append(bag)
		var parcel := Node3D.new()
		parcel.name = "Delivery parcel %d" % (i+1)
		add_child(parcel)
		if i == 0:
			_make_box("Clinic supply case",Vector3(.46,.28,.33),Vector3.UP*.14,Color("#e1e7dc"),false,parcel)
			_make_box("Case lid",Vector3(.47,.045,.34),Vector3.UP*.275,Color("#367873"),false,parcel)
			for side in [-1,1]:
				_make_box("Case latch",Vector3(.045,.065,.018),Vector3(side*.13,.245,-.166),Color("#333c3f"),false,parcel)
		else:
			_make_box("Marina crate base",Vector3(.46,.045,.33),Vector3.UP*.023,Color("#935832"),false,parcel)
			for side in [-1,1]:
				for level in 3:
					_make_box("Crate slat",Vector3(.46,.065,.018),Vector3(0,.072+level*.082,side*.16),Color("#b78254"),false,parcel)
				_make_box("Crate end",Vector3(.025,.27,.30),Vector3(side*.22,.136,0),Color("#a06d49"),false,parcel)
			var rope_finish := _material(Color("#e6b86d"))
			for coil in 4:
				var z := -.098+coil*.065
				_tube_between(parcel,Vector3(-.17,.175,z),Vector3(.17,.175,z),.035,rope_finish)
				_tube_between(parcel,Vector3(-.17,.238,z),Vector3(.17,.238,z),.035,rope_finish)
		delivery_parcels.append(parcel)
		var roll := Node3D.new()
		roll.name = "Blanket roll %d" % (i+1)
		add_child(roll)
		for stripe in [-1,0,1]:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = .11 if stripe == 0 else .115
			cylinder.bottom_radius = cylinder.top_radius
			cylinder.height = .48 if stripe == 0 else .035
			cylinder.radial_segments = 24
			cylinder.rings = 1
			var fabric := MeshInstance3D.new()
			fabric.mesh = cylinder
			fabric.material_override = _material(Color("#407883") if stripe == 0 else Color("#ded8b8"))
			fabric.rotation.z = PI/2
			fabric.position = Vector3(stripe*.15,.115,0)
			roll.add_child(fabric)
		blanket_rolls.append(roll)
	var square := WALK_TARGETS[0]
	var hydrant := preload("res://environment/fire_hydrant.tscn").instantiate() as Node3D
	hydrant.position = Vector3(square.x-.85,_foot_height(square.x-.85,square.z),square.z)
	add_child(hydrant)
	hydrant.add_child(practice_hose)
	practice_hose.hide()
	var hose_finish := _material(Color("#e6bb61"))
	var hose_path := PackedVector3Array([Vector3(.17,.56,0),Vector3(.52,.09,-.20),Vector3(.85,.06,-.64),Vector3(.97,.06,-1.1),Vector3(.74,.19,-1.48)])
	for i in range(1,hose_path.size()):
		_tube_between(practice_hose,hose_path[i-1],hose_path[i],.052,hose_finish)
	var nozzle := Vector3(.70,.32,-1.76)
	_tube_between(practice_hose,hose_path[-1],nozzle,.065,_material(Color("#9aaab2")))
	practice_hose.add_child(practice_spray)
	practice_spray.position = nozzle
	practice_spray.direction = Vector3(-.14,.46,-1).normalized()
	practice_spray.spread = 4
	practice_spray.initial_velocity_min = 4.2
	practice_spray.initial_velocity_max = 4.8
	practice_spray.gravity = Vector3.DOWN*4.9
	practice_spray.lifetime = 1.05
	practice_spray.amount = 150
	var drop := SphereMesh.new()
	drop.radius = .038
	drop.height = .076
	drop.radial_segments = 6
	drop.rings = 2
	drop.material = _material(Color("#76c9ed"))
	practice_spray.mesh = drop
	practice_spray.emitting = false
	building_bounds.append(AABB(hydrant.position-Vector3(.22,.1,.2),Vector3(.44,1.1,.4)))
	_make_walker("Neighbour at the square",square.x+.9,square.z,-1,Color("#408a91"),Color("#465162"))
	square_neighbour = walker_data.pop_back().actor
	square_neighbour.position.y = _foot_height(square_neighbour.position.x,square.z)
	square_neighbour.rotation.y = 0
	var quay := WALK_TARGETS[2]
	var lifebuoy_scene := preload("res://environment/marina_lifebuoy.tscn")
	var lifebuoy := lifebuoy_scene.instantiate() as Node3D
	lifebuoy.position = Vector3(quay.x,_foot_height(quay.x,quay.z-.9),quay.z-.9)
	add_child(lifebuoy)
	building_bounds.append(AABB(lifebuoy.position-Vector3(.38,.1,.23),Vector3(.76,1.7,.35)))
	for safety_z in [-35.4, -16.6]:
		var safety_ring := lifebuoy_scene.instantiate() as Node3D
		safety_ring.position = Vector3(87.79, _foot_height(87.79, safety_z), safety_z)
		safety_ring.rotation.y = -PI * .5
		add_child(safety_ring)
		building_bounds.append(AABB(safety_ring.position - Vector3(.12, 0, .38), Vector3(.36, 1.55, .76)))
	_make_walker("Marina attendant",quay.x+.8,quay.z,1,Color("#e18a39"),Color("#314755"))
	marina_recipient = walker_data.pop_back().actor
	marina_recipient.position.y = _foot_height(marina_recipient.position.x,quay.z)
	var pickup := WALK_TARGETS[1]
	for side in [-1, 1]:
		var spot := pickup + Vector3(.65,0,side*1.15)
		_make_walker("Fire safety team",spot.x,spot.z,side,Color("#e59637"),Color("#28394a"))
		var member: Node3D = walker_data.pop_back().actor
		member.position.y = _foot_height(spot.x,spot.z)
		member.look_at(Vector3(pickup.x,member.position.y,pickup.z))
		clinic_fire_team.append(member)
	var receiving := HOSPITAL_RECEIVING_POINT
	_make_walker("Waiting medic",receiving.x,receiving.z,1,Color("#d5db46"),Color("#275744"))
	waiting_medic = walker_data.pop_back().actor
	waiting_medic.position.y = _foot_height(receiving.x, receiving.z)
	waiting_medic.rotation.y = PI/2
	waiting_medic.add_child(medical_bag)
	medical_bag.name = "FirstAidKit"
	_make_box("Medical bag",Vector3(.24,.30,.38),Vector3.ZERO,Color("#30605b"),false,medical_bag)
	for side in [-1,1]:
		for size in [Vector3(.012,.14,.045),Vector3(.012,.045,.14)]:
			_make_box("First aid symbol",size,Vector3(side*.122,0,0),Color("#eef0df"),false,medical_bag)
	for end in [-1,1]:
		_make_box("Handle strap",Vector3(.021,.083,.018),Vector3(0,.19,end*.064),Color("#253f40"),false,medical_bag)
	_make_box("Bag handle",Vector3(.024,.023,.146),Vector3(0,.226,0),Color("#253f40"),false,medical_bag)
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
	curb_bay.name = "CurbBay"
	mission_marker.add_child(curb_bay)
	var stripe := _material(Color("#ffdf77"), .65, true)
	# The long edge faces the pavement. The open side faces approaching traffic.
	_make_box("Curb stripe",Vector3(6.8,.025,.16),Vector3(0,0,1.1),Color.WHITE,false,curb_bay).material_override = stripe
	for side in [-1,1]:
		_make_box("Bay end",Vector3(.16,.025,2.35),Vector3(side*3.32,0,0),Color.WHITE,false,curb_bay).material_override = stripe
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
	camera.far = 4000.0 if long_view_distance else 220.0
	camera.current = true
	camera.fov = 58
	add_child(camera)
	_update_camera(0.0, true)

func _toggle_camera_view() -> void:
	if boating or tram_mode != 0 or walker.visible or not _world_controls_available(): return
	if operating_excavator:
		excavator_work_view = not excavator_work_view
	elif vehicle_index in DRIVER_VIEW_VEHICLES:
		cockpit_look = Vector2.ZERO
		cockpit_view = not cockpit_view
	else:
		return
	_update_camera(0,true)
	_refresh_ui()
	get_viewport().gui_release_focus()

func _update_camera(delta: float, snap_to_car := false) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(ambulance): return
	camera.fov = 58
	if cockpit_view and not walker.visible and not boating and tram_mode == 0 and not operating_excavator and not ferry_passenger:
		if vehicle_index == 2:
			camera.fov = 78
		elif vehicle_index == QUATTRO:
			camera.fov = 74
	if ferry_passenger:
		var focus := walker.position + Vector3.UP*.95
		camera.position = focus + Vector3(5,3.3+orbit_height,7).rotated(Vector3.UP,orbit_angle)
		camera.look_at(focus)
		return
	if boating and is_instance_valid(launch):
		var chase := launch.to_global(Vector3(1,3.6+orbit_height,7).rotated(Vector3.UP,orbit_angle))
		# Lower the chase camera before the deck can hide the boat from view.
		var bridge_z := -48.0 if launch.position.z < -24.0 else 0.0
		var distance := absf(launch.position.z - bridge_z)
		var underpass := 1.0 - smoothstep(12.5, 19.0, distance)
		if underpass > 0.0:
			var lower_deck := minf(_bridge_rise(launch.position.x, bridge_z), _bridge_rise(chase.x, bridge_z))
			var ceiling := maxf(launch.position.y + .9, lower_deck - .90)
			chase.y = lerpf(chase.y, minf(chase.y, ceiling), underpass)
		camera.position = chase
		camera.look_at(launch.to_global(Vector3(0,.4,-1.7)))
		return
	if tram_mode == 1 and tram.sections.size() > 1:
		var saloon: Node3D = tram.sections[1]
		var eye := Vector3(-.18, 1.75, 1.8)
		var gaze := eye.direction_to(Vector3(0, 1.55, -2.2))
		gaze = gaze.rotated(Vector3.RIGHT, passenger_look.y).rotated(Vector3.UP, passenger_look.x)
		camera.global_position = saloon.to_global(eye)
		camera.look_at(saloon.to_global(eye + gaze), saloon.global_basis.y)
		return
	if tram_mode > 0 and not tram.sections.is_empty():
		var cab: Node3D = tram.sections[0]
		camera.position = cab.to_global(Vector3(4.0,4.1+orbit_height,8.0).rotated(Vector3.UP,orbit_angle))
		camera.look_at(cab.to_global(Vector3(0,1.4,-1)))
		return
	if operating_excavator:
		if excavator_work_view:
			var bucket := bucket_joint.global_position
			var ground := Vector3(bucket.x, _surface_height(bucket.x,bucket.z), bucket.z)
			var target := ground.lerp(bucket,.5)
			var distance := maxf(4.8, bucket.y-ground.y+2.6)
			camera.global_position = target + cab_turntable.global_basis * Vector3(.90,.44,.28).normalized() * distance
			camera.look_at(target)
			return
		var focus := excavator.position + Vector3.UP*2.2
		camera.position = focus + cab_turntable.global_basis * Vector3(8,4,-9).rotated(Vector3.UP,orbit_angle)
		camera.look_at(focus + cab_turntable.global_basis.z*1.8)
		return
	if walker.visible:
		var target := walker.position + Vector3.UP*1.2
		var chase := target + walker.basis.z.normalized()*4.5 + Vector3.UP*(2.0+walk_camera_height)
		camera.position = _clear_camera_view(target,chase)
		camera.look_at(target)
		return
	if cockpit_view and vehicle_index in DRIVER_VIEW_VEHICLES:
		var pitch := -.16
		var curb_yaw := 0.0
		match vehicle_index:
			2:
				camera.global_position = vehicle_model.to_global(Vector3(.57, 2.55, 2.45))
				pitch = -2.68
			BUS:
				camera.global_position = vehicle_model.to_global(Vector3(.58,2.13,4.07))
				pitch = -1.30
			QUATTRO:
				camera.global_position = vehicle_model.to_global(Vector3(.346,1.17,-.20))
				pitch = -1.66
			REFUSE:
				camera.global_position = ambulance.to_global(Vector3(-.52,2.60,-4.02))
				curb_yaw = -.20
				pitch = -1.35
			FARM_TRACTOR:
				camera.global_position = ambulance.to_global(Vector3(0,2.77,.40))
				pitch = -2.2
			PUCH_DAKOTA:
				camera.global_position = ambulance.to_global(Vector3(0,1.53,.30))
				pitch = -1.90
			FOOD_TRUCK:
				# Midpoint of the pupils in both portrait meshes, relative to the face origin.
				camera.global_position = road_driver.get_node("Face").to_global(Vector3(0,.0139,-.1073))
				pitch = -1.18
			_:
				camera.global_position = ambulance.to_global(Vector3(-.32,1.56,-.10))
		var gaze := Vector3(steering*.38,pitch,-5.9).rotated(Vector3.RIGHT,cockpit_look.y).rotated(Vector3.UP,cockpit_look.x + curb_yaw)
		camera.look_at(camera.global_position + ambulance.global_basis*gaze)
		return
	var forward := -ambulance.global_transform.basis.z
	var chase_distance := 10.5
	var chase_height := 6.0
	var look_ahead := 4.0
	var anchor_height := 2.8
	match vehicle_index:
		PUCH_DAKOTA:
			chase_distance = 5.0
			chase_height = 2.65
			look_ahead = 1.6
			anchor_height = 1.5
		MOWER:
			chase_distance = 5.6
			chase_height = 3.8
			look_ahead = 0.6
			anchor_height = 1.4
	var desired := ambulance.global_position - forward.rotated(Vector3.UP,orbit_angle) * chase_distance + Vector3(0, chase_height+orbit_height, 0)
	var preview := steering * clampf(1.0 - absf(speed) / 45.0, 0.35, 1.0)
	if speed < -0.1:
		preview = 0.0
	camera_turn = 0.0 if snap_to_car else lerpf(camera_turn, preview, 1.0 - exp(-5.0 * delta))
	var right := ambulance.global_transform.basis.x
	desired += right * camera_turn * 0.65
	var look := ambulance.global_position + forward * look_ahead + right * camera_turn * 2.5 + Vector3.UP
	var weight := 1.0 if snap_to_car else 1.0 - exp(-4.0 * maxf(delta, 0.0))
	var followed := camera.global_position.lerp(desired, weight)
	# Bound lag along the road while preserving the damped orbit through turns.
	var lag := (desired - followed).dot(forward)
	followed += forward * (lag - clampf(lag, -2.0, 2.0))
	var anchor := ambulance.global_position + Vector3.UP * anchor_height
	camera.global_position = _clear_camera_view(anchor, followed)
	camera.look_at(look, Vector3.UP)

func _clear_camera_view(anchor: Vector3, desired: Vector3) -> Vector3:
	var direction := anchor.direction_to(desired)
	for crown in canopy_camera_bounds:
		var entry = crown.intersects_segment(anchor, desired)
		if entry != null and not crown.has_point(anchor):
			desired = anchor + direction * maxf(.04, anchor.distance_to(entry) - .20)
	for building in building_bounds:
		var contact = building.grow(0.18).intersects_segment(anchor, desired)
		if contact != null:
			desired = anchor + direction * maxf(0.04, anchor.distance_to(contact) - 0.08)
	return desired

func _place_taxi_passenger(person: Node3D, stop: int) -> void:
	var pavement: Vector3 = _stop_pavement(stop)
	pavement.y = _foot_height(pavement.x, pavement.z)
	person.position = pavement
	var curb := _stop_curb(stop)
	person.look_at(Vector3(curb.x, pavement.y, curb.z))

func _update_stop_label(label: Label3D) -> void:
	var stop_name := tr(label.get_meta("stop_name"))
	label.text = BUS_DESTINATION + "\n" + stop_name
	var font := ThemeDB.fallback_font
	var width := maxf(font.get_string_size(stop_name,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x,font.get_string_size(BUS_DESTINATION,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x)
	label.pixel_size = minf(.004, 1.43 / maxf(width, 1.0))

func _update_bus_board() -> void:
	if is_instance_valid(bus_board):
		seated_bus_riders.visible = not free_drive and bus_leg % 2 == 1
		if not seated_bus_riders.visible:
			bus_press_time = 0
			bus_request_arm.rotation.x = 0
			bus_stop_request.hide()
		var font := ThemeDB.fallback_font
		next_bus_stop_board.visible = not free_drive
		var stop: int = BUS_STOPS[bus_leg % BUS_STOPS.size()]
		next_bus_stop_board.text = tr("Next stop: %s") % tr(BUS_STOP_NAMES[stop])
		var size := font.get_string_size(next_bus_stop_board.text,HORIZONTAL_ALIGNMENT_LEFT,-1,next_bus_stop_board.font_size)
		next_bus_stop_board.pixel_size = minf(1.61/size.x,.22/size.y)
		_update_driver_bus_stop_board()

func _update_driver_bus_stop_board() -> void:
	if not is_instance_valid(driver_bus_stop_board): return
	driver_bus_stop_board.visible = not free_drive
	driver_bus_stop_board.text = tr("Stop requested") if bus_stop_request.visible else next_bus_stop_board.text
	driver_bus_stop_board.modulate = bus_stop_request.modulate if bus_stop_request.visible else next_bus_stop_board.modulate
	_fit_world_sign(driver_bus_stop_board)

func _update_mission_marker() -> void:
	_update_bus_board()
	if not is_instance_valid(mission_marker): return
	_sync_recovery()
	for i in refuse_bins.size():
		refuse_bins[i].visible = vehicle_index == REFUSE and not free_drive
	_update_route_arrows()
	passenger.visible = not free_drive and vehicle_index == TAXI and taxi_leg%2==0
	if passenger.visible:
		_place_taxi_passenger(passenger, _taxi_stop())
	arriving_passenger.visible = passenger.visible and taxi_leg >= 2
	if arriving_passenger.visible:
		_place_taxi_passenger(arriving_passenger, _taxi_stop(taxi_leg-1))
	if vehicle_index == BUS and not free_drive:
		passenger.visible = bus_leg%2==0
		arriving_passenger.visible = bus_leg>=2 and passenger.visible
		if passenger.visible: _place_taxi_passenger(passenger,BUS_STOPS[bus_leg%BUS_STOPS.size()])
		if arriving_passenger.visible: _place_taxi_passenger(arriving_passenger,BUS_STOPS[(bus_leg-1)%BUS_STOPS.size()])
	if vehicle_index == ICE_CREAM and not free_drive and mission_index < ICE_STOPS.size():
		passenger.visible = true
		_place_taxi_passenger(passenger, ICE_STOPS[mission_index])
	passenger.scale = Vector3.ONE*(.72 if vehicle_index==TAXI and _school_fare(taxi_leg) else 1.0)
	arriving_passenger.scale = Vector3.ONE*(.72 if vehicle_index==TAXI and taxi_leg>=2 and _school_fare(taxi_leg-1) else 1.0)
	for i in bus_companions.size():
		var companion := bus_companions[i]
		var leader := passenger if i==0 else arriving_passenger
		companion.visible = vehicle_index==BUS and not free_drive and leader.visible
		if companion.visible:
			companion.transform = leader.transform
			companion.translate_object_local(Vector3(-1.1 if i==0 else 1.1,0,0))
			companion.position.y = _foot_height(companion.position.x,companion.position.z)
	for member in clinic_fire_team:
		member.visible = not free_drive and vehicle_index == 2 and mission_index == 0
	for i in grocery_bags.size():
		var bag := grocery_bags[i]
		var stage := mission_index if vehicle_index == SHOPPER else int(vehicle_progress.get(SHOPPER,0))
		var onboard := stage > 0 and stage < i+2
		var carrier: Node3D = self
		if onboard:
			carrier = ambulance if vehicle_index == SHOPPER and ambulance.visible else parked_cars[SHOPPER]
		if bag.get_parent() != carrier:
			bag.reparent(carrier,false)
		bag.visible = not free_drive and (vehicle_index == SHOPPER or onboard)
		if onboard:
			bag.position = Vector3(-.133+i*.266,.558,.80)
		elif bag.visible:
			var site := WALK_TARGETS[0] if stage == 0 else WALK_TARGETS[i+1]
			bag.position = site + Vector3(.35+i*.34,0,.58)
			bag.position.y = _foot_height(bag.position.x,bag.position.z)
	var delivering := vehicle_index in PARCEL_VEHICLES and not free_drive
	for i in delivery_parcels.size():
		var parcel := delivery_parcels[i]
		var delivered := mission_index >= i+2
		var carried := delivering and walker.visible and carried_parcel_leg == mission_index and mission_index == i+1
		var holder: Node3D = walker.get_node("Jacket") if carried else self
		var onboard := delivering and mission_index > 0 and not delivered and not carried
		if onboard:
			holder = ambulance if ambulance.visible else parked_cars[vehicle_index]
		if parcel.get_parent() != holder:
			parcel.reparent(holder,false)
		parcel.visible = delivering and (mission_index == 0 or delivered or carried or onboard)
		if carried:
			parcel.position = Vector3(0,-.16,-.40)
		elif onboard:
			parcel.position = parcel_mounts[vehicle_index] + Vector3((i-.5)*PARCEL_SPACING,0,0)
		elif parcel.visible:
			var stop := WALK_TARGETS[i+1] if delivered else WALK_TARGETS[0]
			parcel.position = stop + Vector3(.45+i*.51,0,.68)
			parcel.position.y = _foot_height(parcel.position.x,parcel.position.z)
	for i in blanket_rolls.size():
		var roll := blanket_rolls[i]
		roll.visible = vehicle_index == SNOWMOBILE and not free_drive
		if not roll.visible: continue
		var onboard := mission_index > 0 and mission_index < i+2
		var carrier: Node3D = self
		if onboard:
			carrier = parked_cars[SNOWMOBILE] if walker.visible else ambulance
		if roll.get_parent() != carrier: roll.reparent(carrier,false)
		if onboard:
			roll.position = Vector3(0,.61,1.03+i*.24)
		else:
			var stop := WALK_TARGETS[0 if mission_index == 0 else i+1]
			roll.position = stop + Vector3(.45+i*.51,0,.68)
			roll.position.y = _foot_height(roll.position.x,roll.position.z)
	var rescue := not free_drive and not boating and vehicle_index == 0
	square_neighbour.visible = rescue and mission_index != 1
	if square_neighbour.visible:
		var patient_position := WALK_TARGETS[0] + Vector3(.9, 0, 0) if mission_index == 0 else HOSPITAL_RECEIVING_POINT + Vector3(0, 0, 1.05)
		patient_position.y = _foot_height(patient_position.x, patient_position.z)
		square_neighbour.position = patient_position
		square_neighbour.rotation.y = 0 if mission_index == 0 else PI
	waiting_medic.visible = rescue and mission_index >= 1
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
	if medical_bag.visible:
		var palm: MeshInstance3D = carrier.get_meta("arms")[1].get_child(1)
		carrier = palm
		bag_position = PALM_GRIP - Vector3.UP*.226
	if medical_bag.get_parent() != carrier:
		var previous_palm := medical_bag.get_parent() as MeshInstance3D
		if previous_palm:
			previous_palm.mesh = preload("res://characters/RelaxedHand.obj")
		medical_bag.reparent(carrier,false)
		if medical_bag.visible:
			(carrier as MeshInstance3D).mesh = preload("res://characters/GrippingHand.obj")
	medical_bag.position = bag_position
	if free_drive or mission_index >= TARGETS.size():
		mission_marker.visible = false
		return
	mission_marker.visible = true
	var zone := mission_marker.get_node("ArrivalZone") as MeshInstance3D
	zone.scale = Vector3(_arrival_radius(),.4,_arrival_radius())
	mission_marker.global_position = _mission_destination() + Vector3(0, 0.05, 0)
	curb_bay.visible = not _needs_mission_vehicle() and vehicle_index in [REFUSE,TAXI,RECOVERY]
	zone.visible = not curb_bay.visible
	if curb_bay.visible:
		var side := Vector3.BACK
		if vehicle_index == RECOVERY:
			if recovery_leg % 4 == 2: side = Vector3.FORWARD
		else:
			var stop := _taxi_stop() if vehicle_index == TAXI else _mission_stop()
			side = _stop_pavement(stop) - _stop_curb(stop)
		curb_bay.rotation.y = atan2(side.x,side.z)
	var marker_label: Label3D = mission_marker.get_node("MissionLabel")
	if _needs_mission_vehicle():
		marker_label.text = tr("Return to your taxi" if vehicle_index == TAXI else "Return to your bus" if vehicle_index==BUS else "Return to your ice cream van" if vehicle_index == ICE_CREAM else "Return to your garbage truck" if vehicle_index == REFUSE else "Return to your recovery truck").to_upper()
		return
	marker_label.text = tr(BUS_MESSAGES[bus_leg%BUS_STOPS.size()] if vehicle_index==BUS else SERVICE_MESSAGES[recovery_leg%4] if vehicle_index==RECOVERY else _taxi_instruction() if vehicle_index==TAXI else _vehicle_tasks()[_mission_stop()]).to_upper()

func _update_emergency_lights() -> void:
	var phase := int(light_phase * 2.0) % 2
	if tractor_beacon:
		tractor_beacon.emission_enabled = lights_on and (calm_mode or steady_player_lights or phase == 0)
		tractor_beacon.emission_energy_multiplier = 3.0
	for light in blue_light_meshes:
		light.visible = lights_on and (calm_mode or steady_player_lights or phase == 0)
	for light in red_light_meshes:
		light.visible = lights_on and (calm_mode or steady_player_lights or phase == 1)

func _build_ice_order() -> void:
	ui.add_child(ice_order)
	ice_order.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ice_order.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ice_order.grow_vertical = Control.GROW_DIRECTION_BOTH
	var layout := VBoxContainer.new()
	ice_order.add_child(layout)
	var title := Label.new()
	title.text = "Match the customer's ice cream"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	requested_ice.custom_minimum_size = Vector2(96,96)
	requested_ice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	requested_ice.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(requested_ice)
	layout.add_child(flavour_choices)
	flavour_choices.columns = 3
	for i in 6:
		var icon := AtlasTexture.new()
		icon.atlas = preload("res://art/ice_cream/menu.png")
		icon.region = Rect2((i%3)*128,floori(i/3.0)*128,128,128)
		ice_flavours.append(icon)
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(100,84)
		choice.icon = icon
		choice.expand_icon = true
		choice.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.tooltip_text = preload("res://vehicles/ice_cream_menu.gd").FLAVOURS[i]
		choice.pressed.connect(_help_at_target.bind(i))
		flavour_choices.add_child(choice)
	ice_order.hide()

func _build_song_card() -> void:
	ui.add_child(song_card)
	song_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	song_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	song_card.offset_right = -22
	song_card.offset_left = -22
	song_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	song_card.add_theme_stylebox_override("panel",_style(Color(.055,.09,.11,.94),12))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",12)
	song_card.add_child(row)
	song_cover.custom_minimum_size = Vector2(64,64)
	song_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	song_cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	song_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(song_cover)
	song_title.custom_minimum_size.x = 205
	song_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	song_title.add_theme_font_size_override("font_size",20)
	row.add_child(song_title)
	song_card.hide()

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.add_child(turn_preview)
	turn_preview.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	turn_preview.grow_horizontal = Control.GROW_DIRECTION_BOTH
	turn_preview.offset_top = 100
	turn_preview.add_theme_font_size_override("font_size",32)
	turn_preview.add_theme_constant_override("outline_size",6)
	turn_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_preview.hide()
	add_child(ui)
	ui.add_child(reward_badge)
	reward_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	reward_badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	reward_badge.offset_top = 160
	reward_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_badge.focus_mode = Control.FOCUS_NONE
	reward_badge.add_theme_font_size_override("font_size",22)
	reward_badge.add_theme_stylebox_override("normal",_style(Color("#203c38"),12))
	reward_badge.hide()
	_build_song_card()
	_build_ice_order()
	var top := PanelContainer.new()
	top.name = "DrivingHeader"
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
	title.text = "Harbor Town Rollabout"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f4f1e8"))
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(heading)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_child(title)
	mission_label = Label.new()
	mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 20)
	mission_label.add_theme_color_override("font_color", Color("#c5efce"))
	heading.add_child(mission_label)
	wallet_label=Label.new()
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
	ui.add_child(driving_footer_margin)
	driving_footer_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	driving_footer_margin.offset_bottom = -8
	driving_footer_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	driving_footer_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer_panel := PanelContainer.new()
	footer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer_style := _style(Color("#111b25c9"), 10)
	footer_style.content_margin_left = 10
	footer_style.content_margin_right = 10
	footer_style.content_margin_top = 4
	footer_style.content_margin_bottom = 5
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	driving_footer_margin.add_child(footer_panel)
	var footer := VBoxContainer.new()
	footer_panel.add_child(footer)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(arrival_progress)
	status_label = Label.new()
	footer.add_child(status_label)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	arrival_progress.custom_minimum_size = Vector2(144, 8)
	arrival_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	arrival_progress.show_percentage = false
	arrival_progress.max_value = HELP_DURATION
	arrival_progress.step = 0.0
	arrival_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrival_progress.add_theme_stylebox_override("background", _style(Color("#203137"), 3))
	arrival_progress.add_theme_stylebox_override("fill", _style(Color("#83dda0"), 3))
	add_child(horn)
	horn.bus = &"Traffic and radio"
	horn.volume_db = -5
	horn_button = _button("Horn · H",135)
	ui.add_child(horn_button)
	horn_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	horn_button.offset_left = -220
	horn_button.offset_right = -22
	horn_button.offset_top = -82
	horn_button.offset_bottom = -34
	horn_button.pressed.connect(_honk)
	tyre_service_button = _button("Fit winter tyres", 135)
	tyre_service_button.add_theme_font_size_override("font_size", 22 if large_text else 16)
	ui.add_child(tyre_service_button)
	tyre_service_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	tyre_service_button.offset_left = -246
	tyre_service_button.offset_right = -22
	tyre_service_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tyre_service_button.offset_top = -138
	tyre_service_button.offset_bottom = -90
	tyre_service_button.pressed.connect(_swap_workshop_tyres)
	spreader_button = _button("Spreader on", 135)
	ui.add_child(spreader_button)
	spreader_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	spreader_button.offset_left = -220
	spreader_button.offset_right = -22
	spreader_button.offset_top = -138
	spreader_button.offset_bottom = -90
	spreader_button.toggle_mode = true
	spreader_button.set_pressed_no_signal(spreader_enabled)
	spreader_button.toggled.connect(func(enabled: bool):
		spreader_enabled = enabled
		_save_preferences()
		if not enabled:
			_set_spreader_active(false)
		_refresh_ui()
	)
	dax_button = _button("Order Dax burger", 170)
	dax_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ui.add_child(dax_button)
	dax_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	dax_button.offset_left = -270
	dax_button.offset_right = -22
	dax_button.offset_top = -200
	dax_button.offset_bottom = -152
	dax_button.pressed.connect(_serve_dax)
	_build_boule_choices()
	seat_button = _button("Get out · F", 135)
	ui.add_child(seat_button)
	seat_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	seat_button.offset_left=-220
	seat_button.offset_right=-22
	seat_button.pressed.connect(_change_seat)
	var help := driving_hints
	help.name = "DrivingHints"
	help.text = "{up} / ↑  Drive     {left} {right} / ← →  Steer     {down} / ↓  Brake or reverse\nRelease to slow down   ·   {help} to help   ·   {pause} to pause"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", Color("#f5f1df"))
	help.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	footer.add_child(help)
	ui.add_child(driving_controls)
	driving_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shops.build_menu(ui)
	ui.add_child(phone)
	phone.instruction_started.connect(func():
		greeting_voice.stop()
		if radio.playing:
			radio.volume_db = minf(radio.volume_db, _radio_target_gain())
		var traffic_bus := AudioServer.get_bus_index("Traffic and radio")
		AudioServer.set_bus_volume_db(traffic_bus, minf(AudioServer.get_bus_volume_db(traffic_bus), _traffic_target_gain()))
	)
	var align_below_header := func():
		var below := top.position.y + top.size.y + 12
		phone.position.y = below
		song_card.position = Vector2(top.position.x + top.size.x - song_card.size.x, below)
	top.resized.connect(align_below_header)
	song_card.resized.connect(align_below_header)
	align_below_header.call()
	_build_town_map()
	radio_button = _button(tr("Turn radio on · %s") % OS.get_keycode_string(radio_keys[0]), 180)
	radio_button.add_theme_constant_override("icon_max_width",32)
	phone.handset.visibility_changed.connect(func():
		if phone.handset.is_visible_in_tree():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_release_mouse_pedals()
		elif mode == "playing" and (boating or operating_excavator or tram_mode == 2 or not walker.visible):
			release_pedal_keys = _keyboard_pedal_pressed()
	)
	phone.take_job.pressed.connect(func():
		if leave_practice_button.visible:
			_leave_practice()
			if leave_practice_button.visible: return
		map_goal = Vector3.INF
		free_drive = false
		phone.toggle()
		_update_mission_marker()
		_update_route_arrows()
		_save_checkpoint()
		_refresh_ui()
	)
	cat_hint = _button("Listen for the cat",180)
	phone.add_child(cat_hint)
	cat_hint.hide()
	cat_hint.pressed.connect(func():
		cat_meow.play()
		_say(lost_cat,"Meow!","")
	)
	shoe_hint = _button("Show footprints",180)
	shoe_hint.toggle_mode = true
	phone.add_child(shoe_hint)
	shoe_hint.hide()
	shoe_hint.toggled.connect(func(_enabled: bool): _update_search_hints())
	phone.add_child(radio_button)
	radio_button.pressed.connect(_toggle_radio)
	next_song_button = _button(tr("Next song · %s") % OS.get_keycode_string(radio_keys[1]), 180)
	phone.add_child(next_song_button)
	next_song_button.pressed.connect(_next_radio_track)
	radio.finished.connect(_next_radio_track)
	radio.bus = &"Radio"
	add_child(radio)
	_build_overlay()
	_build_menu_footer()
	siren_player = AudioStreamPlayer.new()
	siren_player.bus = &"Traffic and radio"
	siren_player.volume_db = -11
	add_child(siren_player)
	for path in SIREN_SOUNDS:
		var stream: AudioStreamWAV = load(path)
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		siren_streams.append(stream)

func _build_town_map() -> void:
	var dialog := AcceptDialog.new()
	dialog.name = "TownMap"
	dialog.window_input.connect(_dialog_quit_key.bind(dialog))
	dialog.exclusive = true
	dialog.transient = true
	add_child(dialog)
	var body := VBoxContainer.new()
	dialog.add_child(body)
	var chart := preload("res://scripts/town_map.gd").new()
	body.add_child(chart)
	var counter := shops.grill_counter()
	chart.water_bounds = CANAL_BOUNDS
	chart.configure(navigator,PackedVector3Array([TARGETS[0],TARGETS[1],TARGETS[2],SCHOOL_CURB,STATION_DROP,counter,FLOUR_CURB,BOULE_BENCH_APPROACH,shops.pizzeria_entrance(),shops.storefront_entrance("Sweet shop"),shops.storefront_entrance("Momo & Bori"),FOUNTAIN_APPROACH,LAUNCH_MAP_STOP,shops.storefront_entrance("Toy Harbour"),suburban_villas.MAP_STOP,dax.MAP_STOP]),MAP_NAMES)
	dialog.window_input.connect(func(event: InputEvent):
		if not event is InputEventKey or not event.pressed or event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
			return
		if event.keycode == map_key:
			dialog.set_input_as_handled()
			dialog.hide()
			return
		var first_key := KEY_KP_1 if event.keycode >= KEY_KP_1 else KEY_1
		var index: int = event.keycode-first_key
		if event.keycode in [KEY_0,KEY_KP_0]:
			index = 9
		elif index < 0 or index > 8:
			return
		if index >= 0 and index < mini(10,chart.stops.size()):
			dialog.set_input_as_handled()
			chart.picked.emit(index)
	)
	var legend := HFlowContainer.new()
	body.add_child(legend)
	for i in MAP_NAMES.size():
		var button := Button.new()
		button.toggle_mode = true
		button.text = "%d · %s" % [chart.pin_number(i),tr(MAP_NAMES[i])]
		button.pressed.connect(func(): chart.picked.emit(i))
		legend.add_child(button)
	chart.picked.connect(func(index: int):
		map_goal = chart.stops[index]
		dialog.hide()
		_update_route_arrows()
		_save_checkpoint()
	)
	leave_practice_button.text = "Return to town"
	phone.add_child(leave_practice_button)
	leave_practice_button.pressed.connect(_leave_practice)
	map_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	phone.add_child(map_button)
	map_button.pressed.connect(func():
		dialog.set_meta("return_focus", get_viewport().gui_get_focus_owner())
		var actor := _player_actor()
		chart.player = Vector2(actor.global_position.x,actor.global_position.z)
		var forward := -actor.global_basis.z
		chart.player_heading = Vector2(forward.x,forward.z).normalized()
		chart.route_preview = PackedVector2Array()
		if map_goal.is_finite() and not (boating or ferry_passenger or tram_mode != 0 or operating_excavator):
			var origin: Vector2 = chart.player
			var target := Vector2(map_goal.x,map_goal.z)
			if map_goal == LAUNCH_MAP_STOP and not walker.visible:
				target = Vector2(LAUNCH_ROAD_STOP.x,LAUNCH_ROAD_STOP.z)
			var heading := Vector2.ZERO if walker.visible else Vector2(forward.x,forward.z).normalized()
			if walker.visible and not LAUNCH_PIER.has_point(origin) and not is_nan(_pier_height(origin.x, origin.y)):
				chart.route_preview = _ferry_pier_exit_path(origin)
				origin = chart.route_preview[-1]
			if _is_villa_driveway_approach(origin, target):
				chart.route_preview = PackedVector2Array([origin, target])
			elif walker.visible and map_goal == LAUNCH_MAP_STOP:
				chart.route_preview.append_array(_launch_walking_path(origin))
			elif walker.visible and LAUNCH_PIER.has_point(origin):
				chart.route_preview = _launch_pier_exit_path(origin)
				chart.route_preview.append_array(navigator.path(chart.route_preview[-1], target))
			else:
				if walker.visible and chart.route_preview.is_empty():
					chart.route_preview.append(origin)
				chart.route_preview.append_array(navigator.path(origin,target,heading,vehicle_index in [2,RECOVERY,BUS,REFUSE]))
		var focused_stop := legend.get_child(0) as Button
		for i in MAP_NAMES.size():
			var caption := tr(MAP_NAMES[i])
			var selected: bool = map_goal == chart.stops[i]
			var stop_button := legend.get_child(i) as Button
			stop_button.set_pressed_no_signal(selected)
			chart.get_child(i).set_pressed_no_signal(selected)
			stop_button.text = "%d · %s" % [chart.pin_number(i),caption]
			if selected:
				focused_stop = stop_button
			chart.get_child(i).tooltip_text = caption
			chart.get_child(i).accessibility_name = caption
		chart.queue_redraw()
		_release_mouse_pedals()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		dialog.title = tr("Town map")
		dialog.ok_button_text = tr("Close")
		_toggle_pause()
		dialog.popup_centered()
		focused_stop.grab_focus.call_deferred()
	)
	dialog.visibility_changed.connect(func():
		if dialog.visible:
			return
		if paused and mode == "playing":
			_toggle_pause()
		if dialog.has_meta("return_focus"):
			var previous: Variant = dialog.get_meta("return_focus")
			dialog.remove_meta("return_focus")
			if is_instance_valid(previous) and previous.is_visible_in_tree():
				previous.grab_focus()
	)

func _build_menu_footer() -> void:
	overlay.add_child(menu_footer)
	menu_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	menu_footer.offset_right = -20
	menu_footer.offset_left = 20
	menu_footer.offset_bottom = -12
	menu_footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var about := _button("About", 92)
	menu_footer.add_child(version_label)
	version_label.size_flags_vertical = Control.SIZE_SHRINK_END
	menu_footer.add_spacer(false)
	menu_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_footer.add_child(about)
	var popup := AcceptDialog.new()
	popup.exclusive = true
	add_child(popup)
	popup.window_input.connect(_dialog_quit_key.bind(popup))
	popup.dialog_autowrap = true
	popup.get_label().custom_minimum_size.x = 480
	about.pressed.connect(func():
		popup.title = tr("About the game")
		popup.ok_button_text = tr("Close")
		popup.dialog_text = tr("Explore Harbor Town with Axel and Alma. Walk along the canal, take the tram or drive a tow truck to help a neighbour. You choose where to go next.") + "\n\n" + tr("My name is Daniel Nylander. I made this game for my children, who have autism and a language disorder. I wanted them to have a town they could explore at their own pace. That is why you can choose a vehicle by its picture and read what people say in speech bubbles.")
		popup.popup_centered(Vector2i(520, 270))
	)
	popup.visibility_changed.connect(func():
		if not popup.visible and about.is_visible_in_tree(): about.grab_focus()
	)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.035, 0.045, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var reserve_footer := func():
		center.offset_bottom = -menu_footer.get_combined_minimum_size().y - 16 if menu_footer.visible else 0.0
	menu_footer.visibility_changed.connect(reserve_footer)
	menu_footer.minimum_size_changed.connect(reserve_footer)
	overlay_panel = PanelContainer.new()
	overlay_panel.custom_minimum_size = Vector2(620, 350)
	overlay_panel.add_theme_stylebox_override("panel", _style(Color("#172b32"), 24))
	center.add_child(overlay_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	overlay_panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	brand_logo.custom_minimum_size = Vector2(180, 62)
	brand_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(brand_logo)
	header.add_spacer(false)
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
	var subtitle_row := HBoxContainer.new()
	box.add_child(subtitle_row)
	pause_action_picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	subtitle_row.add_child(pause_action_picture)
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_row.add_child(subtitle_label)
	start_button = _button("Start a gentle drive", 300)
	_color_action(start_button, true)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_overlay_action)
	vehicle_selector.columns = 7
	vehicle_selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var vehicle_group := ButtonGroup.new()
	var normal_style := _style(Color("#49616b"),8)
	var hover_style := _style(Color("#536e78"),8)
	var selected_style := _style(Color("#355d64"),8)
	for style in [normal_style,hover_style,selected_style]:
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 4
	selected_style.set_border_width_all(3)
	selected_style.border_color = Color("#ffe395")
	for index in VEHICLE_NAMES_ALL.size()+EXTRA_GALLERY_NAMES.size():
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(166,94)
		tile.toggle_mode = true
		tile.button_group = vehicle_group
		var vehicle_name: String = VEHICLE_NAMES_ALL[index] if index < VEHICLE_NAMES_ALL.size() else EXTRA_GALLERY_NAMES[index-VEHICLE_NAMES_ALL.size()]
		tile.set_meta("vehicle_name",vehicle_name)
		tile.text = "City bus 74" if index == BUS else vehicle_name
		tile.accessibility_name = tr(tile.text)
		tile.add_theme_font_size_override("font_size",14)
		tile.add_theme_stylebox_override("normal",normal_style)
		tile.add_theme_stylebox_override("hover",hover_style)
		tile.add_theme_stylebox_override("pressed",selected_style)
		tile.add_theme_stylebox_override("hover_pressed",selected_style)
		var thumbnail := AtlasTexture.new()
		thumbnail.atlas = preload("res://vehicles/menu_thumbnails.png")
		var picture_index := index + 3 if index in [DAM_PICKUP, QUATTRO] else index - 2 if index > QUATTRO else index
		thumbnail.region = Rect2(picture_index % 6 * 256, floori(picture_index / 6.0) * 128,256,128)
		thumbnail.filter_clip = true
		tile.icon = thumbnail
		tile.expand_icon = true
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		if index == VEHICLE_NAMES_ALL.size():
			tile.pressed.connect(func():
				if boating or tram_mode != 0: _select_gallery_activity(1)
				_mark_selected_vehicle(index)
				start_in_excavator = true
				_refresh_ui()
			)
		elif index > VEHICLE_NAMES_ALL.size():
			tile.pressed.connect(_select_gallery_activity.bind(3 if index == VEHICLE_NAMES_ALL.size()+1 else 4))
		else:
			tile.pressed.connect(_on_vehicle_selected.bind(index))
		vehicle_selector.add_child(tile)
		var star := Button.new()
		star.name = "Favorite"
		star.toggle_mode = true
		star.flat = true
		star.button_pressed = vehicle_name in favorites
		star.text = "★" if star.button_pressed else "☆"
		star.accessibility_name = tr("Favorite vehicles") + " · " + tr(tile.text)
		tile.add_child(star)
		star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		star.offset_left = -36
		star.offset_bottom = 36
		star.toggled.connect(func(enabled: bool):
			if enabled: favorites.append(vehicle_name)
			else: favorites.remove_at(favorites.find(vehicle_name))
			star.text = "★" if enabled else "☆"
			_save_preferences()
			_filter_gallery()
		)
	_mark_selected_vehicle(vehicle_index)
	category_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	var category_group := ButtonGroup.new()
	for category: String in GALLERY_GROUPS.keys() + ["Favorite vehicles"]:
		var tab := Button.new()
		tab.text = category
		tab.toggle_mode = true
		tab.button_group = category_group
		tab.button_pressed = category == gallery_category
		var members: Array = GALLERY_GROUPS.get(category, [])
		if category == "Favorite vehicles":
			tab.text = "★"
			tab.tooltip_text = tr(category)
			tab.accessibility_name = tr(category)
		elif members.is_empty():
			tab.icon = ThemeDB.get_default_theme().get_icon("grid", "GraphEdit")
		else:
			var sample := VEHICLE_NAMES_ALL.find(members[0])
			tab.icon = vehicle_selector.get_child(sample).icon
		tab.add_theme_constant_override("icon_max_width",46)
		tab.custom_minimum_size.y = 44
		tab.pressed.connect(func():
			gallery_category = category
			_filter_gallery()
		)
		category_tabs.add_child(tab)
	box.add_child(category_tabs)
	box.add_child(vehicle_selector)
	var player_row := HBoxContainer.new()
	player_row.alignment=BoxContainer.ALIGNMENT_CENTER
	header.add_child(player_row)
	var drivers := ButtonGroup.new()
	for index in 2:
		var driver := _button("Axel" if index == 0 else "Alma", 88)
		driver.toggle_mode = true
		driver.button_group = drivers
		if index == 0:
			var portrait := AtlasTexture.new()
			portrait.atlas = preload("res://branding/rollabout-sv.png")
			portrait.region = Rect2(100, 156, 405, 405)
			portrait.filter_clip = true
			driver.icon = portrait
		else:
			driver.icon = preload("res://branding/driver-alma.png")
		driver.add_theme_constant_override("icon_max_width", 32)
		for state in ["pressed", "hover_pressed"]:
			driver.add_theme_stylebox_override(state, selected_style)
			driver.add_theme_color_override("font_" + state + "_color", Color.WHITE)
		driver.button_pressed = index == int(play_as_alma)
		driver.pressed.connect(func():
			_select_player_profile(index == 1, separate_profiles)
		)
		player_row.add_child(driver)
	var profile_toggle := CheckButton.new()
	profile_toggle.name = "SeparateProfiles"
	profile_toggle.text = "Separate profiles"
	profile_toggle.button_pressed = separate_profiles
	profile_toggle.toggled.connect(func(enabled: bool): _select_player_profile(play_as_alma, enabled))
	header.add_child(profile_toggle)
	var settings_toggle := _button("Settings", 220)
	settings_toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var menu_actions := HBoxContainer.new()
	menu_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(menu_actions)
	var practice_button := _button("Practice driving", 165)
	practice_button.name = "PracticeDriving"
	menu_actions.add_child(practice_button)
	fire_bay_button = _button("Return to bay 711",220)
	box.add_child(fire_bay_button)
	fire_bay_button.pressed.connect(func():
		mode = "playing"
		free_drive = true
		map_goal = FIRE_RETURN_BAY
		_update_mission_marker()
		_update_route_arrows()
		_refresh_ui()
	)
	practice_button.pressed.connect(_start_driving_school)
	practice_button.visibility_changed.connect(func():
		if mode != "menu" and practice_button.visible: practice_button.hide()
	)
	menu_actions.add_child(settings_toggle)
	menu_actions.add_child(start_button)
	_sync_resume_button(menu_actions)
	var quit_button := _button("Quit game · F8" if quit_key == KEY_F8 else "Quit game · F10", 220)
	menu_actions.add_child(quit_button)
	quit_button.pressed.connect(_request_quit)
	var dialog := AcceptDialog.new()
	dialog.name = "GameSettings"
	dialog.wrap_controls = false
	dialog.window_input.connect(_dialog_quit_key.bind(dialog))
	dialog.title = tr("Settings")
	dialog.ok_button_text = tr("Close settings")
	dialog.exclusive = true
	dialog.transient = true
	add_child(dialog)
	var tabs := TabContainer.new()
	dialog.add_child(tabs)
	var pages: Array[VBoxContainer] = []
	for title in ["Graphics", "Sound", "Driving", "World", "Language"]:
		var page := VBoxContainer.new()
		page.alignment = BoxContainer.ALIGNMENT_CENTER
		page.add_theme_constant_override("separation",12)
		var scroll := ScrollContainer.new()
		scroll.follow_focus = true
		tabs.add_child(scroll)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(page)
		tabs.set_tab_title(scroll.get_index(),title)
		if title == "Language":
			tabs.set_tab_icon(scroll.get_index(), preload("res://branding/language-globe.svg"))
		pages.append(page)
	var calm_toggle := CheckButton.new()
	calm_toggle.name = "CalmMode"
	calm_toggle.text = "Calm mode"
	calm_toggle.button_pressed = calm_mode
	calm_toggle.toggled.connect(func(enabled: bool):
		_apply_calm_mode(enabled)
		_update_emergency_lights()
		shops.advance_grill_sign(0, enabled)
		_save_preferences()
	)
	pages[0].add_child(calm_toggle)
	var movement := CheckButton.new()
	movement.name = "NumberMovement"
	movement.text = "Move with 8, 4, 5, 6"
	movement.button_pressed = number_movement
	movement.toggled.connect(func(enabled: bool):
		number_movement = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(movement)
	var recovery := CheckButton.new()
	recovery.name = "BackspaceRecovery"
	recovery.text = "Use Backspace to return to a safe place"
	recovery.button_pressed = recovery_key == KEY_BACKSPACE
	recovery.toggled.connect(func(enabled: bool):
		recovery_key = KEY_BACKSPACE if enabled else KEY_R
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(recovery)
	var jump := CheckButton.new()
	jump.name = "ZeroJump"
	jump.text = "Jump with 0"
	jump.button_pressed = jump_key == KEY_0
	jump.toggled.connect(func(enabled: bool):
		jump_key = KEY_0 if enabled else KEY_E
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(jump)
	var run := CheckButton.new()
	run.name = "CtrlRun"
	run.text = "Run with Ctrl"
	run.button_pressed = ctrl_run
	run.toggled.connect(func(enabled: bool):
		ctrl_run = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(run)
	var help := CheckButton.new()
	help.name = "InsertHelp"
	help.text = "Help at mission stops with Insert"
	help.button_pressed = insert_help
	help.toggled.connect(func(enabled: bool):
		insert_help = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(help)
	var phone_key := CheckButton.new()
	phone_key.name = "PhoneF2"
	phone_key.text = "Open the phone with F2"
	phone_key.button_pressed = phone.toggle_key == KEY_F2
	phone_key.toggled.connect(func(enabled: bool):
		phone.toggle_key = KEY_F2 if enabled else KEY_T
		phone.refresh()
		_save_preferences()
	)
	pages[2].add_child(phone_key)
	var map_binding := CheckButton.new()
	map_binding.name = "MapF11"
	map_binding.text = "Open the town map with F11"
	map_binding.button_pressed = map_key == KEY_F11
	map_binding.toggled.connect(func(enabled: bool):
		map_key = KEY_F11 if enabled else KEY_F5
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(map_binding)
	var vehicle_switches := CheckButton.new()
	vehicle_switches.name = "NumberVehicleSwitches"
	vehicle_switches.text = "Use 1 for warning lights, 2 for vehicle sound and 7 for the spreader"
	vehicle_switches.button_pressed = number_vehicle_switches
	vehicle_switches.toggled.connect(func(enabled: bool):
		number_vehicle_switches = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(vehicle_switches)
	var scooter_binding := CheckButton.new()
	scooter_binding.name = "ScooterF9"
	scooter_binding.text = "Fold or unfold the scooter with F9"
	scooter_binding.button_pressed = scooter_key == KEY_F9
	scooter_binding.toggled.connect(func(enabled: bool):
		scooter_key = KEY_F9 if enabled else KEY_U
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(scooter_binding)
	var seat_binding := CheckButton.new()
	seat_binding.name = "SeatF3"
	seat_binding.text = "Also use F3 to enter or leave vehicles"
	seat_binding.button_pressed = seat_f3
	seat_binding.toggled.connect(func(enabled: bool):
		seat_f3 = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(seat_binding)
	var horn_binding := CheckButton.new()
	horn_binding.name = "HornF4"
	horn_binding.text = "Also use F4 to sound the horn"
	horn_binding.button_pressed = horn_f4
	horn_binding.toggled.connect(func(enabled: bool):
		horn_f4 = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(horn_binding)
	var view_binding := CheckButton.new()
	view_binding.name = "CameraF6"
	view_binding.text = "Also use F6 to change camera view"
	view_binding.button_pressed = camera_f6
	view_binding.toggled.connect(func(enabled: bool):
		camera_f6 = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(view_binding)
	var pause_binding := CheckButton.new()
	pause_binding.name = "PauseF7"
	pause_binding.text = "Also use F7 to pause or resume"
	pause_binding.button_pressed = pause_f7
	pause_binding.toggled.connect(func(enabled: bool):
		pause_f7 = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(pause_binding)
	var quit_binding := CheckButton.new()
	quit_binding.name = "QuitF8"
	quit_binding.text = "Quit with F8"
	quit_binding.button_pressed = quit_key == KEY_F8
	quit_binding.toggled.connect(func(enabled: bool):
		quit_key = KEY_F8 if enabled else KEY_F10
		quit_button.text = "Quit game · F8" if enabled else "Quit game · F10"
		_save_preferences()
	)
	pages[2].add_child(quit_binding)
	var look_binding := CheckButton.new()
	look_binding.name = "LookAroundF12"
	look_binding.text = "Use F12 to look around"
	look_binding.button_pressed = look_key == KEY_F12
	look_binding.toggled.connect(func(enabled: bool):
		look_key = KEY_F12 if enabled else KEY_V
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(look_binding)
	var camera_keys := CheckButton.new()
	camera_keys.name = "NumberCameraHeight"
	camera_keys.text = "Adjust walking camera height with 9 and 3"
	camera_keys.button_pressed = number_camera
	camera_keys.toggled.connect(func(enabled: bool):
		number_camera = enabled
		_save_preferences()
		_refresh_ui()
	)
	pages[2].add_child(camera_keys)
	var reading_size := CheckButton.new()
	reading_size.name = "LargeText"
	reading_size.text = "Larger text"
	reading_size.button_pressed = large_text
	reading_size.toggled.connect(func(enabled: bool):
		large_text = enabled
		_apply_reading_size()
		_save_preferences()
	)
	pages[4].add_child(reading_size)
	var reading_time := CheckButton.new()
	reading_time.name = "ExtraReadingTime"
	reading_time.text = "Show speech bubbles for longer"
	reading_time.button_pressed = extra_reading_time
	reading_time.toggled.connect(func(enabled: bool):
		extra_reading_time = enabled
		_save_preferences()
	)
	pages[4].add_child(reading_time)
	renderer_choices.columns = 2
	renderer_choices.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	renderer_choices.name = "RendererChoice"
	renderer_choices.accessibility_name = tr("Graphics mode")
	var methods := ["gl_compatibility","mobile","forward_plus","fsr2"]
	var captions := ["Compatibility (OpenGL)", "Mobile", "Forward+", "Forward+ · AMD FSR 2.2"]
	var supports_dlss := _engine_supports_dlss_mode() and _active_renderer_reports_dlss()
	if supports_dlss:
		methods.append("dlss")
		captions.append("Forward+ · NVIDIA DLSS (experimental; RTX required)")
	var graphics := ConfigFile.new()
	graphics.load("user://graphics.cfg")
	var selected := str(graphics.get_value("rendering","renderer/rendering_method", RenderingServer.get_current_rendering_method()))
	if selected=="forward_plus":
		var saved_upscaler_mode := int(graphics.get_value("rendering","scaling_3d/mode",0))
		if supports_dlss and saved_upscaler_mode == 5:
			selected="dlss"
		elif saved_upscaler_mode == 2 or "--fsr2" in OS.get_cmdline_user_args():
			selected="fsr2"
	var renderer_note := Label.new()
	renderer_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	renderer_note.text = "Renderer changes apply next time you start the game."
	pages[0].add_child(renderer_choices)
	pages[0].add_child(renderer_note)
	var view_distance := CheckButton.new()
	view_distance.name = "LongViewDistance"
	view_distance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view_distance.text = "Show more of the city in the distance"
	view_distance.button_pressed = long_view_distance
	view_distance.toggled.connect(func(enabled: bool):
		long_view_distance = enabled
		camera.far = 4000.0 if enabled else 220.0
		_save_preferences()
	)
	pages[0].add_child(view_distance)
	var shadow_choice := CheckButton.new()
	shadow_choice.name = "StreetlampShadows"
	shadow_choice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shadow_choice.text = "Streetlamp shadows"
	shadow_choice.button_pressed = streetlamp_shadows
	shadow_choice.toggled.connect(func(enabled: bool):
		streetlamp_shadows = enabled
		for lamp in shadow_streetlamps:
			lamp.shadow_enabled = enabled
		_save_preferences()
	)
	pages[0].add_child(shadow_choice)
	var save_renderer := func(index: int):
		var fsr: bool = methods[index]=="fsr2"
		var dlss: bool = methods[index]=="dlss"
		var uses_forward_plus: bool = fsr or dlss
		graphics.set_value("rendering","renderer/rendering_method","forward_plus" if uses_forward_plus else methods[index])
		graphics.set_value("rendering","scaling_3d/mode",5 if dlss else (2 if fsr else 0))
		graphics.set_value("rendering","scaling_3d/scale",.67 if dlss else (.75 if fsr else 1.0))
		graphics.set_value("rendering","anti_aliasing/quality/msaa_3d",0 if uses_forward_plus else 2)
		if graphics.save("user://graphics.cfg")!=OK:
			renderer_note.text = "Could not save graphics settings."
		elif dlss:
			renderer_note.text = "DLSS is experimental. It needs the NGX-enabled engine and a supported NVIDIA RTX GPU/driver; otherwise it continues without DLSS. Restart to apply."
		else:
			renderer_note.text = "Renderer changes apply next time you start the game."
	var renderer_group := ButtonGroup.new()
	for index in methods.size():
		var tile := _button(captions[index], 180)
		if methods[index] == "dlss":
			tile.text = "NVIDIA DLSS"
			tile.tooltip_text = captions[index]
		var icon := AtlasTexture.new()
		icon.atlas = preload("res://branding/graphics-modes.svg")
		icon.region = Rect2(index*32,0,32,32)
		tile.icon = icon
		tile.button_group = renderer_group
		tile.toggle_mode = true
		tile.button_pressed = index == maxi(0, methods.find(selected))
		tile.pressed.connect(save_renderer.bind(index))
		renderer_choices.add_child(tile)
	settings_toggle.pressed.connect(func():
		dialog.title = tr("Settings")
		dialog.ok_button_text = tr("Close settings")
		dialog.popup_centered_clamped(Vector2i(710, 530), .94)
	)
	dialog.visibility_changed.connect(func():
		if not dialog.visible: settings_toggle.grab_focus()
	)
	var language_row := GridContainer.new()
	language_row.columns = 3
	language_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pages[4].add_child(language_row)
	var language_group := ButtonGroup.new()
	for locale in PackedStringArray([""]) + L10n.locales():
		var catalog := TranslationServer.get_translation_object(locale) if locale != "" else null
		var native_name := catalog.get_message("LANGUAGE_SELF_NAME") if catalog and catalog.locale == locale else &""
		var language := _button(str(native_name) if native_name != &"" else TranslationServer.get_locale_name(locale), 156)
		if locale.is_empty(): language.text = "System language"
		else: language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		language.icon = L10n.media("res://branding/language-%s.svg", locale)
		if language.icon == null:
			language.icon = preload("res://branding/language-globe.svg")
		language.toggle_mode = true
		language.button_group = language_group
		language.button_pressed = locale == language_preference
		language.pressed.connect(func():
			language_preference = locale
			L10n.apply_language(locale)
			dialog.title = tr("Settings")
			dialog.ok_button_text = tr("Close settings")
			_save_preferences()
		)
		language_row.add_child(language)
	var handling := HBoxContainer.new()
	handling.name = "Korlage"
	handling.alignment = BoxContainer.ALIGNMENT_CENTER
	var speed_group := ButtonGroup.new()
	for index in 2:
		var choice := _button("Gentle driving · up to 30 km/h" if index == 0 else "Full speed", 170)
		choice.icon = preload("res://branding/gentle-driving.svg") if index == 0 else preload("res://branding/full-speed.svg")
		choice.toggle_mode = true
		choice.button_group = speed_group
		if index == 0:
			dialog.about_to_popup.connect(func():
				choice.text = "Gentle driving · up to 90 km/h" if vehicle_index == PORSCHE else "Gentle driving · up to 30 km/h"
			)
		choice.button_pressed = gentle_driving == (index == 0)
		choice.pressed.connect(_set_handling.bind(index))
		handling.add_child(choice)
	pages[2].add_child(handling)
	var crashes := CheckButton.new()
	crashes.name = "AllowCrashes"
	crashes.text = "Allow crashes"
	crashes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crashes.button_pressed = allow_crashes
	crashes.toggled.connect(func(enabled: bool):
		allow_crashes = enabled
		_save_preferences()
	)
	pages[2].add_child(crashes)
	var street_names := CheckButton.new()
	street_names.name = "TurnStreetNames"
	street_names.text = "Show street names with turn arrows"
	street_names.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	street_names.button_pressed = show_turn_street
	street_names.toggled.connect(func(enabled: bool):
		show_turn_street = enabled
		_save_preferences()
	)
	pages[2].add_child(street_names)
	var red_lights := CheckButton.new()
	red_lights.text = "Allow driving through red lights"
	red_lights.tooltip_text = "Red means stop. Orange means slow down. Green means go."
	red_lights.accessibility_description = red_lights.tooltip_text
	red_lights.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	red_lights.button_pressed = allow_red_lights
	red_lights.toggled.connect(func(enabled: bool):
		allow_red_lights = enabled
		_save_preferences()
	)
	pages[2].add_child(red_lights)
	var signal_help := Label.new()
	signal_help.text = "Red: stop. Orange: slow down. Green: go."
	signal_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	signal_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pages[2].add_child(signal_help)
	preview_sound_button = _button("Preview vehicle sound", 300)
	preview_sound_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_sound_button.pressed.connect(_preview_sound)
	pages[1].add_child(preview_sound_button)
	var volume_row := HBoxContainer.new()
	volume_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var volume_label := Label.new()
	volume_label.text = "Game volume"
	volume_row.add_child(volume_label)
	var volume := game_volume_slider
	volume.accessibility_name = tr("Game volume")
	volume.custom_minimum_size.x = 180
	volume.max_value = 100
	volume.step = 5
	volume.value = 0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0)) * 100
	volume.value_changed.connect(_set_game_volume)
	volume_row.add_child(volume)
	var traffic_volume_label := Label.new()
	traffic_volume_label.text = "Traffic sirens"
	volume_row.add_child(traffic_volume_label)
	var traffic_volume := traffic_volume_slider
	traffic_volume.accessibility_name = tr("Traffic sirens")
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
	pages[1].add_child(volume_row)
	for channel: String in MIX_CHANNELS + ["Lower radio during speech"]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var caption := Label.new()
		caption.text = channel
		caption.custom_minimum_size.x = 120
		row.add_child(caption)
		var slider := HSlider.new()
		slider.name = channel + "Volume"
		slider.accessibility_name = channel
		slider.custom_minimum_size.x = 180
		slider.step = 5
		slider.value = radio_ducking if channel == "Lower radio during speech" else _channel_volume(channel)
		if channel == "Speech":
			var sample := AudioStreamPlayer.new()
			sample.bus = &"Speech"
			sample.volume_db = greeting_voice.volume_db
			slider.add_child(sample)
			dialog.visibility_changed.connect(func():
				if not dialog.visible:
					sample.stop()
			)
			slider.visibility_changed.connect(func():
				if not slider.is_visible_in_tree():
					sample.stop()
			)
			slider.value_changed.connect(func(percent: float):
				if percent <= 0 or AudioServer.is_bus_mute(0) or not slider.is_visible_in_tree():
					sample.stop()
				elif not sample.playing:
					sample.stream = L10n.media("res://audio/voices/%s_hello.wav", TranslationServer.get_locale())
					if sample.stream:
						sample.play()
			)
		slider.value_changed.connect(func(percent: float):
			if channel == "Lower radio during speech":
				_set_radio_ducking(percent)
			else:
				_apply_channel_volume(channel, percent)
			_save_preferences()
		)
		row.add_child(slider)
		pages[1].add_child(row)
	for index in RADIO_KEYS.size():
		var row := HBoxContainer.new()
		row.name = "RadioToggleKeys" if index == 0 else "RadioNextTrackKeys"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var label := Label.new()
		label.text = ["Radio key", "Next song key"][index]
		row.add_child(label)
		var choices := ButtonGroup.new()
		for code: int in RADIO_KEYS[index]:
			var key_button := Button.new()
			key_button.text = OS.get_keycode_string(code)
			key_button.custom_minimum_size = Vector2(48,44)
			key_button.toggle_mode = true
			key_button.button_group = choices
			key_button.button_pressed = radio_keys[index] == code
			key_button.pressed.connect(func():
				radio_keys[index] = code
				_save_preferences()
				_sync_radio()
			)
			row.add_child(key_button)
		pages[1].add_child(row)
	for own in [false, true]:
		var row := HBoxContainer.new()
		row.name = "OwnBeacon" if own else "TrafficBeacons"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		pages[0].add_child(row)
		var heading := Label.new()
		heading.text = "My vehicle" if own else "Emergency lights in traffic"
		row.add_child(heading)
		var group := ButtonGroup.new()
		var beacon_labels := ["Flashing", "Steady", "Off"]
		for index in (2 if own else 3):
			var tile := _button(beacon_labels[index], 90)
			var icon := AtlasTexture.new()
			icon.atlas = preload("res://branding/beacon-modes.svg")
			icon.region = Rect2(index * 32, 0, 32, 32)
			tile.icon = icon
			tile.toggle_mode = true
			tile.button_group = group
			tile.button_pressed = index == (int(steady_player_lights) if own else traffic_light_mode)
			tile.pressed.connect(func():
				if own:
					steady_player_lights = index == 1
					_update_emergency_lights()
					_save_preferences()
				else:
					_set_traffic_light_mode(index)
			)
			row.add_child(tile)
	var daylight := HBoxContainer.new()
	daylight.name = "TimeChoices"
	daylight.alignment = BoxContainer.ALIGNMENT_CENTER
	var time_group := ButtonGroup.new()
	var time_icons := [preload("res://branding/time-day.svg"), preload("res://branding/time-night.svg"), preload("res://branding/time-cycle.svg")]
	var time_labels := ["Time · Day", "Time · Night", "Time · Day and night"]
	for index in time_labels.size():
		var tile := _button(time_labels[index], 132)
		tile.icon = time_icons[index]
		tile.button_group = time_group
		tile.toggle_mode = true
		tile.button_pressed = time_mode == index
		tile.pressed.connect(func():
			time_mode = index
			_update_daylight(0)
			_save_preferences()
		)
		daylight.add_child(tile)
	pages[3].add_child(daylight)
	for is_season in [true, false]:
		var row := HBoxContainer.new()
		row.name = "SeasonChoices" if is_season else "WeatherChoices"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		pages[3].add_child(row)
		var group := ButtonGroup.new()
		var labels: Array = weather.SEASONS if is_season else weather.CONDITIONS
		for index in labels.size():
			var tile := _button(labels[index], 80)
			var icon := AtlasTexture.new()
			icon.atlas = preload("res://branding/weather-symbols.svg")
			var column := index if is_season or index == 0 else index + 4
			icon.region = Rect2(column * 32, 0, 32, 32)
			tile.icon = icon
			tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.toggle_mode = true
			tile.button_group = group
			tile.button_pressed = index == (weather.season_setting if is_season else weather.weather_setting)
			tile.pressed.connect(func():
				if is_season:
					weather.season_setting = index
					var choices := pages[3].get_node("WeatherChoices")
					choices.get_child(weather.weather_setting).button_pressed = true
				else: weather.weather_setting = index
				_save_preferences()
			)
			row.add_child(tile)

func _button(caption: String, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(width, 48)
	button.add_theme_font_size_override("font_size", 17)
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Color("#172b32"))
	button.add_theme_stylebox_override("normal", _style(Color("#d9e8dc"), 12))
	button.add_theme_stylebox_override("hover", _style(Color("#f3f5e9"), 12))
	button.add_theme_stylebox_override("pressed", _style(Color("#a8cfb1"), 12))
	return button

func _color_action(button: Button, affirmative: bool) -> void:
	var focus_ring := StyleBoxFlat.new()
	focus_ring.draw_center = false
	focus_ring.set_corner_radius_all(12)
	focus_ring.set_border_width_all(3)
	focus_ring.border_color = Color.WHITE
	button.add_theme_stylebox_override("focus",focus_ring)
	var base := Color("#20743f") if affirmative else Color("#ae3339")
	for state in ["normal","hover","pressed","hover_pressed"]:
		var shade := base.lightened(.06) if state == "hover" else base.darkened(.15) if state != "normal" else base
		button.add_theme_stylebox_override(state,_style(shade,12))
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color.WHITE)

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

func _road_obstacles(exclude: Node3D = null) -> Array[AABB]:
	var obstacles := building_bounds.duplicate()
	for i in shops.SHOPS.size():
		obstacles.append(AABB(Vector3(shops.storefront_x(i)-4.2,-1,shops.FRONT_Z-.08),Vector3(8.4,4.7,7.14)))
	obstacles.append_array(roadside_solids)
	obstacles.append_array(tram.car_bounds(exclude))
	if workshop_car.visible: obstacles.append(WORKSHOP_CAR_BOUNDS)
	if casualty.visible and casualty.get_parent()==self:
		obstacles.append(AABB(casualty.position-Vector3(2.1,1,.86),Vector3(4.2,3,1.72)))
	for person in [crossing_pedestrian,passenger,arriving_passenger,waiting_medic,marina_recipient,square_neighbour] + bus_companions + clinic_fire_team:
		if not person.visible: continue
		obstacles.append(AABB(person.position-Vector3(.28,1,.28),Vector3(.56,3,.56)))
	for neighbour in walker_data:
		var person: Node3D = neighbour.actor
		if not person.is_visible_in_tree(): continue
		obstacles.append(AABB(person.position-Vector3(.28,1,.28),Vector3(.56,3,.56)))
		if neighbour.has("pet") and neighbour.pet.is_visible_in_tree():
			obstacles.append(neighbour.pet.global_transform * neighbour.pet.BODY_BOUNDS)
		if neighbour.get("pushing",false):
			var cart_position := person.position-person.basis.z*.73
			obstacles.append(AABB(cart_position-Vector3(.48,1,.32),Vector3(.96,3,.64)))
	for i in parked_cars.size():
		if parked_cars[i].visible:
			obstacles.append(_parked_bounds(i))
	return obstacles

func _recover_road_vehicle() -> bool:
	var obstacles := _road_obstacles()
	for item in traffic_data:
		var traffic_size := _traffic_extent(item)
		var half_size := Vector3(traffic_size.x+1,2,traffic_size.y+.3)
		obstacles.append(AABB(item.actor.position - half_size, half_size * 2))
	var old_pose := ambulance.transform
	ambulance.rotation = Vector3(0, -PI * .5, 0)
	var extent := _player_extent() + Vector2(.4,.4)
	for x: float in [-34, -22, 19, 39, -58, -79, -130, -190]:
		ambulance.position = Vector3(x, _surface_height(x, 2.35), 2.35)
		var clear := true
		for obstacle in obstacles:
			if _vehicle_overlap_depth(obstacle, extent, ambulance.basis) > 0:
				clear = false
				break
		if clear: return true
	ambulance.transform = old_pose
	return false

func _recover_position() -> void:
	snow_slip_angle = 0.0
	if boule_seated:
		_change_seat()
	if shopper_boarding:
		shopper_recovery_requested = true
		return
	walk_jump_left = 0
	bridge_jump_left = 0
	var success := true
	if practice_active:
		if walker.visible:
			success = false
			var door := parked_cars[vehicle_index].to_global(parked_door_offset)
			for site: Vector3 in [door, PRACTICE_START + Vector3.BACK * 3, PRACTICE_START + Vector3.FORWARD * 3]:
				site.y = _foot_height(site.x, site.z)
				if not PRACTICE_YARD.has_point(Vector2(site.x, site.z)): continue
				if scooter.visible:
					if not scooter.can_stand(self, site, walker.rotation.y, walker.scale.y): continue
					site.y += Scooter.DECK_HEIGHT * walker.scale.y
					scooter.speed = 0
					scooter.yaw_input = 0
				elif not _on_foot_clear(site): continue
				walker.position = site
				walking_velocity = Vector3.ZERO
				success = true
				break
		else:
			ambulance.position = PRACTICE_START
			ambulance.rotation.y = -PI * .5
	elif tram_mode > 0:
		tram.stop_at_station(0)
	elif boating:
		launch.transform = Transform3D(Basis.IDENTITY, LAUNCH_BERTH)
		launch_speed = 0
		outboard.rotation.y = 0
	elif operating_excavator:
		var previous_pose := excavator.transform
		success = false
		for spot in [Vector2(-115,43), Vector2(-115,51), Vector2(-108,47), Vector2(-101,51)]:
			excavator.transform = Transform3D(Basis(Vector3.UP, PI*.5), Vector3(spot.x,-.10,spot.y))
			if _crawler_clear():
				building_bounds[excavator_wall] = _crawler_bounds()
				walker.position = excavator.position
				success = true
				break
		if success: crawler_speed = 0.0
		else: excavator.transform = previous_pose
	elif walker.visible or ferry_passenger:
		success = false
		for site in [Vector2(20,6.8), Vector2(-23,-6.8), Vector2(90,-24)]:
			var landing := Vector3(site.x, _foot_height(site.x, site.y), site.y)
			var clear := scooter.can_stand(self, landing, walker.rotation.y, walker.scale.y) if scooter.visible else _on_foot_clear(landing)
			if clear:
				scooter.speed = 0
				scooter.yaw_input = 0
				ferry_passenger = false
				ferry_exit_requested = false
				walker.position = landing
				if scooter.visible:
					walker.position.y += Scooter.DECK_HEIGHT * walker.scale.y
				walking_velocity = Vector3.ZERO
				success = true
				break
	else:
		success = _recover_road_vehicle()
	if success:
		if walker.visible and not scooter.visible and not ferry_passenger and tram_mode == 0 and not operating_excavator and not boating:
			_animate_steps(walker, 0.0, 1.0)
		speed = 0
		steering = 0
		_release_mouse_pedals()
		parked_at_target = 0
		_end_skid()
		_update_camera(0, true)
		_update_route_arrows()
		_refresh_ui()
		_update_entry_button()
	message = "Back in a safe place." if success else "No clear spot yet. Try again in a moment."
	message_timer = 4
	_refresh_status()

func _play_bounds() -> Rect2:
	return PRACTICE_YARD if practice_active else CITY_INTERIOR

func _build_practice_yard() -> void:
	var center := PRACTICE_YARD.get_center()
	_make_driving_surface("Practice meadow", Vector3(120,.30,96),
		Vector3(center.x,-.36,center.y+18), Color.WHITE).material_override = soil_finish
	_make_driving_surface("Practice asphalt", Vector3(64,.2,40), Vector3(center.x,-.1,center.y), Color.WHITE).material_override = road_finish
	for z in [90,128]:
		_make_box("Course edge", Vector3(62,.02,.14), Vector3(center.x,.01,z), Color.WHITE).material_override = marking_finish
	for x in [-129,-67]:
		_make_box("Course edge", Vector3(.14,.02,38), Vector3(x,.01,center.y), Color.WHITE).material_override = marking_finish
	for x in range(-120,-72,6):
		_make_box("Lane marking", Vector3(3,.02,.16), Vector3(x,.01,112), Color.WHITE).material_override = marking_finish
	var stop_line_size := Vector3(.36,.02,5)
	var signal_line_size := Vector3(.26,.02,5)
	# The lesson measures the bumper against the near edge of the paint.
	_make_box("Practice stop line",stop_line_size,Vector3(PRACTICE_STOP_X + stop_line_size.x*.5,.01,PRACTICE_STOP_LANE_Z),Color.WHITE).material_override = marking_finish
	_make_box("Practice signal stop line",signal_line_size,Vector3(PRACTICE_SIGNAL_X + signal_line_size.x*.5,.01,PRACTICE_STOP_LANE_Z),Color.WHITE).material_override = marking_finish
	var post := _signpost(Vector3(PRACTICE_STOP_X,0,PRACTICE_STOP_LANE_Z-3.1),-PI*.5)
	var stop_aluminium := _material(Color("#a4adaf"), .65)
	stop_aluminium.metallic = .42
	var stop_finishes := [stop_aluminium, _material(Color.WHITE), _material(Color("#b52429"))]
	var stop_depths := [.019, .055, .08]
	for layer in stop_finishes.size():
		var plate := MeshInstance3D.new()
		plate.name = "Stop sign layer"
		var mesh := CylinderMesh.new()
		mesh.top_radius = .49 if layer == 2 else .56
		mesh.bottom_radius = mesh.top_radius
		mesh.height = .039 if layer == 0 else .035
		mesh.radial_segments = 8
		plate.mesh = mesh
		plate.rotation.x = PI * .5
		plate.rotate_object_local(Vector3.UP, PI / 8)
		plate.position = Vector3(0, 2.52, stop_depths[layer])
		plate.material_override = stop_finishes[layer]
		post.add_child(plate)
	for rail_y in [2.32, 2.71]:
		_add_sign_mount(post, rail_y, .64, stop_aluminium)
	_road_sign_text(post,"STOP",Vector3(0,2.52,.115),.005,Color.WHITE)

	var cone := Node3D.new()
	cone.name = "Practice cone"
	add_child(cone)
	var rubber := _material(Color("#292925"), .88, false, "rubber")
	_make_box("Weighted foot", Vector3(.44, .045, .44),
		Vector3.UP * .0225, Color.WHITE, false, cone).material_override = rubber
	var seat := CylinderMesh.new()
	seat.top_radius = .179
	seat.bottom_radius = .203
	seat.height = .034
	seat.radial_segments = 24
	seat.material = rubber
	var shoulder := MeshInstance3D.new()
	shoulder.name = "Moulded cone socket"
	shoulder.mesh = seat
	shoulder.position.y = .046
	cone.add_child(shoulder)
	for corner in [Vector2(-.184, -.184), Vector2(.184, -.184), Vector2(-.184, .184), Vector2(.184, .184)]:
		_make_box("Moulded base pad", Vector3(.055, .013, .055),
			Vector3(corner.x, .049, corner.y), Color.WHITE, false, cone).material_override = rubber
	var orange := _material(Color("#ff610d"), .54)
	var white := _material(Color("#fff4de"), .31)
	var levels := [Vector2(.045, .18), Vector2(.21, .137), Vector2(.30, .114),
		Vector2(.36, .099), Vector2(.46, .073), Vector2(.66, .022)]
	for i in levels.size()-1:
		var band := CylinderMesh.new()
		band.bottom_radius = levels[i].y
		band.top_radius = levels[i+1].y
		band.height = levels[i+1].x-levels[i].x
		band.radial_segments = 20
		band.rings = 0
		band.material = white if i in [1, 3] else orange
		var shell := MeshInstance3D.new()
		shell.mesh = band
		shell.position.y = (levels[i].x+levels[i+1].x)*.5
		cone.add_child(shell)
	cone.position = Vector3(-129.5,0,89.5)
	for x in [-129.5,-114,-98,-82,-66.5]:
		for z in [89.5,128.5]:
			var spot := Vector3(x,0,z)
			if spot == cone.position: continue
			var copy := cone.duplicate() as Node3D
			add_child(copy)
			copy.position = spot

	_build_driving_school()

func _build_driving_school() -> void:
	var site := Vector3(-119,0,96)
	var school := Node3D.new()
	school.name = "DrivingSchool"
	school.position = site
	add_child(school)
	var footprint := Vector3(12,3.3,6)
	var wall_finish := _material(Color("#ddd8cd"), .91, false, "mineral")
	wall_finish.uv2_scale = Vector3.ONE * 2.8
	_make_roadside_solid("School building", footprint, Vector3.UP * 1.65,
		Color.WHITE, true, school).material_override = wall_finish
	var plinth_finish := _material(Color("#93928a"), .89, false, "mineral")
	_make_box("Roof flashing",Vector3(12.44,.25,6.43),Vector3.UP*3.37,Color("#293c42"),false,school)
	var roof_metal := _material(Color("#435357"), .63)
	roof_metal.metallic = .38
	var membrane := _material(Color("#414446"), .94, false, "mineral")
	membrane.uv2_scale = Vector3.ONE * 2.2
	_make_box("School roof waterproofing", Vector3(12.13, .018, 6.10),
		Vector3(0, 3.500, 0), Color.WHITE, false, school).material_override = membrane
	for seam in range(-3, 4):
		_make_box("Roof membrane lap seam", Vector3(12.10, .006, .027),
			Vector3(0, 3.509, seam * .84), Color("#34383a"), false, school)
	var gutter_z := -3.274
	for edge in [-1, 1]:
		_make_box("Roof coping longitudinal cap", Vector3(12.46, .046, .16),
			Vector3(0, 3.512, edge * 3.14), Color.WHITE, false, school).material_override = roof_metal
		_make_box("Roof coping end cap", Vector3(.16, .046, 6.12),
			Vector3(edge * 6.15, 3.512, 0), Color.WHITE, false, school).material_override = roof_metal
		for joint_x in [-4.13, -2.07, 0.0, 2.07, 4.13]:
			_make_box("Long roof coping joint cover", Vector3(.041, .009, .166),
				Vector3(joint_x, 3.538, edge * 3.14), Color.WHITE, false, school).material_override = roof_metal
			_make_box("Long roof coping folded joint edge", Vector3(.041, .046, .008),
				Vector3(joint_x, 3.514, edge * 3.221), Color.WHITE, false, school).material_override = roof_metal
		for joint_z in [-1.53, 0.0, 1.53]:
			_make_box("End roof coping joint cover", Vector3(.166, .009, .041),
				Vector3(edge * 6.15, 3.538, joint_z), Color.WHITE, false, school).material_override = roof_metal
		var drain_x: float = edge * 5.58
		var outlet := Vector3(drain_x, 3.226, gutter_z)
		_add_moored_round_fitting(school, "Gutter outlet collar",
			outlet, outlet - Vector3.UP * .054, .063, roof_metal)
		_tube_between(school, outlet - Vector3.UP * .041,
			Vector3(drain_x, 3.06, -3.09), .047, roof_metal)
		_tube_between(school, Vector3(drain_x, 3.06, -3.09),
			Vector3(drain_x, .25, -3.09), .046, roof_metal)
		for strap_y in [.61, 1.64, 2.68]:
			_make_box("Downpipe bracket wall plate", Vector3(.145, .059, .021),
				Vector3(drain_x, strap_y, -3.011), Color.WHITE, false, school).material_override = roof_metal
			_make_box("Downpipe bracket stand-off", Vector3(.042, .024, .064),
				Vector3(drain_x, strap_y, -3.046), Color.WHITE, false, school).material_override = roof_metal
			_add_moored_round_fitting(school, "Downpipe collar",
				Vector3(drain_x, strap_y - .011, -3.09),
				Vector3(drain_x, strap_y + .011, -3.09), .052, roof_metal)
			for tab_side in [-1, 1]:
				_add_moored_round_fitting(school, "Downpipe bracket screw",
					Vector3(drain_x + tab_side * .054, strap_y, -3.019),
					Vector3(drain_x + tab_side * .054, strap_y, -3.026), .008, roof_metal)
		var elbow := Vector3(drain_x, .25, -3.09)
		var mouth := Vector3(drain_x, .132, -3.27)
		var outlet_axis := (mouth - elbow).normalized()
		var outlet_shell := CylinderMesh.new()
		outlet_shell.top_radius = .047
		outlet_shell.bottom_radius = .047
		outlet_shell.height = elbow.distance_to(mouth)
		outlet_shell.radial_segments = 24
		outlet_shell.cap_top = false
		outlet_shell.cap_bottom = false
		var spout_finish := roof_metal.duplicate() as StandardMaterial3D
		spout_finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		var spout := MeshInstance3D.new()
		spout.name = "Open downpipe spout"
		spout.mesh = outlet_shell
		spout.material_override = spout_finish
		spout.position = (elbow + mouth) * .5
		spout.quaternion = Quaternion(Vector3.UP, outlet_axis)
		school.add_child(spout)
		var rolled_rim := TorusMesh.new()
		rolled_rim.inner_radius = .042
		rolled_rim.outer_radius = .049
		rolled_rim.rings = 24
		rolled_rim.ring_segments = 8
		var outlet_rim := MeshInstance3D.new()
		outlet_rim.name = "Rolled downpipe outlet rim"
		outlet_rim.mesh = rolled_rim
		outlet_rim.material_override = roof_metal
		outlet_rim.position = mouth
		outlet_rim.quaternion = spout.quaternion
		school.add_child(outlet_rim)
		var splash := _make_box("Downpipe splash block", Vector3(.29, .039, .57),
			Vector3(drain_x, .040, -3.55), Color("#969488"), false, school)
		splash.rotation.x = -.055
		for rim_side in [-1, 1]:
			_make_box("Splash block channel edge", Vector3(.039, .025, .55),
				Vector3(rim_side * .118, .030, 0), Color("#969488"), false, splash)
	_make_box("Rear roof gutter bottom", Vector3(12.24, .018, .162),
		Vector3(0, 3.235, gutter_z), Color.WHITE, false, school).material_override = roof_metal
	for lip_side in [-1, 1]:
		_make_box("Rear roof gutter side", Vector3(12.24, .097, .018),
			Vector3(0, 3.282, gutter_z + lip_side * .074),
			Color.WHITE, false, school).material_override = roof_metal
		_make_box("Rear roof gutter end plate", Vector3(.025, .106, .166),
			Vector3(lip_side * 6.11, 3.28, gutter_z),
			Color.WHITE, false, school).material_override = roof_metal
	for support in range(-5, 6):
		_make_box("Rear roof gutter support strap", Vector3(.041, .020, .265),
			Vector3(support * 1.09, 3.222, -3.224),
			Color.WHITE, false, school).material_override = roof_metal
		_make_box("Rear roof gutter strap return", Vector3(.041, .078, .014),
			Vector3(support * 1.09, 3.26, gutter_z - .086),
			Color.WHITE, false, school).material_override = roof_metal
	for vent_at in [Vector3(-2.70, 3.495, -.87), Vector3(2.41, 3.495, -1.31)]:
		_make_box("Roof vent flashing", Vector3(.66, .038, .55),
			vent_at, Color.WHITE, false, school).material_override = roof_metal
		_make_box("Roof vent riser", Vector3(.48, .226, .36),
			vent_at + Vector3.UP * .123, Color.WHITE, false, school).material_override = roof_metal
		_make_box("Roof vent recessed grille", Vector3(.406, .105, .304),
			vent_at + Vector3.UP * .279, Color("#202b2f"), false, school)
		for blade in 3:
			_make_box("Roof vent grille slat", Vector3(.482, .012, .362),
				vent_at + Vector3.UP * (.242 + blade * .035), Color.WHITE, false, school).material_override = roof_metal
		var hood := _make_box("Roof vent rain hood", Vector3(.59, .055, .462),
			vent_at + Vector3.UP * .345, Color.WHITE, false, school)
		hood.rotation.x = .041
		hood.material_override = roof_metal
	var service_color := Color("#46595d")
	_make_box("Rear plinth", Vector3(12.03, .29, .043),
		Vector3(0, .145, -3.007), Color.WHITE, false, school).material_override = plinth_finish
	_make_box("Service door frame", Vector3(1.095, 2.18, .066),
		Vector3(-2.66, 1.13, -3.036), service_color.darkened(.22), false, school)
	_make_box("Service door leaf", Vector3(.974, 2.052, .031),
		Vector3(-2.66, 1.13, -3.072), service_color, false, school)
	var service_hardware := _material(Color("#a4afb0"), .43)
	service_hardware.metallic = .55
	_make_box("Service door kick plate", Vector3(.86, .208, .015),
		Vector3(-2.66, .255, -3.093), Color.WHITE, false, school).material_override = service_hardware
	_make_box("Service door lock escutcheon", Vector3(.068, .174, .019),
		Vector3(-2.36, 1.02, -3.098), Color.WHITE, false, school).material_override = service_hardware
	_add_moored_round_fitting(school, "Service door lever spindle", Vector3(-2.36, 1.056, -3.100),
		Vector3(-2.36, 1.056, -3.154), .014, service_hardware)
	_add_moored_round_fitting(school, "Service door lever", Vector3(-2.36, 1.056, -3.154),
		Vector3(-2.476, 1.056, -3.154), .013, service_hardware)
	for hinge_y in [.48, 1.16, 1.86]:
		_add_moored_round_fitting(school, "Service door hinge barrel",
			Vector3(-3.152, hinge_y - .043, -3.106), Vector3(-3.152, hinge_y + .043, -3.106),
			.016, service_hardware)
	_make_box("Service door threshold", Vector3(1.07, .063, .20),
		Vector3(-2.66, .066, -3.082), Color("#a4a49a"), false, school)
	var service_paving := _material(Color("#aaa69b"), .89)
	for slab in 16:
		_make_box("Rear service paving slab", Vector3(.744, .032, .88),
			Vector3((slab - 7.5) * .75, .010, -3.452), Color.WHITE, false, school).material_override = service_paving
	var drain_at := Vector3(-2.66, .005, -3.962)
	_make_box("Service landing drain recess", Vector3(1.14, .033, .14),
		drain_at, Color("#263034"), false, school)
	for slot in 18:
		_make_box("Service landing drain grate bar", Vector3(.026, .012, .127),
			drain_at + Vector3((slot - 8.5) * .062, .018, 0),
			Color.WHITE, false, school).material_override = roof_metal
	for vent_x in [1.22, 3.64]:
		_make_box("Rear ventilation frame", Vector3(.76, .48, .055),
			Vector3(vent_x, 2.37, -3.029), service_color, false, school)
		_make_box("Rear ventilation recess", Vector3(.66, .385, .016),
			Vector3(vent_x, 2.37, -3.063), Color("#283438"), false, school)
		var vent_cap := _make_box("Rear ventilation drip flashing", Vector3(.80, .022, .133),
			Vector3(vent_x, 2.629, -3.057), Color.WHITE, false, school)
		vent_cap.rotation.x = -.14
		vent_cap.material_override = roof_metal
		for edge in [-1, 1]:
			_make_box("Rear ventilation edge trim", Vector3(.043, .441, .044),
				Vector3(vent_x + edge * .353, 2.37, -3.070), Color.WHITE, false, school).material_override = roof_metal
			for fastener_y in [2.178, 2.562]:
				_add_moored_round_fitting(school, "Rear ventilation frame fastener",
					Vector3(vent_x + edge * .353, fastener_y, -3.092),
					Vector3(vent_x + edge * .353, fastener_y, -3.097), .009, service_hardware)
		for slat in 5:
			var louvre := _make_box("Rear ventilation louvre", Vector3(.665, .034, .046),
				Vector3(vent_x, 2.229 + slat * .071, -3.081), service_color, false, school)
			louvre.rotation.x = -.35
	_make_box("Entrance canopy",Vector3(5.0,.16,1.40),Vector3(0,2.72,3.59),Color("#225c63"),false,school)
	_make_box("Canopy folded front edge", Vector3(5.02, .059, .054),
		Vector3(0, 2.663, 4.288), Color.WHITE, false, school).material_override = roof_metal
	for bracket_x in [-1.96, 1.96]:
		_make_box("Canopy wall plate", Vector3(.125, .40, .056),
			Vector3(bracket_x, 2.471, 3.029), Color.WHITE, false, school).material_override = roof_metal
		_tube_between(school, Vector3(bracket_x, 2.324, 3.053),
			Vector3(bracket_x, 2.635, 4.124), .029, roof_metal)
		_make_box("Canopy cross bracket", Vector3(.076, .053, 1.24),
			Vector3(bracket_x, 2.622, 3.64), Color.WHITE, false, school).material_override = roof_metal
	for seam in range(-2, 3):
		_make_box("Canopy standing seam", Vector3(.019, .023, 1.37),
			Vector3(seam * .90, 2.802, 3.586), Color.WHITE, false, school).material_override = roof_metal
	var lamp_at := Vector3(0, 2.61, 3.66)
	_make_box("School entrance light housing", Vector3(.80, .052, .27),
		lamp_at + Vector3.UP * .019, Color.WHITE, false, school).material_override = roof_metal
	for end in [-1, 1]:
		_make_box("School entrance light end cap", Vector3(.038, .054, .246),
			lamp_at + Vector3(end * .382, .004, 0), Color.WHITE, false, school).material_override = roof_metal
		_make_box("School entrance light lens rim", Vector3(.746, .024, .025),
			lamp_at + Vector3(0, -.014, end * .106), Color.WHITE, false, school).material_override = roof_metal
	var lamp := _add_entry_light(site + lamp_at, Vector3(.72,.05,.19), 4.5)
	lamp.name = "Driving school entrance light"
	lamp.look_at(site + Vector3(0,0,3.35), Vector3.BACK)
	_make_box("Entrance frame",Vector3(1.56,2.34,.14),Vector3(0,1.19,3.035),Color("#263e43"),false,school)
	var door_metal := _material(Color("#92a1a4"), .48)
	door_metal.metallic = .56
	for side in [-1, 1]:
		var door_x: float = side * .345
		_make_box("Entrance door leaf", Vector3(.671, 2.15, .048),
			Vector3(door_x, 1.145, 3.12), Color("#344a50"), false, school)
		_make_box("Entrance glazing", Vector3(.566, 1.67, .023),
			Vector3(door_x, 1.33, 3.15), Color("#526d76"), false, school)
		var handle_x: float = side * .085
		for support_y in [1.02, 1.26]:
			_make_box("Door handle mount", Vector3(.027, .027, .071),
				Vector3(handle_x, support_y, 3.181), Color.WHITE, false, school).material_override = door_metal
		_add_moored_round_fitting(school, "Entrance pull handle",
			Vector3(handle_x, 1.017, 3.218), Vector3(handle_x, 1.264, 3.218), .014, door_metal)
	_make_box("Entrance aluminium threshold", Vector3(1.49, .044, .23),
		Vector3(0, .036, 3.14), Color.WHITE, false, school).material_override = door_metal
	var classroom_glass := _material(Color("#566e73"), .27)
	for window_x in [-3.55, 3.55]:
		_add_school_window(school, Vector3(window_x, 1.71, 3), 0.0, classroom_glass, door_metal)
	for side in [-1, 1]:
		_add_school_window(school, Vector3(side * 6.0, 1.82, -.73),
			side * PI * .5, classroom_glass, door_metal)
		_make_box("School end wall plinth", Vector3(.043, .29, 6.01),
			Vector3(side * 6.009, .145, 0), Color.WHITE, false, school).material_override = plinth_finish
		_make_box("School front plinth", Vector3(5.24, .29, .043),
			Vector3(side * 3.399, .145, 3.007), Color.WHITE, false, school).material_override = plinth_finish
	for mount_x in [-2.18, 0.0, 2.18]:
		_make_box("School sign canopy bracket", Vector3(.144, .33, .18),
			Vector3(mount_x, 2.85, 4.18), Color.WHITE, false, school).material_override = roof_metal
	var fascia := _make_box("School sign board",Vector3(5.10,.62,.12),Vector3(0,3.04,4.32),Color("#225c63"),false,school)
	for edge in [-1, 1]:
		_make_box("School sign horizontal trim", Vector3(5.12, .028, .129),
			Vector3(0, edge * .307, 0), Color.WHITE, false, fascia).material_override = roof_metal
		_make_box("School sign end cap", Vector3(.028, .59, .129),
			Vector3(edge * 2.544, 0, 0), Color.WHITE, false, fascia).material_override = roof_metal
	var sign := _station_sign("Driving school",Vector3(0,0,.07),.009,Color("#fff1c8"),0,fascia)
	_size_world_sign(sign,4.84)
	_make_driving_surface("School entrance pavement", Vector3(12, .14, 2.5),
		site + Vector3(0, -.068, 4.26), Color.WHITE).material_override = quay_finish
	var edging_finish := _material(Color("#85837b"), .9, false, "mineral")
	for piece in 20:
		_make_box("School pavement front edging stone", Vector3(.594, .038, .145),
			Vector3((piece - 9.5) * .60, -.011, 5.434), Color.WHITE, false, school).material_override = edging_finish
	for side in [-1, 1]:
		for piece in 4:
			_make_box("School pavement side edging stone", Vector3(.145, .038, .58),
				Vector3(side * 5.924, -.011, 3.308 + piece * .586), Color.WHITE, false, school).material_override = edging_finish
	_make_box("Entrance mat surround", Vector3(1.53, .022, .69),
		Vector3(0, .011, 3.58), Color.WHITE, false, school).material_override = door_metal
	_make_box("Entrance rubber mat", Vector3(1.47, .017, .63),
		Vector3(0, .020, 3.58), Color("#252927"), false, school)
	for rib in 10:
		_make_box("Entrance mat rib", Vector3(1.44, .006, .016),
			Vector3(0, .029, 3.305 + rib * .061), Color("#494d47"), false, school)
	_speed_sign(Vector3(-110,0,103.5),-PI*.5,PRACTICE_SPEED_LIMIT)

func _add_school_window(school: Node3D, at: Vector3, yaw: float, glazing: Material, metal: Material) -> void:
	var window := _make_box("Window frame", Vector3(3.25, 1.55, .13),
		at + Vector3.BACK.rotated(Vector3.UP, yaw) * .03, Color("#263e43"), false, school)
	window.rotation.y = yaw
	for offset in [-.765, .765]:
		_make_box("Classroom window sash", Vector3(1.50, 1.37, .055),
			Vector3(offset, 0, .075), Color("#3c5257"), false, window)
		_make_box("Classroom glazing", Vector3(1.408, 1.272, .018),
			Vector3(offset, 0, .105), Color.WHITE, false, window).material_override = glazing
	var sill := _make_box("Classroom window sill flashing", Vector3(3.32, .045, .242),
		Vector3(0, -.776, .056), Color.WHITE, false, window)
	sill.rotation.x = .084
	sill.material_override = metal
	_make_box("Window sill drip edge", Vector3(3.32, .025, .020),
		Vector3(0, -.803, .17), Color("#647477"), false, window)
	for side in [-1, 1]:
		_make_box("Window sill folded end", Vector3(.019, .035, .223),
			Vector3(side * 1.642, .034, 0), Color.WHITE, false, sill).material_override = metal
	var head_flashing := _make_box("Classroom window head flashing", Vector3(3.32, .035, .177),
		Vector3(0, .804, .048), Color.WHITE, false, window)
	head_flashing.rotation.x = .084
	head_flashing.material_override = metal
	_make_box("Window head folded drip edge", Vector3(3.32, .036, .018),
		Vector3(0, .776, .133), Color.WHITE, false, window).material_override = metal

func _add_school_car_sign(model: Node3D) -> void:
	var mount := Node3D.new()
	mount.name = "SchoolCarSign"
	mount.position = Vector3(0, 1.78, .14)
	model.add_child(mount)
	_make_box("Roof sign crossbar", Vector3(.82, .032, .285),
		Vector3.UP * .010, Color("#3a4548"), false, mount)
	for side in [-1, 1]:
		var foot_x: float = side * .284
		_make_box("Roof sign rubber pad", Vector3(.193, .025, .298),
			Vector3(foot_x, -.041, 0), Color("#242a2b"), false, mount)
		_make_box("Roof sign mounting foot", Vector3(.13, .048, .126),
			Vector3(foot_x, -.024, 0), Color("#58676b"), false, mount)
		for end in [-1, 1]:
			_make_box("Roof sign foot bolt", Vector3(.027, .016, .027),
				Vector3(foot_x, -.018, end * .101), Color("#a2adae"), false, mount)
	var hull := SurfaceTool.new()
	hull.begin(Mesh.PRIMITIVE_TRIANGLES)
	hull.set_smooth_group(-1)
	hull.set_material(_material(Color("#eac34e"), .54))
	var perimeter := [
		Vector3(-.368, 0, .13), Vector3(.368, 0, .13),
		Vector3(.40, 0, .098), Vector3(.40, 0, -.098),
		Vector3(.368, 0, -.13), Vector3(-.368, 0, -.13),
		Vector3(-.40, 0, -.098), Vector3(-.40, 0, .098),
	]
	var half_height := Vector3.UP * .12
	for i in perimeter.size():
		var corner: Vector3 = perimeter[i]
		var next: Vector3 = perimeter[(i + 1) % perimeter.size()]
		for vertex: Vector3 in [corner - half_height, corner + half_height, next - half_height,
				next - half_height, corner + half_height, next + half_height,
				half_height, next + half_height, corner + half_height,
				-half_height, corner - half_height, next - half_height]:
			hull.add_vertex(vertex)
	hull.generate_normals()
	var plate := MeshInstance3D.new()
	plate.name = "Driving school roof sign"
	plate.mesh = hull.commit()
	plate.position.y = .134
	mount.add_child(plate)
	for side in [-1, 1]:
		_make_box("Roof sign face panel", Vector3(.728, .173, .012),
			Vector3(0, 0, side * .127), Color("#ffde62"), false, plate)
		var face := _station_sign("Driving school", Vector3(0, 0, side * .135),
			.0018, Color("#253031"), PI if side == -1 else 0.0, plate)
		_size_world_sign(face, .692)
	var learner_plate := _make_box("Rear learner plate backing", Vector3(.42, .116, .029),
		Vector3(0, -.390, -2.349), Color("#333b3b"), false, mount)
	learner_plate.rotation.x = .86
	for anchor_x in [-.148, .148]:
		_make_box("Rear learner plate rubber mount", Vector3(.067, .044, .046),
			Vector3(anchor_x, 0, .032), Color("#252c2c"), false, learner_plate)
	_make_box("Rear learner plate white border", Vector3(.403, .102, .014),
		Vector3(0, 0, -.020), Color("#f2f1dd"), false, learner_plate)
	_make_box("Rear learner plate red face", Vector3(.382, .083, .010),
		Vector3(0, 0, -.031), Color("#b9232e"), false, learner_plate)
	var learner_text := _station_sign("Practice driving", Vector3(0, 0, -.037),
		.00095, Color.WHITE, PI, learner_plate)
	_size_world_sign(learner_text, .351)
	mount.hide()

func _start_driving_school() -> void:
	if mode != "menu": return
	_on_vehicle_selected(SCHOOL_CAR)
	_start_practice()

func _track_practice_speed(forward_distance: float) -> void:
	if not practice_active or vehicle_index != SCHOOL_CAR or practice_speed_distance >= PRACTICE_SPEED_DISTANCE:
		return
	if absf(speed)*3.6 > PRACTICE_SPEED_LIMIT:
		practice_speed_distance = 0.0
	elif speed > 0.0:
		practice_speed_distance += maxf(0.0,forward_distance)

func _track_practice_stop(after: Vector3, front_reach: float, heading_x: float) -> void:
	if not practice_active or vehicle_index != SCHOOL_CAR or practice_stop_complete or practice_speed_distance < PRACTICE_SPEED_DISTANCE:
		return
	var gap := PRACTICE_STOP_X - after.x - front_reach
	if gap >= 1.5:
		practice_stop_missed = false
	if gap < 0.0:
		practice_stop_missed = true
	elif not practice_stop_missed and gap <= 1.0 and heading_x >= .85 and absf(after.z-PRACTICE_STOP_LANE_Z) <= 2.25 and is_zero_approx(speed):
		practice_stop_complete = true

func _set_practice_signal(phase: int) -> void:
	practice_signal_phase = phase
	for index in practice_signal_lamps.size():
		practice_signal_lamps[index].visible = index == phase

func _track_practice_signal(before: Vector3, after: Vector3, front_reach: float, heading_x: float, delta: float) -> void:
	if not practice_active or vehicle_index != SCHOOL_CAR or not practice_stop_complete or practice_signal_complete:
		return
	var gap := PRACTICE_SIGNAL_X - after.x - front_reach
	if gap >= 3.0:
		practice_signal_missed = false
		practice_signal_waited = false
		practice_signal_elapsed = 0.0
		_set_practice_signal(0)
	var in_approach_lane := heading_x >= .85 and absf(after.z-PRACTICE_STOP_LANE_Z) <= 2.25
	if gap < 0.0:
		practice_signal_complete = not practice_signal_missed and in_approach_lane and before.x+front_reach <= PRACTICE_SIGNAL_X and practice_signal_phase == 2 and practice_signal_waited
		practice_signal_missed = not practice_signal_complete
		return
	if not in_approach_lane:
		return
	if gap <= 1.0 and is_zero_approx(speed) and practice_signal_phase == 0:
		practice_signal_waited = true
	if practice_signal_waited:
		practice_signal_elapsed = fmod(practice_signal_elapsed+delta,9.0)
		_set_practice_signal(0 if practice_signal_elapsed < 2.0 else 2 if practice_signal_elapsed < 8.0 else 1)

func _start_practice() -> void:
	if mode != "menu": return
	if boating or tram_mode != 0 or start_in_excavator:
		_on_vehicle_selected(3)
	_start_game()
	practice_active = true
	ambulance.position = PRACTICE_START
	_refresh_ui()
	_update_camera(0, true)

func _leave_practice() -> void:
	if shopper_boarding or not leave_practice_button.visible: return
	if not _recover_road_vehicle(): return
	practice_active = false
	if walker.visible:
		parked_cars[vehicle_index].transform = ambulance.transform
		walker.position = ambulance.to_global(parked_door_offset)
		walker.position.y = _foot_height(walker.position.x, walker.position.z)
		walking_velocity = Vector3.ZERO
		if scooter.visible and scooter.can_stand(self, walker.position, walker.rotation.y, walker.scale.y):
			walker.position.y += Scooter.DECK_HEIGHT * walker.scale.y
			scooter.speed = 0
			scooter.yaw_input = 0
		elif scooter.visible or not _on_foot_clear(walker.position):
			_recover_position()
	else:
		speed = 0
		steering = 0
		_release_mouse_pedals()
		_end_skid()
	_update_camera(0,true)
	_update_route_arrows()
	_refresh_ui()
	_save_checkpoint()

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

func _resume_road_checkpoint() -> void:
	dax.order_pending = false
	map_goal = Vector3.INF
	if mode != "menu" or road_checkpoint.is_empty():
		return
	var sand: Variant = road_checkpoint.get("sand", Vector2i(excavation_sand.LOADS,0))
	if sand is Vector2i and sand.x >= 0 and sand.y >= 0 and sand.x + sand.y in [excavation_sand.LOADS,excavation_sand.LOADS-1]:
		excavation_sand.remaining = sand.x
		excavation_sand.delivered = sand.y
		excavation_sand.refresh()
	restoring_radio = true
	_on_vehicle_selected(road_checkpoint.vehicle)
	if road_checkpoint.has("tram"):
		_select_gallery_activity(road_checkpoint.tram.mode + 1)
	elif road_checkpoint.has("launch_transform"):
		_select_gallery_activity(4)
	elif road_checkpoint.has("excavator"):
		var pose: Dictionary = road_checkpoint.excavator
		var parked_pose := excavator.transform
		excavator.transform = pose.base
		if not _crawler_clear():
			excavator.transform = parked_pose
		cab_turntable.rotation.y = pose.slew
		boom_joint.rotation.x = pose.arm.x
		stick_joint.rotation.x = pose.arm.y
		bucket_joint.rotation.x = pose.arm.z
		building_bounds[excavator_wall] = _crawler_bounds()
		start_in_excavator = true
	_start_game()
	if boating:
		launch.transform = road_checkpoint.launch_transform
	var saved_position: Vector3 = road_checkpoint.position
	var saved_point := Vector2(saved_position.x, saved_position.z)
	practice_active = road_checkpoint.get("practice", PRACTICE_YARD.has_point(saved_point))
	if practice_active and vehicle_index == SCHOOL_CAR and road_checkpoint.has("lesson"):
		var lesson: Dictionary = road_checkpoint.lesson
		practice_speed_distance = lesson.speed_distance
		practice_stop_complete = lesson.stop_complete
		practice_signal_complete = lesson.signal_complete
	var bounds := PRACTICE_YARD if practice_active else CITY_INTERIOR
	if bounds.has_point(saved_point):
		ambulance.rotation.y = road_checkpoint.heading
		var extent := _player_extent()
		var center := saved_point.clamp(bounds.position + extent, bounds.end - extent)
		if center != saved_point:
			saved_position = Vector3(center.x, _surface_height(center.x, center.y), center.y)
		if OPEN_WATER.any(func(span: Vector2): return _shore_overlap(span, saved_position, extent) > .01):
			_recover_road_vehicle()
		else:
			if not practice_active and _on_south_bridge(saved_position):
				saved_position.y = _surface_height(saved_position.x, saved_position.z)
			ambulance.global_position = saved_position
	elif practice_active:
		ambulance.position = PRACTICE_START
		ambulance.rotation.y = -PI * .5
	else:
		# If every recovery spot is occupied, keep the normal starting pose.
		_recover_road_vehicle()
	free_drive = road_checkpoint.free_drive
	var saved_goal: Variant = road_checkpoint.get("map_goal")
	if free_drive and saved_goal is Vector3 and saved_goal.is_finite():
		map_goal = saved_goal
	mission_index = road_checkpoint.mission
	recovery_leg = road_checkpoint.recovery
	taxi_leg = road_checkpoint.taxi
	bus_leg = road_checkpoint.bus
	if vehicle_index == BUS and not free_drive and bus_leg % 2 == 1 and road_checkpoint.get("bus_stop_requested", false):
		bus_press_time = 1.2
		_update_bus_stop_request(0.0)
	if vehicle_index == BUS and not free_drive and not road_checkpoint.has("walk_position") and road_checkpoint.get("bus_departure_pending", false):
		bus_departure_pending = true
		bus_merge_time = BUS_MERGE_SECONDS
	vehicle_progress = road_checkpoint.progress.duplicate()
	if tram_mode != 0:
		var trip: Dictionary = road_checkpoint.tram
		tram_driver_exit_requested = tram_mode == 2 and trip.get("driver_exit_requested", false)
		tram.stop_at_station(posmod(trip.next_stop - 1, tram.stops.size()))
		tram.distance = trip.distance
		tram.dwell = trip.dwell
		tram.velocity = trip.get("velocity",0.0) if tram.dwell <= 0 else 0.0
		tram.place_sections()
		tram.advance(0, tram_mode == 2, false, false)
		if trip.parked:
			parked_cars[vehicle_index].transform = ambulance.transform
			parked_cars[vehicle_index].show()
			ambulance.hide()
		if tram_mode == 1:
			listener.reparent(tram.sections[1], false)
			listener.position = Vector3.UP * 1.6
	if road_checkpoint.has("walk_position"):
		parked_cars[vehicle_index].transform = ambulance.transform
		parked_cars[vehicle_index].show()
		ambulance.hide()
		walker.position = road_checkpoint.walk_position
		if not practice_active and _on_south_bridge(walker.position):
			walker.position.y = _foot_height(walker.position.x, walker.position.z)
		walker.rotation.y = road_checkpoint.walk_heading
		walk_basis = walker.basis
		carried_parcel_leg = road_checkpoint.get("carried_parcel_leg",mission_index)
		parked_door_offset = road_checkpoint.door_offset
		walker.show()
		listener.reparent(walker, false)
		listener.transform = Transform3D(Basis.IDENTITY, Vector3.UP * 1.6)
		if road_checkpoint.has("ferry_time"):
			ferry_passenger = true
			ferry_exit_requested = road_checkpoint.get("exit_at_landing", false)
			wave_time = road_checkpoint.ferry_time
			ferry_delay = 0.0
			ferry_speed_factor = 1.0
			_update_moorings(0)
		elif not bounds.grow(-.25).has_point(Vector2(walker.position.x, walker.position.z)):
			# Choose recovery sites in the saved vehicle's play area.
			walker.position = ambulance.position
			_recover_position()
			if road_checkpoint.get("scooter", false):
				_toggle_scooter()
		elif road_checkpoint.get("scooter", false):
			walker.position.y = _foot_height(walker.position.x, walker.position.z)
			_toggle_scooter()
		elif road_checkpoint.get("boule_bench",false) or (walker.position.y < BOULE_CENTRE.y and Vector2(walker.position.x,walker.position.z).is_equal_approx(Vector2(BOULE_BENCH.x,BOULE_BENCH.z))):
			# Earlier saves on this bench stored only the lowered seated position.
			_set_boule_seated(true)
	cockpit_view = road_checkpoint.get("cockpit_view", false) and vehicle_index in DRIVER_VIEW_VEHICLES and not walker.visible and not boating and tram_mode == 0 and not operating_excavator
	if road_checkpoint.has("quests"):
		var quests: Dictionary = road_checkpoint.quests
		shoe_quest = quests.shoe
		cat_quest = quests.cat
		shoe_owner.position = quests.shoe_owner
		cat_owner.position = quests.cat_owner
		lost_cat.position = quests.lost_cat
		var stages: Variant = quests.get("pets",PackedInt32Array([0,0]))
		if stages is PackedInt32Array and stages.size() == 2:
			pet_stages = stages.duplicate()
		komodo.visible = quests.get("komodo_present",komodo.visible) or pet_stages[1] == FootQuest.SEARCHING
		dog_ball.visible = pet_stages[0] == FootQuest.SEARCHING
		lizard_mat.visible = pet_stages[1] == FootQuest.FINISHED
		lost_shoe.visible = shoe_quest in [FootQuest.SEARCHING, FootQuest.RETURNING]
		if shoe_quest == FootQuest.RETURNING:
			_hold_lost_shoe()
		socked_foot.visible = shoe_quest != FootQuest.FINISHED
		returned_trainer.visible = shoe_quest == FootQuest.FINISHED
	var saved_hose: float = road_checkpoint.get("hose_seconds", -1.0)
	var resume_hose := vehicle_index == 2 and mission_index == 2 and saved_hose >= 0.0 and _at_target()
	hose_seconds = saved_hose if resume_hose else 0.0
	practice_hose.visible = resume_hose
	practice_spray.emitting = resume_hose
	release_pedal_keys = _keyboard_pedal_pressed()
	_sync_radio()
	_update_route_arrows()

	_update_mission_marker()
	_update_camera(0.0, true)
	_refresh_ui()
	if road_checkpoint.has("radio") and radio_button.visible:
		var station: Dictionary = road_checkpoint.radio
		radio_enabled = station.enabled
		if station.track in radio_tracks:
			radio_bag.clear()
			for track: String in station.get("remaining", PackedStringArray()):
				if track != station.track and track in radio_tracks and track not in radio_bag:
					radio_bag.append(track)
			radio_track = station.track
			if radio_enabled:
				_play_radio_track(station.track, station.position)
	restoring_radio = false
	_sync_radio()

func _start_game() -> void:
	dax.order_pending = false
	radio_vehicle = ""
	radio.stop()
	hose_seconds = 0.0
	practice_hose.hide()
	practice_spray.emitting = false
	cockpit_view = false
	cockpit_look = Vector2.ZERO
	practice_active = false
	practice_speed_distance = 0.0
	practice_stop_complete = false
	practice_stop_missed = false
	practice_signal_elapsed = 0.0
	practice_signal_waited = false
	practice_signal_missed = false
	practice_signal_complete = false
	_set_practice_signal(0)
	boule_seated = false
	boule_choices.hide()
	boule_guest_turn = false
	boule_join_requested = false
	boule_pause_focus = null
	reward_badge.hide()
	map_goal = Vector3.INF
	komodo.visible = pet_stages[1] == FootQuest.SEARCHING or randf() < .25
	chat_pair.clear()
	chat_wait = 0
	walk_jump_left = 0
	bridge_jump_left = 0
	free_drive = true
	crawler_speed = 0.0
	operating_excavator = false
	run_reserve = 60
	run_ready_hint_time = 0
	winded = false
	scooter.dismount(walker)
	ferry_passenger = false
	if boating:
		launch.transform = Transform3D(Basis.IDENTITY, LAUNCH_BERTH)
		launch_speed = 0.0
		outboard.rotation.y = 0.0
	reward_seconds = 0.0
	slowing_for_amber = false
	waiting_for_signal = false
	last_dispatch=""
	happy_seconds = 0
	phone.reset_social()
	phone.messages.clear()
	phone.unread=0
	phone.handset.hide()
	_reset_parked_controls()
	mode = "playing"
	paused = false
	mission_index = 0
	vehicle_progress.clear()
	recovery_leg = 0
	taxi_leg = 0
	bus_leg = 0
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
		_park_at_home(parked_cars[i], i)
	ambulance.global_position = _starting_position()
	ambulance.rotation = Vector3(0, -PI * 0.5, 0)
	if start_in_excavator:
		free_drive = true
		parked_cars[vehicle_index].show()
		ambulance.hide()
		walker.position = excavator.position
		listener.reparent(cab_turntable,false)
		listener.position = Vector3.UP*2.5
		operating_excavator = true
		start_in_excavator = false
	release_pedal_keys = _keyboard_pedal_pressed()
	_update_camera(0.0, true)
	speed = 0
	steering = 0
	message = ""
	_update_mission_marker()
	_update_siren()
	_refresh_ui()
	get_viewport().gui_release_focus()

func _select_gallery_activity(index: int) -> void:
	start_in_excavator = false
	if mode == "menu":
		var gallery_index := VEHICLE_NAMES_ALL.size() + (2 if index == 4 else 1) if index >= 2 else vehicle_index
		_mark_selected_vehicle(gallery_index)
	boating = index==4
	if mode == "menu" and index >= 2: siren_player.stop()
	tram_mode = index-1 if index in [2,3] else 0
	if boating or tram_mode == 2: release_pedal_keys = _keyboard_pedal_pressed()
	tram_driver_exit_requested = false
	launch_speed = 0
	var ear: Node3D = tram.sections[0] if tram_mode > 0 else launch if boating else (walker if walker.visible else ambulance)
	if listener.get_parent()!=ear:
		listener.reparent(ear,false)
		listener.position=Vector3.UP*1.3
	parked_at_target = 0.0
	message_timer = 0.0
	_update_mission_marker()
	_refresh_ui()

func _filter_gallery() -> void:
	category_tabs.visible = mode == "menu"
	if mode == "menu":
		subtitle_label.text = "Tap a star on a vehicle to add it here." if gallery_category == "Favorite vehicles" and favorites.is_empty() else "Click the pictures to choose your vehicle and driver."
	var members: Array = GALLERY_GROUPS.get(gallery_category, [])
	for tile: Button in vehicle_selector.get_children():
		if mode == "menu":
			var vehicle_name: String = tile.get_meta("vehicle_name")
			tile.visible = vehicle_name in favorites if gallery_category == "Favorite vehicles" else members.is_empty() or vehicle_name in members
		else:
			tile.visible = tile.get_index() < VEHICLE_NAMES_ALL.size()

func _mark_selected_vehicle(index: int) -> void:
	var tile := vehicle_selector.get_child(index) as Button
	tile.button_pressed = true

func _on_vehicle_selected(index: int) -> void:
	if mode == "playing" and not paused:
		_mark_selected_vehicle(vehicle_index)
		return
	start_in_excavator = false
	if mode == "menu" and (boating or tram_mode != 0): _select_gallery_activity(0)
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
	_mark_selected_vehicle(index)
	_change_mission_vehicle(clampi(index, 0, VEHICLE_NAMES_ALL.size() - 1))
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
		siren_player.bus = _vehicle_sound_bus()
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
	if boule_guest_turn and boule_throw_length < 0:
		if paused:
			boule_pause_focus = get_viewport().gui_get_focus_owner()
		boule_choices.visible = not paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		horn.stop()
		_set_spreader_active(false)
		_end_skid()
		for item in traffic_data:
			item.horn.stop()
	elif boating or operating_excavator or tram_mode == 2 or not walker.visible:
		release_pedal_keys = _keyboard_pedal_pressed()
	greeting_voice.stream_paused = paused
	_update_traffic_signals(0)
	_update_siren()
	_refresh_ui()
	if paused:
		start_button.grab_focus()
	elif boule_choices.visible:
		if is_instance_valid(boule_pause_focus) and boule_choices.is_ancestor_of(boule_pause_focus):
			boule_pause_focus.grab_focus()
		else:
			boule_aim.grab_focus()
		boule_pause_focus = null
	else:
		get_viewport().gui_release_focus()

func _toggle_lights() -> void:
	if (vehicle_index >= 3 and vehicle_index not in [XC60_POLICE, FARM_TRACTOR]) or walker.visible: return
	lights_on = not lights_on
	_update_emergency_lights()
	_refresh_ui()

func _checkpoint_fields(value: Variant, fields: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	for key in fields:
		if not value.has(key) or typeof(value[key]) != fields[key]:
			return false
		match fields[key]:
			TYPE_FLOAT:
				if not is_finite(value[key]): return false
			TYPE_VECTOR3, TYPE_TRANSFORM3D:
				if not value[key].is_finite(): return false
	return true

func _valid_checkpoint(saved: Variant) -> bool:
	if not _checkpoint_fields(saved, {"vehicle": TYPE_INT, "position": TYPE_VECTOR3, "heading": TYPE_FLOAT,
			"mission": TYPE_INT, "recovery": TYPE_INT, "taxi": TYPE_INT, "bus": TYPE_INT,
			"progress": TYPE_DICTIONARY, "free_drive": TYPE_BOOL}):
		return false
	if saved.vehicle < 0 or saved.vehicle >= VEHICLE_NAMES_ALL.size() or saved.mission < 0 or saved.mission > TARGETS.size():
		return false
	if saved.recovery < 0 or saved.taxi < 0 or saved.bus < 0:
		return false
	for vehicle in saved.progress:
		var step = saved.progress[vehicle]
		if not vehicle is int or not step is int or step < 0 or step > TARGETS.size(): return false
	if saved.has("walk_position") and not _checkpoint_fields(saved, {"walk_position": TYPE_VECTOR3, "walk_heading": TYPE_FLOAT, "door_offset": TYPE_VECTOR3}):
		return false
	var optional := {"practice": TYPE_BOOL, "boule_bench": TYPE_BOOL, "scooter": TYPE_BOOL, "exit_at_landing": TYPE_BOOL, "ferry_time": TYPE_FLOAT, "launch_transform": TYPE_TRANSFORM3D, "bus_stop_requested": TYPE_BOOL, "bus_departure_pending": TYPE_BOOL}
	for key in optional:
		if saved.has(key) and not _checkpoint_fields(saved, {key: optional[key]}):
			return false
	if saved.has("radio"):
		if not _checkpoint_fields(saved.radio, {"enabled": TYPE_BOOL, "track": TYPE_STRING, "position": TYPE_FLOAT}):
			return false
		if saved.radio.has("remaining") and not saved.radio.remaining is PackedStringArray:
			return false
		if not is_finite(saved.radio.position) or saved.radio.position < 0.0:
			return false
	if saved.has("hose_seconds"):
		var seconds: Variant = saved.hose_seconds
		if not seconds is float or not is_finite(seconds) or seconds < 0.0 or seconds >= 2.5:
			return false
	if saved.has("cockpit_view") and not saved.cockpit_view is bool:
		return false
	if saved.has("lesson"):
		if not _checkpoint_fields(saved.lesson, {"speed_distance": TYPE_FLOAT, "stop_complete": TYPE_BOOL, "signal_complete": TYPE_BOOL}):
			return false
		var lesson: Dictionary = saved.lesson
		if not is_finite(lesson.speed_distance) or lesson.speed_distance < 0.0 or lesson.speed_distance > PRACTICE_SPEED_DISTANCE:
			return false
		if (lesson.stop_complete and lesson.speed_distance < PRACTICE_SPEED_DISTANCE) or (lesson.signal_complete and not lesson.stop_complete):
			return false
	if saved.has("excavator") and not _checkpoint_fields(saved.excavator, {"base": TYPE_TRANSFORM3D, "slew": TYPE_FLOAT, "arm": TYPE_VECTOR3}):
		return false
	if saved.has("tram"):
		if not _checkpoint_fields(saved.tram, {"mode": TYPE_INT, "distance": TYPE_FLOAT, "next_stop": TYPE_INT, "dwell": TYPE_FLOAT, "parked": TYPE_BOOL}) or saved.tram.mode not in [1, 2]:
			return false
		if saved.tram.has("velocity") and (not _checkpoint_fields(saved.tram, {"velocity": TYPE_FLOAT}) or saved.tram.velocity < 0 or saved.tram.velocity > 7.0):
			return false
		if saved.tram.has("driver_exit_requested") and not saved.tram.driver_exit_requested is bool:
			return false
	if saved.has("quests"):
		if not _checkpoint_fields(saved.quests, {"shoe": TYPE_INT, "cat": TYPE_INT, "shoe_owner": TYPE_VECTOR3, "cat_owner": TYPE_VECTOR3, "lost_cat": TYPE_VECTOR3}):
			return false
		if saved.quests.shoe not in FootQuest.values() or saved.quests.cat not in FootQuest.values(): return false
	return true

func _sync_resume_button(menu_actions: Control) -> void:
	var existing := menu_actions.get_node_or_null("ResumeCheckpoint")
	if existing:
		if road_checkpoint.is_empty():
			menu_actions.remove_child(existing)
			existing.queue_free()
		return
	if not road_checkpoint.is_empty():
		var resume := _button("Resume", 160)
		resume.name = "ResumeCheckpoint"
		menu_actions.add_child(resume)
		resume.pressed.connect(_resume_road_checkpoint)
		resume.visibility_changed.connect(func():
			if mode != "menu" and resume.visible: resume.hide()
		)
		menu_actions.move_child(resume, start_button.get_index()+1)

func _profile_section() -> String:
	if not separate_profiles: return "player"
	return "alma_progress" if play_as_alma else "axel_progress"

func _select_player_profile(alma: bool, separate: bool) -> void:
	var previous := _profile_section()
	_save_preferences()
	play_as_alma = alma
	separate_profiles = separate
	if previous != _profile_section():
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		_load_player_progress(config, _profile_section())
		for marker: Node3D in star_markers.values():
			marker.hide()
			marker.queue_free()
		star_markers.clear()
		_build_stars()
		for stamp in phone.memory_strip.get_children():
			phone.memory_strip.remove_child(stamp)
			stamp.queue_free()
		shops.show_carried_toy()
		_sync_resume_button(start_button.get_parent())
	_apply_player_appearance()
	_save_preferences()
	_refresh_ui()

func _load_player_progress(config: ConfigFile, section: String) -> void:
	var saved = config.get_value(section, "road_checkpoint", {})
	road_checkpoint = saved if _valid_checkpoint(saved) else {}
	purchases=config.get_value(section,"purchases",{})
	boutique_jacket = config.get_value(section,"boutique_jacket","")
	var recipe: Variant = config.get_value(section,"pizza_order",0)
	shops.order_recipe = recipe if recipe is int and recipe >= 0 and recipe < shops.MENUS[2].size() else 0
	shops._update_order_slip()
	shops.carried_toy = config.get_value(section,"carried_toy","")
	wallet=maxi(0,int(config.get_value(section,"coins",0)))
	crate_stage = clampi(int(config.get_value(section,"crate_return",0)),0,CrateStage.AT_DEPOT)
	_sync_ice_crates()
	flour_stage = clampi(int(config.get_value(section,"flour",0)),0,FlourStage.AT_BAKERY)
	_sync_flour_sacks()
	courier_stage = clampi(int(config.get_value(section,"courier",0)),0,FootQuest.FINISHED)
	_place_courier_parcel()
	cake_stage = config.get_value(section,"birthday_cake",FootQuest.WAITING)
	if cake_stage not in [FootQuest.RETURNING,FootQuest.FINISHED]: cake_stage = FootQuest.WAITING
	_place_cake_box()
	figurine_stage = config.get_value(section,"figurine",FootQuest.WAITING)
	if figurine_stage not in [FootQuest.RETURNING,FootQuest.FINISHED]: figurine_stage = FootQuest.WAITING
	_place_lost_figurine()
	umbrella_stage = config.get_value(section,"umbrella",FootQuest.WAITING)
	if umbrella_stage not in [FootQuest.RETURNING,FootQuest.FINISHED]: umbrella_stage = FootQuest.WAITING
	_place_umbrella()
	thermos_stage = clampi(int(config.get_value(section,"thermos",FootQuest.WAITING)),FootQuest.WAITING,FootQuest.FINISHED)
	_place_thermos()
	foot_quest_points = maxi(0, int(config.get_value(section, "foot_quest_points", 0)))
	delivery_points = maxi(0, int(config.get_value(section, "delivery_points", 0)))
	var saved_receipts = config.get_value(section,"delivery_receipts",PackedStringArray())
	phone.delivery_receipts.clear()
	if saved_receipts is PackedStringArray:
		for receipt in saved_receipts:
			if receipt in [phone.CLINIC_RECEIPT,phone.MARINA_RECEIPT,phone.FLOUR_RECEIPT,phone.HOSPITAL_RECEIPT]:
				phone.delivery_receipts.append(receipt)
	var saved_memories = config.get_value(section,"mission_memories",PackedStringArray())
	mission_memories = saved_memories if saved_memories is PackedStringArray else PackedStringArray()
	if umbrella_stage == FootQuest.FINISHED and not mission_memories.has("foot/6"):
		mission_memories.append("foot/6")
	if thermos_stage == FootQuest.FINISHED and not mission_memories.has("foot/7"):
		mission_memories.append("foot/7")
	var saved_stars = config.get_value(section, "stars", PackedStringArray())
	collected_stars = PackedStringArray()
	if saved_stars is PackedStringArray:
		for id in saved_stars:
			if STAR_SITES.has(id) and not collected_stars.has(id): collected_stars.append(id)

func _store_player_progress(config: ConfigFile, section: String) -> void:
	config.set_value(section, "road_checkpoint", road_checkpoint)
	config.set_value(section,"coins",wallet)
	config.set_value(section,"mission_memories",mission_memories)
	config.set_value(section,"delivery_receipts",phone.delivery_receipts)
	config.set_value(section,"stars",collected_stars)
	config.set_value(section,"thermos",thermos_stage)
	config.set_value(section,"crate_return",crate_stage)
	config.set_value(section,"flour",flour_stage)
	config.set_value(section,"courier",courier_stage)
	config.set_value(section,"birthday_cake",cake_stage)
	config.set_value(section,"figurine",figurine_stage)
	config.set_value(section,"umbrella",umbrella_stage)
	config.set_value(section, "foot_quest_points", foot_quest_points)
	config.set_value(section, "delivery_points", delivery_points)
	config.set_value(section,"purchases",purchases)
	config.set_value(section,"boutique_jacket",boutique_jacket)
	config.set_value(section,"carried_toy",shops.carried_toy)
	config.set_value(section,"pizza_order",shops.order_recipe)

func _load_preferences() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(SETTINGS_PATH) == OK
	var saved_language = config.get_value("language", "locale", "")
	language_preference = saved_language.strip_edges() if saved_language is String else ""
	L10n.apply_language(language_preference)
	if not loaded:
		return
	for i in RADIO_KEYS.size():
		var code = config.get_value("keyboard","radio_%d" % i,radio_keys[i])
		if code in RADIO_KEYS[i]: radio_keys[i] = code
	var saved_favorites = config.get_value("gallery","favorites",PackedStringArray())
	if saved_favorites is PackedStringArray: favorites = saved_favorites
	insert_help = config.get_value("keyboard","insert_help",false) == true
	ctrl_run = config.get_value("keyboard","ctrl_run",false) == true
	look_key = KEY_F12 if config.get_value("keyboard","look_f12",false) == true else KEY_V
	number_camera = config.get_value("keyboard","number_camera",false) == true
	scooter_key = KEY_F9 if config.get_value("keyboard","scooter_f9",false) == true else KEY_U
	seat_f3 = config.get_value("keyboard","seat_f3",false) == true
	horn_f4 = config.get_value("keyboard","horn_f4",false) == true
	pause_f7 = config.get_value("keyboard","pause_f7",false) == true
	camera_f6 = config.get_value("keyboard","camera_f6",false) == true
	quit_key = KEY_F8 if config.get_value("keyboard","quit_f8",false) == true else KEY_F10
	phone.toggle_key = KEY_F2 if config.get_value("keyboard","phone_f2",false) == true else KEY_T
	number_vehicle_switches = config.get_value("keyboard","number_vehicle_switches",false) == true
	map_key = KEY_F11 if config.get_value("keyboard","map_f11",false) == true else KEY_F5
	jump_key = KEY_0 if config.get_value("keyboard","zero_jump",false) == true else KEY_E
	recovery_key = KEY_BACKSPACE if config.get_value("keyboard","backspace_recovery",false) == true else KEY_R
	number_movement = config.get_value("keyboard","number_movement",false) == true
	extra_reading_time = config.get_value("accessibility", "extra_reading_time", false) == true
	streetlamp_shadows = config.get_value("graphics", "streetlamp_shadows", true) == true
	long_view_distance = config.get_value("graphics", "long_view_distance", false) == true
	large_text = config.get_value("accessibility", "large_text", false) == true
	play_as_alma = config.get_value("player","alma",false) == true
	separate_profiles = config.get_value("player","separate_profiles",false) == true
	_load_player_progress(config, _profile_section())
	weather.season_setting = clampi(int(config.get_value("world","season",0)),0,4)
	weather.weather_setting = clampi(int(config.get_value("world","weather",0)),0,4)
	time_mode = clampi(int(config.get_value("world","daylight",2)),0,2)
	_apply_calm_mode(config.get_value("accessibility","calm_mode",false) == true)
	steady_player_lights = config.get_value("driving","steady_lights",false) == true
	show_turn_street = config.get_value("driving","turn_street_names",false) == true
	allow_red_lights = config.get_value("driving","allow_red_lights",false) == true
	allow_crashes = config.get_value("driving","allow_crashes",true) == true
	spreader_enabled = config.get_value("driving","spreader_enabled",true) != false
	var tyres: Variant = config.get_value("driving","winter_tyre_models",PackedStringArray())
	if tyres is PackedStringArray: winter_tyre_models = tyres
	var gentle = config.get_value("driving","gentle",true)
	if gentle is bool:
		gentle_driving = gentle
	var mode_value = config.get_value("traffic","lights",0)
	if mode_value is int:
		traffic_light_mode = clampi(mode_value,0,2)
	for channel: String in MIX_CHANNELS:
		_apply_channel_volume(channel, float(config.get_value("audio",channel.to_lower(),100)))
	_set_radio_ducking(float(config.get_value("audio","radio_ducking",100)))
	traffic_siren_volume = clampf(float(config.get_value("audio","traffic_sirens",100)),0,100)
	var volume_value = config.get_value("audio","volume",100)
	if volume_value is float or volume_value is int:
		_apply_game_volume(clampf(volume_value,0,100))

func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var volume := 0.0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0))*100
	config.set_value("accessibility", "extra_reading_time", extra_reading_time)
	config.set_value("accessibility", "large_text", large_text)
	config.set_value("graphics", "long_view_distance", long_view_distance)
	config.set_value("graphics", "streetlamp_shadows", streetlamp_shadows)
	config.set_value("player","alma",play_as_alma)
	config.set_value("player","separate_profiles",separate_profiles)
	_store_player_progress(config, _profile_section())
	config.set_value("language", "locale", language_preference)
	for channel: String in MIX_CHANNELS:
		config.set_value("audio", channel.to_lower(), roundi(_channel_volume(channel)))
	config.set_value("audio","volume",roundi(volume))
	config.set_value("audio","radio_ducking",roundi(radio_ducking))
	config.set_value("audio","traffic_sirens",roundi(traffic_siren_volume))
	config.set_value("world","season",weather.season_setting)
	config.set_value("world","weather",weather.weather_setting)
	config.set_value("world","daylight",time_mode)
	config.set_value("driving","turn_street_names",show_turn_street)
	config.set_value("driving","allow_red_lights",allow_red_lights)
	config.set_value("driving","allow_crashes",allow_crashes)
	config.set_value("driving","spreader_enabled",spreader_enabled)
	config.set_value("driving","winter_tyre_models",winter_tyre_models)
	config.set_value("driving","gentle",gentle_driving)
	config.set_value("traffic","lights",traffic_light_mode)
	for i in RADIO_KEYS.size():
		config.set_value("keyboard","radio_%d" % i, radio_keys[i])
	config.set_value("gallery","favorites",favorites)
	config.set_value("keyboard","insert_help",insert_help)
	config.set_value("keyboard","ctrl_run",ctrl_run)
	config.set_value("keyboard","look_f12",look_key == KEY_F12)
	config.set_value("keyboard","number_camera",number_camera)
	config.set_value("keyboard","scooter_f9",scooter_key == KEY_F9)
	config.set_value("keyboard","seat_f3",seat_f3)
	config.set_value("keyboard","horn_f4",horn_f4)
	config.set_value("keyboard","pause_f7",pause_f7)
	config.set_value("keyboard","camera_f6",camera_f6)
	config.set_value("keyboard","quit_f8",quit_key == KEY_F8)
	config.set_value("keyboard","phone_f2",phone.toggle_key == KEY_F2)
	config.set_value("keyboard","number_vehicle_switches",number_vehicle_switches)
	config.set_value("keyboard","map_f11",map_key == KEY_F11)
	config.set_value("keyboard","zero_jump",jump_key == KEY_0)
	config.set_value("keyboard","backspace_recovery",recovery_key == KEY_BACKSPACE)
	config.set_value("keyboard","number_movement",number_movement)
	config.set_value("accessibility","calm_mode",calm_mode)
	config.set_value("driving","steady_lights",steady_player_lights)
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Kunde inte spara spelinställningarna: " + error_string(result))

func _set_handling(index: int) -> void:
	gentle_driving = index == 0
	if gentle_driving:
		speed = clampf(speed, -1.8, 30.0 / 3.6)
	_save_preferences()

func _apply_calm_mode(enabled: bool) -> void:
	calm_mode = enabled
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Traffic and radio"), _traffic_target_gain())

func _traffic_target_gain() -> float:
	# Keep quiet syllables clear of engine and street noise throughout a phone instruction.
	var reading := phone.job_voice.playing and not phone.job_voice.stream_paused
	return (-10.0 if calm_mode else 0.0) - (9.0 if reading else 0.0)

func _set_traffic_light_mode(index: int) -> void:
	traffic_light_mode = index
	_save_preferences()

func _set_radio_ducking(percent: float) -> void:
	radio_ducking = clampf(percent, 0, 100)
	var index := AudioServer.get_bus_index("Radio")
	var compressor := AudioServer.get_bus_effect(index, 0) as AudioEffectCompressor
	compressor.mix = radio_ducking / 100.0

func _channel_volume(channel: String) -> float:
	var index := AudioServer.get_bus_index(channel)
	return 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))*100.0

func _apply_channel_volume(channel: String, percent: float) -> void:
	var index := AudioServer.get_bus_index(channel)
	AudioServer.set_bus_mute(index, percent <= 0)
	if percent > 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(percent,0,100)/100.0))

func _set_game_volume(percent: float) -> void:
	_apply_game_volume(percent)
	_save_preferences()

func _apply_game_volume(percent: float) -> void:
	AudioServer.set_bus_mute(0, percent <= 0)
	if percent <= 0:
		greeting_voice.stop()
	if percent > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(percent / 100.0))

func _toggle_sound() -> void:
	sound_on = not sound_on
	if is_instance_valid(spreader_particles):
		_set_spreader_active(spreader_particles.emitting)
	_update_siren()
	_refresh_ui()

func _vehicle_sound_bus() -> StringName:
	return &"Traffic and radio" if vehicle_index < 3 or vehicle_index == XC60_POLICE else &"Engines"

func _update_siren() -> void:
	if (operating_excavator or boating) and mode == "playing" and not paused:
		siren_player.bus = &"Engines"
		var engine: AudioStream = preload("res://audio/outboard.wav") if boating else siren_streams[WHEEL_LOADER]
		if siren_player.stream != engine:
			siren_player.stream = engine
		siren_player.volume_db = -8
		if not siren_player.playing:
			siren_player.pitch_scale = 0.78
			siren_player.play()
		return
	if sound_on and not operating_excavator and not boating and tram_mode == 0 and mode == "playing" and not paused and not walker.visible:
		siren_player.bus = _vehicle_sound_bus()
		if siren_player.stream != siren_streams[vehicle_index]:
			siren_player.stream = siren_streams[vehicle_index]
		if vehicle_index < 3 or vehicle_index == XC60_POLICE:
			siren_player.pitch_scale = 1.0
		siren_player.volume_db = -1.0
		if not siren_player.playing: siren_player.play()
	else:
		if mode != "menu" or not siren_player.playing:
			siren_player.stop()

func _refresh_dispatch() -> void:
	phone.foot_jobs.clear()
	if walker.visible:
		for i in 2:
			if pet_stages[i] == FootQuest.SEARCHING: phone.foot_jobs.append(PET_REQUESTS[i])
		if pet_stages[0] == FootQuest.RETURNING: phone.foot_jobs.append("Bring the ball back to the dog.")
		if courier_stage == FootQuest.SEARCHING: phone.foot_jobs.append(COURIER_REQUEST)
		if courier_stage == FootQuest.RETURNING: phone.foot_jobs.append(COURIER_RETURN)
		if cake_stage == FootQuest.RETURNING: phone.foot_jobs.append(CAKE_ROUTE)
		if figurine_stage == FootQuest.RETURNING: phone.foot_jobs.append(FIGURINE_RETURN)
		if umbrella_stage == FootQuest.RETURNING: phone.foot_jobs.append(UMBRELLA_RETURN)
		if thermos_stage == FootQuest.SEARCHING: phone.foot_jobs.append(THERMOS_REQUEST)
		if thermos_stage == FootQuest.RETURNING: phone.foot_jobs.append(THERMOS_RETURN)
		if shoe_quest == FootQuest.SEARCHING: phone.foot_jobs.append("Find the red shoe on the pavement.")
		if shoe_quest == FootQuest.RETURNING: phone.foot_jobs.append("Bring the red shoe back to the neighbour.")
		if cat_quest == FootQuest.SEARCHING: phone.foot_jobs.append("Find the cat with white paws.")
		if cat_quest == FootQuest.RETURNING: phone.foot_jobs.append("Walk back to the neighbour with the cat.")
	leave_practice_button.visible = practice_active
	map_button.visible = free_drive and not leave_practice_button.visible
	phone.take_job.text = "Return to town for a job" if leave_practice_button.visible else "Take a job"
	phone.take_job.visible = free_drive and not walker.visible and not boating and not operating_excavator and tram_mode == 0 and not ferry_passenger and mission_index < TARGETS.size()
	phone.visible = mode=="playing" and not paused
	if free_drive or mode!="playing" or mission_index>=TARGETS.size():
		last_dispatch=""
		phone.current_job=""
		if free_drive and vehicle_index == ICE_CREAM and crate_stage != CrateStage.AT_DEPOT:
			phone.current_job = CRATE_PICKUP if crate_stage == CrateStage.AT_KIOSK else CRATE_RETURN
			phone.vehicle_action = phone.Action.DELIVER
		if free_drive and vehicle_index == RECOVERY and flour_stage != FlourStage.AT_BAKERY:
			phone.current_job = FLOUR_PICKUP if flour_stage == FlourStage.AT_SQUARE else FLOUR_ROUTE
			phone.vehicle_action = phone.Action.DELIVER
		phone.refresh()
		return
	var dispatch: String
	if vehicle_index==RECOVERY:
		match recovery_leg%4:
			0: dispatch="A car is smoking on the main street. Follow the arrows and stop beside it."
			2: dispatch="A car on the east bank has lost a wheel. Follow the arrows to pick it up."
			_: dispatch="The car is on your flatbed. Follow the arrows to the petrol station for 20 coins."
	elif vehicle_index==BUS:
		dispatch=BUS_MESSAGES[bus_leg%BUS_STOPS.size()]
	elif vehicle_index==TAXI:
		var requests := ["Taxi requested at the square.","Please take me to the marina.","A pupil is waiting at the square.","Please take me to school.","Taxi requested at the clinic.","Please take me to the square.","A pupil is waiting at school.","Please take me to the clinic.","Taxi requested at the marina.","Please take me to the clinic."]
		dispatch=requests[taxi_leg%requests.size()]
	else:
		dispatch=_vehicle_tasks()[_mission_stop()]
		if vehicle_index==0:
			dispatch=[TARGET_NAMES[0],"Drive into the hospital ambulance bay and stop to drop off the patient.","Please bring the first-aid supplies to the marina."][mission_index]
	match vehicle_index:
		RECOVERY: phone.vehicle_action = phone.Action.TOW if recovery_leg % 2 == 0 else phone.Action.DELIVER
		BUS: phone.vehicle_action = phone.Action.BOARD if bus_leg % 2 == 0 else phone.Action.ALIGHT
		TAXI: phone.vehicle_action = phone.Action.BOARD if taxi_leg % 2 == 0 else phone.Action.ALIGHT
		0: phone.vehicle_action = [phone.Action.BOARD, phone.Action.ALIGHT, phone.Action.DELIVER][mission_index]
		1, XC60_POLICE, 2: phone.vehicle_action = phone.Action.INSPECT
		REFUSE: phone.vehicle_action = phone.Action.BIN if mission_index < 2 else phone.Action.DELIVER
		ICE_CREAM: phone.vehicle_action = phone.Action.ICE_CREAM
		FOOD_TRUCK: phone.vehicle_action = phone.Action.COLLECT if mission_index == 0 else phone.Action.SOUP
		_: phone.vehicle_action = phone.Action.COLLECT if mission_index == 0 else phone.Action.DELIVER
	if dispatch!=last_dispatch:
		last_dispatch=dispatch
		phone.current_job=dispatch
		phone.receive(dispatch)
	else:
		phone.refresh()

func _refresh_ui() -> void:
	map_button.text = "%s · %s" % [tr("Town map"),OS.get_keycode_string(map_key)]
	if is_instance_valid(vehicle_model):
		var school_sign := vehicle_model.get_node_or_null("SchoolCarSign") as Node3D
		if school_sign: school_sign.visible = practice_active
	if parked_cars.size() > SCHOOL_CAR:
		var parked_school_sign := parked_cars[SCHOOL_CAR].find_child("SchoolCarSign",true,false) as Node3D
		parked_school_sign.visible = practice_active and vehicle_index == SCHOOL_CAR
	phone.recovery_hint.text = _recovery_hint()
	if road_driver:
		for avatar in [walker, road_driver]:
			avatar.get_node("Smile").visible = happy_seconds > 0
		var on_moped := vehicle_index == PUCH_DAKOTA
		road_driver.scale = Vector3.ONE * (.88 if play_as_alma else 1.0) * (1.0 if on_moped else .78)
		road_driver.position = Vector3(0,.82-.77*road_driver.scale.y,.18) if vehicle_index==SNOWMOBILE else Vector3(-.32,.88-.87*road_driver.scale.y,-.04)
		if vehicle_index == 2:
			road_driver.position = Vector3(-.57,1.69-.87*road_driver.scale.y,-2.53)
		if vehicle_index == BUS:
			road_driver.position = Vector3(-.59,1.535-.87*road_driver.scale.y,-4.13)
		if vehicle_index == FOOD_TRUCK:
			road_driver.position = Vector3(-.46,1.505-.87*road_driver.scale.y,-1.39)
		if vehicle_index == MOWER:
			road_driver.position = Vector3(0,.79-.77*road_driver.scale.y,.18)
		if vehicle_index == SHOPPER:
			road_driver.position = Vector3(0,.64-.77*road_driver.scale.y,.18)
		if vehicle_index == MINI_CABRIO:
			road_driver.position = Vector3(-.38,.595-.87*road_driver.scale.y,-.19)
		if vehicle_index == QUATTRO:
			road_driver.position = Vector3(-.346,.52-.87*road_driver.scale.y,.16)
		if vehicle_index == PORSCHE:
			road_driver.position = Vector3(-.356,.48-.87*road_driver.scale.y,.10)
		moped_pose.visible = on_moped
		if on_moped:
			moped_pose.fit_to(vehicle_model)
		for arm in road_driver.get_meta("arms"):
			arm.visible = not on_moped
		road_driver.get_node("RidingLegs").visible = vehicle_index == SNOWMOBILE
		road_driver.get_node("AlmaMowerLegs").visible = vehicle_index == MOWER and play_as_alma
		road_driver.get_node("AxelMowerLegs").visible = vehicle_index == MOWER and not play_as_alma
		road_driver.get_node("AlmaShopperLegs").visible = vehicle_index == SHOPPER and play_as_alma
		road_driver.get_node("AxelShopperLegs").visible = vehicle_index == SHOPPER and not play_as_alma
		road_driver.get_node("AlmaCabLegs").visible = vehicle_index == FOOD_TRUCK and play_as_alma
		road_driver.get_node("AxelCabLegs").visible = vehicle_index == FOOD_TRUCK and not play_as_alma
		road_driver.get_node("CarLegs").visible = vehicle_index in [2,3,PORSCHE,XC60_POLICE,MINI_CABRIO,BUS,QUATTRO]
		road_driver.visible = vehicle_index in [2,3,PORSCHE,SNOWMOBILE,XC60_POLICE,MINI_CABRIO,PUCH_DAKOTA,FOOD_TRUCK,MOWER,SHOPPER,BUS,QUATTRO] and mode == "playing" and not walker.visible and not boating and tram_mode == 0 and not cockpit_view
		if vehicle_index in [2,SHOPPER,BUS,QUATTRO] and cabin_wheel:
			_pose_driver_arms()
	if skipper: skipper.visible = boating and mode == "playing"
	if not is_instance_valid(mission_label): return
	menu_footer.visible = mode == "menu"
	version_label.text = tr("Version %s") % ProjectSettings.get_setting("application/config/version")
	_refresh_dispatch()
	_sync_radio()
	phone.update_star_album(STAR_SITES, collected_stars)
	phone.update_mission_album(MEMORY_SHEETS, mission_memories, shops, purchases)
	var remaining := STAR_SITES.size() - collected_stars.size()
	if remaining == 0:
		phone.star_progress.text = tr("★ All stars found!")
	else:
		phone.star_progress.text = tr_n("★ %d star left", "★ %d stars left", remaining) % remaining
	var points := delivery_points + foot_quest_points + collected_stars.size() * POINTS_PER_STAR
	wallet_label.text = tr_n("★ %d point", "★ %d points", points) % points + "   ·   " + tr_n("%d coin", "%d coins", wallet) % wallet
	if happy_seconds > 0:
		wallet_label.text += "   ☺ " + tr("%s feels extra happy!") % ("Alma" if play_as_alma else "Axel")
	wallet_label.accessibility_name = tr("Wallet") + ". " + wallet_label.text
	light_button.text = "Lights ON" if lights_on else "Lights OFF"
	if vehicle_index >= 3 and vehicle_index != XC60_POLICE:
		siren_button.text = "Engine sound ON" if sound_on else "Engine sound OFF"
	else:
		siren_button.text = "Siren ON" if sound_on else "Siren OFF"
	if number_vehicle_switches:
		light_button.text = tr(light_button.text) + " · 1"
		siren_button.text = tr(siren_button.text) + " · 2"
	pause_button.text = (tr("Resume") if paused else tr("Pause")) + _movement_hint(" · {pause}")
	if ferry_passenger:
		mission_label.text = "On board Lotten"
	elif tram_mode > 0:
		mission_label.text = "Ride the tram" if tram_mode == 1 else "Drive the tram"
	elif boating:
		mission_label.text = "Drive the motorboat"
	elif free_drive:
		mission_label.text = "Practice course" if practice_active else "Free exploration"
	elif vehicle_index==RECOVERY:
		mission_label.text=tr(SERVICE_MESSAGES[recovery_leg%4])
	elif vehicle_index==BUS:
		mission_label.text = tr(BUS_MESSAGES[bus_leg%BUS_STOPS.size()])
	elif vehicle_index==TAXI:
		mission_label.text = tr(_taxi_instruction())
	elif mission_index < TARGET_NAMES.size():
		mission_label.text = tr("MISSION %d / %d   ·   %s") % [mission_index + 1, TARGET_NAMES.size(), tr(_vehicle_tasks()[_mission_stop()])]
	else:
		mission_label.text = "ALL MISSIONS COMPLETE"
	if is_instance_valid(driven_fire_locker):
		var destination := ""
		if free_drive and map_goal == FIRE_RETURN_BAY:
			destination = tr("Fire station")
		elif not free_drive and mission_index < FIRE_TASKS.size():
			destination = tr(MAP_NAMES[_mission_stop()])
		driven_fire_locker.set_destination(destination)
	fire_bay_button.visible = mode == "complete" and vehicle_index == 2
	var show_overlay := mode == "menu" or mode == "complete" or paused
	driving_footer_margin.visible = mode == "playing"
	status_label.visible = mode == "playing"
	if show_overlay or vehicle_index != ICE_CREAM: ice_order.hide()
	ui.get_node("DrivingHeader").visible = mode != "menu"
	for control in [light_button, siren_button, pause_button]:
		control.focus_mode = Control.FOCUS_NONE if show_overlay else Control.FOCUS_ALL
	camera_button.visible = tram_mode == 0 and not boating and (operating_excavator or vehicle_index in DRIVER_VIEW_VEHICLES) and not walker.visible and not show_overlay
	var camera_caption := tr("Outside view · C") if cockpit_view else tr("Driver view · C")
	if operating_excavator:
		camera_caption = tr("Outside view · C") if excavator_work_view else tr("Bucket view · C")
	camera_button.text = camera_caption + (" / F6" if camera_f6 else "")
	horn_button.visible = not show_overlay and (tram_mode==2 or (tram_mode==0 and (boating or not walker.visible)))
	var horn_caption := tr("Horn · H")
	if tram_mode == 2:
		horn_caption = tr("Tram bell · H")
	elif vehicle_index == ICE_CREAM and not boating:
		horn_caption = tr("Ice cream chime · H")
	horn_button.text = horn_caption + (" / F4" if horn_f4 else "")
	spreader_button.text = "Spreader on" if spreader_enabled else "Spreader off"
	if number_vehicle_switches:
		spreader_button.text = tr(spreader_button.text) + " · 7"
	spreader_button.visible = not show_overlay and vehicle_index == FARM_TRACTOR and weather.season == 4 and tram_mode == 0 and not (walker.visible or boating or operating_excavator or ferry_passenger)
	seat_button.visible = not show_overlay and (not boating or _launch_at_berth())
	light_button.visible = tram_mode == 0 and not boating and not walker.visible and (vehicle_index < 3 or vehicle_index in [XC60_POLICE, FARM_TRACTOR])
	siren_button.visible = tram_mode == 0 and not boating and not walker.visible
	if walker.visible or tram_mode != 0 or operating_excavator or boating:
		_update_entry_button()
	else:
		seat_button.disabled = false
		entry_marker.visible = false
		seat_button.text = tr("Get out · F") + (" / F3" if seat_f3 else "")
	driving_controls.reverse_pedal = operating_excavator
	driving_controls.show_wheel = tram_mode == 0 and not operating_excavator
	driving_controls.visible = not show_overlay and (tram_mode == 2 or (tram_mode == 0 and (boating or not walker.visible)))
	var hints := driving_hints
	driving_footer_margin.add_theme_constant_override("margin_right", 228 if driving_controls.visible else 12)
	driving_footer_margin.add_theme_constant_override("margin_left", 142 if driving_controls.visible and driving_controls.show_wheel else 12)
	hints.visible = not show_overlay and not shops.shop_card.is_visible_in_tree()
	if tram_mode == 1:
		hints.text = "Passenger ride · {pause} to pause"
	elif tram_mode == 2:
		hints.text = "{up} / ↑ Accelerate · {down} / ↓ Brake · Automatic station stops"
	elif boating:
		hints.text = "{up} / ↑ Throttle · {left} {right} / ← → Steer · {down} / ↓ Slow or reverse · {horn} Horn · {pause} Pause"
	elif free_drive:
		hints.text = "{up} / ↑ Drive   ·   {left} {right} / ← → Steer   ·   {down} / ↓ Brake or reverse   ·   {seat} Get out   ·   {pause} Pause"
	else:
		hints.text = "{up} / ↑  Drive     {left} {right} / ← →  Steer     {down} / ↓  Brake or reverse\nRelease to slow down   ·   {help} to help   ·   {pause} to pause"
	var camera_hint := (tr("Hold %s and move the mouse to look around") % OS.get_keycode_string(look_key))
	if walker.visible and tram_mode == 0 and not boating and not ferry_passenger and not operating_excavator and shops.inside < 0:
		camera_hint = tr("{up} / ↑ Accelerate · {down} / ↓ Brake · {left} / {right} Steer · {scooter} Fold scooter") if scooter.visible else tr("{scooter} Unfold scooter") + "   ·   " + camera_hint
		camera_hint = camera_hint.replace("{scooter}",OS.get_keycode_string(scooter_key))
	hints.text = camera_hint if walker.visible and tram_mode == 0 and not boating else tr(hints.text) + "   ·   " + camera_hint
	if operating_excavator:
		hints.text = tr("Arrows or {up}{left}{down}{right}: drive and steer · Q/E: turn the cab · {seat}: get out\nI/K: raise or lower the boom · Y/G: move the outer arm · O/L: tilt the bucket")
		hints.text += "\n" + tr("Hold left mouse to drive forward or right mouse to reverse.") + "   ·   " + camera_hint
		for control in [horn_button, light_button, siren_button]:
			control.hide()
	elif walker.visible and not scooter.visible and not ferry_passenger and not boating and tram_mode == 0:
		hints.text = _walking_hint()
	if tram_mode == 0 and not (walker.visible or boating or operating_excavator or ferry_passenger):
		hints.text += "\n" + tr("Hold the left mouse button to accelerate or the right to brake. To reverse, stop, release the brake and hold it again.")
	if tram_mode == 2:
		hints.text += "\n" + tr("Hold left mouse to accelerate or right mouse to brake.")
	elif boating:
		hints.text += "\n" + tr("Hold left to speed up or right to slow down and reverse. Move the mouse sideways to steer, or use {left}/{right} or the arrow keys.")
	elif tram_mode == 0 and not ferry_passenger and (operating_excavator or not walker.visible):
		hints.text += "\n" + tr("Hold the left or right mouse button and move the mouse sideways to steer.")
	hints.text = _with_recovery_hint(hints.text)
	if show_overlay:
		_release_mouse_pedals()
	if show_overlay: turn_preview.hide()
	overlay.visible = show_overlay
	overlay_panel.visible = show_overlay
	vehicle_selector.visible = mode == "menu" or (show_overlay and not walker.visible and not boating and tram_mode == 0)
	if vehicle_selector.visible: _filter_gallery()
	else: category_tabs.hide()
	preview_sound_button.visible = not start_in_excavator and mode == "menu" and not boating and tram_mode == 0
	preview_sound_button.text = "Stop preview" if siren_player.playing and mode == "menu" else ("Preview engine" if vehicle_index >= 3 and vehicle_index != XC60_POLICE else "Preview siren")
	brand_logo.texture = L10n.logo(TranslationServer.get_locale())
	title_label.visible = mode != "menu" or brand_logo.texture == null
	brand_logo.visible = mode == "menu" and brand_logo.texture != null
	brand_logo.accessibility_name = tr("Harbor Town Rollabout")
	get_window().title = tr("Harbor Town Rollabout")
	if mode == "menu":
		title_label.text = "Harbor Town Rollabout"
		start_button.text = "Start driving"
	elif mode == "complete":
		title_label.text = "All missions complete!"
		subtitle_label.text = tr("Well done, %s!") % ("Alma" if play_as_alma else "Axel") + "\n" + tr(_delivery_receipt())
		start_button.text = "Drive again"
	else:
		title_label.text = "Pause"
		subtitle_label.text = "You can change vehicles here and continue your mission."
		if free_drive:
			subtitle_label.text = "Explore on foot or by vehicle. Stop at the depot to change vehicles."
		if walker.visible:
			subtitle_label.text = "Walk up to a parked vehicle to get in."
		start_button.text = "Continue walking" if walker.visible else "Continue driving"
	if mode == "menu" and start_in_excavator:
		subtitle_label.text = tr("Operate the excavator in the equipment yard.")
		start_button.text = tr("Start excavating")
	if show_overlay and mode != "complete":
		if ferry_passenger:
			subtitle_label.text = "You can step ashore at either landing."
			start_button.text = "Resume"
		elif boating:
			subtitle_label.text = "Hold left to speed up or right to slow down and reverse. Move the mouse sideways to steer, or use {left}/{right} or the arrow keys."
			start_button.text = "Start boating" if mode=="menu" else "Continue boating"
		elif tram_mode > 0:
			subtitle_label.text = "The tram drives itself and stops at each platform." if tram_mode==1 else "Control the speed. The tram follows the rails and stops at each platform."
			start_button.text = "Ride the tram" if tram_mode==1 else "Drive the tram"
			if paused: start_button.text = "Resume"
	if paused:
		reward_badge.hide()
	elif mode == "playing" and reward_seconds > 0:
		reward_badge.show()
	pause_action_picture.visible = paused and mode == "playing" and not phone.pictured_jobs.is_empty()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if pause_action_picture.visible else HORIZONTAL_ALIGNMENT_CENTER
	if pause_action_picture.visible:
		var current_step := phone.action_rows.get_child(0)
		pause_action_picture.texture = current_step.get_child(0).texture
		subtitle_label.text = current_step.get_child(1).text
	_refresh_status()

func _can_swap_workshop_tyres() -> bool:
	if not _world_controls_available() or practice_active or not ambulance.visible or tram_mode != 0:
		return false
	if walker.visible or boating or ferry_passenger or operating_excavator or absf(speed) >= .16:
		return false
	if vehicle_index in FIXED_TYRE_VEHICLES:
		return false
	return Vector2(ambulance.position.x,ambulance.position.z).distance_to(Vector2(STATION_DROP.x,STATION_DROP.z)) <= 5.3

func _swap_workshop_tyres() -> void:
	if not _can_swap_workshop_tyres():
		return
	var model: String = VEHICLE_SCENES_ALL[vehicle_index]
	var current := winter_tyre_models.find(model)
	if current >= 0:
		winter_tyre_models.remove_at(current)
		message = "Summer tyres fitted."
	else:
		winter_tyre_models.append(model)
		message = "Winter tyres fitted."
	message_timer = 3.0
	_save_preferences()
	_refresh_status()

func _dax_action() -> String:
	if not _world_controls_available() or practice_active or walker.visible or boating or operating_excavator or tram_mode != 0 or ferry_passenger or absf(speed) >= .12:
		return ""
	return dax.action_at(ambulance.global_position)

func _serve_dax() -> bool:
	var action := _dax_action()
	if action.is_empty():
		return false
	if not dax.order_pending:
		dax.order_pending = true
		message = "Order received. Drive to the pickup window."
	elif wallet >= dax.PRICE:
		dax.order_pending = false
		wallet -= dax.PRICE
		purchases["Dax burger"] = int(purchases.get("Dax burger", 0)) + 1
		message = "Dax burger picked up."
		_save_checkpoint()
		_refresh_ui()
	else:
		return true
	message_timer = 4.0
	_refresh_status()
	return true

func _refresh_status() -> void:
	if not is_instance_valid(status_label): return
	var dax_action := _dax_action()
	dax_button.visible = not dax_action.is_empty()
	if dax_button.visible:
		dax_button.disabled = dax.order_pending and wallet < dax.PRICE
		dax_button.text = tr("Dax burger costs %d coins") % dax.PRICE if dax_button.disabled else tr(dax_action)
	tyre_service_button.visible = _can_swap_workshop_tyres()
	if tyre_service_button.visible:
		var has_winter_tyres: bool = VEHICLE_SCENES_ALL[vehicle_index] in winter_tyre_models
		tyre_service_button.text = "Fit summer tyres" if has_winter_tyres else "Fit winter tyres"
		var fitted_tyres := tr("Winter tyres fitted." if has_winter_tyres else "Summer tyres fitted.")
		tyre_service_button.tooltip_text = fitted_tyres
		tyre_service_button.accessibility_description = fitted_tyres
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
			if vehicle_index == BUS: _fit_world_sign(dash_direction)
			dash_direction.modulate = Color("#ffd07a") if speed < -.12 else Color("#def4f7")
		var reading := tr("%d km/h") % roundi(absf(speed)*3.6)
		if dash_speed.text != reading:
			dash_speed.text = reading
			if vehicle_index == BUS: _fit_world_sign(dash_speed)
	arrival_progress.visible = mode == "playing" and not paused and not free_drive and parked_at_target > 0.0
	arrival_progress.value = parked_at_target
	if paused:
		status_label.text = "Paused — take your time."
	elif message_timer > 0 and message in ["Back in a safe place.", "No clear spot yet. Try again in a moment."]:
		status_label.text = message
	elif ferry_passenger:
		if _ferry_stop() >= 0:
			status_label.text = tr("Step ashore · F") + (" / F3" if seat_f3 else "")
		else:
			var remaining := ceili(29.0-fmod(_ferry_clock(),29.0))
			status_label.text = tr("Stepping ashore in %d s") % remaining if ferry_exit_requested else tr("Next landing in %d s") % remaining
	elif tram_mode > 0 and mode == "playing":
		if tram.dwell > 0:
			var station: String = tram.STATION_NAMES[posmod(tram.next_stop-1,tram.stops.size())]
			status_label.text = tr("%s · Departure in %d s") % [station,ceili(tram.dwell)]
		else:
			status_label.text = tr("Next stop: %s · %d m · %d km/h") % [tram.STATION_NAMES[tram.next_stop],ceili(tram.distance_to_next_stop()),roundi(tram.velocity*3.6)]
	elif scooter.visible:
		status_label.text = tr("Electric scooter · %d km/h") % roundi(scooter.speed*3.6)
	elif message_timer > 0 and message != "":
		status_label.text = message
	elif mode == "playing" and not paused and walker.visible and _at_target():
		status_label.text = "Stand here to help" if gentle_driving else _movement_hint(tr("Press {help} to help"))
	elif mode == "playing" and not paused and _at_target():
		if vehicle_index == RECOVERY:
			var loading := recovery_leg % 2 == 0
			if absf(speed) >= .12:
				status_label.text = "Stop here to load the car." if loading else "Stop here to unload the car."
			elif gentle_driving:
				status_label.text = "Loading the car …" if loading else "Unloading the car …"
			else:
				status_label.text = _movement_hint(tr("Press {help} to load the car.")) if loading else _movement_hint(tr("Press {help} to unload the car."))
		elif vehicle_index == TAXI:
			var pickup := taxi_leg % 2 == 0
			if absf(speed) >= .12:
				status_label.text = "Stop for your passenger." if pickup else "Stop to let your passenger out."
			elif gentle_driving:
				status_label.text = "Your passenger is getting in …" if pickup else "Your passenger is getting out …"
			else:
				status_label.text = _movement_hint(tr("Press {help} to pick up your passenger.")) if pickup else _movement_hint(tr("Press {help} to let your passenger out."))
		elif absf(speed) >= .12:
			status_label.text = "Stop here to help."
		else:
			status_label.text = "Helping …" if gentle_driving else _movement_hint(tr("Press {help} to help"))
	elif tyre_service_button.visible:
		status_label.text = tyre_service_button.tooltip_text
	elif practice_active and vehicle_index == SCHOOL_CAR and not walker.visible and not paused:
		if practice_signal_missed or practice_stop_missed:
			status_label.text = tr("You passed the line. Reverse until this message clears.")
		elif absf(speed)*3.6 > PRACTICE_SPEED_LIMIT:
			status_label.text = tr("Slow down. The limit is 20 km/h.")
		elif practice_signal_complete:
			status_label.text = tr("Driving lesson complete.")
		elif practice_stop_complete:
			if practice_signal_phase == 2:
				status_label.text = tr("Green light. Drive across the line.")
			elif practice_signal_phase == 1:
				status_label.text = tr("Orange light. Slow down.")
			else:
				status_label.text = tr("Red light! Stop at the line and wait for green.")
		elif practice_speed_distance >= PRACTICE_SPEED_DISTANCE:
			status_label.text = tr("Come to a full stop at the stop line.")
		else:
			status_label.text = tr("Drive 15 m at 20 km/h or less.")
		status_label.text += " · " + tr("%d km/h") % roundi(absf(speed)*3.6)
	elif slowing_for_amber and mode == "playing" and not paused and not walker.visible and not boating:
		status_label.text = tr("Orange light. Slow down.")
	elif waiting_for_signal and mode=="playing" and not paused and not walker.visible and not boating:
		status_label.text = tr("Wait until the crossing is clear." if waiting_for_clear_crossing else "Waiting for a green light")
	elif walker.visible and not boating and not paused:
		status_label.text = _movement_hint(tr("Walk with {up}{left}{down}{right} or arrows · {seat} to enter a vehicle"))
	else:
		var current_speed := launch_speed if boating else crawler_speed if operating_excavator else speed
		status_label.text = tr("Speed  %02d km/h") % roundi(absf(current_speed) * 3.6)

func _make_driving_surface(label: String, size: Vector3, pos: Vector3, color: Color, collision := false, parent: Node3D = self) -> MeshInstance3D:
	var surface := _make_box(label, size, pos, color, collision, parent)
	driving_surfaces.append(surface.global_transform * surface.get_aabb())
	if size.y < .2:
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return surface

func _on_south_bridge(point: Vector3) -> bool:
	return absf(point.z) <= 5.8 and point.x >= HIGH_BRIDGE_X[0] and point.x <= HIGH_BRIDGE_X[3]

func _surface_height(x: float, z: float) -> float:
	if x >= HIGH_BRIDGE_X[0] and x <= HIGH_BRIDGE_X[3] and minf(absf(z+48.0), absf(z)) <= 5.8:
		return _bridge_rise(x, z) - .02 + (.16 if minf(absf(z+48.0), absf(z)) >= 4.95 else 0.0)
	var height := -0.2
	for surface in driving_surfaces:
		if x >= surface.position.x and x <= surface.end.x and z >= surface.position.z and z <= surface.end.z:
			height = maxf(height, surface.end.y)
	return height

func _make_roadside_solid(label: String, size: Vector3, pos: Vector3, color: Color, collision := false, parent: Node = self) -> MeshInstance3D:
	var mesh := _make_box(label, size, pos, color, collision, parent)
	var bounds := mesh.global_transform * mesh.get_aabb()
	# Driving sweeps use the vehicle's ground pivot, including on raised paving.
	bounds = bounds.expand(Vector3(bounds.position.x, bounds.position.y - 2.0, bounds.position.z))
	roadside_solids.append(bounds)
	return mesh

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

func _material(color: Color, roughness := 0.82, glow := false, finish := "") -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if not finish.is_empty():
		preload("res://art/surfaces/model_finish.gd").apply(material, finish)
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.1
	return material

func _noise_material(dark_color: Color, light_color: Color, frequency: float, strength: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
	shader_type spatial;
	#include "res://environment/road_grit.gdshaderinc"
	uniform vec4 dark_color : source_color;
	uniform vec4 light_color : source_color;
	uniform float wet = 0.0;
	uniform float snow_cover = 0.0;
	uniform float snow_retention = 1.0;
	uniform sampler2D work_map : hint_default_black, filter_linear, repeat_disable;
	uniform vec4 work_bounds = vec4(0.,0.,1.,1.);
	uniform bool is_grass = false;
	uniform bool road_paint = false;
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
		vec3 worked = vec3(0.0);
		if (is_grass || snow_cover > 0.0) {
			worked = texture(work_map,(world_position.xz-work_bounds.xy)/work_bounds.zw).rgb;
		}
		if (is_grass) {
			vec3 short_grass = light_color.rgb * vec3(1.06,1.15,.93) * (.96 + .08 * grain);
			ALBEDO = mix(ALBEDO, short_grass, worked.g);
		}
		ALBEDO *= 1.0 - wet*(road_paint ? .16 : .42);
		float coverage = smoothstep(.12, .92, snow_cover * snow_retention + (broad - .5) * .65);
		coverage *= (1.0-worked.r) * (1.0-.27*worked.b) * smoothstep(0., .22, snow_cover);
		ALBEDO = mix(ALBEDO,vec3(.73,.81,.85) * (.90 + .10 * grain),coverage);
		ALBEDO = road_grit_color(ALBEDO, world_position.xz, worked.b);
		ROUGHNESS = mix(mix(mix(.92,road_paint ? .48 : .23,wet),.94,coverage),.94,worked.b);
	}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("dark_color", dark_color)
	material.set_shader_parameter("light_color", light_color)
	material.set_shader_parameter("frequency", frequency)
	material.set_shader_parameter("strength", strength)
	return material
