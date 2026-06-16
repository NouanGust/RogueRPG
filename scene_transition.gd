extends CanvasLayer

@onready var color_rect = $ColorRect

func change_scene(target_path: String) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Bloqueia cliques
	
	# Fade para preto
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.3)
	await tween.finished
	
	get_tree().change_scene_to_file(target_path)
	
	# Fade de volta para transparente
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.3)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
