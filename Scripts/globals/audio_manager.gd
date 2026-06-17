extends Node

@onready var menu_music_player: AudioStreamPlayer = $MenuMusicPlayer

@export_group("UI")
@export var ui_click_sfx: AudioStream
@export var ui_hover_sfx: AudioStream
@export var ui_cancel_sfx: AudioStream
@export var ui_choose: AudioStream
@export var single_dice_rool: AudioStream
@export var multi_dice_rool: AudioStream


func play_menu_music() -> void:
	if not menu_music_player.playing:
		menu_music_player.play()
		

func stop_music() -> void:
	if menu_music_player.playing:
		menu_music_player.stop()

func play_ui_click() -> void:
	play_sfx(ui_click_sfx, false)
	
func play_ui_cancel() -> void:
	play_sfx(ui_cancel_sfx, false)
	
func play_ui_hover() -> void:
	play_sfx(ui_hover_sfx, false)
	
func play_ui_choose() -> void:
	play_sfx(ui_choose, false)
	
func play_single_dice() -> void:
	play_sfx(single_dice_rool, true)
	
func play_multi_dice() -> void:
	play_sfx(multi_dice_rool, true)
	


func play_sfx(stream: AudioStream, randomize_pitch: bool = true) -> void:
	if stream == null: return
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	
	if randomize_pitch:
		player.pitch_scale = randf_range(0.9, 1.1)
		
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
