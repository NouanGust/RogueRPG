#extends CanvasLayer
#
#
## --- Referência da Transição ---
#@onready var fade_screen: ColorRect = $TransitionLayer/FadeScreen
#
#func _ready() -> void:
	#if SaveManager.has_method("load_profile"):
		#SaveManager.load_profile()
	#GameState.reset_run() 
	#
	## 1. Configurações Iniciais "Invisíveis"
	#_switch_ui(title_screen)
	#title_screen.modulate.a = 0.0 # Deixa a UI principal transparente no começo
	#
	## 2. Posiciona a câmera propositalmente "errada" (um pouco para cima e para trás)
	#camera.global_position = pos_main.global_position + Vector3(0, 1.5, 2.0)
	#camera.global_rotation = pos_main.global_rotation
	#camera.rotation_degrees.x -= 10 # Olha mais para baixo
	#
	## 3. Dispara o Efeito Visual de Entrada
	#_play_intro_sequence()
	#
	## ... (Suas conexões de botões continuam aqui embaixo normalmente) ...
	#var btn_nova_run = title_screen.get_node("Caminho/Para/BotaoNovaRun")
	#btn_nova_run.pressed.connect(_on_nova_run_pressed)
	## ...
#
#func _play_intro_sequence() -> void:
	## create_tween().set_parallel(true) faz todas as animações acontecerem ao mesmo tempo
	#var tween = create_tween().set_parallel(true) 
	#
	## A. A tela preta clareia até ficar 100% transparente em 1.5 segundos
	#tween.tween_property(fade_screen, "color:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	#
	## B. A câmera desliza suavemente para a posição oficial do menu principal (pos_main) em 2.5 segundos
	#tween.tween_property(camera, "global_position", pos_main.global_position, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#tween.tween_property(camera, "global_rotation", pos_main.global_rotation, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#
	## C. A interface do jogo (texto e botões) surge depois de 1 segundo de delay
	#tween.tween_property(title_screen, "modulate:a", 1.0, 1.5).set_delay(1.0).set_trans(Tween.TRANS_SINE)
	#
	#await tween.finished
	#
	## Esconde o nó ColorRect para garantir que ele não bloqueie os cliques do mouse nos botões
	#fade_screen.hide()
