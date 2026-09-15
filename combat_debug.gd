class_name CombatDebug
extends PanelContainer

@onready var info_label: RichTextLabel = $MarginContainer/RichTextLabel

var player: PlayerActor
var enemy: EnemyActor
var last_math_log: String = "Nenhum ataque realizado."

var is_visible:bool = true


func setup(_player: PlayerActor, _enemy: EnemyActor) -> void:
	player = _player
	enemy = _enemy
	
	player.combat_component.attacked.connect(_on_player_attacked)
	enemy.combat_component.attacked.connect(_on_enemy_attacked)
	
	update_display()
	self.visible = is_visible


func update_display() -> void:
	if player == null or enemy == null: return
	
	var p_stats = player.stats_component
	var e_stats = enemy.stats_component
	
	var text := ""
	
	# --- STATUS DO JOGADOR ---
	text += "[color=cyan][b]--- JOGADOR ---[/b][/color]\n"
	text += "ATK Base: %d | DEF Total: %d\n" % [p_stats.get_value("attack"), p_stats.get_value("defense")]
	text += "FOR: %d | AGI: %d | INT: %d\n\n" % [p_stats.get_value("strength"), p_stats.get_value("agility"), p_stats.get_value("intelligence")]
	
	# --- STATUS DO INIMIGO ---
	text += "[color=orange][b]--- INIMIGO ---[/b][/color]\n"
	text += "ATK Base: %d | DEF Total: %d\n" % [e_stats.get_value("attack"), e_stats.get_value("defense")]
	text += "FOR: %d | AGI: %d\n\n" % [e_stats.get_value("strength"), e_stats.get_value("agility")]
	
	# --- MATEMÁTICA DOS BASTIDORES ---
	text += "[color=yellow][b]--- ÚLTIMO CÁLCULO ---[/b][/color]\n"
	text += last_math_log
	
	info_label.text = text

func _on_player_attacked(raw_damage: int, final_damage: int) -> void:
	var enemy_def = enemy.stats_component.get_value("defense")
	last_math_log = "Jogador ataca!\n"
	last_math_log += "Dano Bruto (%d) - Defesa Inimiga (%d) = Dano Final: [color=red]%d[/color]" % [raw_damage, enemy_def, final_damage]
	update_display()

func _on_enemy_attacked(raw_damage: int, final_damage: int) -> void:
	var player_def = player.stats_component.get_value("defense")
	last_math_log = "Inimigo ataca!\n"
	last_math_log += "Dano Bruto (%d) - Defesa Jogador (%d) = Dano Final: [color=red]%d[/color]" % [raw_damage, player_def, final_damage]
	update_display()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug"):
		is_visible = !is_visible
		self.visible = is_visible
	
