extends Control

@onready var countdown_label: Label = %CountdownLabel
@onready var map_name_label: Label = %MapNameLabel

const COUNTDOWN_TIME := 3.0
var time_remaining := COUNTDOWN_TIME

func _ready() -> void:
	set_process(false)  # Disabled by default

func activate(map_id: int = 1) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Hide weapon selection UI (zombies mode doesn't use it)
	get_tree().call_group("WeaponSelectionUI", "hide")

	# Set map name
	map_name_label.text = MapRegistry.get_map_name(map_id)

	# Reset countdown
	time_remaining = COUNTDOWN_TIME

	show()
	set_process(true)
	print("Zombies countdown started!")

func _process(delta: float) -> void:
	if not visible:
		return

	time_remaining -= delta

	# Update countdown display
	var seconds_left := ceili(time_remaining)
	countdown_label.text = str(seconds_left)

	# Auto-ready when countdown finishes
	if time_remaining <= 0:
		set_process(false)
		auto_ready()
		hide()

func auto_ready() -> void:
	print("Auto-readying with pistol (weapon_id=0)")
	# Send pistol selection (weapon_id = 0) to server
	get_tree().call_group("Lobby", "weapon_selected", 0)
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
