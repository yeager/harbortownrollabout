extends SceneTree

const SWEDISH := {
	"Harbor Town Hospital": "Sjöstadens sjukhus",
	"Ambulance intake": "Ambulansintag",
	"Patient handover": "Patientöverlämning",
	"Police station": "Polisstationen",
	"Bakery & Coffee": "Bageri & Kaffe",
	"Clinic": "Vårdcentralen",
	"Library": "Biblioteket",
	"HARBOR TOWN SCHOOL": "SJÖSTADSSKOLAN",
	"HARBOR TOWN GARAGE": "SJÖSTADENS BILVERKSTAD",
	"Vehicle depot": "Fordonsdepå",
	"Tyre service": "Däckservice",
	"HARBOR FUEL": "SJÖMACKEN",
}

func _initialize() -> void:
	call_deferred("check_signs")

func check_signs() -> void:
	var game = preload("res://main.tscn").instantiate()
	root.add_child(game)
	var facade := game.find_child("Hospital illuminated sign", true, false) as MeshInstance3D
	if not facade or facade.position.y < 9.0 or facade.find_children("Red hospital cross*", "MeshInstance3D", false, false).size() != 3:
		printerr("The hospital sign or cross is missing at the roof line")
		quit(1)
		return
	for locale in ["sv", "de", "es", "fr", "fi", "nb", "en"]:
		TranslationServer.set_locale(locale)
		await process_frame
		var found := {}
		for label: Label3D in get_nodes_in_group("fitted_world_signs"):
			var key := label.text
			if not SWEDISH.has(key):
				continue
			found[key] = true
			var expected: String = SWEDISH[key] if locale == "sv" else TranslationServer.translate(key)
			var rendered := label.atr(key)
			var width := ThemeDB.fallback_font.get_string_size(rendered, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x * label.pixel_size
			if rendered != expected or width > float(label.get_meta("available_width")) + .005:
				printerr("Incorrect or overflowing sign in ", locale, ": ", key, " / ", rendered)
				quit(1)
				return
		if found.size() != SWEDISH.size():
			printerr("Missing localized building signs: ", found.keys())
			quit(1)
			return
	print("Building and patient handover signs followed all seven locales.")
	game._finish_quit(false)
