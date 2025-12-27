extends Control

@onready var marker_lines: Array[ColorRect] = [
	$TopLeft,
	$TopRight,
	$BottomLeft,
	$BottomRight
]

const MARKER_DURATION := 0.15
const HEADSHOT_COLOR := Color(1, 0.3, 0.3)  # Red for headshots
const NORMAL_COLOR := Color(1, 1, 1)  # White for normal hits

var marker_timer := 0.0

func _ready() -> void:
	hide_marker()

func _process(delta: float) -> void:
	if marker_timer > 0:
		marker_timer -= delta
		if marker_timer <= 0:
			hide_marker()

func show_hit(is_headshot := false) -> void:
	var color := HEADSHOT_COLOR if is_headshot else NORMAL_COLOR

	for line in marker_lines:
		line.color = color
		line.modulate.a = 1.0

	marker_timer = MARKER_DURATION

func hide_marker() -> void:
	for line in marker_lines:
		line.modulate.a = 0.0
