extends Control

@onready var lobby_list_container: VBoxContainer = %LobbyListContainer
@onready var refresh_button: Button = %RefreshButton
@onready var back_button: Button = %BackButton
@onready var pvp_tab_button: Button = %PvPTabButton
@onready var zombies_tab_button: Button = %ZombiesTabButton
@onready var no_lobbies_label: Label = %NoLobbiesLabel

var current_game_mode: int = MapRegistry.GameMode.PVP
var player_name: String = ""
var refresh_timer: Timer = null

func _ready() -> void:
	add_to_group("LobbyBrowser")
	refresh_button.pressed.connect(_on_refresh_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Setup tab buttons
	if pvp_tab_button:
		pvp_tab_button.pressed.connect(_on_pvp_tab_pressed)
	if zombies_tab_button:
		zombies_tab_button.pressed.connect(_on_zombies_tab_pressed)

	# Setup auto-refresh timer
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 1.0
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	add_child(refresh_timer)

func activate(saved_player_name: String) -> void:
	player_name = saved_player_name
	current_game_mode = MapRegistry.GameMode.PVP

	# Update tab button states
	update_tab_buttons()

	# Request lobby list from server
	Server.request_lobby_list(current_game_mode)

	# Start auto-refresh
	refresh_timer.start()

	show()

func _exit_tree() -> void:
	# Stop auto-refresh when leaving
	if refresh_timer:
		refresh_timer.stop()

func _on_pvp_tab_pressed() -> void:
	current_game_mode = MapRegistry.GameMode.PVP
	update_tab_buttons()
	Server.request_lobby_list(current_game_mode)

func _on_zombies_tab_pressed() -> void:
	current_game_mode = MapRegistry.GameMode.ZOMBIES
	update_tab_buttons()
	Server.request_lobby_list(current_game_mode)

func update_tab_buttons() -> void:
	if pvp_tab_button:
		pvp_tab_button.disabled = (current_game_mode == MapRegistry.GameMode.PVP)
	if zombies_tab_button:
		zombies_tab_button.disabled = (current_game_mode == MapRegistry.GameMode.ZOMBIES)

func _on_refresh_timer_timeout() -> void:
	# Auto-refresh lobby list every second
	Server.request_lobby_list(current_game_mode)

func update_lobby_list(lobbies: Array[Dictionary]) -> void:
	# Clear existing lobby entries
	for child in lobby_list_container.get_children():
		child.queue_free()

	if lobbies.is_empty():
		no_lobbies_label.visible = true
		return

	no_lobbies_label.visible = false

	# Create a button for each lobby
	for lobby_data in lobbies:
		var lobby_button = Button.new()
		lobby_button.custom_minimum_size = Vector2(600, 50)

		# Format: "MAP_NAME - HOST_NAME (2/4 players)"
		var button_text = "%s - %s (%d/%d players)" % [
			lobby_data.get("map_name", "Unknown"),
			lobby_data.get("host_name", "Unknown"),
			lobby_data.get("current_players", 0),
			lobby_data.get("max_players", 4)
		]

		lobby_button.text = button_text
		lobby_button.pressed.connect(_on_lobby_selected.bind(lobby_data.get("lobby_id", "")))

		lobby_list_container.add_child(lobby_button)

func _on_lobby_selected(lobby_id: String) -> void:
	# Join the selected lobby
	Server.join_lobby(lobby_id, player_name)

func _on_refresh_pressed() -> void:
	Server.request_lobby_list(current_game_mode)

func _on_back_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
