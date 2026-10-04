extends Node2D
class_name SandboxWorld

signal terrain_changed(changed_cells: Array[Vector2i])

const CELL_SIZE := 8
const CHUNK_SIZE := 32
const TEXELS_PER_CELL := 4
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
var _visual_tiles: Dictionary = {}


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
	var changed: Array[Vector2i] = []
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
		changed.append(cell)
	if not changed.is_empty():
		terrain_changed.emit(changed)
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
	var image := Image.create(CHUNK_SIZE * TEXELS_PER_CELL, CHUNK_SIZE * TEXELS_PER_CELL, false, Image.FORMAT_RGBA8)
	var active: Dictionary = {}
	for y in CHUNK_SIZE:
		var next: Dictionary = {}
		var x := 0
		while x < CHUNK_SIZE:
			var cell := key * CHUNK_SIZE + Vector2i(x, y)
			var id := get_cell_material(cell)
			if not Materials.is_solid(id):
				x += 1
				continue
			var begin := x
			while x < CHUNK_SIZE:
				cell = key * CHUNK_SIZE + Vector2i(x, y)
				id = get_cell_material(cell)
				if not Materials.is_solid(id):
					break
				_paint_cell(image, Vector2i(x, y), cell, id)
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
	sprite.scale = Vector2.ONE * (float(CELL_SIZE) / TEXELS_PER_CELL)


func _paint_cell(image: Image, pixel_cell: Vector2i, cell: Vector2i, id: int) -> void:
	var above_open := not Materials.is_solid(get_cell_material(cell + Vector2i.UP))
	var side_open := not Materials.is_solid(get_cell_material(cell + Vector2i.LEFT)) or not Materials.is_solid(get_cell_material(cell + Vector2i.RIGHT))
	var turf := id == Materials.EARTH and above_open and (ORIGIN.y + cell.y * CELL_SIZE) <= 352
	var variant := _texture_hash(cell.x / 3, cell.y / 2) % 16
	var rock_row := posmod(cell.y, 9) if id == Materials.ROCK else 0
	var tile_key := Vector4i(id, variant, int(above_open) + int(side_open) * 2 + int(turf) * 4, rock_row)
	var tile: Image = _visual_tiles.get(tile_key)
	if tile == null:
		tile = _make_visual_tile(id, variant, rock_row, above_open, side_open, turf)
		_visual_tiles[tile_key] = tile
	image.blit_rect(tile, Rect2i(0, 0, TEXELS_PER_CELL, TEXELS_PER_CELL), pixel_cell * TEXELS_PER_CELL)


func _make_visual_tile(id: int, variant: int, rock_row: int, above_open: bool, side_open: bool, turf: bool) -> Image:
	var tile := Image.create(TEXELS_PER_CELL, TEXELS_PER_CELL, false, Image.FORMAT_RGBA8)
	var base := Materials.color_for(id)
	# Cached small tiles keep excavation responsive while retaining stable variation.
	var variation := (float(variant) / 15.0 - 0.5) * 0.1
	base = base.lightened(variation) if variation > 0 else base.darkened(-variation)
	for py in TEXELS_PER_CELL:
		for px in TEXELS_PER_CELL:
			var noise_hash := _texture_hash(variant * 4 + px, id * 4 + py) % 97
			var color := base
			if noise_hash < 2: color = base.darkened(0.12)
			elif noise_hash > 94: color = base.lightened(0.09)
			if id == Materials.ROCK and (rock_row * 4 + py) % 9 == 0:
				color = base.darkened(0.13)
			if id == Materials.EARTH and noise_hash < 3:
				color = Color("ad8c60")
			if id in [Materials.COAL, Materials.ORE, Materials.GOLD] and noise_hash > 73:
				color = Color("536767") if id == Materials.COAL else (Color("d89a6b") if id == Materials.ORE else Color("e6c575"))
			if above_open and py == 0: color = base.lightened(0.18)
			if side_open and px == 0: color = color.darkened(0.13)
			if turf and py < 2:
				color = Color("8b9e63") if py == 0 else Color("607c50")
			tile.set_pixel(px, py, color)
	return tile


func _texture_hash(x: int, y: int) -> int:
	var value := (x * 374761393 + y * 668265263) & 0x7fffffff
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return value ^ (value >> 16)


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
	# Fixed deposits make the sandbox repeatable; each cell yields one item.
	_paint_deposit(Vector2(-470, 385), 36.0, Materials.COAL)
	_paint_deposit(Vector2(-385, 425), 42.0, Materials.ORE)
	_paint_deposit(Vector2(90, 500), 38.0, Materials.GOLD)
	_paint_deposit(Vector2(470, 610), 46.0, Materials.ORE)
	_carve_cave(Vector2(-615, 440), 25.0)
	_carve_cave(Vector2(-465, 440), 25.0)
	# A dry mine below the lake floods when its roof is opened.
	_carve_cave(Vector2(700, 640), 55.0)


func _paint_deposit(center: Vector2, radius: float, material: int) -> void:
	var first := world_to_cell(center - Vector2.ONE * radius)
	var last := world_to_cell(center + Vector2.ONE * radius)
	for y in range(maxi(first.y, 0), mini(last.y, HEIGHT - 1) + 1):
		for x in range(maxi(first.x, 0), mini(last.x, WIDTH - 1) + 1):
			var cell := Vector2i(x, y)
			var middle := cell_to_world(cell) + Vector2.ONE * CELL_SIZE * 0.5
			if middle.distance_squared_to(center) <= radius * radius:
				cells[y * WIDTH + x] = material


func _carve_cave(center: Vector2, radius: float) -> void:
	var first := world_to_cell(center - Vector2.ONE * radius)
	var last := world_to_cell(center + Vector2.ONE * radius)
	for y in range(maxi(first.y, 0), mini(last.y, HEIGHT - 1) + 1):
		for x in range(maxi(first.x, 0), mini(last.x, WIDTH - 1) + 1):
			var cell := Vector2i(x, y)
			var middle := cell_to_world(cell) + Vector2.ONE * CELL_SIZE * 0.5
			if middle.distance_squared_to(center) <= radius * radius:
				cells[y * WIDTH + x] = Materials.SKY
