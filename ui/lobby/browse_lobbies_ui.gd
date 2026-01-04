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

	# Create a card for each lobby
	for lobby_data in lobbies:
		create_lobby_card(lobby_data)

func create_lobby_card(lobby_data: Dictionary) -> void:
	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 55)

	# Create StyleBox for card
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.18, 0.25, 1)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.5, 0.7, 0.6)
	card.add_theme_stylebox_override("panel", style_box)

	# Make card clickable
	var button = Button.new()
	button.custom_minimum_size = Vector2(580, 55)

	# Transparent button style to keep card appearance
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", btn_style)
	button.add_theme_stylebox_override("pressed", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.2, 0.3, 0.4, 0.3)
	btn_hover.corner_radius_top_left = 10
	btn_hover.corner_radius_top_right = 10
	btn_hover.corner_radius_bottom_left = 10
	btn_hover.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("hover", btn_hover)

	button.pressed.connect(_on_lobby_selected.bind(lobby_data.get("lobby_id", "")))

	# Create content layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# Top row: Map name + player count
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)

	var map_label = Label.new()
	map_label.text = lobby_data.get("map_name", "Unknown Map")
	map_label.add_theme_font_size_override("font_size", 14)
	map_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1, 1))
	map_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(map_label)

	var player_count_label = Label.new()
	player_count_label.text = "%d/%d" % [
		lobby_data.get("current_players", 0),
		lobby_data.get("max_players", 4)
	]
	player_count_label.add_theme_font_size_override("font_size", 14)

	# Color-code based on fullness
	var current = lobby_data.get("current_players", 0)
	var max_p = lobby_data.get("max_players", 4)
	if current >= max_p:
		player_count_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))  # Full = red
	elif current >= max_p * 0.75:
		player_count_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))  # Almost full = yellow
	else:
		player_count_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5, 1))  # Has space = green

	top_row.add_child(player_count_label)

	# Bottom row: Host name
	var host_label = Label.new()
	host_label.text = "Host: %s" % lobby_data.get("host_name", "Unknown")
	host_label.add_theme_font_size_override("font_size", 11)
	host_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 1))
	vbox.add_child(host_label)

	# Add button overlay for clicking
	card.add_child(button)

	lobby_list_container.add_child(card)

func _on_lobby_selected(lobby_id: String) -> void:
	# Join the selected lobby
	Server.join_lobby(lobby_id, player_name)

func _on_refresh_pressed() -> void:
	Server.request_lobby_list(current_game_mode)

func _on_back_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
