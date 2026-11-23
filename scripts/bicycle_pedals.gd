extends RefCounted

const RADIUS := .135
const METRES_PER_TURN := 2.65
var angle := 0.0
var legs: Array[Dictionary] = []

func _init(world: Node, model: Node3D) -> void:
	var axle := model.find_child("Pedal crank", true, false) as MeshInstance3D
	var mount := axle.get_parent() as Node3D
	axle.rotation = Vector3(0,0,PI/2)
	model.find_child("Pedal",true,false).hide()
	for thigh: MeshInstance3D in model.find_children("Cyclist thigh*","MeshInstance3D",true,false):
		var side := signf(thigh.position.x)
		var shin: MeshInstance3D
		for candidate: MeshInstance3D in model.find_children("Cyclist lower leg*","MeshInstance3D",true,false):
			if signf(candidate.position.x) == side: shin = candidate
		var crank = world._make_box("Crank arm",Vector3(.024,RADIUS,.028),Vector3.ZERO,Color("#98a0a5"),false,mount)
		var pedal = world._make_box("Pedal tread",Vector3(.102,.028,.074),Vector3.ZERO,Color("#292d30"),false,mount)
		var shoe = world._make_box("Cycling shoe",Vector3(.105,.073,.205),Vector3.ZERO,Color("#45403c"),false,mount)
		legs.append({"side":side,"thigh":thigh,"shin":shin,"crank":crank,"pedal":pedal,"shoe":shoe})
	advance(0)

func _span(part: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var offset := end-start
	part.position = (start+end)*.5
	part.basis = Basis(Quaternion(Vector3.UP,offset.normalized())).scaled_local(Vector3(1,offset.length()/part.mesh.get_aabb().size.y,1))

func advance(travel: float) -> void:
	angle = fposmod(angle+travel*TAU/METRES_PER_TURN,TAU)
	for leg in legs:
		var axle := Vector3(leg.side*.12,.46,-.02)
		var throw_offset := Vector3(0,cos(angle),sin(angle))*RADIUS*float(leg.side)
		var foot := axle+throw_offset
		_span(leg.crank,axle,foot)
		leg.pedal.position = foot
		leg.shoe.position = foot+Vector3(0,.0505,.016)
		var ankle := foot+Vector3(0,.077,-.04)
		var hip := Vector3(axle.x,1.13,-.13)
		var axis := ankle-hip
		var forward := Vector3(0,axis.z,-axis.y).normalized()
		# Equal-length leg segments meet at the forward of the two possible knees.
		var knee := (hip+ankle)*.5 + forward*sqrt(maxf(0,.40*.40-axis.length_squared()*.25))
		_span(leg.thigh,hip,knee)
		_span(leg.shin,knee,ankle)
