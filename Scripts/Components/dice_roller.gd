class_name DiceRoller
extends Node

signal rolled(sides: int, result: int)

func roll(sides:int) -> int:
	var result := randi_range(1, max(1,sides))
	rolled.emit(sides, result)
	return result
	
