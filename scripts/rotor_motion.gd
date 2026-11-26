extends RefCounted

const DISC_SHADER := preload("res://vehicles/rotor_motion.gdshader")

static func fit(hub: Node3D, radius: float, blade_count: int, tail: bool = false) -> MeshInstance3D:
	var disc := PlaneMesh.new()
	disc.size = Vector2.ONE * radius * 2.0
	var finish := ShaderMaterial.new()
	finish.shader = DISC_SHADER
	finish.set_shader_parameter("blade_count", float(blade_count))
	var motion := MeshInstance3D.new()
	motion.name = "Rotor motion blur"
	motion.mesh = disc
	motion.material_override = finish
	motion.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tail:
		motion.rotation.z = PI * .5
		motion.position.x = .026
	else:
		motion.position.y = .032
	hub.add_child(motion)
	return motion
