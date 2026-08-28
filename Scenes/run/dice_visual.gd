class_name VisualDice
extends Node2D

signal roll_finished

@export var animated_sprite: AnimatedSprite2D 

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	pass

func play_animation(result: int) -> void:
	animated_sprite.play("result_%d" %result)
	
