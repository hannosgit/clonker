extends RigidBody2D
class_name WorldItem

const ItemCatalogScript = preload("res://scripts/item_catalog.gd")
const Art = preload("res://scripts/item_art.gd")
var item_id := ""
var quantity := 1
var health := 100.0


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
	$Visual.hide()
	$Count.text = str(quantity) if quantity > 1 else ""
	$Count.add_theme_color_override("font_color", Color("ede4c2"))
	$Count.add_theme_color_override("font_outline_color", Color("203633"))
	$Count.add_theme_constant_override("outline_size", 3)
	queue_redraw()


func _draw() -> void:
	if not item_id.is_empty():
		Art.draw_icon(self, item_id, Vector2.ZERO, 0.6)


func set_quantity(amount: int) -> void:
	assert(amount > 0)
	quantity = amount
	_update_appearance()


func receive_damage(amount: float, impulse: Vector2) -> void:
	if not is_queued_for_deletion():
		apply_central_impulse(impulse)
		health -= maxf(amount, 0.0)
		if health <= 0.0:
			queue_free()
