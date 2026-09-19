extends Node2D
class_name SettlementBuilding

const Items = preload("res://scripts/item_catalog.gd")
var building_id := ""
var construction_state := "complete"
var contents: Dictionary = {}
var definition: Dictionary = {}


func configure(id: String, data: Dictionary) -> void:
	building_id = id
	definition = data.duplicate(true)
	var size := Vector2(float(definition["size"][0]), float(definition["size"][1]))
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = Vector2(0, -size.y * 0.5)
	body.add_child(shape)
	var label := Label.new()
	label.text = str(definition["name"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-size.x * 0.5, -size.y + 5.0)
	label.size = Vector2(size.x, 20.0)
	label.add_theme_font_size_override("font_size", 11)
	add_child(label)
	queue_redraw()


func footprint() -> Rect2:
	var size := Vector2(float(definition["size"][0]), float(definition["size"][1]))
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)


func interaction_point() -> Vector2:
	return global_position + Vector2(float(definition["interaction_offset"][0]), float(definition["interaction_offset"][1]))


func stored_count() -> int:
	var count := 0
	for id in contents:
		count += int(contents[id])
	return count


func capacity_for(id: String) -> int:
	if Items.get_definition(id)["kind"] != "resource":
		return 0
	return maxi(0, int(definition["storage_capacity"]) - stored_count())


func deposit(id: String, quantity: int) -> bool:
	if quantity <= 0 or quantity > capacity_for(id):
		return false
	contents[id] = int(contents.get(id, 0)) + quantity
	queue_redraw()
	return true


func withdraw(id: String, quantity: int) -> bool:
	if quantity <= 0 or int(contents.get(id, 0)) < quantity:
		return false
	var remaining := int(contents[id]) - quantity
	if remaining == 0:
		contents.erase(id)
	else:
		contents[id] = remaining
	queue_redraw()
	return true


func _draw() -> void:
	if definition.is_empty():
		return
	var size := Vector2(float(definition["size"][0]), float(definition["size"][1]))
	var rect := Rect2(Vector2(-size.x * 0.5, -size.y), size)
	draw_rect(rect, Color.html(definition["color"]))
	draw_rect(rect, Color(0.11, 0.15, 0.19), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(8, 9), Vector2(size.x - 16, 9)), Color(0.15, 0.21, 0.25, 0.7))
	draw_rect(Rect2(Vector2(-8, -19), Vector2(16, 19)), Color(0.23, 0.29, 0.30))
