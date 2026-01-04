extends Node3D
class_name BuyableBase

@export_group("Buyable Settings")
@export var buyable_id: String = ""
@export var cost: int = 1000
@export var buyable_name: String = "Item"
@export var prompt_text: String = "Press F to buy"
@export var one_time_purchase: bool = false

@export_group("Interaction")
@export var interact_range: float = 2.0
@export var require_hold_confirm: bool = false  # Hold F to confirm purchase
@export var hold_duration: float = 0.5  # How long to hold F

var is_purchased: bool = false
var interact_area: Area3D
var player_nearby: PlayerLocal = null
var hold_timer: float = 0.0
var is_holding: bool = false

func _ready() -> void:
	setup_interaction_area()
	setup_visuals()

func setup_interaction_area() -> void:
	interact_area = Area3D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 2  # Player layer

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(interact_range * 2, interact_range * 2, interact_range * 2)
	collision.shape = shape
	collision.position = Vector3(0, interact_range, 0)

	interact_area.add_child(collision)
	add_child(interact_area)

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func setup_visuals() -> void:
	# Override in child classes
	pass

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerLocal:
		player_nearby = body
		update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		hide_prompt()

func _process(delta: float) -> void:
	if not player_nearby or not can_interact():
		hold_timer = 0.0
		is_holding = false
		return

	# Handle hold-to-confirm
	if require_hold_confirm:
		if Input.is_action_pressed("interact"):
			is_holding = true
			hold_timer += delta

			# Update prompt with progress
			var progress = min(hold_timer / hold_duration, 1.0)
			var bar_length = 20
			var filled = int(progress * bar_length)
			var bar = "[" + "=".repeat(filled) + " ".repeat(bar_length - filled) + "]"
			get_tree().call_group("InteractionPrompt", "show_prompt", get_prompt_text() + "\n" + bar)

			if hold_timer >= hold_duration:
				attempt_purchase()
				hold_timer = 0.0
				is_holding = false
		else:
			if is_holding:
				# Released before completion
				hold_timer = 0.0
				is_holding = false
				update_prompt()
	else:
		# Normal instant purchase
		if Input.is_action_just_pressed("interact"):
			attempt_purchase()

func update_prompt() -> void:
	if not can_interact():
		return
	get_tree().call_group("InteractionPrompt", "show_prompt", get_prompt_text())

func hide_prompt() -> void:
	get_tree().call_group("InteractionPrompt", "hide_prompt")

func get_prompt_text() -> String:
	return "%s\nCost: %d points" % [prompt_text, cost]

func can_interact() -> bool:
	if one_time_purchase and is_purchased:
		return false
	return true

func attempt_purchase() -> void:
	if not can_interact():
		return
	on_purchase_requested()

# Override in child classes
func on_purchase_requested() -> void:
	pass

func on_purchase_success() -> void:
	is_purchased = true
	if player_nearby:
		update_prompt()

	# Note: Success message is shown by server RPC handler (s_door_opened, s_weapon_upgraded, s_perk_purchased)
	# Don't show duplicate message here

func on_purchase_failed(reason: String) -> void:
	print("Purchase failed: ", reason)

	# Show error message in chat/feed
	get_tree().call_group("MatchInfoUI", "show_purchase_failed", reason)
