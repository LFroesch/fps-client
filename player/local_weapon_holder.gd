extends WeaponHolder
class_name LocalWeaponHolder

var trigger_pressed := false
var is_on_cooldown := false
var is_reloading := false
const RECOIL_TWEEN_TIME := 0.2
var recoil_tween : Tween
var is_switching := false

# Multiple weapons support
var weapons_cache: Dictionary = {}  # weapon_id -> Weapon instance

func _physics_process(delta: float) -> void:
	if trigger_pressed and not is_on_cooldown and not is_reloading:
		shoot()
	# Update HUD ammo display
	if weapon:
		get_tree().call_group("HUDManager", "update_ammo", weapon.current_ammo, weapon.reserve_ammo, weapon.mag_size, weapon.weapon_id)
		
func shoot() -> void:
	# Check if we can shoot
	if not weapon.can_shoot():
		if not is_reloading:
			start_reload()
		return

	if not weapon.is_automatic:
		trigger_pressed = false

	weapon.consume_ammo()

	# Get player ADS state and weapon config for effects
	var player = get_parent().get_parent() as PlayerLocal
	var is_aiming = player.is_aiming if player else false
	var weapon_data = WeaponConfig.get_weapon_data(weapon.weapon_id)

	is_on_cooldown = true
	get_tree().create_timer(weapon.shot_cooldown).timeout.connect(on_cooldown_timer_timeout)
	weapon.play_shoot_fx(true, is_aiming)

	if recoil_tween != null:
		recoil_tween.kill()

	var recoil_rotation = weapon_data["recoil_rotation_ads"] if is_aiming else weapon_data["recoil_rotation_hipfire"]
	var recoil_position = weapon_data["recoil_position_ads"] if is_aiming else weapon_data["recoil_position_hipfire"]
	var shake_amount = weapon_data["recoil_camera_shake_ads"] if is_aiming else weapon_data["recoil_camera_shake_hipfire"]

	weapon.rotation_degrees.x = recoil_rotation
	weapon.position.z = recoil_position

	recoil_tween = create_tween().set_parallel()
	recoil_tween.tween_property(weapon, "rotation:x", 0.0, RECOIL_TWEEN_TIME)
	recoil_tween.tween_property(weapon, "rotation:z", 0.0, RECOIL_TWEEN_TIME)

	get_tree().call_group("Lobby", "local_shot_fired")
	get_tree().call_group("CameraShakeComponent", "add_noise", shake_amount)

	# Auto-reload when empty
	if weapon.current_ammo <= 0:
		start_reload()

func start_reload() -> void:
	if is_reloading or weapon.reserve_ammo <= 0 or weapon.current_ammo >= weapon.mag_size:
		return

	is_reloading = true
	trigger_pressed = false  # Cancel shooting

	# Hide reload prompt during reload
	get_tree().call_group("ReloadPrompt", "hide")

	# Animate gun tilt during reload
	var reload_tween := create_tween().set_parallel()
	reload_tween.tween_property(weapon, "rotation:z", deg_to_rad(-45), weapon.reload_time * 0.3)
	reload_tween.tween_property(weapon, "position:y", -0.1, weapon.reload_time * 0.3)
	reload_tween.chain().tween_property(weapon, "rotation:z", 0.0, weapon.reload_time * 0.7)
	reload_tween.parallel().tween_property(weapon, "position:y", 0.0, weapon.reload_time * 0.7)

	await get_tree().create_timer(weapon.reload_time).timeout

	weapon.reload()
	is_reloading = false
	
func start_trigger_press() -> void:
	trigger_pressed = true
	
func end_trigger_press() -> void:
	trigger_pressed = false

func on_cooldown_timer_timeout() -> void:
	is_on_cooldown = false

# Weapon inventory management
func add_weapon_to_inventory(weapon_id: int) -> void:
	# If the current weapon matches this weapon_id and isn't cached yet, cache it
	if weapon and weapon.weapon_id == weapon_id and not weapons_cache.has(weapon_id):
		_apply_perks_to_weapon(weapon)  # Apply perks to existing weapon
		weapons_cache[weapon_id] = weapon
		print("Cached existing weapon: ", weapon_id)
	# Create and cache the weapon if not already cached
	elif not weapons_cache.has(weapon_id):
		var new_weapon = _create_weapon_instance(weapon_id)
		_apply_perks_to_weapon(new_weapon)
		weapons_cache[weapon_id] = new_weapon

	# Switch to this weapon
	switch_to_weapon(weapon_id)

func switch_to_weapon(weapon_id: int) -> void:
	if is_switching or is_reloading:
		return

	# If we don't have this weapon, can't switch
	if not weapons_cache.has(weapon_id):
		return

	# Already on this weapon
	if weapon and weapon.weapon_id == weapon_id:
		return

	is_switching = true
	trigger_pressed = false  # Cancel shooting

	# Hide current weapon
	if weapon and weapon.is_inside_tree():
		weapon.visible = false

	# Switch to new weapon
	var new_weapon = weapons_cache[weapon_id]

	# Remove old weapon from tree but keep in cache
	if weapon and weapon.is_inside_tree():
		remove_child(weapon)

	# Add new weapon to tree
	weapon = new_weapon
	if not weapon.is_inside_tree():
		add_child(weapon)

	weapon.visible = true

	# Notify server of weapon switch
	get_tree().call_group("Lobby", "weapon_switched", weapon_id)

	# Simple delay instead of fade (Node3D doesn't have modulate)
	await get_tree().create_timer(0.3).timeout
	is_switching = false

func has_weapon_in_inventory(weapon_id: int) -> bool:
	return weapons_cache.has(weapon_id)

func get_current_weapon_id() -> int:
	if weapon and is_instance_valid(weapon):
		return weapon.weapon_id
	return -1

func _create_weapon_instance(weapon_id: int) -> Weapon:
	var new_weapon: Weapon
	match weapon_id:
		0: new_weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: new_weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: new_weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		3: new_weapon = preload("res://player/weapons/weapon_sniper.tscn").instantiate()
		4: new_weapon = preload("res://player/weapons/weapon_assault_rifle.tscn").instantiate()
		5: new_weapon = preload("res://player/weapons/weapon_lmg.tscn").instantiate()
		_:
			push_error("Invalid weapon_id: %d" % weapon_id)
			new_weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()

	if new_weapon:
		new_weapon.weapon_id = weapon_id
		new_weapon.init_ammo()
	return new_weapon

func _apply_perks_to_weapon(weapon: Weapon) -> void:
	# Apply active perks to newly acquired weapons
	var player = get_parent().get_parent() as PlayerLocal
	if not player or not player.has_meta("perks"):
		return

	var perks = player.get_meta("perks")

	# Apply FastHands perk (+50% reload speed)
	if "FastHands" in perks:
		weapon.reload_time /= 1.5

	# Apply RapidFire perk (+33% fire rate)
	if "RapidFire" in perks:
		weapon.shot_cooldown /= 1.33
