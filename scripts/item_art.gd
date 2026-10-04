extends RefCounted
## Shared, resolution-independent artwork for the hotbar, held tools and loose items.

static func draw_icon(canvas: CanvasItem, id: String, center: Vector2, scale_factor := 1.0) -> void:
	var dark := Color("243b3b")
	var steel := Color("b9d2cd")
	var wood := Color("b78453")
	if id == "shovel" or id == "pickaxe":
		_line(canvas, center, Vector2(-7, 12), Vector2(6, -9), dark, 6.0, scale_factor)
		_line(canvas, center, Vector2(-7, 12), Vector2(6, -9), wood, 3.0, scale_factor)
		if id == "shovel":
			_poly(canvas, center, [Vector2(1, -10), Vector2(6, -16), Vector2(14, -12), Vector2(14, -5), Vector2(9, -1)], dark, scale_factor)
			_poly(canvas, center, [Vector2(3, -9), Vector2(7, -14), Vector2(12, -11), Vector2(12, -6), Vector2(9, -3)], steel, scale_factor)
			_line(canvas, center, Vector2(-10, 9), Vector2(-5, 13), steel, 3.0, scale_factor)
		else:
			_poly(canvas, center, [Vector2(-8, -6), Vector2(-4, -13), Vector2(7, -15), Vector2(17, -7), Vector2(6, -10), Vector2(-2, -9)], dark, scale_factor)
			_poly(canvas, center, [Vector2(-6, -7), Vector2(-3, -11), Vector2(7, -13), Vector2(15, -8), Vector2(5, -11), Vector2(-2, -9)], steel, scale_factor)
	elif id == "explosive":
		for x in [-6, 0, 6]:
			canvas.draw_style_box(_box(Color("b45141"), 3), Rect2(center + Vector2(x - 3, -9) * scale_factor, Vector2(6, 21) * scale_factor))
		canvas.draw_rect(Rect2(center + Vector2(-9, -2) * scale_factor, Vector2(18, 5) * scale_factor), Color("e4c28a"))
		_line(canvas, center, Vector2(0, -9), Vector2(4, -16), wood, 2.0, scale_factor)
		canvas.draw_circle(center + Vector2(4, -16) * scale_factor, 2 * scale_factor, Color("f2c66d"))
	elif id == "wood":
		for y in [-4, 4]:
			canvas.draw_style_box(_box(wood, 3), Rect2(center + Vector2(-12, y - 4) * scale_factor, Vector2(23, 8) * scale_factor))
			canvas.draw_circle(center + Vector2(9, y) * scale_factor, 3 * scale_factor, Color("e3bd80"))
			canvas.draw_circle(center + Vector2(9, y) * scale_factor, 1.3 * scale_factor, wood)
	elif id == "metal":
		_poly(canvas, center, [Vector2(-13, 5), Vector2(-7, -6), Vector2(8, -6), Vector2(13, 5), Vector2(7, 9), Vector2(-9, 9)], Color("6b8d92"), scale_factor)
		_poly(canvas, center, [Vector2(-7, -6), Vector2(8, -6), Vector2(4, 2), Vector2(-11, 2)], steel, scale_factor)
	else:
		var color := Color("8b9d99")
		if id == "coal": color = Color("405052")
		if id == "ore": color = Color("c48361")
		if id == "gold": color = Color("dcb765")
		_poly(canvas, center, [Vector2(-12, 4), Vector2(-8, -7), Vector2(2, -11), Vector2(11, -4), Vector2(13, 6), Vector2(3, 11), Vector2(-8, 9)], dark, scale_factor)
		_poly(canvas, center, [Vector2(-10, 3), Vector2(-7, -6), Vector2(2, -9), Vector2(9, -3), Vector2(11, 5), Vector2(3, 9), Vector2(-7, 7)], color, scale_factor)
		_poly(canvas, center, [Vector2(-7, -6), Vector2(2, -9), Vector2(9, -3), Vector2(1, 1)], color.lightened(0.2), scale_factor)
		_line(canvas, center, Vector2(1, 1), Vector2(3, 9), color.darkened(0.18), 1.0, scale_factor)


static func _poly(canvas: CanvasItem, center: Vector2, points: Array, color: Color, scale_factor: float) -> void:
	var polygon := PackedVector2Array()
	for point: Vector2 in points:
		polygon.append(center + point * scale_factor)
	canvas.draw_colored_polygon(polygon, color)


static func _line(canvas: CanvasItem, center: Vector2, start: Vector2, end: Vector2, color: Color, width: float, scale_factor: float) -> void:
	canvas.draw_line(center + start * scale_factor, center + end * scale_factor, color, width * scale_factor, true)


static func _box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
