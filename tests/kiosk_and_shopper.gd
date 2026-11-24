extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var sign_shop = game.shops
	for interval in [2.9,.8]:
		sign_shop.advance_grill_sign(interval)
		if sign_shop.grill_neon_light.visible != (interval < 1):
			printerr("Roof sign light out of sync with tubes")
			quit(1)
			return
		if sign_shop.grill_neon_finishes.size() != 3:
			quit(1)
			return
		for finish in sign_shop.grill_neon_finishes:
			if finish.emission_enabled != (interval < 1):
				printerr("Neon korv failed its blink cycle")
				quit(1)
				return
	game.vehicle_selector.get_child(game.SHOPPER).pressed.emit()
	game.start_button.pressed.emit()
	var hinge = game.vehicle_model.find_child("EntryHinge",true,false)
	# Inspect both ends of each imported rod throughout a complete wet sweep.
	var parked_arm: Transform3D = game.shopper_wiper_parts[0].transform
	game.weather.intensity = Vector2(1,0)
	for frame in 120:
		game._advance_wipers(TAU/5.4/120)
		for part: MeshInstance3D in game.shopper_wiper_parts:
			var bounds := part.get_aabb()
			for y: float in [bounds.position.y,bounds.end.y]:
				var point: Vector3 = hinge.transform * part.transform * Vector3(0,y,0)
				var t := (point.y-.916)/.603
				var u := point.x/(.418-.026*t)
				t += .018*u*u/.603
				if absf(u)>1.001 or t < -.001 or t > 1.001 or absf(point.z-(.448-.33*t-.09*u*u))>.003:
					printerr("Wiper leaves the windscreen: ",point)
					quit(1)
					return
		if frame == 59 and parked_arm.origin.distance_to(game.shopper_wiper_parts[0].position)<.08:
			printerr("Wiper failed to sweep")
			quit(1)
			return
	game.weather.intensity = Vector2.ZERO
	game._advance_wipers(4)
	if not parked_arm.is_equal_approx(game.shopper_wiper_parts[0].transform):
		printerr("Wiper failed to park")
		quit(1)
		return
	game._change_seat()
	await create_timer(.28).timeout
	if not game.shopper_boarding or absf(hinge.rotation.x)<.01 or absf(hinge.rotation.z)<.01:
		printerr("Entry shell did not swing diagonally")
		quit(1)
		return
	var recover := InputEventKey.new()
	recover.keycode = KEY_R
	recover.pressed = true
	var parked = game.parked_cars[game.SHOPPER]
	var original_pose: Transform3D = parked.transform
	game._unhandled_key_input(recover)
	while game.shopper_boarding: await process_frame
	if not game.walker.visible or parked.transform != original_pose or game.message != "Back in a safe place." or not game._on_foot_clear(game.walker.position):
		printerr("Recovery during exit must place the walker safely and leave the trike parked")
		quit(1)
		return
	game.walker.position = parked.to_global(game.parked_door_offset)
	game.message = ""
	game._change_seat()
	game._unhandled_key_input(recover)
	while game.shopper_boarding: await process_frame
	if game.walker.visible or game.message != "Back in a safe place." or not is_zero_approx(game.speed):
		printerr("Shopping trike entry failed")
		quit(1)
		return
	await game._change_seat()
	game.find_child("LargeText", true, false).button_pressed = true
	var shops = game.shops
	game.walker.position = Vector3(shops.storefront_x(6),0,41.7)
	shops.update_customer(true,game.walker.position,true)
	if shops.first_product.get_theme_font_size("font_size") != 22 or shops.balance.get_theme_font_size("font_size") != 22:
		printerr("Large text did not reach the shop balance and purchase buttons")
		quit(1)
		return
	const CURRENCIES := {"sv":"mynt","de":"Münzen","es":"monedas","fi":"kolikkoa","fr":"pièces","nb":"mynter","en":"coins"}
	for locale: String in CURRENCIES.keys():
		TranslationServer.set_locale(locale)
		await process_frame
		for i in 4:
			var coins: int = shops.PRICES[6][i]
			var expected := "%d %s" % [coins,CURRENCIES[locale]]
			var dish: String = shops.MENUS[6][i]
			var recipe: String = shops.GRILL_TOPPINGS[i]
			var button: Button = shops.panel.get_child(shops.first_product.get_index()+i)
			if button.icon == null or shops.snack_buttons[dish].icon != button.icon:
				printerr("Dish picture differs between buying and eating ", dish)
				quit(1)
				return
			if not button.text.contains(game.tr(dish)) or not button.text.ends_with(game.tr(recipe)) or not button.text.contains(expected):
				printerr("Menu did not update for ",locale," / ",dish,": ",button.text)
				quit(1)
				return
			if locale != "en" and game.tr(recipe) == recipe:
				printerr("Untranslated recipe for ",locale," / ",dish)
				quit(1)
				return
			if shops.grill_price_signs[i].text != expected:
				printerr("Incorrect hot dog board price: ",shops.grill_price_signs[i].text)
				quit(1)
				return
	game.wallet = 26
	game.purchases.clear()
	for i in 4:
		shops.purchase(6,i)
		if not shops.serving_dish.is_visible_in_tree() or shops.serving_dish.texture.region.position.x != i*64:
			printerr("Cook is holding the wrong dish")
			quit(1)
			return
		if game.purchases.get(shops.MENUS[6][i]) != 1:
			printerr("Kitchen order failed")
			quit(1)
			return
	if game.wallet != 0:
		quit(1)
		return
	await create_timer(1.85).timeout
	shops.purchase(6,0)
	if shops.serving_dish.visible or not is_zero_approx(shops.serving_arm.rotation.x):
		printerr("Failed purchase triggered a handover")
		quit(1)
		return
	if game.purchases["Hot dog"] != 1:
		quit(1)
		return
	for product in shops.MENUS[6]:
		var eat: Button = shops.snack_buttons[product]
		if product == shops.MENUS[6][0]:
			eat.grab_focus()
		if not eat.has_focus():
			printerr("Keyboard focus skipped ", product)
			quit(1)
			return
		for pressed in [true, false]:
			var enter := InputEventKey.new()
			enter.keycode = KEY_ENTER
			enter.pressed = pressed
			root.push_input(enter)
		if game.purchases[product] != 0 or eat.visible or game.wallet != 0 or game.happy_seconds <= 0:
			printerr("Failed to eat one serving of ",product)
			quit(1)
			return
	if not shops.first_product.has_focus():
		printerr("Keyboard focus lost after the final serving")
		quit(1)
		return
	print("Enter consumed all four meals and focus returned to the menu.")
	print("Diagonal shopper exit and re-entry, kiosk hatch, four purchases and insufficient funds passed.")
	for shop in [2, 3]:
		game.walker.position = Vector3(shops.storefront_x(shop), 0, 44)
		shops.update_customer(true, game.walker.position, true)
		for i in shops.MENUS[shop].size():
			var product: String = shops.MENUS[shop][i]
			game.wallet = shops.PRICES[shop][i]
			var buy: Button = shops.panel.get_child(shops.first_product.get_index()+i)
			buy.pressed.emit()
			var price: int = shops.PRICES[shop][i]
			var expected_receipt: String = shops.tr_n("%s · Paid %d coin. Thank you!", "%s · Paid %d coins. Thank you!", price) % [shops.tr(product), price]
			if not shops.receipt.is_visible_in_tree() or not shops.receipt.text.begins_with(expected_receipt):
				printerr("Receipt did not show the purchased item and price for ", product)
				quit(1)
				return
			var eat: Button = shops.snack_buttons[product]
			if not eat.is_visible_in_tree() or buy.icon == null or eat.icon != buy.icon:
				printerr("Missing matching snack button for ", product)
				quit(1)
				return
			eat.pressed.emit()
			if eat.visible or game.purchases[product] != 0 or game.wallet != 0:
				printerr("Failed to consume purchased ", product)
				quit(1)
				return
		if shop == 2:
			game.wallet = shops.PRICES[2][0]
			shops.first_product.pressed.emit()
	print("Bought and ate every pizza and sweet through the shop buttons.")
	game._process(0)
	var saved_position: Vector3 = game.walker.position
	game._save_checkpoint()
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game._resume_road_checkpoint()
	game._process(0)
	shops = game.shops
	if shops.order_recipe != 1 or shops.order_slip.texture.region.position.x != 64:
		printerr("The next pizza order and its picture must survive a restart")
		quit(1)
		return
	if shops.inside != 3 or not shops.first_product.has_focus() or not game.walker.position.is_equal_approx(saved_position):
		printerr("Sweet shop resume: ", shops.inside, " focus ", shops.first_product.has_focus(), " position ",game.walker.position," expected ",saved_position," checkpoint ",game.road_checkpoint)
		quit(1)
		return
	game.walker.position = Vector3(shops.storefront_x(3), 0, shops.FRONT_Z - 1)
	game._process(0)
	game.walker.position = game.parked_cars[game.SHOPPER].to_global(game.parked_door_offset)
	await game._change_seat()
	if shops.shop_card.visible or game.walker.visible or game.vehicle_index != game.SHOPPER:
		printerr("Could not return to the parked trike after reopening the shop")
		quit(1)
		return
	print("Resumed at the sweet counter and re-entered the parked trike.")
	game._finish_quit()
