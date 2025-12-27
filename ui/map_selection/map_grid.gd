extends Control

signal map_selected(map_id: int, game_mode: MapRegistry.GameMode)

@onready var grid_container: GridContainer = %GridContainer

const MapCard = preload("res://ui/map_selection/map_card.tscn")

var current_game_mode: MapRegistry.GameMode = MapRegistry.GameMode.PVP

func setup(game_mode: MapRegistry.GameMode) -> void:
	current_game_mode = game_mode
	populate_maps()

func populate_maps() -> void:
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()

	# Add random map card first
	var random_card = MapCard.instantiate()
	grid_container.add_child(random_card)
	random_card.setup_random()
	random_card.map_selected.connect(_on_map_card_selected)

	# Get maps for current mode
	var map_ids = MapRegistry.get_maps_for_mode(current_game_mode)

	# Create card for each map
	for map_id in map_ids:
		var card = MapCard.instantiate()
		grid_container.add_child(card)
		card.setup(map_id)
		card.map_selected.connect(_on_map_card_selected)

func _on_map_card_selected(map_id: int) -> void:
	map_selected.emit(map_id, current_game_mode)
