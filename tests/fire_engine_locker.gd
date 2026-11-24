extends SceneTree

func _initialize() -> void:
	call_deferred("check_model")

func check_model() -> void:
	var model := preload("res://vehicles/brandbil.glb").instantiate()
	root.add_child(model)
	var locker := preload("res://scripts/fire_locker.gd").new()
	locker.fit(model)
	if not locker.panel or locker.fittings.is_empty() or locker.work_lights.size() != 2:
		printerr("Incomplete shutter or work lights on imported fire engine")
		quit(1)
		return
	var closed_position := locker.panel.position
	locker.advance(2, true)
	if locker.panel.scale.y >= .1 or not locker.work_lights.all(func(light): return light.visible):
		printerr("Shutter did not open with work lights")
		quit(1)
		return
	locker.advance(2, false, true)
	if not locker.panel.position.is_equal_approx(closed_position) or not locker.work_lights.all(func(light): return light.visible):
		printerr("Reversing should light the ground with the shutter closed")
		quit(1)
		return
	locker.advance(.1, false)
	if locker.work_lights.any(func(light): return light.visible) or not locker.fittings.all(func(part): return part.visible and is_equal_approx(part.position.y,part.get_meta("closed_y"))):
		printerr("Work lights or shutter fittings did not reset")
		quit(1)
		return
	print("Imported fire engine opened and closed the shutter, restored fittings and switched both work lights.")
	quit()
