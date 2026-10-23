extends Control

signal confirmed

@onready var card: PanelContainer = $Card
@onready var continue_button: Button = $Card/Content/Continue

func _ready() -> void:
	hide()
	continue_button.pressed.connect(_confirm)

func _confirm() -> void:
	if not visible or continue_button.disabled:
		return
	continue_button.disabled = true
	AudioManager.play_ui_choose()
	confirmed.emit()

func present(growth: Dictionary) -> void:
	$Card/Content/Title.text = "Nível %d alcançado" % growth.level
	var keys := ["strength", "intelligence", "faith", "agility"]
	var nodes := ["Strength", "Intelligence", "Faith", "Agility"]
	for index in range(4):
		var stat_card := get_node("Card/Content/Stats/" + nodes[index] + "/VBox")
		var bonus: int = growth.bonuses[index]
		var total: int = growth.attributes[keys[index]]
		stat_card.get_node("Bonus").text = "+%d" % bonus
		stat_card.get_node("Value").text = "%d → %d" % [total - bonus, total]
	$Card/Content/Detail.text = "Vida máxima +%d  ·  Seu poder foi atualizado" % growth.bonuses[0]
	continue_button.disabled = true
	card.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.3)
	await tween.finished
	continue_button.disabled = false
	continue_button.grab_focus()
	await confirmed
	tween = create_tween()
	tween.tween_property(card, "modulate:a", 0.0, 0.18)
	await tween.finished
	hide()
