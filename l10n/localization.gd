extends RefCounted

const SOURCE := "en"

static func load_catalogs() -> void:
	for file in ResourceLoader.list_directory("res://l10n"):
		if file.get_extension() == "po":
			var catalog := load("res://l10n/" + file) as Translation
			if catalog != null:
				TranslationServer.add_translation(catalog)

static func locales() -> PackedStringArray:
	var result := TranslationServer.get_loaded_locales()
	if not SOURCE in result:
		result.append(SOURCE)
	result.sort()
	return result

static func variants(locale: String) -> PackedStringArray:
	var full := TranslationServer.standardize_locale(locale)
	var base := full.get_slice("_", 0)
	return PackedStringArray([full]) if full == base else PackedStringArray([full, base])

static func media(pattern: String, locale: String) -> Resource:
	for variant in variants(locale):
		var path := pattern % variant
		if ResourceLoader.exists(path):
			return load(path)
	return null

static func radio_tracks(locale: String) -> PackedStringArray:
	var by_locale := {}
	for file in ResourceLoader.list_directory("res://audio/radio"):
		if file.get_extension() != "mp3": continue
		var name := file.get_basename()
		var suffix := name.rfind(" (")
		var code := SOURCE
		if suffix >= 0 and name.ends_with(")"):
			code = TranslationServer.standardize_locale(name.substr(suffix+2, name.length()-suffix-3).to_lower())
		if not by_locale.has(code): by_locale[code] = []
		by_locale[code].append(file)
	for variant in variants(locale):
		if by_locale.has(variant): return PackedStringArray(by_locale[variant])
	return PackedStringArray()

const SETTINGS_PATH := "user://preferences.cfg"

static func apply_language(preference: String, system_locale := OS.get_locale()) -> void:
	var available := locales()
	for choice in [preference, system_locale]:
		if str(choice).strip_edges().is_empty(): continue
		for candidate in variants(str(choice).strip_edges()):
			if candidate in available:
				TranslationServer.set_locale(candidate)
				return
	TranslationServer.set_locale(SOURCE)

static func logo(locale: String) -> Texture2D:
	var localized := media("res://branding/rollabout-%s.png", locale) as Texture2D
	return localized if localized else preload("res://branding/rollabout-en.png")
