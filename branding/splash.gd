extends ColorRect

const Languages := preload("res://l10n/localization.gd")
const GAME := "res://main.tscn"

func _ready() -> void:
	Languages.load_catalogs()
	var config := ConfigFile.new()
	config.load(Languages.SETTINGS_PATH)
	var stored = config.get_value("language", "locale", "")
	Languages.apply_language(stored if stored is String else "")
	$Logo.texture = Languages.logo(TranslationServer.get_locale())
	$Logo.accessibility_name = tr("Harbor Town Rollabout")
	get_window().title = tr("Harbor Town Rollabout")
	# Load the game on the main thread once the splash has been shown.
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file(GAME)
