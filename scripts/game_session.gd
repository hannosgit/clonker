extends Node2D

const SPAWN_POSITION := Vector2(-620, 280)
const FALL_LIMIT := 900.0
const MAX_RESOURCE_PILES := 96
const Materials = preload("res://scripts/material_catalog.gd")
const Items = preload("res://scripts/item_catalog.gd")
const MiningAction = preload("res://scripts/tool_action.gd")
const ItemScene = preload("res://scenes/world_item.tscn")
const ExplosiveScene = preload("res://scenes/timed_explosive.tscn")
const ExplosiveScript = preload("res://scripts/timed_explosive.gd")

@onready var _character: CharacterController = $Character
@onready var _world: SandboxWorld = $World
@onready var _items: Node2D = $Items
@onready var _construction: ConstructionSystem = $Construction
var inventory: CharacterInventory:
	get:
		return _character.inventory
	set(value):
		_character.inventory = value
var brush_radius := 24.0
var _pending_yields: Dictionary = {}
var _suppress_paint_until_release := false


func _ready() -> void:
	inventory.add("shovel", 1)
	inventory.add("pickaxe", 1)
	inventory.slots[5] = {"id": "explosive", "quantity": 3}


func _physics_process(delta: float) -> void:
	_character.tool_cooldown = maxf(0.0, _character.tool_cooldown - delta)
	if not Input.is_action_pressed("terrain_paint"):
		_suppress_paint_until_release = false
	if Input.is_action_just_pressed("restart_sandbox") or _character.global_position.y > FALL_LIMIT:
		_character.revive_at(SPAWN_POSITION)
	if _character.health <= 0:
		_flush_pending_yields()
		return
	if _construction.build_mode:
		_flush_pending_yields()
		return
	if Input.is_action_pressed("terrain_dig") and _character.tool_cooldown <= 0.0:
		_use_selected_tool(get_global_mouse_position())
	if Input.is_action_pressed("terrain_paint") and not _suppress_paint_until_release:
		var material := Materials.ROCK if Input.is_key_pressed(KEY_SHIFT) else Materials.EARTH
		_world.paint_circle(get_global_mouse_position(), brush_radius, material)
	if Input.is_action_just_pressed("pickup_item"):
		pickup_nearest()
	if Input.is_action_just_pressed("drop_item"):
		drop_selected(false)
	if Input.is_action_just_pressed("throw_item"):
		drop_selected(true)
	_flush_pending_yields()


func suppress_paint_until_release() -> void:
	_suppress_paint_until_release = true


func _use_selected_tool(target: Vector2) -> Dictionary:
	var stack := inventory.selected_stack()
	if stack.is_empty():
		return {}
	var definition: Dictionary = Items.get_definition(stack["id"])
	if definition["kind"] == "explosive":
		if _character.global_position.distance_to(target) > 340.0:
			return {}
		throw_explosive(target)
		return {}
	if not definition.has("tool"):
		return {}
	var tool: Dictionary = definition["tool"]
	if _character.global_position.distance_to(target) > float(tool["reach"]):
		return {}
	_character.tool_cooldown = float(tool["cooldown"])
	var removed: Dictionary = MiningAction.execute(_world, _character.global_position, target, tool)
	if not removed.is_empty():
		$Feedback.emit_chips(target)
	for material in removed:
		var material_definition: Dictionary = Materials.get_definition(material)
		if material_definition.has("yield_item"):
			_spawn_resource(material_definition["yield_item"], int(removed[material]) * int(material_definition["yield_count"]), target)
	return removed


func _spawn_resource(id: String, quantity: int, position: Vector2) -> void:
	if quantity <= 0:
		return
	if _resource_pile_count() >= MAX_RESOURCE_PILES:
		var pile := _nearest_pile(id, position)
		if pile != null:
			pile.set_quantity(pile.quantity + quantity)
		else:
			_pending_yields[id] = int(_pending_yields.get(id, 0)) + quantity
		return
	spawn_world_item(id, quantity, position)


func spawn_world_item(id: String, quantity: int, position: Vector2, impulse := Vector2.ZERO) -> WorldItem:
	var item: WorldItem = (ExplosiveScene if id == "explosive" else ItemScene).instantiate()
	item.configure(id, quantity)
	_items.add_child(item)
	item.global_position = position
	item.apply_central_impulse(impulse)
	return item


func throw_explosive(target: Vector2) -> WorldItem:
	var stack := inventory.selected_stack()
	if stack.get("id", "") != "explosive" or _character.health <= 0:
		return null
	var direction := (target - _character.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var start := _character.global_position + direction * 27.0
	if _world.solid_intersects(Rect2(start - Vector2.ONE * 7.0, Vector2.ONE * 14.0)):
		start = _character.global_position + Vector2.UP * 28.0
	var charge: WorldItem = spawn_world_item("explosive", 1, start, direction * 170.0 + Vector2.UP * 90.0)
	charge.arm(float(Items.get_definition("explosive")["fuse"]))
	inventory.slots[inventory.selected]["quantity"] = int(stack["quantity"]) - 1
	if inventory.slots[inventory.selected]["quantity"] <= 0:
		inventory.slots[inventory.selected] = {}
	_character.tool_cooldown = 0.35
	return charge


func pickup_nearest() -> bool:
	var closest: WorldItem
	var best_distance := 56.0 * 56.0
	for child in _items.get_children():
		var item := child as WorldItem
		var distance := _character.global_position.distance_squared_to(item.global_position)
		if distance < best_distance and inventory.capacity_for(item.item_id) > 0 and not (item is ExplosiveScript and item.armed):
			closest = item
			best_distance = distance
	if closest == null:
		return false
	var transfer := mini(inventory.capacity_for(closest.item_id), closest.quantity)
	if transfer <= 0 or not inventory.add(closest.item_id, transfer):
		return false
	if transfer == closest.quantity:
		_items.remove_child(closest)
		closest.queue_free()
	else:
		closest.set_quantity(closest.quantity - transfer)
	return true


func drop_selected(throw_item: bool) -> WorldItem:
	var stack := inventory.selected_stack()
	if stack.is_empty():
		return null
	if stack["id"] == "explosive" and throw_item:
		return throw_explosive(get_global_mouse_position())
	var direction := signf(get_global_mouse_position().x - _character.global_position.x)
	if is_zero_approx(direction):
		direction = 1.0
	var position := _character.global_position + Vector2(direction * 26.0, -9.0)
	if _world.solid_intersects(Rect2(position - Vector2.ONE * 8.0, Vector2.ONE * 16.0)):
		position = _character.global_position + Vector2(0, -30)
	if Items.get_definition(stack["id"])["kind"] == "resource" and _resource_pile_count() >= MAX_RESOURCE_PILES:
		var existing := _nearest_pile(stack["id"], position)
		if existing == null:
			return null
		existing.set_quantity(existing.quantity + int(stack["quantity"]))
		inventory.take_selected()
		return existing
	var impulse := Vector2(direction * 190.0, -160.0) if throw_item else Vector2.ZERO
	var item := spawn_world_item(stack["id"], stack["quantity"], position, impulse)
	inventory.take_selected()
	return item


func _resource_pile_count() -> int:
	var count := 0
	for child in _items.get_children():
		if Items.get_definition(child.item_id)["kind"] == "resource":
			count += 1
	return count


func _nearest_pile(id: String, position: Vector2) -> WorldItem:
	var best: WorldItem
	var best_distance := INF
	for child in _items.get_children():
		var item := child as WorldItem
		if item.item_id == id:
			var distance := position.distance_squared_to(item.global_position)
			if distance < best_distance:
				best = item
				best_distance = distance
	return best


func _flush_pending_yields() -> void:
	if _pending_yields.is_empty() or _resource_pile_count() >= MAX_RESOURCE_PILES:
		return
	for id in _pending_yields.keys():
		if _resource_pile_count() >= MAX_RESOURCE_PILES:
			break
		spawn_world_item(id, int(_pending_yields[id]), _character.global_position + Vector2(0, -25))
		_pending_yields.erase(id)


func physics_object_count() -> int:
	return _items.get_child_count() + 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _construction.build_mode:
			return
		for index in range(6):
			if event.physical_keycode == KEY_1 + index:
				inventory.select_slot(index)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush_radius = minf(brush_radius + 8.0, 80.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush_radius = maxf(brush_radius - 8.0, 8.0)
