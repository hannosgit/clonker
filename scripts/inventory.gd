extends RefCounted
class_name CharacterInventory

const ItemCatalogScript = preload("res://scripts/item_catalog.gd")
const SLOT_COUNT := 6
var slots: Array[Dictionary] = []
var selected := 0


func _init() -> void:
	for i in SLOT_COUNT:
		slots.append({})


func selected_stack() -> Dictionary:
	return slots[selected].duplicate()


func select_slot(index: int) -> void:
	if index >= 0 and index < SLOT_COUNT:
		selected = index


func count(id: String) -> int:
	var total := 0
	for stack in slots:
		if stack.get("id", "") == id:
			total += int(stack["quantity"])
	return total


func capacity_for(id: String) -> int:
	var maximum: int = ItemCatalogScript.max_stack(id)
	var capacity := 0
	for stack in slots:
		if stack.is_empty():
			capacity += maximum
		elif stack["id"] == id:
			capacity += maximum - int(stack["quantity"])
	return capacity


func add(id: String, quantity: int) -> bool:
	if quantity <= 0 or capacity_for(id) < quantity:
		return false
	var remaining := quantity
	var maximum: int = ItemCatalogScript.max_stack(id)
	for stack in slots:
		if stack.get("id", "") == id and remaining > 0:
			var transfer: int = mini(maximum - int(stack["quantity"]), remaining)
			stack["quantity"] += transfer
			remaining -= transfer
	for i in SLOT_COUNT:
		if remaining == 0:
			break
		if slots[i].is_empty():
			var transfer := mini(maximum, remaining)
			slots[i] = {"id": id, "quantity": transfer}
			remaining -= transfer
	return remaining == 0


func take_selected() -> Dictionary:
	var stack := selected_stack()
	if not stack.is_empty():
		slots[selected] = {}
	return stack


func remove(id: String, quantity: int) -> bool:
	if quantity <= 0 or count(id) < quantity:
		return false
	var remaining := quantity
	for i in SLOT_COUNT:
		if slots[i].get("id", "") != id:
			continue
		var used: int = mini(remaining, int(slots[i]["quantity"]))
		slots[i]["quantity"] = int(slots[i]["quantity"]) - used
		remaining -= used
		if int(slots[i]["quantity"]) == 0:
			slots[i] = {}
		if remaining == 0:
			break
	return true
