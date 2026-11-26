extends RefCounted
## Approximate operating masses in kg, including the rider on two-wheelers.
const KG := {
	"ambulance": 4100, "polisbil": 1820, "brandbil": 16500, "luxury_suv": 2475,
	"taxi": 1740, "bargare": 7200, "sport_sedan": 1250, "classic_estate": 1380,
	"classic_fastback": 970, "electric_sedan": 2160, "city_bus": 13200, "snowmobile": 320,
	"police_suv": 2110, "track_coupe": 1480, "ice_cream_van": 3350,
	"compact_convertible": 1370, "classic_moped": 115, "monster_truck": 5400,
	"a_traktor": 1530, "raggarbil": 1930, "wheel_loader": 19800,
	"farm_tractor": 6800, "food_truck_road": 4650, "ride_on_mower": 295,
	"shopping_trike": 185, "refuse_truck": 14200, "traffic_suv_blue": 2450, "traffic_suv_silver": 2450,
	"cyklist": 88, "dam_pickup": 2870, "rally_coupe": 1290,
}
const EXCAVATOR_KG := 92000.0
const TRAM_KG := 42000.0
const LAUNCH_KG := 850.0
const SCOOTER_KG := 75.0
const FERRY_KG := 48000.0
const PATROL_HELICOPTER_KG := 3200.0

static func for_model(path: String) -> float:
	return KG[path.get_file().get_basename()]

## Larger vehicles have larger engines and brakes. Payload adds inertia only.
static func road_response(empty_kg: float, load_kg := 0.0) -> float:
	return pow(1600.0 / empty_kg, .16) * empty_kg / (empty_kg + load_kg)

## Normal collision impulse, projected onto each vehicle's rolling direction.
static func contact_speeds(player_speed: float, traffic_speed: float, player_axis: Vector3, traffic_axis: Vector3, normal: Vector3, player_mass: float, traffic_mass: float) -> Vector2:
	var a := player_axis.dot(normal)
	var b := traffic_axis.dot(normal)
	var closing := player_speed*a - traffic_speed*b
	if closing <= 0.0: return Vector2(player_speed,traffic_speed)
	var impulse := 1.12 * closing / (1.0/player_mass + 1.0/traffic_mass)
	return Vector2(player_speed - impulse*a/player_mass, maxf(0.0, traffic_speed + impulse*b/traffic_mass))
