extends CanvasLayer

@onready var color_rect = $ColorRect
var is_transitioning: bool = false

func change_scene(target_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Bloqueia cliques
	
	# Fade para preto
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.3)
	await tween.finished
	
	var error := get_tree().change_scene_to_file(target_path)
	if error != OK:
		push_error("Não foi possível abrir a cena: " + target_path)
	
	# Fade de volta para transparente
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.3)
	await tween.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
