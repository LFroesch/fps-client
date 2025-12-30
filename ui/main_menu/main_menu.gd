extends Control

@onready var player_name_line_edit: LineEdit = %PlayerNameLineEdit
@onready var code_line_edit: LineEdit = %CodeLineEdit
@onready var browse_button: Button = %BrowseButton
@onready var create_button: Button = %CreateButton
@onready var audio_checkbox: CheckBox = %AudioCheckBox
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox

const NAME_SAVE_PATH := "user://player_name.dat"

func _ready() -> void:
	# Load player name
	if FileAccess.file_exists(NAME_SAVE_PATH):
		var file := FileAccess.open(NAME_SAVE_PATH, FileAccess.READ)
		player_name_line_edit.text = file.get_as_text().left(16)

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

func _on_browse_button_pressed() -> void:
	var player_name = save_player_name()
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/lobby/browse_lobbies_ui.tscn", player_name)

func _on_audio_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_audio_mute(not toggled_on)

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)

func _on_create_button_pressed() -> void:
	save_player_name()
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/lobby/create_lobby_ui.tscn")

func _on_join_button_pressed() -> void:
	var code = code_line_edit.text.to_upper().strip_edges()
	if code.length() != 6:
		return

	var player_name = save_player_name()
	Server.join_lobby(code, player_name)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
