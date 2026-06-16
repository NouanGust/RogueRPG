extends Label

func start(damage_value: int, start_position: Vector2, is_critical: bool = false) -> void:
	text = str(damage_value)
	# Centraliza o texto na posição exata de onde ele nasceu
	position = start_position - (size / 2.0) 
	
	# Se for um dano alto, pode pintar de vermelho ou laranja
	if is_critical:
		modulate = Color(1.0, 0.2, 0.2) # Vermelho
		scale = Vector2(1.5, 1.5) # Dá uma ampliada
		
	var tween = create_tween().set_parallel(true)
	
	# Animação 1: Sobe 50 pixels em 0.6 segundos, começando rápido e desacelerando
	tween.tween_property(self, "position:y", position.y - 50, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Animação 2: Some (fade out) ao mesmo tempo
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Espera o tween inteiro acabar e deleta o nó para não pesar a memória
	await tween.finished
	queue_free()
