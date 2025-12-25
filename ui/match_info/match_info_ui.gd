extends Control

const BLUE_TEAM_COLOR := "0087ff"
const RED_TEAM_COLOR := "FF4D00"

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var minutes_left_label: Label = %MinutesLeftLabel
@onready var seconds_left_label: Label = %SecondsLeftLabel

@onready var elimination_texts_container: VBoxContainer = %EliminationTextsContainer

# Parent containers to hide/show
@onready var team_scores_container = blue_team_score_label.get_parent().get_parent() if blue_team_score_label else null
@onready var timer_container = minutes_left_label.get_parent().get_parent() if minutes_left_label else null

func _ready() -> void:
	add_to_group("MatchInfoUI")
	update_score(0,0)
	update_match_time_left(0)

func hide_team_scores() -> void:
	# Hide PVP-specific UI elements for zombies mode
	if team_scores_container:
		team_scores_container.hide()
	if timer_container:
		timer_container.hide()
	
func update_score(blue_score : int, red_score : int) -> void:
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)

func update_match_time_left(time_left : int) -> void:
	var minutes_left := time_left / 60
	var seconds_left := time_left - minutes_left * 60
	minutes_left_label.text = str(minutes_left).lpad(2, "0")
	seconds_left_label.text = str(seconds_left).lpad(2, "0")

func show_elimination_text(killer_id: int, victim_id: int, killer_name : String, killer_team : int, victim_name : String, victim_team : int) -> void:
	var elimination_text := preload("res://ui/match_info/elimination_text.tscn").instantiate()
	var killer_color := BLUE_TEAM_COLOR if killer_team == 0 else RED_TEAM_COLOR
	var victim_color := BLUE_TEAM_COLOR if victim_team == 0 else RED_TEAM_COLOR
	
	elimination_text.text = "[color=#%s]%s[/color] eliminated [color=#%s]%s[/color]" % [
		killer_color,
		killer_name,
		victim_color,
		victim_name
	]
	elimination_texts_container.add_child(elimination_text)

func show_chat_message(sender_id: int, sender_name: String, sender_team: int, message: String, is_team_only: bool) -> void:
	var chat_text := preload("res://ui/match_info/elimination_text.tscn").instantiate()
	var sender_color := BLUE_TEAM_COLOR if sender_team == 0 else RED_TEAM_COLOR
	
	if is_team_only:
		chat_text.text = "[color=#%s][TEAM] %s:[/color] %s" % [
			sender_color,
			sender_name,
			message
		]
	else:
		chat_text.text = "[color=#%s]%s:[/color] %s" % [
			sender_color,
			sender_name,
			message
		]
	
	elimination_texts_container.add_child(chat_text)
