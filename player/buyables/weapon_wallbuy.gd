extends Node3D
class_name WeaponWallbuy

@export var weapon_id: int = 1
@export var weapon_cost: int = 1000
@export var ammo_cost: int = 500

var interact_area: Area3D
var player_nearby: PlayerLocal = null
var weapon_display: Node3D

func _ready() -> void:
	# Instantiate the actual weapon scene based on weapon_id
	weapon_display = _create_weapon_display()
	if weapon_display:
		weapon_display.position = Vector3(0, 1.5, 0)
		weapon_display.rotation = Vector3(0, -90, 0)
		add_child(weapon_display)

	interact_area = Area3D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 2, 2)
	collision.shape = shape
	collision.position = Vector3(0, 1, 0)
	interact_area.add_child(collision)
	add_child(interact_area)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	print("Weapon wallbuy ready at: ", global_position)

func _on_body_entered(body: Node3D) -> void:
	print("Body entered wallbuy: ", body.name)
	if body is PlayerLocal:
		print("Player detected!")
		player_nearby = body
		_update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		get_tree().call_group("InteractionPrompt", "hide_prompt")

func _update_prompt() -> void:
	if not player_nearby:
		return
	var weapon_name = _get_weapon_name()
	var has_weapon = _player_has_weapon()
	if has_weapon:
		get_tree().call_group("InteractionPrompt", "show_prompt",
			"Press F to buy ammo for %s\nCost: %d points" % [weapon_name, ammo_cost])
	else:
		get_tree().call_group("InteractionPrompt", "show_prompt",
			"Press F to buy %s\nCost: %d points" % [weapon_name, weapon_cost])
	print("Prompt updated: ", weapon_name)

func _get_weapon_name() -> String:
	match weapon_id:
		0: return "Pistol"
		1: return "SMG"
		2: return "Shotgun"
		3: return "Assault Rifle"
		4: return "Sniper"
		5: return "LMG"
		_: return "Unknown"

func _player_has_weapon() -> bool:
	if not player_nearby or not player_nearby.weapon_inventory:
		return false
	return player_nearby.weapon_inventory.has_weapon(weapon_id)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		attempt_purchase()

func attempt_purchase() -> void:
	if not player_nearby:
		return
	print("Attempting to buy weapon ", weapon_id)
	get_tree().call_group("Lobby", "try_buy_weapon", weapon_id)

func _create_weapon_display() -> Node3D:
	var weapon: Node3D
	match weapon_id:
		0: weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		3: weapon = preload("res://player/weapons/weapon_sniper.tscn").instantiate()
		4: weapon = preload("res://player/weapons/weapon_assault_rifle.tscn").instantiate()
		5: weapon = preload("res://player/weapons/weapon_lmg.tscn").instantiate()
	return weapon
