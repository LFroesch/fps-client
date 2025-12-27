extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"

# Audio settings
var master_volume := 1.0
var music_volume := 0.7
var sfx_volume := 0.8
var mute_enabled := false

# Graphics settings
var fullscreen_enabled := false

# Control settings
var mouse_sensitivity := 0.5

func _ready() -> void:
	load_settings()
	apply_all_settings()

# Audio
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	save_settings()
	settings_changed.emit()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
	save_settings()
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
	save_settings()
	settings_changed.emit()

func set_audio_mute(enabled: bool) -> void:
	mute_enabled = enabled
	AudioServer.set_bus_mute(0, enabled)
	save_settings()
	settings_changed.emit()

# Graphics
func set_fullscreen(enabled: bool) -> void:
	fullscreen_enabled = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()
	settings_changed.emit()

# Controls
func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clamp(value, 0.1, 2.0)
	save_settings()
	settings_changed.emit()

# Persistence
func save_settings() -> void:
	var config := ConfigFile.new()

	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "mute_enabled", mute_enabled)

	# Graphics
	config.set_value("graphics", "fullscreen_enabled", fullscreen_enabled)

	# Controls
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)

	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)

	if err != OK:
		return

	# Audio
	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	mute_enabled = config.get_value("audio", "mute_enabled", mute_enabled)

	# Graphics
	fullscreen_enabled = config.get_value("graphics", "fullscreen_enabled", fullscreen_enabled)

	# Controls
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)

func apply_all_settings() -> void:
	# Audio
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	AudioServer.set_bus_mute(0, mute_enabled)

	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))

	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

	# Graphics
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
