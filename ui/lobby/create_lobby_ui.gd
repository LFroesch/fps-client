extends Control

@onready var pvp_button: Button = %PvPButton
@onready var zombies_button: Button = %ZombiesButton
@onready var map_option: OptionButton = %MapOption
@onready var player_1_button: Button = %Player1Button
@onready var player_2_button: Button = %Player2Button
@onready var player_3_button: Button = %Player3Button
@onready var player_4_button: Button = %Player4Button
@onready var public_checkbox: CheckBox = %PublicCheckBox
@onready var create_button: Button = %CreateButton
@onready var cancel_button: Button = %CancelButton

var current_mode: int = MapRegistry.GameMode.ZOMBIES
var selected_players: int = 2
var player_buttons: Array[Button] = []

func _ready() -> void:
	# Setup mode button group
	var mode_group = ButtonGroup.new()
	pvp_button.button_group = mode_group
	zombies_button.button_group = mode_group
	zombies_button.button_pressed = true

	# Setup player count button group
	var player_group = ButtonGroup.new()
	player_1_button.button_group = player_group
	player_2_button.button_group = player_group
	player_3_button.button_group = player_group
	player_4_button.button_group = player_group
	player_2_button.button_pressed = true

	player_buttons = [player_1_button, player_2_button, player_3_button, player_4_button]

	# Populate maps
	populate_maps()

	# Connect signals
	pvp_button.pressed.connect(_on_mode_changed)
	zombies_button.pressed.connect(_on_mode_changed)
	player_1_button.pressed.connect(func(): selected_players = 1)
	player_2_button.pressed.connect(func(): selected_players = 2)
	player_3_button.pressed.connect(func(): selected_players = 3)
	player_4_button.pressed.connect(func(): selected_players = 4)
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	_on_mode_changed()

func populate_maps() -> void:
	map_option.clear()
	var maps = MapRegistry.get_maps_for_mode(current_mode)
	for map_id in maps:
		map_option.add_item(MapRegistry.get_map_name(map_id), map_id)

func _on_mode_changed() -> void:
	current_mode = MapRegistry.GameMode.ZOMBIES if zombies_button.button_pressed else MapRegistry.GameMode.PVP
	populate_maps()

	# PvP: disable 1 player, only allow 2 or 4
	if current_mode == MapRegistry.GameMode.PVP:
		player_1_button.disabled = true
		player_3_button.disabled = true
		if selected_players == 1 or selected_players == 3:
			player_2_button.button_pressed = true
			selected_players = 2
	else:
		player_1_button.disabled = false
		player_3_button.disabled = false

func _on_create_pressed() -> void:
	var player_name = get_player_name()
	var map_id = map_option.get_selected_id()
	var is_public = public_checkbox.button_pressed

	Server.create_lobby(player_name, selected_players, map_id, current_mode, is_public)

func _on_cancel_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")

func get_player_name() -> String:
	const NAME_SAVE_PATH = "user://player_name.dat"
	if FileAccess.file_exists(NAME_SAVE_PATH):
		var file = FileAccess.open(NAME_SAVE_PATH, FileAccess.READ)
		return file.get_as_text().left(16)
	return "Player" + str(randi() % 1000)
