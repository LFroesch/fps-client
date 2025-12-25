extends Control

@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit
@onready var map_grid = %MapGrid
@onready var pvp_button: Button = %PvPButton
@onready var zombies_button: Button = %ZombiesButton
@onready var audio_checkbox: CheckBox = %AudioCheckBox
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox

const NAME_SAVE_PATH := "user://player_name.dat"

var current_game_mode: MapRegistry.GameMode = MapRegistry.GameMode.PVP

func _ready() -> void:
	# Load player name
	if FileAccess.file_exists(NAME_SAVE_PATH):
		var file := FileAccess.open(NAME_SAVE_PATH, FileAccess.READ)
		player_name_line_edit.text = file.get_as_text().left(16)

	# Initialize map grid with default mode
	map_grid.setup(current_game_mode)

	# Setup button group for game mode toggle
	var button_group = ButtonGroup.new()
	pvp_button.button_group = button_group
	zombies_button.button_group = button_group

	# Setup settings toggles
	audio_checkbox.button_pressed = not SettingsManager.mute_enabled
	fullscreen_checkbox.button_pressed = SettingsManager.fullscreen_enabled

	#AudioManager.play_music(AudioManager.MusicKeys.MenuMusic)

func save_player_name() -> String:
	var player_name := player_name_line_edit.text
	if player_name.is_empty():
		player_name = "Player" + str(randi() % 1000)

	var file := FileAccess.open(NAME_SAVE_PATH, FileAccess.WRITE)
	file.store_string(player_name)

	return player_name

func _on_map_grid_map_selected(map_id: int, game_mode: MapRegistry.GameMode) -> void:
	var player_name = save_player_name()

	# Pass game mode to server for proper lobby routing
	Server.try_connect_client_to_lobby(player_name, map_id, game_mode)
	$QuickplayConnectionUI.activate(map_id)

func _on_pvp_button_pressed() -> void:
	current_game_mode = MapRegistry.GameMode.PVP
	map_grid.setup(current_game_mode)
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_zombies_button_pressed() -> void:
	current_game_mode = MapRegistry.GameMode.ZOMBIES
	map_grid.setup(current_game_mode)
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_audio_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_audio_mute(not toggled_on)

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
