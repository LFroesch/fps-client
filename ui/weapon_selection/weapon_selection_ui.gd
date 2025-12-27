extends Control

@onready var auto_select_timer: Timer = $AutoSelectTimer
@onready var background_texture: TextureRect = %BackgroundTexture

func activate(map_id: int = 1) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	# Load the map screenshot
	var screenshot_path := MapRegistry.get_screenshot_path(map_id)
	if ResourceLoader.exists(screenshot_path):
		background_texture.texture = load(screenshot_path)
	else:
		# Fallback to default if screenshot doesn't exist
		print("Map screenshot not found: %s" % screenshot_path)

	show()
	auto_select_timer.start()
	
func _on_pistol_button_pressed() -> void:
	weapon_selected(0)
	
func _on_smg_button_pressed() -> void:
	weapon_selected(1)

func _on_shotgun_button_pressed() -> void:
	weapon_selected(2)

func _on_sniper_button_pressed() -> void:
	weapon_selected(3)

func _on_assault_rifle_button_pressed() -> void:
	weapon_selected(4)

func _on_lmg_button_pressed() -> void:
	weapon_selected(5)

func weapon_selected(weapon_id : int) -> void:
	auto_select_timer.stop()
	get_tree().call_group("Lobby", "weapon_selected", weapon_id)
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_auto_select_timer_timeout() -> void:
	weapon_selected(0)
