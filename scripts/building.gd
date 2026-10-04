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
	label.position = Vector2(-size.x * 0.5 - 10, -size.y - 24.0)
	label.size = Vector2(size.x + 20, 20.0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("e9dfbc"))
	label.add_theme_color_override("font_outline_color", Color("29443b"))
	label.add_theme_constant_override("outline_size", 3)
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
	var left := -size.x * 0.5
	var top := -size.y
	var timber := Color("52634c")
	draw_rect(Rect2(left - 3, -2, size.x + 6, 5), Color(0.09, 0.18, 0.15, 0.24))
	if building_id == "furnace":
		draw_rect(rect, Color("697267"))
		for row in 6:
			for column in 5:
				var brick := Rect2(left + column * 13 - (6 if row % 2 else 0), top + row * 8, 12, 7).intersection(rect)
				if brick.has_area(): draw_rect(brick, Color("879080") if (row + column) % 3 == 0 else Color("747e70"))
		draw_rect(Rect2(9, top - 12, 12, 18), Color("59695f"))
		draw_rect(Rect2(7, top - 14, 16, 4), Color("a6aa8a"))
		draw_circle(Vector2(0, -16), 15, Color("a9a285"))
		draw_rect(Rect2(-15, -16, 30, 16), Color("a9a285"))
		draw_circle(Vector2(0, -15), 10, Color("293e37"))
		draw_rect(Rect2(-10, -15, 20, 15), Color("293e37"))
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -4), Vector2(-5, -12), Vector2(0, -9), Vector2(4, -17), Vector2(8, -4)]), Color("d99757"))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -3), Vector2(0, -10), Vector2(4, -3)]), Color("f0cf7c"))
		draw_line(Vector2(-14, -1), Vector2(14, -1), timber, 3)
		return
	if building_id == "storage":
		draw_rect(rect, Color("9f865b"))
		for row in range(1, 5):
			draw_line(Vector2(left + 2, top + row * 8), Vector2(-left - 2, top + row * 8), Color("806d4e"), 1)
		draw_rect(Rect2(left + 1, top + 2, 5, size.y - 2), timber)
		draw_rect(Rect2(-left - 6, top + 2, 5, size.y - 2), timber)
		draw_line(Vector2(left + 7, top + 6), Vector2(-left - 7, -4), Color("c4a572"), 4)
		draw_line(Vector2(-left - 7, top + 6), Vector2(left + 7, -4), Color("c4a572"), 4)
		draw_rect(Rect2(left - 2, top - 2, size.x + 4, 6), Color("5a735b"))
		draw_rect(Rect2(-4, top + 14, 8, 8), Color("d6bd78"))
		return
	var wall := Color.html(definition["color"])
	draw_rect(Rect2(left, top + 14, size.x, size.y - 14), wall)
	for row in range(3, 8):
		draw_line(Vector2(left, top + row * 6), Vector2(-left, top + row * 6), wall.darkened(0.1), 1)
	for post in [left + 2, -left - 5]:
		draw_rect(Rect2(post, top + 14, 4, size.y - 14), timber)
	draw_colored_polygon(PackedVector2Array([Vector2(left - 4, top + 16), Vector2(0, top - 2), Vector2(-left + 4, top + 16)]), Color("485f50"))
	draw_colored_polygon(PackedVector2Array([Vector2(left - 3, top + 13), Vector2(0, top - 3), Vector2(0, top + 13)]), Color("657c5b"))
	for row in 3:
		var y := top + 4 + row * 4
		var half := (row + 1) * size.x / 8.0
		draw_line(Vector2(-half, y), Vector2(half, y), Color("798965"), 1)
	draw_line(Vector2(left - 4, top + 16), Vector2(-left + 4, top + 16), Color("bbad79"), 2)
	# Framed amber windows and a plank door.
	_window(Vector2(left + 11, top + 23))
	if building_id == "base": _window(Vector2(-left - 24, top + 23))
	draw_rect(Rect2(-8, -24, 16, 24), timber)
	draw_rect(Rect2(-6, -22, 12, 22), Color("a18455"))
	draw_line(Vector2(0, -20), Vector2(0, -2), Color("796d4c"), 1)
	draw_circle(Vector2(4, -11), 1.3, Color("e7ca84"))
	draw_rect(Rect2(-11, -3, 22, 3), Color("c1b082"))
	if building_id == "workshop":
		draw_rect(Rect2(15, -18, 17, 3), Color("e0c286"))
		for x in [17, 28]: draw_rect(Rect2(x, -15, 3, 15), timber)
		draw_circle(Vector2(24, top + 25), 5, timber)
		draw_circle(Vector2(24, top + 25), 2, Color("d6bd78"))
	else:
		# A little outpost pennant.
		draw_line(Vector2(20, top + 7), Vector2(20, top - 13), timber, 2)
		draw_colored_polygon(PackedVector2Array([Vector2(21, top - 13), Vector2(36, top - 10), Vector2(21, top - 5)]), Color("c38c5f"))


func _window(origin: Vector2) -> void:
	draw_rect(Rect2(origin - Vector2.ONE * 2, Vector2(17, 14)), Color("425b4c"))
	draw_rect(Rect2(origin, Vector2(13, 10)), Color("d9bd78"))
	draw_rect(Rect2(origin + Vector2(1, 1), Vector2(5, 4)), Color("ebd79b"))
	draw_line(origin + Vector2(6, 0), origin + Vector2(6, 10), Color("6a7651"), 1)
	draw_line(origin + Vector2(0, 5), origin + Vector2(13, 5), Color("6a7651"), 1)
