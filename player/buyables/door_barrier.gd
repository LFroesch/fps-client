extends StaticBody3D
class_name DoorBarrier

@export var cost: int = 750
@export var door_id: String = "door_1"

var is_open: bool = false
var interact_area: Area3D
var player_nearby: PlayerLocal = null
var door_mesh: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready() -> void:
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3, 2.5, 0.3)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, 1.25, 0)
	add_child(collision_shape)
	door_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(3, 2.5, 0.3)
	door_mesh.mesh = mesh
	door_mesh.position = Vector3(0, 1.25, 0)
	add_child(door_mesh)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	door_mesh.material_override = material
	interact_area = Area3D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 2
	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	area_shape.size = Vector3(4, 3, 2)
	area_collision.shape = area_shape
	area_collision.position = Vector3(0, 1.5, 0)
	interact_area.add_child(area_collision)
	add_child(interact_area)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	print("Door barrier ready at: ", global_position)

func _on_body_entered(body: Node3D) -> void:
	print("Body entered door: ", body.name)
	if body is PlayerLocal and not is_open:
		print("Player detected at door!")
		player_nearby = body
		_update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		get_tree().call_group("InteractionPrompt", "hide_prompt")

func _update_prompt() -> void:
	if not player_nearby or is_open:
		return
	get_tree().call_group("InteractionPrompt", "show_prompt",
		"Press F to open door\nCost: %d points" % cost)
	print("Door prompt shown")

func _process(_delta: float) -> void:
	if player_nearby and not is_open and Input.is_action_just_pressed("interact"):
		attempt_purchase()

func attempt_purchase() -> void:
	if is_open or not player_nearby:
		return
	print("Attempting to buy door ", door_id)
	get_tree().call_group("Lobby", "try_buy_door", door_id)

func open_door() -> void:
	if is_open:
		return
	is_open = true
	collision_shape.disabled = true
	var tween = create_tween()
	tween.set_parallel(true)
	var material = door_mesh.material_override as StandardMaterial3D
	tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
	tween.tween_property(door_mesh, "position:y", 3.0, 0.5)
	tween.finished.connect(func():
		door_mesh.visible = false
		get_tree().call_group("InteractionPrompt", "hide_prompt")
	)
	print("Door %s opened!" % door_id)
