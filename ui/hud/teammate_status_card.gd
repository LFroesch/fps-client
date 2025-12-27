extends PanelContainer
class_name TeammateStatusCard

@onready var player_name_label: Label = $MarginContainer/VBox/PlayerNameLabel
@onready var score_label: Label = $MarginContainer/VBox/ScoreLabel
@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var status_label: Label = $MarginContainer/VBox/StatusLabel

var player_id: int = -1
var player_name: String = ""
var is_downed: bool = false
var current_health: int = 100
var max_health: int = 100
var score: int = 0

func _ready() -> void:
	update_display()

func setup(p_id: int, p_name: String) -> void:
	player_id = p_id
	player_name = p_name
	update_display()

func set_health(health: int, max_hp: int) -> void:
	current_health = health
	max_health = max_hp
	update_display()

func set_downed(downed: bool) -> void:
	is_downed = downed
	update_display()

func set_score(new_score: int) -> void:
	score = new_score
	update_display()

func update_display() -> void:
	if not is_node_ready():
		return

	if player_name_label:
		player_name_label.text = player_name

	if score_label:
		score_label.text = "Score: %d" % score

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

		# Color code the health bar
		if is_downed:
			health_bar.modulate = Color.RED
		elif current_health < max_health * 0.3:
			health_bar.modulate = Color.ORANGE_RED
		elif current_health < max_health * 0.6:
			health_bar.modulate = Color.ORANGE
		else:
			health_bar.modulate = Color.GREEN

	if status_label:
		if is_downed:
			status_label.text = "⚠ DOWNED"
			status_label.add_theme_color_override("font_color", Color.RED)
		else:
			status_label.text = ""
			status_label.add_theme_color_override("font_color", Color.GREEN)
		status_label.show()  # Always show status

	# Change panel color based on status
	if is_downed:
		modulate = Color(1.0, 0.5, 0.5, 0.9)  # Reddish tint
	else:
		modulate = Color.WHITE
