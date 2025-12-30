extends Control

@onready var pvp_button: Button = %PvPButton
@onready var zombies_button: Button = %ZombiesButton
@onready var map_option: OptionButton = %MapOption
@onready var size_option: OptionButton = %SizeOption
@onready var play_button: Button = %PlayButton
@onready var cancel_button: Button = %CancelButton

var current_mode: int = MapRegistry.GameMode.ZOMBIES

func _ready() -> void:
	# Setup mode button group
	var mode_group = ButtonGroup.new()
	pvp_button.button_group = mode_group
	zombies_button.button_group = mode_group
	zombies_button.button_pressed = true

	# Populate options
	populate_maps()
	populate_sizes()

	# Connect signals
	pvp_button.pressed.connect(_on_mode_changed)
	zombies_button.pressed.connect(_on_mode_changed)
	play_button.pressed.connect(_on_play_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func populate_maps() -> void:
	map_option.clear()
	map_option.add_item("Any Map", -1)
	var maps = MapRegistry.get_maps_for_mode(current_mode)
	for map_id in maps:
		map_option.add_item(MapRegistry.get_map_name(map_id), map_id)

func populate_sizes() -> void:
	size_option.clear()
	size_option.add_item("Any Size", -1)
	if current_mode == MapRegistry.GameMode.PVP:
		size_option.add_item("2 Players", 2)
		size_option.add_item("4 Players", 4)
	else:
		size_option.add_item("1 Player", 1)
		size_option.add_item("2 Players", 2)
		size_option.add_item("3 Players", 3)
		size_option.add_item("4 Players", 4)

func _on_mode_changed() -> void:
	current_mode = MapRegistry.GameMode.ZOMBIES if zombies_button.button_pressed else MapRegistry.GameMode.PVP
	populate_maps()
	populate_sizes()

func _on_play_pressed() -> void:
	var player_name = get_player_name()
	var map_pref = map_option.get_selected_id()
	var size_pref = size_option.get_selected_id()

	Server.quick_play(player_name, current_mode, map_pref, size_pref)

func _on_cancel_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")

func get_player_name() -> String:
	const NAME_SAVE_PATH = "user://player_name.dat"
	if FileAccess.file_exists(NAME_SAVE_PATH):
		var file = FileAccess.open(NAME_SAVE_PATH, FileAccess.READ)
		return file.get_as_text().left(16)
	return "Player" + str(randi() % 1000)
