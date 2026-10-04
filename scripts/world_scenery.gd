extends Node2D
## Decorative scenery follows the same terrain queries as the editable world.

const SkyBackdrop = preload("res://scripts/sky_backdrop.gd")
@onready var _world: SandboxWorld = get_parent().get_node("World")


func _ready() -> void:
	z_index = -10
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var sky := SkyBackdrop.new()
	sky.camera = get_parent().get_node("Character/Camera2D")
	layer.add_child(sky)
	_world.terrain_changed.connect(func(_cells: Array[Vector2i]): queue_redraw())


func _draw() -> void:
	# Cavities reveal dark underground rather than the outdoor sky.
	var underground := PackedVector2Array([Vector2(-800, 344), Vector2(-260, 344), Vector2(0, 264), Vector2(616, 264), Vector2(616, 520), Vector2(776, 520), Vector2(776, 304), Vector2(1504, 304), Vector2(1504, 768), Vector2(-800, 768)])
	draw_colored_polygon(underground, Color("263b3b"))
	for i in 70:
		var x := -790.0 + fposmod(i * 137.73, 2280.0)
		var y := 370.0 + fposmod(i * 93.7, 370.0)
		draw_circle(Vector2(x, y), 1.0, Color(0.6, 0.73, 0.65, 0.14))
	if not is_instance_valid(_world):
		return
	for tree in [Vector3(-560, 344, 100), Vector3(-315, 344, 140), Vector3(40, 264, 120), Vector3(390, 264, 154), Vector3(560, 264, 92), Vector3(830, 304, 132), Vector3(1220, 304, 155), Vector3(1390, 304, 90)]:
		var root_position := Vector2(tree.x, tree.y)
		if _world.Materials.is_solid(_world.get_cell_material(_world.world_to_cell(root_position + Vector2(0, 4)))):
			_tree(root_position, tree.z)
	# Small tufts, pebbles and flowers are anchored to the current solid surface.
	for x in range(-780, 1500, 18):
		var surface := 344.0
		if x >= -260 and x < 0: surface = ceilf((340.0 - (x + 260) * 80.0 / 260.0) / 8.0) * 8.0
		elif x >= 0 and x < 620: surface = 264.0
		elif x >= 620 and x < 770: continue
		elif x >= 770: surface = 304.0
		var root_position := Vector2(x + 5, surface)
		if not _world.Materials.is_solid(_world.get_cell_material(_world.world_to_cell(root_position + Vector2(0, 2)))):
			continue
		if _world.Materials.is_solid(_world.get_cell_material(_world.world_to_cell(root_position + Vector2(0, -2)))):
			continue
		var h := 4.0 + fposmod(x * 7.13, 7.0)
		for blade in 3:
			draw_line(root_position + Vector2(blade * 2 - 2, 0), root_position + Vector2(blade * 4 - 4, -h + blade), Color("6f9362"), 1.5, true)
		if posmod(x, 7) == 0:
			draw_circle(root_position + Vector2(0, -h), 2.0, Color("dfc784"))


func _tree(root_position: Vector2, height: float) -> void:
	draw_rect(Rect2(root_position + Vector2(-4, -height * 0.64), Vector2(8, height * 0.64)), Color("5c6851"))
	draw_rect(Rect2(root_position + Vector2(0, -height * 0.64), Vector2(3, height * 0.64)), Color("73795a"))
	for tier in 4:
		var top := root_position + Vector2(0, -height + tier * height * 0.18)
		var width := height * (0.19 + tier * 0.035)
		var points := PackedVector2Array([top, top + Vector2(width, height * 0.38), top + Vector2(width * 0.45, height * 0.34), top + Vector2(-width, height * 0.38)])
		draw_colored_polygon(points, Color("3e6c59"))
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(-width, height * 0.38), top + Vector2(-3, height * 0.29)]), Color("507d60"))
