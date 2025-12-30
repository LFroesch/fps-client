extends Node3D
class_name Lobby

const INTERPOLATION_BUFFER_MS := 100

var players := {}
var world_state_buffer : Array[Dictionary] = []
var pickups := {}
var grenades := {}
var zombies := {}  # For zombies mode
var player_names_and_teams := {}
var map_id : int = -1
var game_mode : int = 0  # 0 = PVP, 1 = Zombies
var match_started : bool = false  # Track if match has started 

func get_local_player() -> PlayerLocal:
	return players.get(multiplayer.get_unique_id())

func get_remote_players() -> Dictionary:
	var remote_players := {}

	for client_id in players.keys():
		if client_id == multiplayer.get_unique_id():
			continue
		var maybe_remote_player = players.get(client_id)
		if is_instance_valid(maybe_remote_player) and maybe_remote_player is PlayerRemote:
			remote_players[client_id] = maybe_remote_player

	return remote_players

func _ready() -> void:
	add_to_group("Lobby")
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		c_lock_client.rpc_id(1)
	set_physics_process(false)

func _exit_tree() -> void:
	# Stop physics processing to prevent errors during cleanup
	set_physics_process(false)

	# Clear all references to prevent stale node access
	players.clear()
	pickups.clear()
	grenades.clear()
	player_names_and_teams.clear()
	world_state_buffer.clear()

func _physics_process(delta: float) -> void:
	send_player_state()
	handle_world_state()

func send_player_state() -> void:
	if get_local_player() == null:
		return
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_send_player_state.rpc_id(1, create_player_data())

func create_player_data() -> Dictionary:
	var local_player := get_local_player()
	var player_state := {
		"pos" : local_player.position,
		"rot_y" : local_player.rotation.y,
		"anim" : local_player.current_anim,
		"rot_x" : local_player.head.rotation.x
	}
	return player_state

func handle_world_state() -> void:
	if world_state_buffer.size() < 2:
		return

	var target_render_unix_ms : int = floori(Time.get_unix_time_from_system() * 1000) - INTERPOLATION_BUFFER_MS - Server.clock_deviation_ms
	while world_state_buffer.size() > 2 and target_render_unix_ms > world_state_buffer[1].t:
		world_state_buffer.pop_front()

	var lerp_weight := remap(target_render_unix_ms, world_state_buffer[0].t, world_state_buffer[1].t, 0, 1)

	if world_state_buffer[0].has("gr") and world_state_buffer[1].has("gr"):
		handle_grenades(world_state_buffer[0].gr, world_state_buffer[1].gr, lerp_weight)

	# Handle zombie interpolation
	if world_state_buffer[0].has("zs") and world_state_buffer[1].has("zs"):
		handle_zombies(world_state_buffer[0].zs, world_state_buffer[1].zs, lerp_weight)

	var remote_players := get_remote_players()

	if not world_state_buffer[0].has("ps") or not world_state_buffer[1].has("ps"):
		return

	for client_id in world_state_buffer[1].ps.keys():
		if not client_id in remote_players.keys():
			continue
		if not client_id in world_state_buffer[0].ps.keys():
			continue

		if not is_instance_valid(players.get(client_id)):
			continue

		var remote_player : PlayerRemote = remote_players.get(client_id)
		remote_player.update_body_geometry(
			world_state_buffer[0].ps.get(client_id),
			world_state_buffer[1].ps.get(client_id),
			lerp_weight
		)

func handle_zombies(old_zombie_data : Dictionary, new_zombie_data : Dictionary, lerp_weight : float) -> void:
	# Interpolate existing zombies
	for zombie_id in new_zombie_data.keys():
		if zombies.has(zombie_id) and is_instance_valid(zombies.get(zombie_id)):
			var zombie = zombies.get(zombie_id)

			# Interpolate position
			if old_zombie_data.has(zombie_id):
				var old_pos = old_zombie_data.get(zombie_id).pos
				var new_pos = new_zombie_data.get(zombie_id).pos
				if zombie_id == 0 and randf() < 0.01:  # Debug first zombie occasionally
					print("[CLIENT %s] Zombie %d: old_pos=%v new_pos=%v, current_pos=%v, global=%v" % [name, zombie_id, old_pos, new_pos, zombie.position, zombie.global_position])
				zombie.position = old_pos.lerp(new_pos, lerp_weight)

				# Interpolate rotation
				var old_rot = old_zombie_data.get(zombie_id).rot_y
				var new_rot = new_zombie_data.get(zombie_id).rot_y
				zombie.rotation.y = lerp_angle(old_rot, new_rot, lerp_weight)
			else:
				# Just appeared, snap to position
				zombie.position = new_zombie_data.get(zombie_id).pos
				zombie.rotation.y = new_zombie_data.get(zombie_id).rot_y

func handle_grenades(old_grenade_data : Dictionary, new_grenade_data : Dictionary, lerp_weight : float) -> void:
	for grenade_name in new_grenade_data.keys():
		# maybe spawning new grenades
		if not grenade_name in grenades.keys():
			var grenade : Grenade = preload("res://player/grenade/grenade.tscn").instantiate()
			grenades[grenade_name] = {"inst" : grenade, "exploded" : false}
			grenade.name = grenade_name
			grenade.transform = new_grenade_data.get(grenade_name).tform
			add_child(grenade, true)

	for grenade_name in old_grenade_data.keys():
		# exploding the grenade if not in buffer anymore nad not exploded yet
		if not grenade_name in new_grenade_data.keys():
			if not grenade_name in grenades.keys():
				continue

			if not grenades.get(grenade_name).exploded:
				explode_grenade(grenade_name)
				grenades.erase(grenade_name)
				continue
		if grenades.get(grenade_name).exploded:
			continue

		# moving the grenades
		var grenade : Grenade = grenades.get(grenade_name).inst

		grenade.lerp_tform(old_grenade_data.get(grenade_name), new_grenade_data.get(grenade_name), lerp_weight)


# Make sure it arrives in right order, but can drop some packets here or there not game breaking
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(player_state : Dictionary) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map(received_map_id: int, received_game_mode: int = 0) -> void:
	if not is_inside_tree():
		return

	map_id = received_map_id
	game_mode = received_game_mode

	var map_path := MapRegistry.get_client_path(map_id)
	if map_path.is_empty():
		print("ERROR: Invalid map_id %d" % map_id)
		return

	var map = load(map_path).instantiate()
	map.name = "Map"
	map.ready.connect(map_ready)
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager", "clear_scenes")
	#AudioManager.play_music(AudioManager.MusicKeys.BattleMusic)

	# Hide team scores if in zombies mode
	if game_mode == 1:
		get_tree().call_group("MatchInfoUI", "hide_team_scores")

func map_ready() -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	# Remove mode-specific elements
	if game_mode == 0:  # PVP mode - remove zombie buyables
		_remove_zombie_buyables()

	c_map_ready.rpc_id(1)
	
@rpc("any_peer", "call_remote", "reliable")
func c_map_ready() -> void:
	pass

func _remove_zombie_buyables() -> void:
	# Find and remove all zombie-specific buyables in PVP mode
	var map_node = get_node_or_null("Map")
	if not map_node:
		return

	# Remove all WeaponWallbuy nodes
	for child in map_node.get_children():
		_remove_buyables_recursive(child)

func _remove_buyables_recursive(node: Node) -> void:
	# Check if this node is any type of buyable (all buyables are zombie-mode specific)
	# Use duck typing to avoid class reference issues
	if node.has_method("on_purchase_requested"):
		node.queue_free()
		return

	# Recursively check children
	for child in node.get_children():
		_remove_buyables_recursive(child)

@rpc("authority", "call_remote", "reliable")
func s_start_match() -> void:
	match_started = true
	get_tree().call_group("PlayerLocal", "unfreeze")
	set_physics_process(true)

@rpc("authority", "call_remote", "reliable")
func s_spawn_player(client_id: int, spawn_tform : Transform3D, team : int, player_name : String, weapon_id : int, auto_freeze : bool):
	if not is_inside_tree():
		return

	var player : PlayerCharacter

	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
		player.auto_freeze = auto_freeze
	else:
		player = preload("res://player/remote/player_remote.tscn").instantiate()
		player.display_name = player_name

	player.weapon_id = weapon_id
	player.team = team
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	players[client_id] = player

	player_names_and_teams[client_id] = {"display_name" : player_name, "team"  : team}

	# Add teammate cards in zombie mode (after player is added to dictionary)
	if game_mode == 1:
		# If this is MY player spawning, add cards for all OTHER players
		if client_id == multiplayer.get_unique_id():
			await get_tree().process_frame  # Wait for HUD to be ready
			for other_id in player_names_and_teams.keys():
				if other_id != multiplayer.get_unique_id():
					var other_data = player_names_and_teams[other_id]
					get_tree().call_group("HUDManager", "add_teammate", other_id, other_data.display_name)
		# If this is ANOTHER player spawning, add their card to my HUD
		else:
			get_tree().call_group("HUDManager", "add_teammate", client_id, player_name)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_world_state : Dictionary) -> void:
	if not is_inside_tree():
		return
	world_state_buffer.append(new_world_state)

@rpc("authority", "call_remote", "reliable")
func s_start_weapon_selection() -> void:
	if game_mode == 1:  # Zombies mode
		get_tree().call_group("ZombiesCountdownUI", "activate", map_id)
	else:  # PvP mode
		get_tree().call_group("WeaponSelectionUI", "activate", map_id)

func weapon_selected(weapon_id : int) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_weapon_selected.rpc_id(1, weapon_id)

@rpc("any_peer", "call_remote", "reliable")
func c_weapon_selected(weapon_id : int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_debug_add_points(amount : int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_debug_damage_or_kill(damage : int) -> void:
	pass

func local_shot_fired() -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_shot_fired.rpc_id(1, floori(Time.get_unix_time_from_system() * 1000) - Server.clock_deviation_ms, create_player_data())

@rpc("any_peer", "call_remote", "unreliable")
func c_shot_fired(time_stamp : int, player_data : Dictionary) -> void:
	pass
	
@rpc("authority", "call_remote", "unreliable")
func s_play_shoot_fx(target_client_id : int) -> void:
	var remote_players := get_remote_players()
	if not target_client_id in remote_players:
		return
	remote_players[target_client_id].play_shoot_fx()

@rpc("authority", "call_remote", "unreliable")
func s_spawn_bullet_hit_fx(pos: Vector3, normal : Vector3, type: int) -> void:
	if not is_inside_tree():
		return

	var bullet_hit_fx : Node3D
	match type:
		0: #environment
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_environment.tscn").instantiate()
		1: #player
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_player.tscn").instantiate()
	var spawn_tform := Transform3D.IDENTITY

	if not normal.is_equal_approx(Vector3.UP) and not normal.is_equal_approx(Vector3.DOWN):
		spawn_tform = spawn_tform.looking_at(normal)
		spawn_tform = spawn_tform.rotated_local(Vector3.RIGHT, -PI/2)

	spawn_tform.origin = pos
	bullet_hit_fx.global_transform = spawn_tform
	add_child(bullet_hit_fx)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_health(target_client_id : int, current_health : int, max_health : int, changed_amount: int, shooter_id : int = 0, is_headshot := false) -> void:
	var maybe_player : PlayerCharacter = players.get(target_client_id)
	if is_instance_valid(maybe_player):
		maybe_player.update_health_bar(current_health, max_health, changed_amount)

	# Update teammate status card in zombie mode (only for other players)
	if game_mode == 1 and target_client_id != multiplayer.get_unique_id():
		get_tree().call_group("HUDManager", "update_teammate_health", target_client_id, current_health, max_health)

	# Show hit marker and damage numbers if local player is the shooter
	if shooter_id == multiplayer.get_unique_id() and changed_amount < 0:
		var damage := absi(changed_amount)
		get_tree().call_group("HUDManager", "show_hit_marker", is_headshot)
		get_tree().call_group("HUDManager", "show_damage_number", damage, is_headshot)

@rpc("authority", "call_remote", "reliable")
func s_spawn_pickup(pickup_name : String, pickup_type : int, pos : Vector3) -> void:
	if not is_inside_tree():
		return

	# In zombie mode, ignore PVP map pickups (spawned before match starts)
	if game_mode == 1 and not match_started:
		return

	var pickup : Pickup = preload("res://player/pickups/pickup.tscn").instantiate()
	pickup.name = pickup_name
	pickup.position = pos
	pickup.pickup_type = pickup_type
	add_child(pickup, true)
	pickups[pickup.name] = pickup

	# In zombie mode, hide the platform/base visuals (zombie drops only, after match starts)
	if game_mode == 1 and match_started:
		await pickup.ready
		if pickup.has_node("Platform"):
			pickup.get_node("Platform").visible = false
		if pickup.has_node("MeshHolder"):
			pickup.get_node("MeshHolder").visible = false

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_started(pickup_name : String) -> void:
	if pickups.has(pickup_name) and is_instance_valid(pickups.get(pickup_name)):
		pickups.get(pickup_name).cooldown_started()

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_ended(pickup_name : String) -> void:
	if pickups.has(pickup_name) and is_instance_valid(pickups.get(pickup_name)):
		pickups.get(pickup_name).cooldown_ended()

@rpc("authority", "call_remote", "reliable")
func s_player_died(dead_player_id : int, killer_id) -> void:
	if not is_inside_tree():
		return

	if players.has(dead_player_id) and is_instance_valid(players.get(dead_player_id)):
		var dead_player = players.get(dead_player_id)
		# Capture position before any other operations to avoid race conditions
		var death_position: Vector3
		var can_spawn_fx := false
		if dead_player.is_inside_tree():
			death_position = dead_player.global_position
			can_spawn_fx = true

		# Spawn elimination effects if we captured a valid position
		if can_spawn_fx:
			var eliminated_fx := preload("res://player/player_eliminated_effects.tscn").instantiate()
			eliminated_fx.global_position = death_position
			add_child(eliminated_fx)

		dead_player.queue_free()
		players[dead_player_id] = null

	# Show kill confirmation if local player is the killer
	if killer_id == multiplayer.get_unique_id() and killer_id != dead_player_id:
		get_tree().call_group("HUDManager", "show_kill_confirmation")

	# Show elimination text if player data is available
	if player_names_and_teams.has(killer_id) and player_names_and_teams.has(dead_player_id):
		get_tree().call_group(
			"MatchInfoUI",
			"show_elimination_text",
			killer_id,
			dead_player_id,
			player_names_and_teams.get(killer_id).display_name,
			player_names_and_teams.get(killer_id).team,
			player_names_and_teams.get(dead_player_id).display_name,
			player_names_and_teams.get(dead_player_id).team,
		)

@rpc("authority", "call_remote", "reliable")
func s_update_game_scores(blue_score : int, red_score : int) -> void:
	get_tree().call_group("MatchInfoUI", "update_score", blue_score, red_score)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_match_time_left(time_left : int) -> void:
	get_tree().call_group("MatchInfoUI", "update_match_time_left", time_left)

@rpc("authority", "call_remote", "reliable")
func s_end_match(end_client_data : Dictionary, end_game_mode : int) -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/match_end_info/match_end_info_ui.tscn", end_client_data, end_game_mode)
	queue_free()

func try_throw_grenade() -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_throw_grenade.rpc_id(1, create_player_data())
	
@rpc("any_peer", "call_remote", "reliable")
func c_try_throw_grenade(player_state : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_grenades_left(grenades_left : int) -> void:
	var local_player := get_local_player()
	if local_player:
		local_player.update_grenades_left(grenades_left)

@rpc("authority", "call_remote", "reliable")
func s_replenish_ammo() -> void:
	var local_player := get_local_player()
	if local_player:
		local_player.replenish_ammo()

@rpc("authority", "call_remote", "reliable")
func s_explode_grenade(grenade_name : String) -> void:
	pass

func explode_grenade(grenade_name : String) -> void:
	if not grenade_name in grenades.keys():
		return

	var grenade : Grenade = grenades.get(grenade_name).inst

	if is_instance_valid(grenade) and grenade.is_inside_tree():
		var explosion_fx : Node3D = preload("res://player/grenade/grenade_explosion_fx.tscn").instantiate()
		explosion_fx.global_transform = grenade.global_transform
		add_child(explosion_fx)
		grenade.queue_free()

	grenades[grenade_name].exploded = true

@rpc("authority", "call_remote", "unreliable")
func s_play_pickup_fx(pickup_type: int) -> void:
	match pickup_type:
		Pickup.PickupTypes.HealthPickup:
			AudioManager.play_sfx(AudioManager.SFXKeys.PickupHealth)
		Pickup.PickupTypes.GrenadePickup:
			AudioManager.play_sfx(AudioManager.SFXKeys.PickupGrenade)
		Pickup.PickupTypes.AmmoPickup:
			AudioManager.play_sfx(AudioManager.SFXKeys.PickupAmmo)

func exit_game() -> void:
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		c_client_quit_match.rpc_id(1)
	queue_free()

@rpc("any_peer", "call_remote", "reliable")
func c_client_quit_match() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_delete_player(client_id : int) -> void:
	if players.has(client_id) and is_instance_valid(players.get(client_id)):
		players.get(client_id).queue_free()
		players.erase(client_id)

func send_chat_message(message: String) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_send_chat_message.rpc_id(1, message)

@rpc("any_peer", "call_remote", "reliable")
func c_send_chat_message(message: String) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_receive_chat_message(sender_id: int, sender_name: String, sender_team: int, message: String, is_team_only: bool) -> void:
	get_tree().call_group("MatchInfoUI", "show_chat_message", sender_id, sender_name, sender_team, message, is_team_only)

# Zombies mode RPCs
@rpc("authority", "call_remote", "reliable")
func s_spawn_zombie(zombie_id : int, position : Vector3, zombie_type : int) -> void:
	if not is_inside_tree():
		return

	var zombie : Node3D = preload("res://player/zombie/zombie_remote.tscn").instantiate()
	zombie.zombie_type = zombie_type
	zombie.name = str(zombie_id)

	# Set health based on type
	match zombie_type:
		0:  # Normal
			zombie.max_health = 100
		1:  # Fast
			zombie.max_health = 60
		2:  # Tank
			zombie.max_health = 300

	zombie.current_health = zombie.max_health

	add_child(zombie, true)
	zombie.position = position  # Use local position (server sends local coords)
	zombies[zombie_id] = zombie

@rpc("authority", "call_remote", "reliable")
func s_zombie_died(zombie_id : int) -> void:
	if zombies.has(zombie_id) and is_instance_valid(zombies.get(zombie_id)):
		var zombie = zombies.get(zombie_id)
		# Spawn death effect
		if zombie.is_inside_tree():
			var eliminated_fx := preload("res://player/player_eliminated_effects.tscn").instantiate()
			eliminated_fx.global_position = zombie.global_position
			add_child(eliminated_fx)

		zombie.queue_free()
		zombies.erase(zombie_id)

		# Track kill in HUD
		get_tree().call_group("HUDManager", "add_kill")

@rpc("authority", "call_remote", "reliable")
func s_update_player_points(points : int) -> void:
	get_tree().call_group("HUDManager", "update_points", points)

@rpc("authority", "call_remote", "reliable")
func s_update_teammate_scores(scores : Dictionary) -> void:
	# Update all teammate scores in the HUD
	for player_id in scores.keys():
		var score = scores[player_id]
		get_tree().call_group("HUDManager", "update_teammate_score", player_id, score)

@rpc("authority", "call_remote", "reliable")
func s_start_wave(wave_number : int, zombie_count : int) -> void:
	get_tree().call_group("HUDManager", "start_wave", wave_number, zombie_count)

@rpc("authority", "call_remote", "reliable")
func s_update_zombies_remaining(zombies_remaining : int) -> void:
	get_tree().call_group("HUDManager", "update_zombies_remaining", zombies_remaining)

@rpc("authority", "call_remote", "reliable")
func s_wave_complete(wave_number : int) -> void:
	get_tree().call_group("HUDManager", "wave_complete", wave_number)

@rpc("authority", "call_remote", "reliable")
func s_update_break_time(time_remaining : int) -> void:
	get_tree().call_group("HUDManager", "update_break_time", time_remaining)

@rpc("authority", "call_remote", "reliable")
func s_delete_pickup(pickup_name : String) -> void:
	if pickups.has(pickup_name) and is_instance_valid(pickups.get(pickup_name)):
		pickups.get(pickup_name).queue_free()
		pickups.erase(pickup_name)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_zombie_health(zombie_id : int, current_health : int, max_health : int, changed_amount: int, shooter_id : int, is_headshot := false) -> void:
	# Update zombie health bar
	if zombies.has(zombie_id) and is_instance_valid(zombies.get(zombie_id)):
		var zombie = zombies.get(zombie_id)
		zombie.update_health_bar(current_health, max_health)

	# Show damage numbers if local player is the shooter
	if shooter_id == multiplayer.get_unique_id():
		var damage := absi(changed_amount)
		get_tree().call_group("HUDManager", "show_hit_marker", is_headshot)
		get_tree().call_group("HUDManager", "show_damage_number", damage, is_headshot)

@rpc("authority", "call_remote", "reliable")
func s_player_downed(player_id : int, damager_id : int) -> void:
	# Update teammate status for this player
	get_tree().call_group("HUDManager", "update_teammate_downed", player_id, true)

	# Show downed overlay for local player
	if player_id == multiplayer.get_unique_id():
		get_tree().call_group("DownedOverlay", "show_downed", 45.0)
		get_tree().call_group("HUDManager", "add_down")
		# Disable local player controls
		var local_player := get_local_player()
		if local_player:
			local_player.freeze()

@rpc("authority", "call_remote", "reliable")
func s_player_revived(player_id : int) -> void:
	# Update teammate status for this player
	get_tree().call_group("HUDManager", "update_teammate_downed", player_id, false)

	# Hide downed overlay for local player
	if player_id == multiplayer.get_unique_id():
		get_tree().call_group("DownedOverlay", "hide_downed")
		# Re-enable local player controls
		var local_player := get_local_player()
		if local_player:
			local_player.unfreeze()

@rpc("authority", "call_remote", "reliable")
func s_player_waiting_for_respawn(player_id : int) -> void:
	# Make the dead player invisible to others
	if players.has(player_id) and is_instance_valid(players.get(player_id)):
		var dead_player = players.get(player_id)
		dead_player.set_visible(false)

	# If this is the local player, hide downed overlay and freeze
	if player_id == multiplayer.get_unique_id():
		get_tree().call_group("DownedOverlay", "hide_downed")
		get_tree().call_group("HUDManager", "show_waiting_for_round")
		var local_player := get_local_player()
		if local_player:
			local_player.freeze()
			# Start spectator mode
			local_player.enter_spectator_mode()

@rpc("authority", "call_remote", "reliable")
func s_player_respawned(player_id : int) -> void:
	# Make the respawned player visible again
	if players.has(player_id) and is_instance_valid(players.get(player_id)):
		var respawned_player = players.get(player_id)
		respawned_player.set_visible(true)

	# Update teammate status card to show player as alive (not downed)
	if game_mode == 1:
		get_tree().call_group("HUDManager", "update_teammate_downed", player_id, false)

	# If this is the local player, hide waiting UI and unfreeze
	if player_id == multiplayer.get_unique_id():
		get_tree().call_group("HUDManager", "hide_waiting_for_round")
		var local_player := get_local_player()
		if local_player:
			local_player.exit_spectator_mode()
			local_player.unfreeze()

@rpc("authority", "call_remote", "reliable")
func s_update_bleed_out_timer(time_remaining : float) -> void:
	# Update downed overlay with bleed-out timer
	get_tree().call_group("DownedOverlay", "update_bleed_out_timer", time_remaining)

# Client revive functions
func try_start_revive(target_player_id : int) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_start_revive.rpc_id(1, target_player_id)

func update_revive_progress(target_player_id : int, progress : float) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_update_revive_progress.rpc_id(1, target_player_id, progress)

func complete_revive(target_player_id : int) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_complete_revive.rpc_id(1, target_player_id)

func cancel_revive(target_player_id : int) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_cancel_revive.rpc_id(1, target_player_id)

@rpc("any_peer", "call_remote", "reliable")
func c_try_start_revive(target_player_id : int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_update_revive_progress(target_player_id : int, progress : float) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_complete_revive(target_player_id : int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_cancel_revive(target_player_id : int) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_revive_started(target_player_id : int, target_name : String) -> void:
	# Show revive progress UI
	get_tree().call_group("ReviveProgress", "start_revive", target_name)

@rpc("authority", "call_remote", "reliable")
func s_revive_progress_update(progress : float) -> void:
	# Update revive progress bar
	get_tree().call_group("ReviveProgress", "update_revive_progress", progress)

# Economy system - Buyables
func try_buy_weapon(weapon_id: int, is_ammo: bool = false) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_buy_weapon.rpc_id(1, weapon_id, is_ammo)

func try_buy_door(door_id: String) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_buy_door.rpc_id(1, door_id)

@rpc("any_peer", "call_remote", "reliable")
func c_try_buy_weapon(weapon_id: int, is_ammo: bool = false) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_try_buy_door(door_id: String) -> void:
	pass

func try_upgrade_weapon(weapon_id: int) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_upgrade_weapon.rpc_id(1, weapon_id)

func try_buy_perk(perk_type: String) -> void:
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	c_try_buy_perk.rpc_id(1, perk_type)

@rpc("any_peer", "call_remote", "reliable")
func c_try_upgrade_weapon(weapon_id: int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_try_buy_perk(perk_type: String) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_weapon_purchased(weapon_id: int, is_ammo: bool) -> void:
	# Client confirmation of weapon purchase
	var local_player := get_local_player()
	if not local_player:
		return

	if is_ammo:
		# Replenish ammo for this specific weapon
		if local_player.weapon_holder_node.has_weapon_in_inventory(weapon_id):
			var weapon = local_player.weapon_holder_node.weapons_cache.get(weapon_id)
			if weapon:
				var weapon_data = WeaponConfig.get_weapon_data(weapon_id)
				weapon.reserve_ammo = weapon_data.reserve_ammo
	else:
		# Add weapon to player's inventory
		var result = local_player.add_weapon_to_player(weapon_id)

@rpc("authority", "call_remote", "reliable")
func s_door_opened(door_id: String) -> void:
	# Find the door in the map and open it
	var door = get_node_or_null("Map/" + door_id)

	if not door:
		door = get_node_or_null("Map/Doors/" + door_id)

	if not door:
		door = get_node_or_null("Map/Buyables/" + door_id)

	if not door:
		door = _find_door_recursive(get_node_or_null("Map"), door_id)

	if door and door.has_method("open_door"):
		door.open_door()

func _find_door_recursive(node: Node, door_id: String) -> Node:
	if not node:
		return null

	# Check if this node matches
	if node.name == door_id and node.has_method("open_door"):
		return node

	# Check children
	for child in node.get_children():
		var result = _find_door_recursive(child, door_id)
		if result:
			return result

	return null

@rpc("authority", "call_remote", "reliable")
func s_purchase_failed(reason: String) -> void:
	# Show error message to player
	print("Purchase failed: %s" % reason)

@rpc("authority", "call_remote", "reliable")
func s_weapon_upgraded(weapon_id: int) -> void:
	var local_player := get_local_player()
	if not local_player:
		return

	# Apply weapon upgrade stats
	var weapon_holder = local_player.get_node_or_null("WeaponHolder")
	if not weapon_holder:
		return

	var weapon = weapon_holder.weapons_cache.get(weapon_id)
	if weapon:
		# Mark as upgraded
		weapon.is_upgraded = true

		# Apply upgrade bonuses (+50% damage, +50% reserve ammo, +33% mag size)
		var weapon_data = WeaponConfig.get_weapon_data(weapon_id)

		# Increase damage by 50%
		weapon.damage = int(weapon_data.damage * 1.5)

		# Increase magazine size by 33%
		var new_mag_size = int(weapon_data.mag_size * 1.33)
		weapon.mag_size = new_mag_size
		weapon.current_ammo = new_mag_size  # Fill the larger mag

		# Increase reserve ammo by 50%
		weapon.reserve_ammo = int(weapon_data.reserve_ammo * 1.5)

@rpc("authority", "call_remote", "reliable")
func s_perk_purchased(perk_type: String) -> void:
	var local_player := get_local_player()
	if not local_player:
		return

	# Track perks
	if not local_player.has_meta("perks"):
		local_player.set_meta("perks", [])

	var perks = local_player.get_meta("perks")
	if perk_type in perks:
		return  # Already have it

	perks.append(perk_type)
	local_player.set_meta("perks", perks)

	# Apply perk effects (store as metadata - server handles actual stat changes)
	match perk_type:
		"TacticalVest":
			# +100% max HP (server-side health management)
			local_player.set_meta("health_multiplier", 2.0)

		"FastHands":
			# +50% reload speed
			local_player.set_meta("reload_speed_multiplier", 1.5)

		"RapidFire":
			# +33% fire rate
			local_player.set_meta("fire_rate_multiplier", 1.33)

		"CombatMedic":
			# +75% revive speed
			local_player.set_meta("revive_speed_multiplier", 1.75)

		"Endurance":
			# +25% movement speed
			if local_player.has("WALK_SPEED") and local_player.has("SPRINT_SPEED"):
				local_player.WALK_SPEED *= 1.25
				local_player.SPRINT_SPEED *= 1.25
			else:
				local_player.set_meta("movement_speed_multiplier", 1.25)

		"Marksman":
			# +10% damage to headshots
			local_player.set_meta("headshot_damage_bonus", 0.1)

		"BlastShield":
			# Immune to explosive damage
			local_player.set_meta("explosive_immunity", true)

		"HeavyGunner":
			# +1 weapon slot (3 total)
			var weapon_holder = local_player.get_node_or_null("WeaponHolder")
			if weapon_holder and weapon_holder.has("max_weapons"):
				weapon_holder.max_weapons = 3
			else:
				local_player.set_meta("weapon_slots", 3)
