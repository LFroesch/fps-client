extends Node3D
class_name Grenade

# Set to true for wallbuy/display grenades to prevent them from showing indicators
var is_display_only: bool = false

func _ready() -> void:
	if not is_display_only:
		AudioManager.play_sfx(AudioManager.SFXKeys.GrenadeThrow, global_position, 0.1)

func lerp_tform(old_data : Dictionary, new_data : Dictionary, lerp_weight : float) -> void:
	transform = old_data.tform.interpolate_with(new_data.tform, lerp_weight)
	
