extends Control

# References to HUD elements
@onready var hit_marker: Control = $HitMarker
@onready var damage_numbers_container: Control = $DamageNumbersContainer
@onready var kill_confirmation: Label = $KillConfirmation
@onready var ammo_label: Label = $AmmoContainer/AmmoLabel
@onready var reload_prompt: Label = $AmmoContainer/ReloadPrompt

# Zombies mode HUD elements (instantiated from scene in _ready)
var points_label: Label = null
var wave_label: Label = null
var zombies_remaining_label: Label = null
var break_timer_label: Label = null
var kills_label: Label = null
var downs_label: Label = null
var teammate_status_container: VBoxContainer = null
var zombies_hud: Control = null

var player_kills := 0
var player_downs := 0
var teammate_cards := {}  # Dictionary to track teammate status cards
var perks_container: VBoxContainer = null
var active_perks := []  # Array of perk type strings

# Power-up system
var powerups_container: VBoxContainer = null
var active_powerups := {}  # {"powerup_name": {label: Label, timer: Timer, end_time: float}}

const DAMAGE_NUMBER_SCENE := preload("res://ui/hud/damage_number.tscn")
const TEAMMATE_STATUS_CARD_SCENE := preload("res://ui/hud/teammate_status_card.tscn")
const ZOMBIE_HUD_SCENE := preload("res://ui/hud/zombie_hud.tscn")

func _ready() -> void:
	add_to_group("HUDManager")

	# Instantiate zombie HUD from scene if it doesn't exist
	if not has_node("ZombieHUD"):
		zombies_hud = ZOMBIE_HUD_SCENE.instantiate()
		add_child(zombies_hud)

		# Get references to all zombie HUD elements
		points_label = zombies_hud.get_node("MarginContainer/StatsContainer/PointsLabel")
		wave_label = zombies_hud.get_node("MarginContainer/StatsContainer/WaveLabel")
		zombies_remaining_label = zombies_hud.get_node("MarginContainer/StatsContainer/ZombiesRemainingLabel")
		break_timer_label = zombies_hud.get_node("BreakTimerLabel")
		kills_label = zombies_hud.get_node("MarginContainer/StatsContainer/KillsLabel")
		downs_label = zombies_hud.get_node("MarginContainer/StatsContainer/DownsLabel")
		teammate_status_container = zombies_hud.get_node("TeammateStatusContainer")
	else:
		zombies_hud = $ZombieHUD
		points_label = zombies_hud.get_node("MarginContainer/StatsContainer/PointsLabel") if zombies_hud.has_node("MarginContainer/StatsContainer/PointsLabel") else null
		wave_label = zombies_hud.get_node("MarginContainer/StatsContainer/WaveLabel") if zombies_hud.has_node("MarginContainer/StatsContainer/WaveLabel") else null
		zombies_remaining_label = zombies_hud.get_node("MarginContainer/StatsContainer/ZombiesRemainingLabel") if zombies_hud.has_node("MarginContainer/StatsContainer/ZombiesRemainingLabel") else null
		break_timer_label = zombies_hud.get_node("BreakTimerLabel") if zombies_hud.has_node("BreakTimerLabel") else null
		kills_label = zombies_hud.get_node("MarginContainer/StatsContainer/KillsLabel") if zombies_hud.has_node("MarginContainer/StatsContainer/KillsLabel") else null
		downs_label = zombies_hud.get_node("MarginContainer/StatsContainer/DownsLabel") if zombies_hud.has_node("MarginContainer/StatsContainer/DownsLabel") else null
		teammate_status_container = zombies_hud.get_node("TeammateStatusContainer") if zombies_hud.has_node("TeammateStatusContainer") else null

	# Hide zombies HUD by default (shown only in zombies mode)
	if zombies_hud:
		zombies_hud.visible = false

	# Create perks container
	_create_perks_container()

func show_hit_marker(is_headshot := false) -> void:
	if hit_marker:
		hit_marker.show_hit(is_headshot)

	# Play hit sound
	AudioManager.play_sfx(AudioManager.SFXKeys.Hit, Vector3.ZERO, 0.2)

func show_damage_number(damage: int, is_headshot := false) -> void:
	if not damage_numbers_container:
		return

	var damage_number = DAMAGE_NUMBER_SCENE.instantiate()
	damage_number.set_damage(damage, is_headshot)

	# Position at center of screen with slight randomness
	var viewport_size := get_viewport_rect().size
	damage_number.position = viewport_size / 2 + Vector2(randf_range(-40, 40), randf_range(-20, 20))

	damage_numbers_container.add_child(damage_number)

func show_kill_confirmation() -> void:
	if kill_confirmation:
		kill_confirmation.show_kill()

func update_ammo(current: int, reserve: int, mag_size: int = 0, weapon_id: int = -1) -> void:
	if ammo_label:
		var ammo_text = "%d / %d" % [current, reserve]

		# Add weapon name if provided (only for valid weapon IDs 0-5)
		if weapon_id >= 0 and weapon_id <= 5:
			var weapon_data = WeaponConfig.get_weapon_data(weapon_id)
			if not weapon_data.is_empty():
				var weapon_name = weapon_data.get("name", "")
				ammo_text = "%s  |  %s" % [weapon_name, ammo_text]

		ammo_label.text = ammo_text

	if reload_prompt and mag_size > 0:
		# Show reload prompt when ammo is less than 1/3 of mag size and player has reserve ammo
		var low_ammo_threshold := floori(mag_size / 3.0)
		if current <= low_ammo_threshold and reserve > 0:
			reload_prompt.visible = true
		else:
			reload_prompt.visible = false

# Zombies mode HUD methods
func update_points(points: int) -> void:
	if zombies_hud:
		zombies_hud.visible = true
		# Make sure teammate container is visible too
		if teammate_status_container:
			teammate_status_container.visible = true
	if points_label:
		points_label.text = "Points: %d" % points

func start_wave(wave_number: int, zombie_count: int) -> void:
	if zombies_hud:
		zombies_hud.visible = true
		# Make sure teammate container is visible too
		if teammate_status_container:
			teammate_status_container.visible = true
	if wave_label:
		wave_label.text = "Wave %d" % wave_number
	if zombies_remaining_label:
		zombies_remaining_label.text = "Zombies: %d" % zombie_count
	if break_timer_label:
		break_timer_label.visible = false

func update_zombies_remaining(zombies_remaining: int) -> void:
	if zombies_remaining_label:
		zombies_remaining_label.text = "Zombies: %d" % zombies_remaining

func wave_complete(wave_number: int) -> void:
	if wave_label:
		wave_label.text = "Wave %d Complete!" % wave_number
	if zombies_remaining_label:
		zombies_remaining_label.text = "Zombies: 0"

func update_break_time(time_remaining: int) -> void:
	if break_timer_label:
		break_timer_label.visible = true
		break_timer_label.text = "Next wave in: %ds" % time_remaining

func update_bleed_out_timer(time_remaining: float) -> void:
	# TODO: Create a proper downed HUD overlay with timer
	# For now, just print to console
	if int(time_remaining) % 5 == 0:  # Every 5 seconds
		print("Bleed out in: ", int(time_remaining), " seconds")

func update_kills(kills: int) -> void:
	player_kills = kills
	if kills_label:
		kills_label.text = "Kills: %d" % kills

func update_downs(downs: int) -> void:
	player_downs = downs
	if downs_label:
		downs_label.text = "Downs: %d" % downs

func add_kill() -> void:
	player_kills += 1
	update_kills(player_kills)

func add_down() -> void:
	player_downs += 1
	update_downs(player_downs)

# Teammate status methods
func add_teammate(player_id: int, player_name: String) -> void:

	if not teammate_status_container:
		return

	# Create card if it doesn't exist
	if not teammate_cards.has(player_id):
		var teammate_card = TEAMMATE_STATUS_CARD_SCENE.instantiate()
		teammate_card.setup(player_id, player_name)
		teammate_card.set_health(100, 100)  # Initialize with full health
		teammate_card.set_downed(false)  # Start as alive
		teammate_status_container.add_child(teammate_card)
		teammate_cards[player_id] = teammate_card

func update_teammate_health(player_id: int, health: int, max_health: int) -> void:
	if teammate_cards.has(player_id):
		var card = teammate_cards[player_id]
		if is_instance_valid(card):
			card.set_health(health, max_health)

func update_teammate_downed(player_id: int, is_downed: bool) -> void:
	if teammate_cards.has(player_id):
		var card = teammate_cards[player_id]
		if is_instance_valid(card):
			card.set_downed(is_downed)

func update_teammate_score(player_id: int, score: int) -> void:
	if teammate_cards.has(player_id):
		var card = teammate_cards[player_id]
		if is_instance_valid(card):
			card.set_score(score)

func remove_teammate(player_id: int) -> void:
	if teammate_cards.has(player_id):
		var card = teammate_cards[player_id]
		if is_instance_valid(card):
			card.queue_free()
		teammate_cards.erase(player_id)

func clear_teammates() -> void:
	for card in teammate_cards.values():
		if is_instance_valid(card):
			card.queue_free()
	teammate_cards.clear()

# Waiting for round UI
func show_waiting_for_round() -> void:
	if zombies_hud and zombies_hud.has_node("WaitingLabel"):
		zombies_hud.get_node("WaitingLabel").visible = true

func hide_waiting_for_round() -> void:
	if zombies_hud and zombies_hud.has_node("WaitingLabel"):
		zombies_hud.get_node("WaitingLabel").visible = false

# Perks system
func _create_perks_container() -> void:
	perks_container = VBoxContainer.new()
	perks_container.name = "PerksContainer"

	# Position in bottom left corner
	perks_container.anchor_left = 0.0
	perks_container.anchor_right = 0.0
	perks_container.anchor_top = 1.0
	perks_container.anchor_bottom = 1.0
	perks_container.offset_left = 10
	perks_container.offset_top = -150
	perks_container.offset_right = 250
	perks_container.offset_bottom = -10
	perks_container.grow_vertical = GROW_DIRECTION_BEGIN

	add_child(perks_container)
	perks_container.visible = false  # Hidden until first perk is acquired

func add_perk(perk_type: String) -> void:
	if perk_type in active_perks:
		return  # Already have it

	active_perks.append(perk_type)
	_update_perks_display()

func _update_perks_display() -> void:
	if not perks_container:
		return

	# Clear existing perk labels
	for child in perks_container.get_children():
		child.queue_free()

	if active_perks.is_empty():
		perks_container.visible = false
		return

	perks_container.visible = true

	# Perk display data
	var perk_names = {
		"TacticalVest": "Tactical Vest",
		"FastHands": "Fast Hands",
		"RapidFire": "Rapid Fire",
		"CombatMedic": "Combat Medic",
		"Endurance": "Endurance",
		"Marksman": "Marksman",
		"BlastShield": "Blast Shield",
		"HeavyGunner": "Heavy Gunner"
	}

	var perk_colors = {
		"TacticalVest": Color(0.2, 0.6, 0.2),
		"FastHands": Color(0.8, 0.4, 0.0),
		"RapidFire": Color(0.9, 0.2, 0.2),
		"CombatMedic": Color(0.3, 0.7, 0.9),
		"Endurance": Color(0.9, 0.9, 0.2),
		"Marksman": Color(0.5, 0.3, 0.8),
		"BlastShield": Color(0.4, 0.4, 0.4),
		"HeavyGunner": Color(0.6, 0.2, 0.1)
	}

	# Create label for each perk
	for perk in active_perks:
		var perk_label = Label.new()
		var perk_name = perk_names.get(perk, perk)
		var perk_color = perk_colors.get(perk, Color.WHITE)

		perk_label.text = "• %s" % perk_name
		perk_label.add_theme_color_override("font_color", perk_color)
		perk_label.add_theme_font_size_override("font_size", 14)

		perks_container.add_child(perk_label)

func clear_perks() -> void:
	active_perks.clear()
	_update_perks_display()

# Power-up system
func _create_powerups_container() -> void:
	if not powerups_container:
		powerups_container = VBoxContainer.new()
		powerups_container.name = "PowerupsContainer"

		# Position in bottom left corner, above perks
		powerups_container.anchor_left = 0.0
		powerups_container.anchor_right = 0.0
		powerups_container.anchor_top = 1.0
		powerups_container.anchor_bottom = 1.0
		powerups_container.offset_left = 10
		powerups_container.offset_top = -310  # Above perks (-150 to -10)
		powerups_container.offset_right = 250
		powerups_container.offset_bottom = -160  # 10px gap above perks
		powerups_container.grow_vertical = GROW_DIRECTION_BEGIN

		add_child(powerups_container)

func show_powerup_notification(powerup_name : String) -> void:
	print("[HUD] Power-up collected: ", powerup_name)
	# TODO: Show collection flash/sound effect

func activate_powerup(powerup_name : String, duration : float) -> void:
	if not powerups_container:
		_create_powerups_container()

	# Remove existing entry if refreshing
	if active_powerups.has(powerup_name):
		var entry = active_powerups[powerup_name]
		entry.label.queue_free()
		active_powerups.erase(powerup_name)

	# Create power-up label
	var label = Label.new()
	var display_name = _get_powerup_display_name(powerup_name)
	var color = _get_powerup_color(powerup_name)

	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)

	# Add to container
	powerups_container.add_child(label)

	# Store entry with end time
	var end_time = Time.get_ticks_msec() / 1000.0 + duration
	active_powerups[powerup_name] = {
		"label": label,
		"end_time": end_time,
		"duration": duration
	}

	_update_powerup_label(powerup_name)

func deactivate_powerup(powerup_name : String) -> void:
	if active_powerups.has(powerup_name):
		var entry = active_powerups[powerup_name]
		entry.label.queue_free()
		active_powerups.erase(powerup_name)

func _process(delta: float) -> void:
	# Update power-up countdown timers
	for powerup_name in active_powerups.keys():
		_update_powerup_label(powerup_name)

func _update_powerup_label(powerup_name: String) -> void:
	if not active_powerups.has(powerup_name):
		return

	var entry = active_powerups[powerup_name]
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_remaining = max(0, entry.end_time - current_time)

	var display_name = _get_powerup_display_name(powerup_name)
	entry.label.text = "%s: %ds" % [display_name, ceil(time_remaining)]

func _get_powerup_display_name(powerup_name: String) -> String:
	match powerup_name:
		"insta_kill": return "INSTA-KILL"
		"double_points": return "DOUBLE POINTS"
		"max_ammo": return "MAX AMMO"
		"nuke": return "NUKE"
		_: return powerup_name.to_upper()

func _get_powerup_color(powerup_name: String) -> Color:
	match powerup_name:
		"insta_kill": return Color(1.0, 0.2, 0.2)  # Red
		"double_points": return Color(1.0, 0.85, 0.0)  # Gold
		"max_ammo": return Color(0.0, 0.8, 1.0)  # Cyan
		"nuke": return Color(0.1, 1.0, 0.1)  # Green
		_: return Color.WHITE
