extends Node

enum GameMode {
	PVP,
	ZOMBIES
}

const MAPS = {
	0: {
		"name": "Farm",
		"client_path": "res://maps/map_farm.tscn",
		"server_path": "res://maps/server_farm.tscn",
		"screenshot_path": "res://asset_packs/tutorial-fps-assets/textures/bg_black_and_white.png",
		"modes": [GameMode.PVP, GameMode.ZOMBIES]
	},
	1: {
		"name": "Killroom",
		"client_path": "res://maps/map_killroom.tscn",
		"server_path": "res://maps/server_killroom.tscn",
		"screenshot_path": "res://asset_packs/tutorial-fps-assets/textures/fill_bg.jpg",
		"modes": [GameMode.PVP, GameMode.ZOMBIES]
	},
	2: {
		"name": "Shipment",
		"client_path": "res://maps/map_shipment.tscn",
		"server_path": "res://maps/server_shipment.tscn",
		"screenshot_path": "res://asset_packs/tutorial-fps-assets/textures/fill_bg.jpg",
		"modes": [GameMode.PVP, GameMode.ZOMBIES]
	},
	3: {
		"name": "Desert",
		"client_path": "res://maps/map_desert.tscn",
		"server_path": "res://maps/server_desert.tscn",
		"screenshot_path": "res://asset_packs/tutorial-fps-assets/textures/fill_bg.jpg",
		"modes": [GameMode.PVP, GameMode.ZOMBIES]
	},
	4: {
		"name": "Office",
		"client_path": "res://maps/map_office.tscn",
		"server_path": "res://maps/server_office.tscn",
		"screenshot_path": "res://asset_packs/tutorial-fps-assets/textures/fill_bg.jpg",
		"modes": [GameMode.PVP, GameMode.ZOMBIES]
	}
}

const ANY_MAP := -1

func get_map_data(map_id: int) -> Dictionary:
	if map_id == ANY_MAP:
		return {}
	return MAPS.get(map_id, {})

func get_map_count() -> int:
	return MAPS.size()

func get_all_map_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in MAPS.keys():
		ids.append(id)
	return ids

func get_map_name(map_id: int) -> String:
	if map_id == ANY_MAP:
		return "Any Map"
	var data = get_map_data(map_id)
	return data.get("name", "Unknown")

func get_client_path(map_id: int) -> String:
	var data = get_map_data(map_id)
	return data.get("client_path", "")

func get_server_path(map_id: int) -> String:
	var data = get_map_data(map_id)
	return data.get("server_path", "")

func get_screenshot_path(map_id: int) -> String:
	var data = get_map_data(map_id)
	return data.get("screenshot_path", "res://asset_packs/tutorial-fps-assets/textures/bg_black_and_white.png")

func get_maps_for_mode(mode: GameMode) -> Array[int]:
	var ids: Array[int] = []
	for id in MAPS.keys():
		var modes = MAPS[id].get("modes", [])
		if mode in modes:
			ids.append(id)
	return ids

func supports_mode(map_id: int, mode: GameMode) -> bool:
	var data = get_map_data(map_id)
	var modes = data.get("modes", [])
	return mode in modes

func get_mode_name(mode: GameMode) -> String:
	match mode:
		GameMode.PVP:
			return "PvP"
		GameMode.ZOMBIES:
			return "Zombies"
		_:
			return "Unknown"
