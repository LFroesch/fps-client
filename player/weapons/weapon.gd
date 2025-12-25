extends Node3D
class_name Weapon

@export var is_automatic := false
@export var shot_cooldown := 0.3

@onready var shoot_light: OmniLight3D = %ShootLight
@onready var shoot_particles: GPUParticles3D = %ShootParticles
@onready var muzzle: Node3D = $Muzzle

var weapon_id : int
var current_ammo : int
var reserve_ammo : int
var mag_size : int
var reload_time : float

func _ready() -> void:
	shoot_light.hide()
	shoot_particles.finished.connect(_on_particles_finished)

func _on_particles_finished() -> void:
	shoot_light.hide()

func init_ammo() -> void:
	var weapon_data := WeaponConfig.get_weapon_data(weapon_id)
	mag_size = weapon_data.mag_size
	reload_time = weapon_data.reload_time
	current_ammo = mag_size
	reserve_ammo = weapon_data.reserve_ammo
	is_automatic = weapon_data.is_automatic
	shot_cooldown = weapon_data.shot_cooldown

func can_shoot() -> bool:
	return current_ammo > 0

func consume_ammo() -> void:
	current_ammo = maxi(0, current_ammo - 1)

func reload() -> void:
	if reserve_ammo <= 0 or current_ammo >= mag_size:
		return

	var ammo_needed := mag_size - current_ammo
	var ammo_to_load := mini(ammo_needed, reserve_ammo)

	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load
	
func play_shoot_fx(is_local := false, is_aiming := false) -> void:
	shoot_light.show()

	# Scale down muzzle flash when aiming down sights
	if is_aiming:
		shoot_light.light_energy = 0.03  # 30% of default
		shoot_particles.amount = 1  # Minimal particles
		shoot_particles.process_material.scale_min = 0.1
		shoot_particles.process_material.scale_max = 0.15
	else:
		shoot_light.light_energy = 0.1  # Default energy
		shoot_particles.amount = 4  # Default particles
		shoot_particles.process_material.scale_min = 1.0
		shoot_particles.process_material.scale_max = 1.0

	shoot_particles.emitting = true

	# Fallback timer to ensure light turns off
	get_tree().create_timer(0.1).timeout.connect(shoot_light.hide)

	var sfx_key : AudioManager.SFXKeys
	
	match weapon_id:
		0:
			sfx_key = AudioManager.SFXKeys.ShootPistol
		1:
			sfx_key = AudioManager.SFXKeys.ShootSMG
		2:
			sfx_key = AudioManager.SFXKeys.ShootShotgun
		3:
			sfx_key = AudioManager.SFXKeys.ShootSniper
		4:
			sfx_key = AudioManager.SFXKeys.ShootAssaultRifle
		5:
			sfx_key = AudioManager.SFXKeys.ShootLMG

	AudioManager.play_sfx(sfx_key, global_position if not is_local else Vector3.ZERO, 0.1)
