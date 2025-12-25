extends Control

@onready var status_label: Label = %StatusLabel
@onready var close_button: Button = %CloseButton
@onready var cancel_button: Button = %CancelButton

var selected_map_id : int = -1

func _enter_tree() -> void:
	hide()
	Server.on_lobby_clients_updated.connect(on_lobby_clients_updated)
	Server.on_cant_connect_to_lobby.connect(on_cant_connect_to_lobby)
	Server.on_lobby_locked.connect(on_lobby_locked)

func activate(map_id: int) -> void:
	selected_map_id = map_id
	var map_name := MapRegistry.get_map_name(map_id)

	if Server.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		close_button.hide()
		cancel_button.show()
		status_label.text = "Searching for %s..." % map_name
	else:
		close_button.show()
		cancel_button.hide()
		status_label.text = "You are not connected to the server. Try again later."
	show()

func on_cant_connect_to_lobby() -> void:
	status_label.text = "Server is full. Try again later."
	close_button.show()
	cancel_button.hide()

func on_lobby_locked() -> void:
	var map_name := MapRegistry.get_map_name(selected_map_id)
	status_label.text = "Starting %s..." % map_name
	close_button.hide()
	cancel_button.hide()

func on_lobby_clients_updated(connected_clients : int, max_clients : int) -> void:
	var map_name := MapRegistry.get_map_name(selected_map_id)
	status_label.text = "Searching for player %d/%d - %s" % [connected_clients, max_clients, map_name]

func _on_close_button_pressed() -> void:
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_cancel_button_pressed() -> void:
	hide()
	Server.cancel_quickplay_search()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
