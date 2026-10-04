extends Node2D
class_name LiquidSystem

signal liquid_material_contact(cell: Vector2i, liquid_type: int, material_id: int)

# Liquid IDs are independent of terrain material IDs. Other liquids can supply
# their own transfer and material-contact rules through this interface later.
enum LiquidType { NONE = 0, WATER = 1, LAVA = 2, OIL = 3 }

const STEP_SECONDS := 1.0 / 30.0
const MAX_ACTIVE_PER_STEP := 512
const MAX_STEPS_PER_FRAME := 2
const CELL_CAPACITY := 255
const DISPLACEMENT_SEARCH_LIMIT := 512
const WATER_COLOR := Color(0.22, 0.56, 0.57, 0.85)
const WaterShader = preload("res://assets/water.gdshader")
const Materials = preload("res://scripts/material_catalog.gd")

@onready var world: SandboxWorld = get_parent().get_node("World")
var amounts := PackedByteArray()
var liquid_types := PackedByteArray()
var active_cell_count := 0
var last_update_us := 0
var simulated_cells_last_step := 0
var displaced_units := 0
var _displaced: Array[Dictionary] = []
var _active: Array[int] = []
var _active_head := 0
var _queued: Dictionary = {}
var _dirty_chunks: Dictionary = {}
var _chunk_sprites: Dictionary = {}
var _accumulator := 0.0
var _water_material: ShaderMaterial


func _ready() -> void:
	_water_material = ShaderMaterial.new()
	_water_material.shader = WaterShader
	amounts.resize(world.WIDTH * world.HEIGHT)
	liquid_types.resize(world.WIDTH * world.HEIGHT)
	world.terrain_changed.connect(_on_terrain_changed)
	_seed_lake()
	_flush_visuals()


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < world.WIDTH and cell.y < world.HEIGHT


func get_amount(cell: Vector2i) -> int:
	return amounts[_index(cell)] if in_bounds(cell) else 0


func get_liquid_type(cell: Vector2i) -> int:
	return liquid_types[_index(cell)] if in_bounds(cell) else LiquidType.NONE


func add_water(cell: Vector2i, units: int) -> int:
	if not in_bounds(cell) or Materials.is_solid(world.get_cell_material(cell)) or units <= 0:
		return 0
	var index := _index(cell)
	if liquid_types[index] != LiquidType.NONE and liquid_types[index] != LiquidType.WATER:
		return 0
	var accepted := mini(units, CELL_CAPACITY - amounts[index])
	if accepted > 0:
		_write(cell, amounts[index] + accepted)
		_wake_around(cell)
	return accepted


func clear_all() -> void:
	amounts.fill(0)
	liquid_types.fill(LiquidType.NONE)
	_displaced.clear()
	displaced_units = 0
	_active.clear()
	_active_head = 0
	_queued.clear()
	active_cell_count = 0
	for key in _chunk_sprites:
		_dirty_chunks[key] = true
	_flush_visuals()


func total_water_units() -> int:
	var total := displaced_units
	for amount in amounts:
		total += amount
	return total


func submersion_at(world_position: Vector2) -> float:
	return float(get_amount(world.world_to_cell(world_position))) / CELL_CAPACITY


func character_submersion(center: Vector2) -> float:
	return (submersion_at(center + Vector2(0, -13)) + submersion_at(center) + submersion_at(center + Vector2(0, 13))) / 3.0


func _physics_process(delta: float) -> void:
	_accumulator += delta
	var steps := 0
	while _accumulator >= STEP_SECONDS and steps < MAX_STEPS_PER_FRAME:
		var started := Time.get_ticks_usec()
		_simulate_step()
		last_update_us = Time.get_ticks_usec() - started
		_accumulator -= STEP_SECONDS
		steps += 1
	# Simulation slows under sustained overload instead of processing unbounded catch-up.
	_accumulator = minf(_accumulator, STEP_SECONDS * MAX_STEPS_PER_FRAME)
	if not _dirty_chunks.is_empty():
		_flush_visuals()


func _simulate_step() -> void:
	simulated_cells_last_step = 0
	# Process only the queue present at the start; fresh work waits for the next step.
	var budget := mini(MAX_ACTIVE_PER_STEP, _active.size() - _active_head)
	for i in budget:
		var index := _active[_active_head]
		_active_head += 1
		_queued.erase(index)
		var cell := Vector2i(index % world.WIDTH, index / world.WIDTH)
		if amounts[index] > 0:
			_flow_cell(cell)
		simulated_cells_last_step += 1
	if _active_head >= _active.size():
		_active.clear()
		_active_head = 0
	elif _active_head > 1024:
		_active = _active.slice(_active_head)
		_active_head = 0


func _flow_cell(cell: Vector2i) -> void:
	# One full cell can fall per step; sideways movement equalizes neighboring cells.
	_transfer(cell, cell + Vector2i.DOWN, get_amount(cell))
	if get_amount(cell) <= 1:
		return
	var left := cell + Vector2i.LEFT
	var right := cell + Vector2i.RIGHT
	# Alternate first side by row and step parity to avoid a directional bias.
	if (cell.x + cell.y + Engine.get_physics_frames()) % 2 == 0:
		_spread(cell, left)
		_spread(cell, right)
	else:
		_spread(cell, right)
		_spread(cell, left)


func _spread(source: Vector2i, target: Vector2i) -> void:
	if not _can_hold_water(target):
		return
	var difference := get_amount(source) - get_amount(target)
	if difference > 1:
		_transfer(source, target, difference / 2)


func _transfer(source: Vector2i, target: Vector2i, requested: int) -> void:
	if requested <= 0 or not in_bounds(target):
		return
	var material := world.get_cell_material(target)
	if Materials.is_solid(material):
		liquid_material_contact.emit(target, LiquidType.WATER, material)
		return
	if not _can_hold_water(target):
		return
	var moved := mini(requested, CELL_CAPACITY - get_amount(target))
	if moved <= 0:
		return
	_write(source, get_amount(source) - moved)
	_write(target, get_amount(target) + moved)
	_wake_around(source)
	_wake_around(target)


func _can_hold_water(cell: Vector2i) -> bool:
	return in_bounds(cell) and not Materials.is_solid(world.get_cell_material(cell)) and get_liquid_type(cell) in [LiquidType.NONE, LiquidType.WATER]


func _write(cell: Vector2i, amount: int) -> void:
	var index := _index(cell)
	var old := amounts[index]
	if old == amount:
		return
	if old == 0 and amount > 0:
		active_cell_count += 1
	elif old > 0 and amount == 0:
		active_cell_count -= 1
	amounts[index] = amount
	liquid_types[index] = LiquidType.WATER if amount > 0 else LiquidType.NONE
	_dirty_chunks[Vector2i(cell.x / world.CHUNK_SIZE, cell.y / world.CHUNK_SIZE)] = true
	if cell.y % world.CHUNK_SIZE == world.CHUNK_SIZE - 1:
		_dirty_chunks[Vector2i(cell.x / world.CHUNK_SIZE, cell.y / world.CHUNK_SIZE + 1)] = true


func _index(cell: Vector2i) -> int:
	return cell.y * world.WIDTH + cell.x


func _wake_around(cell: Vector2i) -> void:
	for neighbor in [cell, cell + Vector2i.UP, cell + Vector2i.DOWN, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]:
		if not in_bounds(neighbor):
			continue
		var index := _index(neighbor)
		if amounts[index] > 0 and not _queued.has(index):
			_queued[index] = true
			_active.append(index)


func _on_terrain_changed(changed_cells: Array[Vector2i]) -> void:
	for cell in changed_cells:
		if Materials.is_solid(world.get_cell_material(cell)) and get_amount(cell) > 0:
			liquid_material_contact.emit(cell, LiquidType.WATER, world.get_cell_material(cell))
			var units := get_amount(cell)
			_write(cell, 0)
			displaced_units += units
			_displaced.append({"cell": cell, "units": units})
		_wake_around(cell)
	for entry in _displaced.duplicate():
		var left := _place_displaced(entry["cell"], entry["units"])
		if left == 0:
			_displaced.erase(entry)
		else:
			entry["units"] = left


func _place_displaced(origin: Vector2i, units: int) -> int:
	if _can_hold_water(origin):
		var restored := add_water(origin, units)
		units -= restored
		displaced_units -= restored
		if units == 0:
			return 0
	var frontier: Array[Vector2i] = [origin]
	var seen: Dictionary = {}
	seen[_index(origin)] = true
	var head := 0
	while head < frontier.size() and head < DISPLACEMENT_SEARCH_LIMIT and units > 0:
		var cell := frontier[head]
		head += 1
		for neighbor in [cell + Vector2i.UP, cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.DOWN]:
			if not _can_hold_water(neighbor):
				continue
			var index := _index(neighbor)
			if seen.has(index):
				continue
			seen[index] = true
			frontier.append(neighbor)
			var accepted := add_water(neighbor, units)
			units -= accepted
			displaced_units -= accepted
			if units == 0:
				break
	return units


func _seed_lake() -> void:
	# The pit between x=620 and x=770 has rock/earth banks and a diggable floor.
	for y in range(93, 113):
		for x in range(178, 197):
			var cell := Vector2i(x, y)
			if not Materials.is_solid(world.get_cell_material(cell)):
				add_water(cell, CELL_CAPACITY)


func _flush_visuals() -> void:
	for key in _dirty_chunks.keys():
		var chunk: Vector2i = key
		var sprite: Sprite2D = _chunk_sprites.get(key)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.material = _water_material
			sprite.position = Vector2(world.ORIGIN + chunk * world.CHUNK_SIZE * world.CELL_SIZE)
			sprite.scale = Vector2.ONE * world.CELL_SIZE
			add_child(sprite)
			_chunk_sprites[key] = sprite
		var image := Image.create(world.CHUNK_SIZE, world.CHUNK_SIZE, false, Image.FORMAT_RGBA8)
		for y in world.CHUNK_SIZE:
			for x in world.CHUNK_SIZE:
				var cell := chunk * world.CHUNK_SIZE + Vector2i(x, y)
				var amount := get_amount(cell)
				if amount > 0:
					var color := WATER_COLOR
					if get_amount(cell + Vector2i.UP) == 0:
						color = Color(0.55, 0.77, 0.68, 0.88)
					else:
						var depth := maxf(0.0, float(world.ORIGIN.y + cell.y * world.CELL_SIZE) - 360.0)
						color = color.darkened(minf(0.16, depth * 0.0007))
					color.a *= float(amount) / CELL_CAPACITY
					image.set_pixel(x, y, color)
		sprite.texture = ImageTexture.create_from_image(image)
	_dirty_chunks.clear()
