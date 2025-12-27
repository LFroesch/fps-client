extends Control
class_name ReviveProgress

@onready var prompt_label: Label = $PromptLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var player_name_label: Label = $PlayerNameLabel

const REVIVE_TIME := 3.0  # Seconds to complete revive

var is_reviving := false
var revive_timer := 0.0
var target_player_name := ""

func _ready() -> void:
	add_to_group("ReviveProgress")
	hide()

func start_revive(player_name: String) -> void:
	target_player_name = player_name
	is_reviving = true
	revive_timer = 0.0

	if player_name_label:
		player_name_label.text = "Reviving %s" % player_name

	if progress_bar:
		progress_bar.value = 0

	show()

func update_revive_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress * 100.0

func cancel_revive() -> void:
	is_reviving = false
	revive_timer = 0.0
	hide()

func complete_revive() -> void:
	is_reviving = false
	if progress_bar:
		progress_bar.value = 100
	# Brief delay then hide
	await get_tree().create_timer(0.3).timeout
	hide()
