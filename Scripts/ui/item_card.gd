class_name ItemCard
extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel
@onready var buy_button: Button = $MarginContainer/VBoxContainer/BuyButton

var current_item: ItemData
var shop_reference: ShopController

func setup(item_data: ItemData, shop: ShopController) -> void:
	current_item = item_data
	shop_reference = shop
	
	name_label.text = current_item.item_name
	desc_label.text = current_item.description
	
	if current_item.icon:
		item_icon.texture = current_item.icon
	buy_button.text = "%d Moedas" % current_item.cost
	buy_button.pressed.connect(_on_buy_pressed)

func _on_buy_pressed() -> void:
	var success = shop_reference.buy_item(current_item)
	
	if success:
		buy_button.disabled = true
		buy_button.text = "Comprado"
		modulate.a = 0.5
