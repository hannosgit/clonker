extends Node2D

# Temporary hand-shaped test geometry. The character only uses physics collision,
# so milestone 2 can replace this scene with generated terrain.
func _ready() -> void:
	_add_solid(PackedVector2Array([
		Vector2(-800, 340), Vector2(-260, 340),
		Vector2(-260, 700), Vector2(-800, 700)
	]), Color("896045"))
	_add_solid(PackedVector2Array([
		Vector2(-260, 340), Vector2(0, 260),
		Vector2(0, 700), Vector2(-260, 700)
	]), Color("a46e48"))
	_add_solid(PackedVector2Array([
		Vector2(0, 260), Vector2(620, 260),
		Vector2(620, 700), Vector2(0, 700)
	]), Color("896045"))
	_add_solid(PackedVector2Array([
		Vector2(770, 300), Vector2(1500, 300),
		Vector2(1500, 700), Vector2(770, 700)
	]), Color("896045"))
	_add_solid(PackedVector2Array([
		Vector2(620, 520), Vector2(770, 520),
		Vector2(770, 700), Vector2(620, 700)
	]), Color("59483f"))
	_add_solid(PackedVector2Array([
		Vector2(1100, 185), Vector2(1130, 185),
		Vector2(1130, 300), Vector2(1100, 300)
	]), Color("4c5d68"))
	_add_solid(PackedVector2Array([
		Vector2(155, 155), Vector2(315, 155),
		Vector2(315, 173), Vector2(155, 173)
	]), Color("596e78"))
	_add_solid(PackedVector2Array([
		Vector2(870, 178), Vector2(1015, 178),
		Vector2(1015, 196), Vector2(870, 196)
	]), Color("596e78"))
	queue_redraw()


func _add_solid(points: PackedVector2Array, fill: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = points
	visual.color = fill
	body.add_child(visual)


func _draw() -> void:
	# Simple original scenery gives the terrain edges visual context.
	draw_circle(Vector2(-555, -200), 74.0, Color("ffe3a2"))
	draw_rect(Rect2(-800, 331, 540, 9), Color("77a75c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-260, 331), Vector2(0, 251),
		Vector2(0, 260), Vector2(-260, 340)
	]), Color("77a75c"))
	draw_rect(Rect2(0, 251, 620, 9), Color("77a75c"))
	draw_rect(Rect2(770, 291, 730, 9), Color("77a75c"))
	draw_rect(Rect2(620, 511, 150, 9), Color("7b725b"))
