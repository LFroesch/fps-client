extends Control
class_name DownedOverlay

@onready var vignette: ColorRect = $Vignette
@onready var bleed_out_label: Label = $BleedOutLabel
@onready var revive_prompt: Label = $RevivePrompt

var bleed_out_time := 0.0
var is_downed := false

func _ready() -> void:
	add_to_group("DownedOverlay")
	hide()

func show_downed(time_remaining: float) -> void:
	is_downed = true
	bleed_out_time = time_remaining
	show()

	# Grayscale effect (applied to the camera, will add that separately)
	# For now just show the vignette
	if vignette:
		vignette.show()

func hide_downed() -> void:
	is_downed = false
	hide()
	if vignette:
		vignette.hide()

func update_bleed_out_timer(time_remaining: float) -> void:
	bleed_out_time = time_remaining
	if bleed_out_label:
		bleed_out_label.text = "DOWNED - %d seconds until death" % int(time_remaining)

		# Change color as time runs out
		if time_remaining < 10:
			bleed_out_label.add_theme_color_override("font_color", Color.RED)
		elif time_remaining < 20:
			bleed_out_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			bleed_out_label.add_theme_color_override("font_color", Color.YELLOW)

func show_revive_prompt(reviving_player_name: String) -> void:
	if revive_prompt:
		revive_prompt.text = "%s is reviving you..." % reviving_player_name
		revive_prompt.show()

func hide_revive_prompt() -> void:
	if revive_prompt:
		revive_prompt.hide()
