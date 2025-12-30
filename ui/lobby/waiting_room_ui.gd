extends Control

signal leave_lobby_pressed

@onready var lobby_info_label: Label = %LobbyInfoLabel
@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton

var lobby_data: Dictionary = {}
var is_host: bool = false

func _ready() -> void:
	add_to_group("WaitingRoomUI")
	start_button.pressed.connect(_on_start_button_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)

func activate(received_lobby_data: Dictionary) -> void:
	lobby_data = received_lobby_data
	is_host = lobby_data.get("host_id") == multiplayer.get_unique_id()
	update_ui()
	show()

func update_lobby_data(new_lobby_data: Dictionary) -> void:
	lobby_data = new_lobby_data
	is_host = lobby_data.get("host_id") == multiplayer.get_unique_id()
	update_ui()

func update_ui() -> void:
	# Update lobby info
	var map_name = MapRegistry.get_map_name(lobby_data.get("map_id", 0))
	var mode_name = "Zombies" if lobby_data.get("game_mode") == MapRegistry.GameMode.ZOMBIES else "PvP"
	var player_count = lobby_data.get("current_players", 0)
	var max_players = lobby_data.get("max_players", 4)

	lobby_info_label.text = "%s - %s (%d/%d Players)" % [map_name, mode_name, player_count, max_players]
	lobby_code_label.text = "Lobby Code: %s" % lobby_data.get("lobby_id", "")

	# Update player list
	for child in player_list.get_children():
		child.queue_free()

	var player_names = lobby_data.get("player_names", {})
	for client_id in player_names.keys():
		var player_info = player_names[client_id]
		var player_label = Label.new()
		var name_text = player_info.get("display_name", "Player")

		if client_id == multiplayer.get_unique_id():
			name_text += " (You)"
		if client_id == lobby_data.get("host_id"):
			name_text += " [HOST]"

		player_label.text = name_text
		player_list.add_child(player_label)

	# Show/hide start button based on host status
	start_button.visible = is_host
	start_button.disabled = not can_start()

func can_start() -> bool:
	if not is_host:
		return false

	var player_count = lobby_data.get("current_players", 0)
	var game_mode = lobby_data.get("game_mode", 0)

	if game_mode == MapRegistry.GameMode.PVP:
		return player_count >= 2 and player_count % 2 == 0
	else:
		return player_count >= 1

func _on_start_button_pressed() -> void:
	Server.start_lobby()

func _on_leave_button_pressed() -> void:
	Server.cancel_quickplay_search()
	leave_lobby_pressed.emit()
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
