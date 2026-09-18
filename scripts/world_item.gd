extends RigidBody2D
class_name WorldItem

const ItemCatalogScript = preload("res://scripts/item_catalog.gd")
var item_id := ""
var quantity := 1


func configure(id: String, amount: int) -> void:
	assert(amount > 0)
	item_id = id
	quantity = amount
	if is_node_ready():
		_update_appearance()


func _ready() -> void:
	_update_appearance()


func _update_appearance() -> void:
	if item_id.is_empty():
		return
	var definition: Dictionary = ItemCatalogScript.get_definition(item_id)
	$Visual.color = Color.html(definition["color"])
	$Count.text = str(quantity) if quantity > 1 else ""


func set_quantity(amount: int) -> void:
	assert(amount > 0)
	quantity = amount
	_update_appearance()
