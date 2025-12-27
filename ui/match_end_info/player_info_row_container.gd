extends VBoxContainer
class_name PlayerInfoRowContainer

@onready var player_name_label: Label = %PlayerNameLabel
@onready var kills_amount_label: Label = %KillsAmountLabel
@onready var deaths_amount_label: Label = %DeathsAmountLabel


var player_name := "Player Name"
var kills_amount := 0
var deaths_amount := 0

func _ready() -> void:
	player_name_label.text = player_name
	kills_amount_label.text = str(kills_amount)
	deaths_amount_label.text = str(deaths_amount)
	
func set_data(_player_name : String, _kills_amount : int, _deaths_amount : int) -> void:
	player_name = _player_name
	kills_amount = _kills_amount
	deaths_amount = _deaths_amount

	# Update labels immediately if they exist
	if player_name_label:
		player_name_label.text = player_name
	if kills_amount_label:
		kills_amount_label.text = str(kills_amount)
	if deaths_amount_label:
		deaths_amount_label.text = str(deaths_amount)

func set_zombie_data(_player_name : String, _points : int, _kills : int) -> void:
	player_name = _player_name
	kills_amount = _points  # Store points in kills column
	deaths_amount = _kills  # Store kills in deaths column

	# For zombie mode: kills column shows points, deaths column shows kills
	if player_name_label:
		player_name_label.text = player_name
	if kills_amount_label:
		kills_amount_label.text = str(_points)
	if deaths_amount_label:
		deaths_amount_label.text = str(_kills)
