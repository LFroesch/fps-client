extends Node

enum MusicKeys {
	MenuMusic,
	BattleMusic
}

enum SFXKeys {
	UIClick,
	PickupHealth,
	PickupGrenade,
	PickupAmmo,
	ShootPistol,
	ShootSMG,
	ShootShotgun,
	ShootSniper,
	ShootAssaultRifle,
	ShootLMG,
	Footstep,
	JumpLand,
	GrenadeThrow,
	GrenadeExplode,
	Kill,
	Hit
}

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var music_transition_tween : Tween

func _ready() -> void:
	set_music_volume(0)
	
func set_music_volume(volume_linear : float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(volume_linear))
	
func play_music(music_key : MusicKeys) -> void:
	var stream : AudioStream
	match music_key:
		MusicKeys.MenuMusic:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/music/Shrooter_Music_Menu.ogg")
		MusicKeys.BattleMusic:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/music/Shrooter_Music_Gameplay.ogg")
	if music_transition_tween != null:
		music_transition_tween.kill()
	music_transition_tween = create_tween()
	if music_player.playing:
		music_transition_tween.tween_method(set_music_volume, 1.0, 0.0, 1)
		
	music_transition_tween.tween_callback(music_player.set_stream.bind(stream))
	music_transition_tween.tween_callback(music_player.play)
	music_transition_tween.tween_method(set_music_volume, 0.0, 1.0, 1)

func play_sfx(sfx_key : SFXKeys, position := Vector3.ZERO, pitch_rand := 0.0) -> void:
	var stream : AudioStream
	match sfx_key:
		SFXKeys.UIClick:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/ui_click.ogg")
		SFXKeys.PickupHealth:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/pickup_health.ogg")
		SFXKeys.PickupGrenade:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/pickup_grenade.ogg")
		SFXKeys.PickupAmmo:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/pickup_grenade.ogg")  # TODO: Replace with actual ammo pickup sound
		SFXKeys.ShootPistol:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/pistol_shot.ogg")
		SFXKeys.ShootSMG:
			stream = load("res://asset_packs/tutorial-fps-assets//audio/sfx/smg_shot.ogg")
		SFXKeys.ShootShotgun:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/shotgun_shot.ogg")
		SFXKeys.ShootSniper:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/shotgun_shot.ogg")  # TODO: Replace with actual sniper sound
		SFXKeys.ShootAssaultRifle:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/smg_shot.ogg")  # TODO: Replace with actual assault rifle sound
		SFXKeys.ShootLMG:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/smg_shot.ogg")  # TODO: Replace with actual LMG sound
		SFXKeys.Footstep:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/footstep.ogg")
		SFXKeys.JumpLand:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/jump_land.ogg")
		SFXKeys.GrenadeThrow:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/grenade_throw.ogg")
		SFXKeys.GrenadeExplode:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/grenade_explosion.ogg")
		SFXKeys.Kill:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/ui_click.ogg")  # TODO: Replace with actual kill sound
		SFXKeys.Hit:
			stream = load("res://asset_packs/tutorial-fps-assets/audio/sfx/ui_click.ogg")  # TODO: Replace with actual hit sound
			
	var sfx_player
	
	if position == Vector3.ZERO:
		sfx_player = AudioStreamPlayer.new()
	else:
		sfx_player = AudioStreamPlayer3D.new()
		sfx_player.position = position
	sfx_player.stream = stream
	sfx_player.bus = "SFX"
	sfx_player.pitch_scale = 1 + randf_range(-pitch_rand, pitch_rand)
	sfx_player.finished.connect(sfx_player.queue_free)
	add_child(sfx_player)
	sfx_player.play()
