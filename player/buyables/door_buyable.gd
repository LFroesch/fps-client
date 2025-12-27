extends BuyableBase
class_name DoorBuyable

@export_enum("Slide", "Swing", "Roll", "Debris") var door_type: String = "Slide"
@export var door_mesh: MeshInstance3D
@export var open_direction: Vector3 = Vector3.RIGHT  # For slide/swing direction

var collision_shape: CollisionShape3D
var is_open: bool = false

func _ready() -> void:
	# Set buyable properties
	one_time_purchase = true
	prompt_text = "Press F to open door"

	super._ready()

func setup_visuals() -> void:
	# If no mesh is provided, create a default door
	if not door_mesh:
		door_mesh = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(3, 2.5, 0.3)
		door_mesh.mesh = mesh
		door_mesh.position = Vector3(0, 1.25, 0)

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.6, 0.4, 0.2)  # Wood color
		door_mesh.material_override = material

		add_child(door_mesh)

	# Create collision for door
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3, 2.5, 0.3)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, 1.25, 0)

	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	add_child(static_body)

func can_interact() -> bool:
	return not is_open

func on_purchase_requested() -> void:
	print("Requesting door purchase: ", buyable_id)
	get_tree().call_group("Lobby", "try_buy_door", buyable_id)

func open_door() -> void:
	if is_open:
		return

	is_open = true
	on_purchase_success()

	# Disable collision
	if collision_shape:
		collision_shape.disabled = true

	# Animate door based on type
	match door_type:
		"Slide":
			_animate_slide_door()
		"Swing":
			_animate_swing_door()
		"Roll":
			_animate_roll_door()
		"Debris":
			_animate_debris_door()

	print("Door %s opened!" % buyable_id)

func _animate_slide_door() -> void:
	if not door_mesh:
		return

	var tween = create_tween()
	tween.set_parallel(false)

	# Slide door in the open_direction
	var target_pos = door_mesh.position + (open_direction.normalized() * 3.0)
	tween.tween_property(door_mesh, "position", target_pos, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_swing_door() -> void:
	if not door_mesh:
		return

	var tween = create_tween()
	tween.set_parallel(false)

	# Rotate door 90 degrees around Y axis
	var current_rotation = door_mesh.rotation_degrees
	var target_rotation = current_rotation + Vector3(0, 90, 0)
	tween.tween_property(door_mesh, "rotation_degrees", target_rotation, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_roll_door() -> void:
	if not door_mesh:
		return

	var tween = create_tween()
	tween.set_parallel(false)

	# Roll door upward (garage door style)
	var target_pos = door_mesh.position + Vector3(0, 3.0, 0)
	tween.tween_property(door_mesh, "position", target_pos, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_debris_door() -> void:
	if not door_mesh:
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out and fall
	var material = door_mesh.material_override as StandardMaterial3D
	if material:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.5)

	tween.tween_property(door_mesh, "position:y", door_mesh.position.y - 1.0, 0.5)

	tween.finished.connect(func():
		door_mesh.visible = false
	)
