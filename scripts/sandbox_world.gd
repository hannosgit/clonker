extends Node2D
class_name SandboxWorld

const CELL_SIZE := 8
const CHUNK_SIZE := 32
const WIDTH := 288
const HEIGHT := 144
const ORIGIN := Vector2i(-800, -384)
const Materials = preload("res://scripts/material_catalog.gd")

var cells := PackedByteArray()
var chunks: Dictionary = {}
var dirty_chunks: Dictionary = {}
var rebuild_count := 0
var last_rebuild_us := 0
var total_rebuild_us := 0
var _scheduled := false


func _ready() -> void:
	Materials.load_definitions()
	cells.resize(WIDTH * HEIGHT)
	_generate_course()
	for cy in ceili(float(HEIGHT) / CHUNK_SIZE):
		for cx in ceili(float(WIDTH) / CHUNK_SIZE):
			dirty_chunks[Vector2i(cx, cy)] = true
	_flush_dirty()


func world_to_cell(world_position: Vector2) -> Vector2i:
	var p := to_local(world_position) - Vector2(ORIGIN)
	return Vector2i(floori(p.x / CELL_SIZE), floori(p.y / CELL_SIZE))


func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(Vector2(ORIGIN + cell * CELL_SIZE))


func get_cell_material(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= WIDTH or cell.y >= HEIGHT:
		return Materials.SKY
	return cells[cell.y * WIDTH + cell.x]


func apply_edits(edits: Array) -> Dictionary:
	var removed: Dictionary = {}
	for edit in edits:
		var cell: Vector2i = edit["cell"]
		var material: int = edit["material"]
		if cell.x < 0 or cell.y < 0 or cell.x >= WIDTH or cell.y >= HEIGHT or not Materials.has_id(material):
			continue
		var old := get_cell_material(cell)
		if old == material or (Materials.is_solid(material) and _overlaps_actor(cell)):
			continue
		if Materials.is_solid(old):
			removed[old] = removed.get(old, 0) + 1
		cells[cell.y * WIDTH + cell.x] = material
		_mark_dirty(cell)
	if not dirty_chunks.is_empty() and not _scheduled:
		_scheduled = true
		call_deferred("_flush_dirty")
	return removed


func remove_circle(center: Vector2, radius: float) -> Dictionary:
	return paint_circle(center, radius, Materials.SKY)


func paint_circle(center: Vector2, radius: float, material: int) -> Dictionary:
	var local := to_local(center)
	var first := world_to_cell(center - Vector2.ONE * radius)
	var last := world_to_cell(center + Vector2.ONE * radius)
	var edits: Array = []
	for y in range(maxi(first.y, 0), mini(last.y, HEIGHT - 1) + 1):
		for x in range(maxi(first.x, 0), mini(last.x, WIDTH - 1) + 1):
			var middle := Vector2(ORIGIN) + Vector2(x + 0.5, y + 0.5) * CELL_SIZE
			if middle.distance_squared_to(local) <= radius * radius:
				edits.append({"cell": Vector2i(x, y), "material": material})
	return apply_edits(edits)


func solid_intersects(rect: Rect2) -> bool:
	var first := world_to_cell(rect.position + Vector2.ONE * 0.1)
	var last := world_to_cell(rect.end - Vector2.ONE * 0.1)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			if Materials.is_solid(get_cell_material(Vector2i(x, y))):
				return true
	return false


func _overlaps_actor(cell: Vector2i) -> bool:
	var bounds := Rect2(cell_to_world(cell), Vector2.ONE * CELL_SIZE)
	for actor in get_tree().get_nodes_in_group("terrain_actors"):
		if bounds.intersects(Rect2(actor.global_position - Vector2(11, 18), Vector2(22, 36))):
			return true
	return false


func _mark_dirty(cell: Vector2i) -> void:
	var chunk := Vector2i(cell.x / CHUNK_SIZE, cell.y / CHUNK_SIZE)
	_dirty(chunk)
	if cell.x % CHUNK_SIZE == 0:
		_dirty(chunk + Vector2i.LEFT)
	if cell.x % CHUNK_SIZE == CHUNK_SIZE - 1:
		_dirty(chunk + Vector2i.RIGHT)
	if cell.y % CHUNK_SIZE == 0:
		_dirty(chunk + Vector2i.UP)
	if cell.y % CHUNK_SIZE == CHUNK_SIZE - 1:
		_dirty(chunk + Vector2i.DOWN)


func _dirty(chunk: Vector2i) -> void:
	if chunk.x >= 0 and chunk.y >= 0 and chunk.x * CHUNK_SIZE < WIDTH and chunk.y * CHUNK_SIZE < HEIGHT:
		dirty_chunks[chunk] = true


func _flush_dirty() -> void:
	_scheduled = false
	if dirty_chunks.is_empty():
		return
	var start := Time.get_ticks_usec()
	var pending := dirty_chunks.keys()
	dirty_chunks.clear()
	for key in pending:
		_rebuild_chunk(key)
	last_rebuild_us = Time.get_ticks_usec() - start
	total_rebuild_us += last_rebuild_us
	rebuild_count += pending.size()
	_resolve_actors()


func _rebuild_chunk(key: Vector2i) -> void:
	var node: Node2D = chunks.get(key)
	if node == null:
		node = Node2D.new()
		node.name = "Chunk_%d_%d" % [key.x, key.y]
		node.position = Vector2(ORIGIN + key * CHUNK_SIZE * CELL_SIZE)
		add_child(node)
		var sprite := Sprite2D.new()
		sprite.name = "Texture"
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node.add_child(sprite)
		var body := StaticBody2D.new()
		body.name = "Collision"
		body.collision_layer = 1
		body.collision_mask = 0
		node.add_child(body)
		chunks[key] = node
	var body: StaticBody2D = node.get_node("Collision")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var image := Image.create(CHUNK_SIZE, CHUNK_SIZE, false, Image.FORMAT_RGBA8)
	var active: Dictionary = {}
	for y in CHUNK_SIZE:
		var next: Dictionary = {}
		var x := 0
		while x < CHUNK_SIZE:
			var cell := key * CHUNK_SIZE + Vector2i(x, y)
			var id := get_cell_material(cell)
			image.set_pixel(x, y, Materials.color_for(id))
			if not Materials.is_solid(id):
				x += 1
				continue
			var begin := x
			while x < CHUNK_SIZE:
				cell = key * CHUNK_SIZE + Vector2i(x, y)
				id = get_cell_material(cell)
				if not Materials.is_solid(id):
					break
				image.set_pixel(x, y, Materials.color_for(id))
				x += 1
			var run := Vector2i(begin, x - begin)
			if active.has(run):
				var rect: Rect2i = active[run]
				rect.size.y += 1
				next[run] = rect
			else:
				next[run] = Rect2i(begin, y, x - begin, 1)
		for run in active:
			if not next.has(run):
				_add_rect(body, active[run])
		active = next
	for run in active:
		_add_rect(body, active[run])
	var sprite: Sprite2D = node.get_node("Texture")
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.scale = Vector2.ONE * CELL_SIZE


func _add_rect(body: StaticBody2D, rect: Rect2i) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(rect.size * CELL_SIZE)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(rect.position * CELL_SIZE) + shape.size * 0.5
	body.add_child(collision)


func _resolve_actors() -> void:
	for actor in get_tree().get_nodes_in_group("terrain_actors"):
		if not solid_intersects(Rect2(actor.global_position - Vector2(11, 18), Vector2(22, 36))):
			continue
		for distance in range(1, 33):
			var candidate: Vector2 = actor.global_position + Vector2.UP * distance * CELL_SIZE
			if not solid_intersects(Rect2(candidate - Vector2(11, 18), Vector2(22, 36))):
				actor.global_position = candidate
				actor.velocity = Vector2.ZERO
				break


func _generate_course() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var wx := ORIGIN.x + x * CELL_SIZE
			var wy := ORIGIN.y + y * CELL_SIZE
			var surface := 340
			if wx >= -260 and wx < 0:
				surface = 340 - int((wx + 260) * 80.0 / 260.0)
			elif wx >= 0 and wx < 620:
				surface = 260
			elif wx >= 620 and wx < 770:
				surface = 520
			elif wx >= 770:
				surface = 300
			var id := Materials.SKY
			if wy >= surface:
				id = Materials.ROCK if wy >= surface + 176 else Materials.EARTH
			if (wx >= 1100 and wx < 1132 and wy >= 184 and wy < 300) or (wx >= 155 and wx < 315 and wy >= 155 and wy < 179) or (wx >= 870 and wx < 1015 and wy >= 178 and wy < 202):
				id = Materials.ROCK
			cells[y * WIDTH + x] = id
