class_name ItemCard
extends PanelContainer

@onready var item_icon: TextureRect = $Row/ItemIcon
@onready var name_label: Label = $Row/Info/NameLabel
@onready var desc_label: Label = $Row/Info/DescLabel
@onready var buy_button: Button = $Row/BuyButton

var current_item: ItemData
var shop_reference: CampController

func setup(item_data: ItemData, shop: CampController) -> void:
	current_item = item_data
	shop_reference = shop
	
	name_label.text = current_item.item_name
	desc_label.text = current_item.description
	
	if current_item.icon:
		item_icon.texture = current_item.icon
	buy_button.text = "%d Moedas" % current_item.cost
	buy_button.pressed.connect(_on_buy_pressed)

func _on_buy_pressed() -> void:
	var success = shop_reference.buy_item(current_item, self)
	
	if success:
		buy_button.disabled = true
		buy_button.text = "Comprado"
		modulate.a = 0.5
