extends SceneTree

func _initialize() -> void:
	call_deferred("check_prices")

func check_prices() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for locale in ["sv", "de", "es", "fi", "fr", "nb", "en"]:
		TranslationServer.set_locale(locale)
		await process_frame
		if not check_displays(game, locale):
			quit(1)
			return
	game.queue_free()
	await game.tree_exited
	print("All eight pump displays and twenty-four nozzle prices matched their grades in all seven languages.")
	quit()

func check_displays(game: Node, locale: String) -> bool:
	var tower := {}
	var prices: Array[Label3D] = []
	var meters: Array[Label3D] = []
	for label: Label3D in game.station_readouts:
		if label.get_parent() == game:
			var fields := label.text.split(" ", false)
			tower[fields[0]] = label.text.substr(fields[0].length()).strip_edges()
		elif label.text.ends_with("/L"):
			if is_zero_approx(label.position.x):
				meters.append(label)
			else:
				prices.append(label)
	var separator := "." if locale == "en" else ","
	var expected := {"95":"1,69 €", "98":"1,79 €", "D":"1,65 €"}
	match locale:
		"en": expected = {"95":"£1.45", "98":"£1.55", "D":"£1.49"}
		"sv": expected = {"95":"17,90 kr", "98":"18,90 kr", "D":"17,50 kr"}
		"nb": expected = {"95":"19,90 kr", "98":"20,90 kr", "D":"19,50 kr"}
	if tower != expected:
		printerr("Incorrect local tariff in ",locale,": ",tower)
		return false
	if tower.size() != 3 or prices.size() != 24 or meters.size() != 8:
		printerr("Expected three tower prices, eight pump displays and twenty-four nozzle labels")
		return false
	var fuel_on_main_displays := {}
	for meter in meters:
		var grade := ""
		for sibling in meter.get_parent().get_children():
			if sibling is Label3D and sibling.position.y < meter.position.y and tower.has(sibling.text):
				grade = sibling.text
				break
		if not tower.has(grade) or meter.text != tower[grade] + "/L":
			printerr("Main pump display disagrees with the tower in ", locale, ": ", meter.text)
			return false
		fuel_on_main_displays[grade] = true
	if fuel_on_main_displays.size() != tower.size():
		printerr("The main pump displays should advertise a mix of petrol and diesel")
		return false
	var grades_by_face := {}
	for price in prices:
		var matched := false
		for sibling in price.get_parent().get_children():
			if sibling is Label3D and is_equal_approx(sibling.position.x, price.position.x) and tower.has(sibling.text):
				var face := price.get_parent()
				if not grades_by_face.has(face): grades_by_face[face] = []
				grades_by_face[face].append(sibling.text)
				var unit_price: String = tower[sibling.text]
				matched = price.text == unit_price + "/L" and unit_price.contains(separator) and unit_price.trim_prefix("£").replace(",", ".").to_float() > 0
				break
		if not matched:
			printerr("Nozzle price disagrees with the tower in ", locale, ": ", price.text)
			return false
	for grades in grades_by_face.values():
		grades.sort()
		if grades != ["95","98","D"]:
			printerr("Missing fuel grade on a pump face")
			return false
	return true
