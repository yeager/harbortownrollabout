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
	ResourceLoader.load_threaded_request(GAME)
	await get_tree().create_timer(1.2).timeout
	while ResourceLoader.load_threaded_get_status(GAME) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(GAME) as PackedScene
	if scene:
		get_tree().change_scene_to_packed(scene)
	else:
		get_tree().change_scene_to_file(GAME)
