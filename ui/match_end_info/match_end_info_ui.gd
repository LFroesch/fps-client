extends Control
class_name MatchEndInfoUI

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var blue_team_player_info_container: VBoxContainer = %BlueTeamPlayerInfoContainer
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var red_team_player_info_container: VBoxContainer = %RedTeamPlayerInfoContainer
@onready var blue_team_info_container: VBoxContainer = $MarginContainer/VBoxContainer/BlueTeamInfoContainer
@onready var red_team_info_container: VBoxContainer = $MarginContainer/VBoxContainer/RedTeamInfoContainer

var player_info_row_container_scene := preload("res://ui/match_end_info/player_info_row_container.tscn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_score_infos(client_data : Dictionary, game_mode : int = 0) -> void:
	print("=== MATCH END INFO ===")
	print("Game mode: ", game_mode)
	print("Client data received:")
	for player_id in client_data.keys():
		var data = client_data[player_id]
		print("  Player ", player_id, ": ", data)

	# Check if this is zombie mode (game_mode 1 = zombies)
	if game_mode == 1:
		show_zombie_scores(client_data)
	else:
		show_pvp_scores(client_data)

func show_pvp_scores(client_data : Dictionary) -> void:
	var blue_score := 0
	var red_score := 0
	for data in client_data.values():
		if not data.has("team"):
			continue
		var player_info_row : PlayerInfoRowContainer = player_info_row_container_scene.instantiate()
		player_info_row.set_data(data.display_name, data.kills, data.deaths)

		var target_player_info_container : VBoxContainer

		if data.team == 0:
			red_score += data.deaths
			target_player_info_container = blue_team_player_info_container
		else:
			blue_score += data.deaths
			target_player_info_container = red_team_player_info_container

		target_player_info_container.add_child(player_info_row)

	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)

func show_zombie_scores(client_data : Dictionary) -> void:
	# Hide team separation for zombie mode
	if red_team_info_container:
		red_team_info_container.visible = false

	# Change blue team container to show all players
	if blue_team_info_container:
		blue_team_info_container.modulate = Color.WHITE
		var title_hbox = blue_team_info_container.get_node("HBoxContainer")
		if title_hbox:
			var title_label = title_hbox.get_node("TitleLabel")
			if title_label:
				title_label.text = "FINAL STATS"

	if blue_team_score_label:
		blue_team_score_label.visible = false

	# Update column headers for zombie mode
	var header_hbox = blue_team_player_info_container.get_node("HBoxContainer")
	if header_hbox:
		# Replace kills icon with "POINTS" label
		var kills_icon = header_hbox.get_node("KillsIconTextureRect")
		if kills_icon:
			kills_icon.visible = false
			var points_label = Label.new()
			points_label.name = "PointsLabel"
			points_label.custom_minimum_size = Vector2(96, 0)
			points_label.add_theme_font_size_override("font_size", 20)
			points_label.text = "POINTS"
			points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header_hbox.add_child(points_label)
			header_hbox.move_child(points_label, kills_icon.get_index())

		# Replace deaths icon with "KILLS" label
		var deaths_icon = header_hbox.get_node("DeathsIconTextureRect")
		if deaths_icon:
			deaths_icon.visible = false
			var kills_label = Label.new()
			kills_label.name = "KillsLabel"
			kills_label.custom_minimum_size = Vector2(96, 0)
			kills_label.add_theme_font_size_override("font_size", 20)
			kills_label.text = "KILLS"
			kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header_hbox.add_child(kills_label)
			header_hbox.move_child(kills_label, deaths_icon.get_index())

	# Sort players by points (primary) then kills (secondary) for zombie mode
	var players_array := []
	for data in client_data.values():
		players_array.append(data)

	# Sort by points first, then kills
	players_array.sort_custom(func(a, b):
		var points_a = a.get("points", 0)
		var points_b = b.get("points", 0)
		if points_a == points_b:
			return a.get("kills", 0) > b.get("kills", 0)
		return points_a > points_b
	)

	# Display players with their points and kills
	for data in players_array:
		var player_info_row : PlayerInfoRowContainer = player_info_row_container_scene.instantiate()
		var points = data.get("points", 0)
		var kills = data.get("kills", 0)
		player_info_row.set_zombie_data(data.get("display_name", "Unknown"), points, kills)
		blue_team_player_info_container.add_child(player_info_row)

func _on_exit_button_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
