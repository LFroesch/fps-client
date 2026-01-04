extends PlayerCharacter
class_name PlayerRemote

const NECK_ROT_SCALAR : PackedFloat32Array = [0.2, -0.2]
const ABDOMEN_ROT_SCALAR : PackedFloat32Array = [0.17, 0]
const TORSO_ROT_SCALAR : PackedFloat32Array = [0.19, -0.15]
const ARM_X_ROT_SCALAR : PackedFloat32Array = [0.19, 0]
const ARM_Y_ROT_SCALAR : PackedFloat32Array = [-0.39, -1.25]

@onready var skeleton: Skeleton3D = %Skeleton3D
@onready var bone_neck := skeleton.find_bone("Neck")
@onready var bone_torso := skeleton.find_bone("Torso")
@onready var bone_abdomen := skeleton.find_bone("Abdomen")
@onready var bone_upper_arm_r := skeleton.find_bone("UpperArm.R")

@onready var animation_player: AnimationPlayer = %AnimationPlayer
const ANIM_BLEND_TIME := 0.2

var display_name : String
@export var name_tag_label: Label

const BLUE_MATERIAL : StandardMaterial3D = preload("res://asset_packs/tutorial-fps-assets/materials/blue_team_material.tres")
const RED_MATERIAL : StandardMaterial3D = preload("res://asset_packs/tutorial-fps-assets/materials/red_team_material.tres")
@onready var helmet_mesh: MeshInstance3D = %Head_2
@onready var body_mesh: MeshInstance3D = %Body

const SKIN_MATERIALS := [
	preload("res://asset_packs/tutorial-fps-assets/materials/player_skin1.tres"),
	preload("res://asset_packs/tutorial-fps-assets/materials/player_skin2.tres"),
	preload("res://asset_packs/tutorial-fps-assets/materials/player_skin3.tres")
]

func _ready() -> void:
	super()
	update_player_colors()
	update_name_tag()

func update_body_geometry(old_data : Dictionary, new_data : Dictionary, lerp_weight : float) -> void:
	position = lerp(old_data.pos, new_data.pos, lerp_weight)
	rotation.y = lerp_angle(old_data.rot_y, new_data.rot_y, lerp_weight)
	set_anim(new_data.anim)
	set_rot_x_visuals(lerp_angle(old_data.rot_x, new_data.rot_x, lerp_weight))
	
func set_anim(anim_name : String) -> void:
	if animation_player.assigned_animation == "Jump_Idle" and anim_name != "Jump_Idle":
		AudioManager.play_sfx(AudioManager.SFXKeys.JumpLand, global_position, 0.2)
		
	if animation_player.assigned_animation == anim_name:
		return
	animation_player.play(anim_name, ANIM_BLEND_TIME)

func set_rot_x_visuals(rot_x : float) -> void:
	var rot_weight := remap(rot_x, -PI/2.0, PI/2.0, 0, 0.7)
	# neck
	var q_neck := skeleton.get_bone_pose_rotation(bone_neck)
	q_neck.x = lerp_angle(NECK_ROT_SCALAR[0], NECK_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation(bone_neck, q_neck)
	# torso
	var q_torso := skeleton.get_bone_pose_rotation(bone_torso)
	q_torso.x = lerp_angle(TORSO_ROT_SCALAR[0], TORSO_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation(bone_torso, q_torso)
	# abdomen
	var q_abdomen := skeleton.get_bone_pose_rotation(bone_abdomen)
	q_abdomen.x = lerp_angle(ABDOMEN_ROT_SCALAR[0], ABDOMEN_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation(bone_abdomen, q_abdomen)
	# upper arm r
	var q_upper_arm_r := skeleton.get_bone_pose_rotation(bone_upper_arm_r)
	q_upper_arm_r.x = lerp_angle(ARM_X_ROT_SCALAR[0], ARM_X_ROT_SCALAR[1], rot_weight)
	q_upper_arm_r.y = lerp_angle(ARM_Y_ROT_SCALAR[0], ARM_Y_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation(bone_upper_arm_r, q_upper_arm_r)

func update_player_colors() -> void:
	var team_material = BLUE_MATERIAL if team == 0 else RED_MATERIAL
	helmet_mesh.set_surface_override_material(1, team_material)
	body_mesh.set_surface_override_material(2, team_material)
	body_mesh.set_surface_override_material(3, team_material)
	body_mesh.set_surface_override_material(0, SKIN_MATERIALS.pick_random())

func update_name_tag() -> void:
	name_tag_label.text = display_name

func play_shoot_fx() -> void:
	weapon_holder.weapon.play_shoot_fx()

func play_footstep_sfx() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.Footstep, global_position, 0.2)

func change_weapon(new_weapon_id: int) -> void:
	# Remove old weapon
	if weapon_holder.weapon and is_instance_valid(weapon_holder.weapon):
		weapon_holder.weapon.queue_free()

	# Update weapon ID and instantiate new weapon
	weapon_id = new_weapon_id
	weapon_holder.instantiate_weapon(new_weapon_id)
