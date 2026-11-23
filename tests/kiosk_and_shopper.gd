extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var sign_shop = game.shops
	for interval in [2.9,.8]:
		sign_shop.advance_grill_sign(interval)
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
	game._change_seat()
	await create_timer(.28).timeout
	if not game.shopper_boarding or absf(hinge.rotation.x)<.01 or absf(hinge.rotation.z)<.01:
		printerr("Entry shell did not swing diagonally")
		quit(1)
		return
	while game.shopper_boarding: await process_frame
	if not game.walker.visible:
		quit(1)
		return
	await game._change_seat()
	if game.walker.visible or game.shopper_boarding:
		printerr("Shopping trike entry failed")
		quit(1)
		return
	await game._change_seat()
	var shops = game.shops
	game.walker.position = Vector3(shops.storefront_x(6),0,41.7)
	shops.update_customer(true,game.walker.position,true)
	for locale in ["sv","en"]:
		TranslationServer.set_locale(locale)
		await process_frame
		for i in 4:
			var coins: int = shops.PRICES[6][i]
			var expected := ("%d mynt" if locale == "sv" else "%d coins") % coins
			if shops.grill_price_signs[i].text != expected:
				printerr("Incorrect hot dog board price: ",shops.grill_price_signs[i].text)
				quit(1)
				return
	game.wallet = 26
	game.purchases.clear()
	for i in 4:
		shops.purchase(6,i)
		if game.purchases.get(shops.MENUS[6][i]) != 1:
			printerr("Kitchen order failed")
			quit(1)
			return
	if game.wallet != 0:
		quit(1)
		return
	shops.purchase(6,0)
	if game.purchases["Hot dog"] != 1:
		quit(1)
		return
	for product in shops.MENUS[6]:
		var eat: Button = shops.snack_buttons[product]
		eat.pressed.emit()
		if game.purchases[product] != 0 or eat.visible or game.wallet != 0 or game.happy_seconds <= 0:
			printerr("Failed to eat one serving of ",product)
			quit(1)
			return
	print("All four kiosk meals could be eaten once.")
	print("Diagonal shopper exit and re-entry, kiosk hatch, four purchases and insufficient funds passed.")
	game._finish_quit()
