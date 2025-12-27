extends PlayerCharacter
class_name PlayerLocal

const IDLE_ANIM := "Idle"
const AIR_ANIM := "Jump_Idle"
const WALK_ANIM := "Walk_Shoot"
const RUN_ANIM := "Run_Shoot"
const FOOTSTEP_AUDIO_INTERVAL_WALK := 0.5
const FOOTSTEP_AUDIO_INTERVAL_RUN := 0.37

@export var grenade_amount_label : Label
@export var normal_speed := 4.0
@export var sprint_speed := 8.0
@export var jump_velocity := 7.0
@export var gravity := 0.2
@export var fast_fall_speed := 1.5  # Additional downward velocity when fast falling
@export var coyote_time := 0.1  # Grace period after leaving ground
@export var jump_buffer_time := 0.1  # Remember jump input for this long

@onready var footstep_timer: Timer = $FootstepTimer
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/CameraShakeComponent/Camera3D
@onready var weapon_holder_node: Node3D = $Head/LocalWeaponHolder
@onready var pause_screen: Control = $PauseScreen
@onready var chat_container: MarginContainer
@onready var chat_input: LineEdit
@onready var weapon_inventory: WeaponInventory

var auto_freeze := false
var is_frozen : bool
var is_paused := false
var is_chat_open := false
var is_grounded := true
var is_sprinting := false
var current_anim : String
var nearby_grenades : Array[Grenade] = []
var coyote_timer := 0.0  # Tracks time since leaving ground
var jump_buffer_timer := 0.0  # Tracks time since jump input

# Revive system
var is_reviving := false
var revive_target_id := -1
var revive_progress := 0.0
const REVIVE_TIME := 3.0  # Seconds to complete revive
const REVIVE_RANGE := 5.0  # Meters

# Spectator mode
var is_spectating := false
var spectator_target_ids : Array[int] = []
var current_spectator_index := 0

# ADS (Aim Down Sights) variables
var is_aiming := false
var default_fov := 75.0
var ads_fov := 30.0  # Zoomed in FOV for sniper
var ads_sensitivity_multiplier := 0.5  # Reduced sensitivity while aiming
var fov_tween: Tween
var weapon_tween: Tween

# Weapon holder positions
var default_weapon_position := Vector3(0.02, -0.025, -0.025)
var default_weapon_scale := Vector3(0.05, 0.05, 0.05)

func _ready() -> void:
	super()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if auto_freeze:
		freeze()

	pause_screen.hide()
	pause_screen.chat_message_sent.connect(_on_chat_message_sent)

	# Get chat UI references from MatchInfoUI
	chat_container = get_tree().get_first_node_in_group("ChatInputContainer")
	chat_input = get_tree().get_first_node_in_group("ChatInput")
	chat_input.text_submitted.connect(_on_chat_input_submitted)
	chat_container.hide()

	# Initialize camera FOV, weapon position, and scale
	camera.fov = default_fov
	weapon_holder_node.position = default_weapon_position
	weapon_holder_node.scale = default_weapon_scale

	# Initialize weapon inventory
	weapon_inventory = WeaponInventory.new()
	add_child(weapon_inventory)
	weapon_inventory.weapon_switched.connect(_on_weapon_switched)

	# IMPORTANT: Add starting weapon to inventory
	await get_tree().process_frame  # Wait for weapon_holder to instantiate weapon
	if weapon_holder_node.weapon:
		weapon_inventory.add_weapon(weapon_holder_node.weapon.weapon_id)
		weapon_holder_node.add_weapon_to_inventory(weapon_holder_node.weapon.weapon_id)
		print("Starting weapon added to inventory: ", weapon_holder_node.weapon.weapon_id)

func _on_chat_message_sent(message: String) -> void:
	# Send the chat message to the server (Lobby)
	get_tree().call_group("Lobby", "send_chat_message", message)

func _on_chat_input_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		close_chat()
		return

	# Send message and close chat
	get_tree().call_group("Lobby", "send_chat_message", text)
	chat_input.clear()
	close_chat()

func open_chat() -> void:
	is_chat_open = true
	chat_container.show()
	chat_input.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_chat() -> void:
	is_chat_open = false
	chat_container.hide()
	chat_input.clear()
	chat_input.release_focus()
	if not is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause() -> void:
	set_processes(false)
	is_paused = true
	pause_screen.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unpause() -> void:
	if not is_frozen:
		set_processes(true)
	is_paused = false
	pause_screen.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func freeze() -> void:
	# Don't disable processes if spectating (need physics for camera updates)
	if not is_spectating:
		set_processes(false)
	is_frozen = true

func unfreeze() -> void:
	if not is_paused:
		set_processes(true)
	is_frozen = false

func set_processes(enabled : bool) -> void:
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)

func _physics_process(delta: float) -> void:
	if is_spectating:
		update_spectator_camera()
		check_spectator_input()
	else:
		move(delta)
		choose_anim()
		check_shoot_input()
		check_reload_input()
		check_throw_grenade_input()
		check_ads_input()
		check_revive_input(delta)
		check_weapon_switch_input()
		show_nearby_grenades()

func move(delta: float):
	# Don't process movement if chat is open
	if is_chat_open:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Update jump buffer timer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Check if we're on floor
	var on_floor := is_on_floor()

	if on_floor:
		is_sprinting = Input.is_action_pressed("sprint")
		coyote_timer = coyote_time  # Reset coyote timer when on floor

		# Execute buffered jump or direct jump input
		if jump_buffer_timer > 0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0  # Consume the buffered jump

		if not direction.is_zero_approx() and footstep_timer.is_stopped():
			AudioManager.play_sfx(AudioManager.SFXKeys.Footstep, Vector3.ZERO, 0.2)
			footstep_timer.start(FOOTSTEP_AUDIO_INTERVAL_WALK if not is_sprinting else FOOTSTEP_AUDIO_INTERVAL_RUN)

		if not is_grounded:
			is_grounded = true
			AudioManager.play_sfx(AudioManager.SFXKeys.JumpLand, Vector3.ZERO, 0.2)

	else:
		# In air - apply gravity and update coyote timer
		velocity.y -= gravity

		# Fast fall when 'x' is pressed in air
		if not is_chat_open and Input.is_physical_key_pressed(KEY_X):
			velocity.y -= fast_fall_speed

		coyote_timer -= delta

		# Allow jump during coyote time
		if jump_buffer_timer > 0 and coyote_timer > 0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0
			coyote_timer = 0

		if is_grounded:
			is_grounded = false
	
	var speed := normal_speed if not is_sprinting else sprint_speed

	velocity.z = direction.z * speed
	velocity.x = direction.x * speed

	# SIMPLE step-up: if hitting wall low, try small step
	move_and_slide()

	# Only if: on floor, moving, hit wall, not jumping
	if is_on_floor() and is_on_wall() and not direction.is_zero_approx() and velocity.y <= 0:
		# Get the collision point
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var hit_height := collision.get_position().y - global_position.y
			var normal := collision.get_normal()

			# Check if it's a vertical wall (not a slope/ramp)
			# Vertical walls have normals that are mostly horizontal (y component near 0)
			# Ramps/slopes have normals pointing upward (positive y component)
			# Allow for beveled edges on containers (normal.y up to ~0.6)
			var is_vertical_wall: bool = abs(normal.y) < 0.6

			# If collision is low (near feet) AND it's a vertical wall, try stepping
			# Threshold 0.2 to account for slightly different collision heights on elevated surfaces
			if hit_height < 0.2 and is_vertical_wall:
				position.y += 0.1
				move_and_slide()

				# If no longer hitting wall, success
				if not is_on_wall():
					break
				else:
					# Still stuck, revert
					position.y -= 0.1
				break

func choose_anim() -> void:
	if not is_grounded:
		current_anim = AIR_ANIM
		return
	if velocity.x or velocity.z:
		current_anim = RUN_ANIM if is_sprinting else WALK_ANIM
		return
	current_anim = IDLE_ANIM

func check_shoot_input() -> void:
	if is_chat_open:
		return
	if Input.is_action_just_pressed("shoot"):
		weapon_holder.start_trigger_press()
	elif Input.is_action_just_released("shoot"):
		weapon_holder.end_trigger_press()

func check_reload_input() -> void:
	if is_chat_open:
		return
	if Input.is_action_just_pressed("reload"):
		weapon_holder.start_reload()

func check_throw_grenade_input() -> void:
	if is_chat_open:
		return
	if Input.is_action_just_pressed("throw_grenade"):
		get_tree().call_group("Lobby", "try_throw_grenade")

func check_weapon_switch_input() -> void:
	if is_chat_open:
		return
	if Input.is_action_just_pressed("switch_weapon"):
		weapon_inventory.switch_weapon()

func _on_weapon_switched(weapon_id: int) -> void:
	# Tell the weapon holder to switch to this weapon
	weapon_holder_node.switch_to_weapon(weapon_id)

func add_weapon_to_player(weapon_id: int) -> Dictionary:
	# Add to inventory
	var result = weapon_inventory.add_weapon(weapon_id)

	# Add to weapon holder cache
	weapon_holder_node.add_weapon_to_inventory(weapon_id)

	return result

func check_ads_input() -> void:
	if is_chat_open:
		if is_aiming:
			exit_ads()
		return

	# Hold to aim
	if Input.is_action_pressed("aim_down_sights"):
		if not is_aiming:
			enter_ads()
	else:
		if is_aiming:
			exit_ads()

func enter_ads() -> void:
	is_aiming = true

	# Kill existing tweens if running
	if fov_tween and fov_tween.is_running():
		fov_tween.kill()
	if weapon_tween and weapon_tween.is_running():
		weapon_tween.kill()

	# Smoothly transition FOV
	fov_tween = create_tween()
	fov_tween.tween_property(camera, "fov", ads_fov, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Get weapon-specific ADS position and scale
	var ads_position := default_weapon_position
	var ads_scale := default_weapon_scale
	if weapon_holder.weapon != null:
		var weapon_data := WeaponConfig.get_weapon_data(weapon_holder.weapon.weapon_id)
		if weapon_data.has("ads_offset"):
			ads_position = weapon_data.ads_offset
		if weapon_data.has("ads_scale"):
			var scale_multiplier: float = weapon_data.ads_scale
			ads_scale = default_weapon_scale * scale_multiplier

	# Smoothly move weapon to ADS position and scale
	weapon_tween = create_tween().set_parallel()
	weapon_tween.tween_property(weapon_holder_node, "position", ads_position, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	weapon_tween.tween_property(weapon_holder_node, "scale", ads_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func exit_ads() -> void:
	is_aiming = false

	# Kill existing tweens if running
	if fov_tween and fov_tween.is_running():
		fov_tween.kill()
	if weapon_tween and weapon_tween.is_running():
		weapon_tween.kill()

	# Smoothly transition FOV back to default
	fov_tween = create_tween()
	fov_tween.tween_property(camera, "fov", default_fov, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Smoothly move weapon back to default position and scale
	weapon_tween = create_tween().set_parallel()
	weapon_tween.tween_property(weapon_holder_node, "position", default_weapon_position, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	weapon_tween.tween_property(weapon_holder_node, "scale", default_weapon_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func show_nearby_grenades() -> void:
	var grenades_data := {}
	var own_pos := Vector2(global_position.x, global_position.z)

	for grenade in nearby_grenades:
		# Check if grenade is valid and in tree before accessing global_position
		if not is_instance_valid(grenade) or not grenade.is_inside_tree():
			continue
		var grenade_pos := Vector2(grenade.global_position.x, grenade.global_position.z)
		grenades_data[grenade.name] = own_pos.angle_to_point(grenade_pos) + PI / 2 + rotation.y

	get_tree().call_group("GrenadePromptsControl", "update_grenade_prompts", grenades_data)
	

func update_grenades_left(grenades_left : int) -> void:
	grenade_amount_label.text = str(grenades_left)

func replenish_ammo() -> void:
	# Replenish ammo for ALL weapons in inventory
	for weapon_id in weapon_holder_node.weapons_cache.keys():
		var weapon_instance = weapon_holder_node.weapons_cache[weapon_id]
		var weapon_data := WeaponConfig.get_weapon_data(weapon_id)

		# Fill reserve ammo
		weapon_instance.reserve_ammo = weapon_data.reserve_ammo
		# Fill current magazine
		weapon_instance.current_ammo = weapon_instance.mag_size

func update_health_bar(current_health : int, max_health : int, changed_amount: int) -> void:
	super(current_health, max_health, changed_amount)
	if changed_amount <= 0:
		get_tree().call_group("CameraShakeComponent", "add_noise", absi(changed_amount) / float(max_health))
	get_tree().call_group("HealthChangeMask", "update_mask", current_health / float(max_health))
	
func _input(event) -> void:
	# Don't allow mouse movement during spectator mode
	if is_spectating:
		return

	if event is InputEventMouseMotion:
		look_around(event.relative)

	# Debug keys (zombies mode only)
	if event is InputEventKey and event.pressed and not event.echo:
		var lobby := get_tree().get_first_node_in_group("Lobby")
		if lobby and lobby.game_mode == 1:  # Zombies mode
			if event.keycode == KEY_1:
				# Add 1000 points
				lobby.c_debug_add_points.rpc_id(1, 1000)
			elif event.keycode == KEY_2:
				# Deal 50 damage or force death
				lobby.c_debug_damage_or_kill.rpc_id(1, 50)

func look_around(relative:Vector2):
	var base_sensitivity = 0.005
	var effective_sensitivity = base_sensitivity * SettingsManager.mouse_sensitivity
	if is_aiming:
		effective_sensitivity *= ads_sensitivity_multiplier
	rotate_y(-relative.x * effective_sensitivity)
	head.rotate_x(-relative.y * effective_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -PI/2, PI/2)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"):
		if is_chat_open:
			close_chat()
		else:
			open_chat()
	elif event.is_action_pressed("ui_cancel"):
		if is_chat_open:
			close_chat()
		else:
			pause() if not is_paused else unpause()

func _on_grenade_detection_area_3d_area_entered(area: Area3D) -> void:
	nearby_grenades.append(area.get_parent())

func _on_grenade_detection_area_3d_area_exited(area: Area3D) -> void:
	nearby_grenades.erase(area.get_parent())

func check_revive_input(delta: float) -> void:
	if is_chat_open or is_frozen:
		return

	# Find nearby downed players
	var nearest_downed_player_id := -1
	var nearest_distance := REVIVE_RANGE

	var lobby := get_tree().get_first_node_in_group("Lobby")
	if not lobby:
		return

	# Check all players for downed state
	for player_id in lobby.player_names_and_teams.keys():
		if player_id == multiplayer.get_unique_id():
			continue  # Can't revive yourself

		var player_node = lobby.players.get(player_id)
		if not is_instance_valid(player_node):
			continue

		# Check distance
		var distance := global_position.distance_to(player_node.global_position)
		if distance < nearest_distance:
			# TODO: Check if player is actually downed (need to track this on client)
			nearest_distance = distance
			nearest_downed_player_id = player_id

	# Handle revive input
	if Input.is_action_pressed("interact") and nearest_downed_player_id != -1:
		if not is_reviving:
			# Start reviving
			is_reviving = true
			revive_target_id = nearest_downed_player_id
			revive_progress = 0.0
			get_tree().call_group("Lobby", "try_start_revive", revive_target_id)

		# Update progress
		revive_progress += delta / REVIVE_TIME
		get_tree().call_group("Lobby", "update_revive_progress", revive_target_id, revive_progress)
		get_tree().call_group("ReviveProgress", "update_revive_progress", revive_progress)

		# Complete revive
		if revive_progress >= 1.0:
			get_tree().call_group("Lobby", "complete_revive", revive_target_id)
			get_tree().call_group("ReviveProgress", "complete_revive")
			is_reviving = false
			revive_target_id = -1
			revive_progress = 0.0

	elif is_reviving:
		# Cancelled revive (released F or moved away)
		get_tree().call_group("Lobby", "cancel_revive", revive_target_id)
		get_tree().call_group("ReviveProgress", "cancel_revive")
		is_reviving = false
		revive_target_id = -1
		revive_progress = 0.0

# Spectator mode functions
func enter_spectator_mode() -> void:
	is_spectating = true
	spectator_target_ids.clear()
	current_spectator_index = 0

	# Re-enable physics processing for spectator camera updates (freeze() may have disabled it)
	if not is_paused:
		set_processes(true)

	# Get lobby and find alive teammates
	var lobby := get_tree().get_first_node_in_group("Lobby")
	if not lobby:
		return

	# Collect alive teammates (players that are visible)
	for player_id in lobby.players.keys():
		if player_id == multiplayer.get_unique_id():
			continue  # Don't spectate yourself

		var player = lobby.players.get(player_id)
		if is_instance_valid(player) and player.visible:
			spectator_target_ids.append(player_id)

	print("Spectator mode: Found %d alive teammates to spectate" % spectator_target_ids.size())

func exit_spectator_mode() -> void:
	is_spectating = false
	spectator_target_ids.clear()
	current_spectator_index = 0

	# Reset camera to default position (local to head/camera shake component)
	camera.position = Vector3.ZERO

func check_spectator_input() -> void:
	if Input.is_action_just_pressed("switch_weapon"):  # Tab key cycles teammates
		print("Spectator: Tab pressed, cycling target")
		cycle_spectator_target()

func cycle_spectator_target() -> void:
	if spectator_target_ids.is_empty():
		return

	current_spectator_index = (current_spectator_index + 1) % spectator_target_ids.size()
	print("Spectating player: %d" % spectator_target_ids[current_spectator_index])

func update_spectator_camera() -> void:
	if spectator_target_ids.is_empty():
		return

	var lobby := get_tree().get_first_node_in_group("Lobby")
	if not lobby:
		return

	var target_id := spectator_target_ids[current_spectator_index]
	var target_player = lobby.players.get(target_id)

	if not is_instance_valid(target_player) or not target_player.visible:
		# Target died or became invalid, remove from list
		print("Spectator: Target %d died or invalid, removing from list" % target_id)
		spectator_target_ids.remove_at(current_spectator_index)
		if current_spectator_index >= spectator_target_ids.size():
			current_spectator_index = 0
		return

	# Position camera above and behind the target player (spectator offset)
	var offset_up := Vector3.UP * 3.0  # 5 units up
	var offset_back : Vector3 = target_player.global_transform.basis.z * 3.0  # 5 units back (basis.z is backward)
	var target_pos : Vector3 = target_player.global_position + offset_up + offset_back

	# Smoothly interpolate camera position to target (prevents jarring movements)
	camera.global_position = camera.global_position.lerp(target_pos, 0.3)

	# Copy target's rotation for looking around
	rotation.y = target_player.rotation.y

	# If target has a head node (for looking up/down), copy that too
	if target_player.has_node("Head"):
		var target_head = target_player.get_node("Head")
		head.rotation.x = target_head.rotation.x
