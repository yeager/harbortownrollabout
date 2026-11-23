extends RefCounted
## Approximate operating masses in kg, including the rider on two-wheelers.
const KG := {
	"ambulance": 4100, "polisbil": 1820, "brandbil": 16500, "bmw_x5_m60i": 2475,
	"taxi": 1740, "bargare": 7200, "m3_e30": 1250, "volvo240": 1380,
	"saab96": 970, "model_s": 2160, "city_bus": 13200, "snowmobile": 320,
	"volvo_xc60_polis": 2110, "porsche_gt3_rs": 1480, "ice_cream_van": 3350,
	"mini_cooper_cabriolet": 1370, "puch_dakota": 115, "monster_truck": 5400,
	"a_traktor": 1530, "raggarbil": 1930, "volvo_wheel_loader": 19800,
	"farm_tractor": 6800, "food_truck_road": 4650, "ride_on_mower": 295,
	"shopping_trike": 185, "refuse_truck": 14200, "traffic_bmw_blue": 2450, "traffic_bmw_silver": 2450,
	"cyklist": 88,
}
const EXCAVATOR_KG := 92000.0
const TRAM_KG := 42000.0
const LAUNCH_KG := 850.0
const SCOOTER_KG := 75.0
const FERRY_KG := 48000.0

static func for_model(path: String) -> float:
	return KG[path.get_file().get_basename()]

## Larger vehicles have larger engines and brakes. Payload adds inertia only.
static func road_response(empty_kg: float, load_kg := 0.0) -> float:
	return pow(1600.0 / empty_kg, .16) * empty_kg / (empty_kg + load_kg)
