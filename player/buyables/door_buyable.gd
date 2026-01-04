@tool
extends BuyableBase
class_name DoorBuyable

@export var door_id: String = ""  # Unique ID for this door (e.g. "door_spawn_room")
@export var door_cost: int = 750  # Cost to open this door
@export_enum("Slide", "Swing", "Roll", "Debris") var door_type: String = "Slide":
	set(value):
		door_type = value
		_update_door_mesh()

@export var door_mesh: MeshInstance3D
@export var open_direction: Vector3 = Vector3.RIGHT  # For slide/swing direction

var collision_body: StaticBody3D
var is_open: bool = false
var info_label: Label3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_door_mesh()
		_create_info_label()
		return

	# Set buyable properties
	buyable_id = door_id  # Use door_id as the buyable_id
	one_time_purchase = true
	cost = door_cost
	prompt_text = "Press F to open door"

	super._ready()

func setup_visuals() -> void:
	_update_door_mesh()
	_create_info_label()

	# Create collision for door
	collision_body = StaticBody3D.new()
	collision_body.collision_layer = 1  # player_boundaries layer
	collision_body.collision_mask = 2   # player layer

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3, 2.5, 0.3)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, 1.25, 0)

	collision_body.add_child(collision_shape)
	add_child(collision_body)

func _update_door_mesh() -> void:
	if not is_inside_tree():
		return

	# Find or create door mesh
	if not door_mesh:
		door_mesh = get_node_or_null("DoorMesh")

	if not door_mesh:
		# Create mesh if it doesn't exist
		door_mesh = MeshInstance3D.new()
		door_mesh.name = "DoorMesh"
		add_child(door_mesh)

	# Always set mesh properties
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(3, 2.8, 0.2)
	door_mesh.mesh = box_mesh
	door_mesh.position = Vector3(0, 1.4, 0)

	if not door_mesh.material_override:
		door_mesh.material_override = StandardMaterial3D.new()

	var material = door_mesh.material_override
	var color = _get_door_color()
	material.albedo_color = color

	# Update label if it exists
	if info_label and not Engine.is_editor_hint():
		_update_label_text()

func _create_info_label() -> void:
	if info_label:
		return

	info_label = Label3D.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector3(0, 0.5, 1.6)  # In front of door
	info_label.rotation_degrees = Vector3(0, 0, 0)
	info_label.pixel_size = 0.004
	info_label.modulate = Color.WHITE
	info_label.outline_modulate = Color.BLACK
	info_label.outline_size = 10
	info_label.font_size = 40
	info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_update_label_text()

	if door_mesh:
		door_mesh.add_child(info_label)
	else:
		add_child(info_label)

func _update_label_text() -> void:
	if not info_label:
		return

	var door_name = _get_door_name()
	info_label.text = "%s\n%d POINTS" % [door_name, cost]

func _get_door_name() -> String:
	match door_type:
		"Slide": return "SLIDE DOOR"
		"Swing": return "SWING DOOR"
		"Roll": return "ROLL DOOR"
		"Debris": return "CLEAR DEBRIS"
		_: return "DOOR"

func _get_door_color() -> Color:
	match door_type:
		"Slide": return Color(0.6, 0.4, 0.2)  # Wood
		"Swing": return Color(0.5, 0.3, 0.15)  # Dark wood
		"Roll": return Color(0.4, 0.4, 0.4)  # Metal
		"Debris": return Color(0.3, 0.25, 0.2)  # Rubble
		_: return Color(0.5, 0.5, 0.5)

func can_interact() -> bool:
	return not is_open

func on_purchase_requested() -> void:
	print("Requesting door purchase: ", buyable_id)
	get_tree().call_group("Lobby", "try_buy_door", buyable_id)

func open_door() -> void:
	if is_open:
		return

	is_open = true
	is_purchased = true
	if player_nearby:
		update_prompt()

	# Show success message
	var door_name = _get_door_name()
	get_tree().call_group("MatchInfoUI", "show_purchase_success", door_name)

	# Disable collision
	if collision_body:
		collision_body.process_mode = Node.PROCESS_MODE_DISABLED
		collision_body.set_collision_layer_value(1, false)
		collision_body.set_collision_mask_value(1, false)

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
