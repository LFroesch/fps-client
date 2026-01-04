extends Control

signal leave_lobby_pressed

@onready var lobby_info_label: Label = %LobbyInfoLabel
@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton
@onready var leave_button: Button = %LeaveButton

var lobby_data: Dictionary = {}
var is_host: bool = false
var host_migrated: bool = false

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
	var old_host_id = lobby_data.get("host_id", -1)
	lobby_data = new_lobby_data
	var new_host_id = lobby_data.get("host_id", -1)
	var previous_is_host = is_host
	is_host = new_host_id == multiplayer.get_unique_id()

	# Check for host migration
	if old_host_id != -1 and old_host_id != new_host_id and is_host and not previous_is_host:
		host_migrated = true
		show_host_migration_notification()

	update_ui()

func show_host_migration_notification() -> void:
	# Create temporary notification label
	var notification = Label.new()
	notification.text = "You are now the host!"
	notification.modulate = Color(1, 0.8, 0, 1)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var host_notification_timer = get_tree().create_timer(3.0)
	host_notification_timer.timeout.connect(func(): notification.queue_free())
	lobby_code_label.get_parent().add_child(notification)
	lobby_code_label.get_parent().move_child(notification, lobby_code_label.get_index() + 1)

func update_ui() -> void:
	# Update lobby info
	var map_name = MapRegistry.get_map_name(lobby_data.get("map_id", 0))
	var mode_name = "Zombies" if lobby_data.get("game_mode") == MapRegistry.GameMode.ZOMBIES else "PvP"
	var player_count = lobby_data.get("current_players", 0)
	var max_players = lobby_data.get("max_players", 4)

	lobby_info_label.text = "%s - %s (%d/%d Players)" % [map_name, mode_name, player_count, max_players]
	lobby_code_label.text = "Code: %s" % lobby_data.get("lobby_id", "")

	# Update player list
	for child in player_list.get_children():
		child.queue_free()

	var player_names = lobby_data.get("player_names", {})
	print("[WaitingRoom] Player names data: ", player_names)
	for client_id in player_names.keys():
		var player_info = player_names[client_id]
		print("[WaitingRoom] Creating card for client %d: %s" % [client_id, player_info])
		create_player_card(client_id, player_info)

	# Show/hide start button based on host status
	start_button.visible = is_host
	start_button.disabled = not can_start()

func create_player_card(client_id: int, player_info: Dictionary) -> void:
	# Create card container (use default theme - blocky style)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 44)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create horizontal container for player info
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(hbox)

	# Player name label
	var name_label = Label.new()
	# Handle both Dictionary and direct access patterns
	var name_text: String
	if player_info is Dictionary:
		name_text = player_info.get("display_name", "Player%d" % client_id)
	else:
		name_text = "Player%d" % client_id

	# Fallback if name is empty
	if name_text.is_empty():
		name_text = "Player%d" % client_id

	if client_id == multiplayer.get_unique_id():
		name_text += " (You)"
	if client_id == lobby_data.get("host_id"):
		name_text += " ★ HOST"

	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)

	# Add kick button if host and not self
	if is_host and client_id != multiplayer.get_unique_id():
		var kick_button = Button.new()
		kick_button.text = "KICK"
		kick_button.custom_minimum_size = Vector2(60, 36)
		kick_button.add_theme_font_size_override("font_size", 14)
		kick_button.tooltip_text = "Kick Player"
		kick_button.pressed.connect(_on_kick_player_pressed.bind(client_id))
		hbox.add_child(kick_button)

	player_list.add_child(card)

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

func _on_kick_player_pressed(client_id: int) -> void:
	# Only host can kick
	if not is_host:
		return

	# Can't kick yourself
	if client_id == multiplayer.get_unique_id():
		return

	Server.kick_player(client_id)
