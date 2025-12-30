extends Node

signal on_lobby_clients_updated(connected_clients : int, max_clients : int)
signal on_cant_connect_to_lobby
signal on_lobby_locked

#Local
const PORT := 7777
const ADDRESS := "127.0.0.1"

#playit.gg
#const ADDRESS := "rss-hu.gl.at.ply.gg"
#const PORT := 6357

@onready var clock_sync_timer: Timer = $ClockSyncTimer

var peer := ENetMultiplayerPeer.new()

var clock_deviation_ms := 0

func _ready() -> void:
	var error := peer.create_client(ADDRESS, PORT)
	
	if error != OK:
		print("error connecting to server")
		return
	
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func _on_connected_to_server() -> void:
	clock_sync_timer.start()

func _on_connection_failed() -> void:
	print("failed to connect to server")
	_cleanup_connection()

func _on_server_disconnected() -> void:
	print("server disconnected")
	_cleanup_connection()

func _cleanup_connection() -> void:
	# Stop the clock sync timer to prevent RPC errors
	if clock_sync_timer and clock_sync_timer.is_inside_tree():
		clock_sync_timer.stop()

	# Clean up any active lobbies
	for child in get_children():
		if child is Lobby:
			child.queue_free()

func try_connect_client_to_lobby(player_name : String, map_id : int, game_mode : int = MapRegistry.GameMode.PVP) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_connect_client_to_lobby.rpc_id(1, player_name, map_id, game_mode)

@rpc("any_peer", "call_remote", "reliable")
func c_try_connect_client_to_lobby(player_name : String, map_id : int, game_mode : int = MapRegistry.GameMode.PVP) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_lobby_clients_updated(connected_clients : int, max_clients : int) -> void:
	on_lobby_clients_updated.emit(connected_clients, max_clients)

@rpc("authority", "call_remote", "reliable")
func s_client_cant_connect_to_lobby() -> void:
	on_cant_connect_to_lobby.emit()

func cancel_quickplay_search() -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_cancel_quickplay_search.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func c_cancel_quickplay_search() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_create_lobby_on_clients(lobby_name: String) -> void:
	var lobby := Lobby.new()
	lobby.name = lobby_name
	add_child(lobby, true)
	on_lobby_locked.emit()

func _on_clock_sync_timer_timeout() -> void:
	# Check if peer is connected before attempting RPC
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_get_server_clock_time.rpc_id(1, floori(Time.get_unix_time_from_system() * 1000))

@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_get_server_clock_time(client_clock_time : int) -> void:
	pass

@rpc("authority", "call_remote", "unreliable_ordered")
func s_return_server_clock_time(server_clock_time : int, old_client_clock_time : int) -> void:
	var local_time_when_server_sent_time := (floori(Time.get_unix_time_from_system() * 1000) + old_client_clock_time) / 2
	clock_deviation_ms = lerp(clock_deviation_ms, local_time_when_server_sent_time - server_clock_time, 0.5)

# New matchmaking system RPCs
func create_lobby(player_name: String, max_players: int, map_id: int, game_mode: int, is_public: bool) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_create_lobby.rpc_id(1, player_name, max_players, map_id, game_mode, is_public)

func join_lobby(lobby_id: String, player_name: String) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_join_lobby.rpc_id(1, lobby_id, player_name)

func quick_play(player_name: String, game_mode: int, map_pref: int, size_pref: int) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_quick_play.rpc_id(1, player_name, game_mode, map_pref, size_pref)

func start_lobby() -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_start_lobby.rpc_id(1)

func kick_player(target_client_id: int) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_kick_player.rpc_id(1, target_client_id)

func request_lobby_list(game_mode: int) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_request_lobby_list.rpc_id(1, game_mode)

@rpc("any_peer", "call_remote", "reliable")
func c_request_lobby_list(game_mode: int) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_lobby_list_updated(lobbies_list: Array[Dictionary]) -> void:
	# Notify lobby browser UI
	get_tree().call_group("LobbyBrowser", "update_lobby_list", lobbies_list)

@rpc("any_peer", "call_remote", "reliable")
func c_create_lobby(player_name: String, max_players: int, map_id: int, game_mode: int, is_public: bool) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_join_lobby(lobby_id: String, player_name: String) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_quick_play(player_name: String, game_mode: int, map_pref: int, size_pref: int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_start_lobby() -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_kick_player(target_client_id: int) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_joined_lobby(lobby_id: String, lobby_data: Dictionary) -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/lobby/waiting_room_ui.tscn", lobby_data)

@rpc("authority", "call_remote", "reliable")
func s_lobby_updated(lobby_id: String, lobby_data: Dictionary) -> void:
	get_tree().call_group("WaitingRoomUI", "update_lobby_data", lobby_data)

@rpc("authority", "call_remote", "reliable")
func s_kicked_from_lobby(reason: String) -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
