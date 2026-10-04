extends Node2D

const Art = preload("res://scripts/item_art.gd")
var _phase := 0.0
var _hurt_time := 0.0
var _last_health := 100
@onready var _player: CharacterController = get_parent()


func _process(delta: float) -> void:
	_phase += delta * absf(_player.velocity.x) * 0.065
	if _player.health < _last_health:
		_hurt_time = 0.2
	_last_health = _player.health
	_hurt_time = maxf(0, _hurt_time - delta)
	modulate = Color("ffd5ba") if _hurt_time > 0 else Color.WHITE
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_player):
		return
	var walking := _player.is_on_floor() and absf(_player.velocity.x) > 10.0
	var stride := sin(_phase) * 3.0 if walking else 0.0
	var bob := absf(sin(_phase)) * -1.1 if walking else sin(Time.get_ticks_msec() * 0.002) * 0.4
	if _player.is_on_floor():
		draw_set_transform(Vector2(0, 19), 0, Vector2(1, 0.24))
		draw_circle(Vector2.ZERO, 14, Color(0.07, 0.15, 0.12, 0.2))
		draw_set_transform(Vector2.ZERO)
	# Boots, trousers, canvas pack, jacket, scarf, and a brass mining helmet.
	_box(Rect2(-9 - stride, 8, 7, 10), Color("304d48"), 2)
	_box(Rect2(2 + stride, 8, 7, 10), Color("243e3c"), 2)
	_box(Rect2(-11 - stride, 15, 10, 5), Color("253b37"), 2)
	_box(Rect2(1 + stride, 15, 11, 5), Color("253b37"), 2)
	draw_line(Vector2(-10 - stride, 19), Vector2(-2 - stride, 19), Color("8b8b63"), 1)
	draw_line(Vector2(2 + stride, 19), Vector2(11 + stride, 19), Color("8b8b63"), 1)
	draw_set_transform(Vector2(0, bob))
	_box(Rect2(-15, -6, 8, 17), Color("53634b"), 3)
	draw_line(Vector2(-13, -2), Vector2(-13, 7), Color("a49c69"), 2)
	_box(Rect2(-10, -5, 20, 19), Color("ad8c4f"), 4)
	_box(Rect2(1, -2, 8, 14), Color("c3a45d"), 2)
	draw_rect(Rect2(-10, 10, 20, 3), Color("5c5940"))
	draw_rect(Rect2(2, 10, 4, 3), Color("dfc77e"))
	draw_line(Vector2(-5, -3), Vector2(-4, 9), Color("e1c786"), 2)
	draw_circle(Vector2(0, -12), 9, Color("dcaf79"))
	draw_circle(Vector2(4, -12), 6, Color("edc18c"))
	draw_circle(Vector2(5, -13), 1.4, Color("253b37"))
	draw_line(Vector2(3, -7), Vector2(7, -7), Color("af7654"), 1, true)
	_box(Rect2(-10, -6, 19, 4), Color("bd6b4e"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -4), Vector2(-14, 3), Vector2(-9, 4), Vector2(-4, -3)]), Color("bd6b4e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -17), Vector2(-8, -24), Vector2(-2, -27), Vector2(6, -25), Vector2(10, -18)]), Color("d2b26a"))
	draw_line(Vector2(-7, -23), Vector2(-2, -25), Color("ecd28a"), 2, true)
	_box(Rect2(-12, -19, 26, 4), Color("90794b"), 1)
	draw_circle(Vector2(10, -20), 4, Color("3d5650"))
	draw_circle(Vector2(11, -20), 2.6, Color("f3dd9c"))
	# A soft lamp halo is visible against the underground background.
	if _player.global_position.y > 355:
		for radius in [23, 15, 9]:
			draw_circle(Vector2(14, -20), radius, Color(1, 0.87, 0.55, 0.055))
	var stack := _player.inventory.selected_stack()
	if not stack.is_empty():
		var swing := sin(clampf(_player.tool_cooldown * 8.0, 0, PI)) * -0.65
		draw_set_transform(Vector2(15, 4 + bob), swing)
		Art.draw_icon(self, stack["id"], Vector2.ZERO, 0.55)
		draw_set_transform(Vector2(0, bob))
	_box(Rect2(6, 0, 7, 9), Color("c5a361"), 3)
	draw_circle(Vector2(11, 7), 3, Color("edc18c"))
	draw_set_transform(Vector2.ZERO)


func _box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)
