extends Node
class_name InventoryComponent

signal item_used(item_id: String)

var items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + amount

func has_item(item_id: String) -> bool:
	return items.get(item_id, 0) > 0

func use_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false

	items[item_id] -= 1
	if items[item_id] <= 0:
		items.erase(item_id)

	item_used.emit(item_id)
	return true
