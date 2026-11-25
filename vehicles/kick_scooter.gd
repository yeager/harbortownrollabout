extends Node3D
## A personal scooter is unfolded on foot. Local -Z is forward.
const DECK_HEIGHT := .174
const WHEELBASE := .96
const MAX_SPEED := 5.55 # 20 km/h
var speed := 0.0
var yaw_input := 0.0
var grips: Array[Node3D] = []
var wheels: Array[Node3D] = []
var palm_stance: Array[Transform3D] = []
var elbow_stance: Array[Quaternion] = []
var stance: Array[Transform3D] = []
var turn_signals := preload("res://scripts/turn_indicators.gd").new()

func _ready() -> void:
	add_child(preload("res://vehicles/electric_kick_scooter.glb").instantiate())
	turn_signals.fit_anchors(self,
		[Vector3(-.252, 1.03, -.472), Vector3(-.087, .22, .54)],
		[Vector3(.252, 1.03, -.472), Vector3(.087, .22, .54)], Vector3(.054, .033, .027))
	for part in ["FrontWheel","RearWheel"]:
		wheels.append(find_child(part,true,false))
	grips.assign(find_children("Handle grip*", "MeshInstance3D", true, false))
	grips.sort_custom(func(a: Node3D,b: Node3D): return to_local(a.global_position).x < to_local(b.global_position).x)
	position.y = -DECK_HEIGHT
	hide()

func mount(rider: Node3D) -> void:
	if visible: return
	stance.clear()
	palm_stance.clear()
	elbow_stance.clear()
	var gait = rider.get_meta("gait")
	for limb: Node3D in rider.get_meta("legs") + rider.get_meta("arms"):
		stance.append(limb.transform)
	var legs: Array = rider.get_meta("legs")
	for i in 2:
		var side := -1 if i == 0 else 1
		legs[i].position.x = side*.063
		legs[i].position.z += side*.11
		palm_stance.append(gait.palms[i].transform)
		elbow_stance.append(gait.elbows[i].get_bone_pose_rotation(1))
		gait.reach_with_hand(i,grips[i].global_position)
	rider.position.y += DECK_HEIGHT*rider.scale.y
	speed = 0
	yaw_input = 0
	show()

func dismount(rider: Node3D) -> void:
	if not visible: return
	var limbs: Array = rider.get_meta("legs") + rider.get_meta("arms")
	for i in limbs.size():
		limbs[i].transform = stance[i]
	var gait = rider.get_meta("gait")
	for i in 2:
		gait.palms[i].transform = palm_stance[i]
		gait.elbows[i].set_bone_pose_rotation(1,elbow_stance[i])
	rider.position.y -= DECK_HEIGHT*rider.scale.y
	speed = 0
	yaw_input = 0
	turn_signals.advance(0, 0, false)
	hide()

func can_stand(game: Node3D, ground: Vector3, yaw: float, actor_scale: float) -> bool:
	# Both wheels and the deck need support, including when turning beside a quay.
	var half_span := Vector3.FORWARD.rotated(Vector3.UP,yaw)*WHEELBASE*.5*actor_scale
	for p: Vector3 in [ground-half_span,ground,ground+half_span]:
		if not game._on_foot_clear(p): return false
		for neighbour in game.walker_data:
			var offset: Vector3 = p-neighbour.actor.position
			if Vector2(offset.x,offset.z).length_squared() < .48*.48: return false
		for i in game.shops.SHOPS.size():
			if absf(p.x-game.shops.storefront_x(i))<4 and p.z>game.shops.FRONT_Z and p.z<49.4:
				return false
	return true

func ride(game: Node3D, throttle: float, steer: float, delta: float) -> void:
	var rider: Node3D = get_parent()
	var previous := rider.position
	var brake_force := 375.0 if throttle < 0.0 else 105.0
	speed = move_toward(speed, MAX_SPEED if throttle > 0 else 0.0, (195.0 if throttle > 0 else brake_force)*delta/preload("res://vehicles/mass.gd").SCOOTER_KG)
	yaw_input = move_toward(yaw_input,steer,delta*3.5)
	turn_signals.advance(yaw_input, delta, game.calm_mode or game.steady_player_lights)
	var steps := maxi(1,ceili(speed*delta/.12))
	var yaw_step := -yaw_input*minf(speed,2.0)*delta/steps
	for i in steps:
		var yaw := rider.rotation.y + yaw_step
		var forward := Vector3.FORWARD.rotated(Vector3.UP,yaw)
		var next := rider.position + forward*speed*delta/steps
		next.y = game._foot_height(next.x,next.z)
		if not game.street_signals.pedestrian_may_enter(rider.position,next) or not can_stand(game,next,yaw,rider.scale.y):
			speed = 0.0
			break
		rider.rotation.y = yaw
		rider.position = next + Vector3.UP*DECK_HEIGHT*rider.scale.y
	game.walk_basis = Basis(Vector3.UP,rider.rotation.y)
	game.listener.global_basis = game.walk_basis
	game.walking_velocity = (rider.position-previous)/maxf(delta,.00001)
	roll(previous.distance_to(rider.position), rider.scale.y)

func roll(distance: float, actor_scale: float) -> void:
	for wheel in wheels:
		wheel.rotate_x(-distance / (.118*actor_scale))
