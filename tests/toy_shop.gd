extends SceneTree

func _initialize() -> void:
	call_deferred("verify_shop")

func verify_shop() -> void:
	var scene := preload("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	game._start_game()
	var shop: Node3D = game.shops
	var doorway: Vector3 = shop.storefront_entrance("Toy Harbour")
	TranslationServer.set_locale("sv")
	await process_frame
	game.map_button.pressed.emit()
	var stop: Button
	for button: Button in game.get_node("TownMap").find_children("*", "Button", true, false):
		if button.text.ends_with("Lekhamnen"):
			stop = button
			break
	if not stop:
		printerr("Lekhamnen was missing from the town map")
		quit(1)
		return
	stop.pressed.emit()
	if not game.map_goal.is_equal_approx(doorway):
		printerr("The toy shop map destination did not point to the doorway")
		quit(1)
		return
	game._change_seat()
	game.traffic_data.clear()
	var start := Vector3(doorway.x, 0, shop.FRONT_Z - 1.5)
	start.y = game._foot_height(start.x, start.z)
	game.walker.position = start
	game.walker.rotation.y = PI
	Input.action_press("ui_up")
	for frame in 100:
		game._walk(1.0 / 60.0)
	Input.action_release("ui_up")
	shop.update_customer(true, game.walker.position, true)
	var index: int = shop.TOY_SHOP
	if shop.inside != index or not shop.shop_card.visible or shop.awnings[index].visible:
		printerr("The player did not walk into the toy shop: ", game.walker.position)
		quit(1)
		return
	var nameplate: Label3D
	for label: Label3D in get_nodes_in_group("fitted_world_signs"):
		if label.text == "Toy Harbour":
			nameplate = label
			break
	if not nameplate or nameplate.atr(nameplate.text) != "Lekhamnen":
		printerr("The toy shop name did not localize to Swedish")
		quit(1)
		return
	game.wallet = 30
	for item in shop.MENUS[index].size():
		shop.purchase(index, item)
	if game.wallet != 11:
		printerr("Toy purchases did not charge the listed prices")
		quit(1)
		return
	if not carries_teddy(game):
		printerr("Buying a teddy bear did not place it in the player's hand")
		quit(1)
		return
	var teddy: Node3D = shop.toy_in_hand
	var grip_offset := teddy.transform
	var previous := teddy.global_position
	for frame in 30:
		game._animate_steps(game.walker, 6.4 / 60.0, 1.0 / 60.0)
	if teddy.global_position.distance_to(previous) < .05 or not teddy.transform.is_equal_approx(grip_offset):
		printerr("The teddy bear did not move with the animated hand")
		quit(1)
		return
	game.wallet = 100
	var palm: Node3D = teddy.get_parent()
	game.walker.position = shop.storefront_entrance("Momo & Bori")
	shop.update_customer(true, game.walker.position, true)
	for item in [2, 3, 3]:
		var old_toy: Node3D = shop.toy_in_hand
		shop.purchase(5, item)
		var current: Node3D = shop.toy_in_hand
		var expected := "MoonRabbit" if item == 3 else "RedPanda"
		if current.get_parent() != palm or current.name != expected or old_toy.get_parent() != null:
			printerr("Buying a boutique toy did not replace the previous prop on the same hand")
			quit(1)
			return
	game.walker.position = doorway
	shop.update_customer(true, game.walker.position, true)
	shop.purchase(index, 2)
	var products: Array = shop.MENUS[index]
	var teddy_product: String = shop.TEDDY_BEAR
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	for product: String in products:
		if game.purchases.get(product, 0) != (2 if product == teddy_product else 1):
			printerr("Toy purchase did not persist: ", product)
			quit(1)
			return
	if not carries_teddy(game):
		printerr("The carried teddy bear was not restored")
		quit(1)
		return
	print("Verified the toy shop, localized sign, purchases, same-frame toy replacement and carried teddy bear after reload.")
	quit()

func carries_teddy(game: Node3D) -> bool:
	var toy: Node3D = game.shops.toy_in_hand
	var arm: Node3D = game.walker.get_meta("arms")[0]
	return is_instance_valid(toy) and toy.name == "TeddyBear" and toy.get_parent() == arm.get_child(1)
