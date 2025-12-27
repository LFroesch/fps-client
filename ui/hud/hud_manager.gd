extends Control

# References to HUD elements
@onready var hit_marker: Control = $HitMarker
@onready var damage_numbers_container: Control = $DamageNumbersContainer
@onready var kill_confirmation: Label = $KillConfirmation
@onready var ammo_label: Label = $AmmoContainer/AmmoLabel
@onready var reload_prompt: Label = $AmmoContainer/ReloadPrompt

# Zombies mode HUD elements (optional, will be created if not present)
@onready var points_label: Label = $ZombiesHUD/PointsLabel if has_node("ZombiesHUD/PointsLabel") else null
@onready var wave_label: Label = $ZombiesHUD/WaveLabel if has_node("ZombiesHUD/WaveLabel") else null
@onready var zombies_remaining_label: Label = $ZombiesHUD/ZombiesRemainingLabel if has_node("ZombiesHUD/ZombiesRemainingLabel") else null
@onready var break_timer_label: Label = $ZombiesHUD/BreakTimerLabel if has_node("ZombiesHUD/BreakTimerLabel") else null
@onready var kills_label: Label = $ZombiesHUD/KillsLabel if has_node("ZombiesHUD/KillsLabel") else null
@onready var downs_label: Label = $ZombiesHUD/DownsLabel if has_node("ZombiesHUD/DownsLabel") else null
@onready var teammate_status_container: VBoxContainer = $ZombiesHUD/TeammateStatusContainer if has_node("ZombiesHUD/TeammateStatusContainer") else null
@onready var zombies_hud: Control = $ZombiesHUD if has_node("ZombiesHUD") else null

var player_kills := 0
var player_downs := 0
var teammate_cards := {}  # Dictionary to track teammate status cards
var waiting_label: Label = null  # "Waiting for next round" label

const DAMAGE_NUMBER_SCENE := preload("res://ui/hud/damage_number.tscn")
const TEAMMATE_STATUS_CARD_SCENE := preload("res://ui/hud/teammate_status_card.tscn")

func _ready() -> void:
	add_to_group("HUDManager")

	# Create zombies HUD dynamically if it doesn't exist
	if not has_node("ZombiesHUD"):
		create_zombies_hud()
	else:
		zombies_hud = $ZombiesHUD
		points_label = zombies_hud.get_node("PointsLabel") if zombies_hud.has_node("PointsLabel") else null
		wave_label = zombies_hud.get_node("WaveLabel") if zombies_hud.has_node("WaveLabel") else null
		zombies_remaining_label = zombies_hud.get_node("ZombiesRemainingLabel") if zombies_hud.has_node("ZombiesRemainingLabel") else null
		break_timer_label = zombies_hud.get_node("BreakTimerLabel") if zombies_hud.has_node("BreakTimerLabel") else null
		kills_label = zombies_hud.get_node("KillsLabel") if zombies_hud.has_node("KillsLabel") else null
		downs_label = zombies_hud.get_node("DownsLabel") if zombies_hud.has_node("DownsLabel") else null
		teammate_status_container = zombies_hud.get_node("TeammateStatusContainer") if zombies_hud.has_node("TeammateStatusContainer") else null

	# Hide zombies HUD by default (shown only in zombies mode)
	if zombies_hud:
		zombies_hud.visible = false

func create_zombies_hud() -> void:
	# Create container
	zombies_hud = Control.new()
	zombies_hud.name = "ZombiesHUD"
	zombies_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	zombies_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zombies_hud)

	# Create VBox for organizing labels
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vbox.offset_left = -300
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.add_theme_constant_override("separation", 10)
	zombies_hud.add_child(vbox)

	# Wave label
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "Wave 1"
	wave_label.add_theme_font_size_override("font_size", 28)
	wave_label.add_theme_color_override("font_outline_color", Color.BLACK)
	wave_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(wave_label)

	# Zombies remaining label
	zombies_remaining_label = Label.new()
	zombies_remaining_label.name = "ZombiesRemainingLabel"
	zombies_remaining_label.text = "Zombies: 0"
	zombies_remaining_label.add_theme_font_size_override("font_size", 20)
	zombies_remaining_label.add_theme_color_override("font_outline_color", Color.BLACK)
	zombies_remaining_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(zombies_remaining_label)

	# Points label
	points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Points: 0"
	points_label.add_theme_font_size_override("font_size", 24)
	points_label.add_theme_color_override("font_outline_color", Color.BLACK)
	points_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(points_label)

	# Kills label
	kills_label = Label.new()
	kills_label.name = "KillsLabel"
	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 20)
	kills_label.add_theme_color_override("font_outline_color", Color.BLACK)
	kills_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(kills_label)

	# Downs label
	downs_label = Label.new()
	downs_label.name = "DownsLabel"
	downs_label.text = "Downs: 0"
	downs_label.add_theme_font_size_override("font_size", 20)
	downs_label.add_theme_color_override("font_outline_color", Color.BLACK)
	downs_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(downs_label)

	# Break timer label (centered at top, below the stats)
	break_timer_label = Label.new()
	break_timer_label.name = "BreakTimerLabel"
	break_timer_label.text = "Next wave in: 10s"
	break_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	break_timer_label.offset_top = 250  # Moved down to avoid overlap with stats
	break_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	break_timer_label.add_theme_font_size_override("font_size", 32)
	break_timer_label.add_theme_color_override("font_color", Color.YELLOW)
	break_timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	break_timer_label.add_theme_constant_override("outline_size", 5)
	break_timer_label.visible = false
	zombies_hud.add_child(break_timer_label)

	# Teammate status container (left side)
	teammate_status_container = VBoxContainer.new()
	teammate_status_container.name = "TeammateStatusContainer"
	teammate_status_container.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	teammate_status_container.offset_left = 20
	teammate_status_container.offset_top = -100
	teammate_status_container.offset_bottom = 100
	teammate_status_container.add_theme_constant_override("separation", 8)
	zombies_hud.add_child(teammate_status_container)

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

func update_ammo(current: int, reserve: int, mag_size: int = 0) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [current, reserve]

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
	print("[HUD] add_teammate called for player %d: %s" % [player_id, player_name])

	if not teammate_status_container:
		print("[HUD] ERROR: teammate_status_container is null!")
		return

	# Create card if it doesn't exist
	if not teammate_cards.has(player_id):
		print("[HUD] Creating new teammate card for %d" % player_id)
		var teammate_card = TEAMMATE_STATUS_CARD_SCENE.instantiate()
		teammate_card.setup(player_id, player_name)
		teammate_card.set_health(100, 100)  # Initialize with full health
		teammate_card.set_downed(false)  # Start as alive
		teammate_status_container.add_child(teammate_card)
		teammate_cards[player_id] = teammate_card
		print("[HUD] Teammate card created successfully. Total cards: %d" % teammate_cards.size())
	else:
		print("[HUD] Card for player %d already exists" % player_id)

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
	if not waiting_label:
		waiting_label = Label.new()
		waiting_label.name = "WaitingLabel"
		waiting_label.text = "WAITING FOR NEXT ROUND"
		waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		waiting_label.add_theme_font_size_override("font_size", 48)
		waiting_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))

		# Position in center of screen
		waiting_label.anchors_preset = Control.PRESET_CENTER
		waiting_label.offset_left = -300
		waiting_label.offset_top = -50
		waiting_label.offset_right = 300
		waiting_label.offset_bottom = 50

		add_child(waiting_label)

	waiting_label.visible = true

func hide_waiting_for_round() -> void:
	if waiting_label:
		waiting_label.visible = false
