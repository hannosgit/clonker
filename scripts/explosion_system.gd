extends Node2D
class_name ExplosionSystem

const Materials = preload("res://scripts/material_catalog.gd")
const Items = preload("res://scripts/item_catalog.gd")
const ExplosiveScript = preload("res://scripts/timed_explosive.gd")
const MAX_DETONATIONS_PER_TICK := 8
const EFFECT_DURATION := 0.55

var pending: Array[WorldItem] = []
var detonation_count := 0
var last_batch_count := 0
var _effects: Array[Dictionary] = []
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _items: Node2D = get_parent().get_node("Items")
@onready var _player: CharacterController = get_parent().get_node("Character")


func enqueue(charge: WorldItem) -> void:
	pending.append(charge)


func _physics_process(_delta: float) -> void:
	last_batch_count = 0
	while not pending.is_empty() and last_batch_count < MAX_DETONATIONS_PER_TICK:
		var charge: WorldItem = pending.pop_front()
		if not is_instance_valid(charge) or charge.is_queued_for_deletion():
			continue
		var definition: Dictionary = Items.get_definition(charge.item_id)
		explode(charge.global_position, float(definition["blast_radius"]), float(definition["blast_power"]), float(definition["damage"]), charge)
		charge.queue_free()
		detonation_count += 1
		last_batch_count += 1


func explode(center: Vector2, radius: float, power: float, max_damage: float, source: Node = null) -> Dictionary:
	var edits: Array = []
	var resistance: Dictionary = {}
	var first := _world.world_to_cell(center - Vector2.ONE * radius)
	var last := _world.world_to_cell(center + Vector2.ONE * radius)
	for y in range(maxi(0, first.y), mini(_world.HEIGHT - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(_world.WIDTH - 1, last.x) + 1):
			var cell := Vector2i(x, y)
			var material := _world.get_cell_material(cell)
			if not Materials.is_solid(material):
				continue
			var middle := _world.cell_to_world(cell) + Vector2.ONE * _world.CELL_SIZE * 0.5
			if not resistance.has(material):
				resistance[material] = float(Materials.get_definition(material)["blast_resistance"])
			if blast_strength(middle.distance_to(center), radius, power) >= resistance[material]:
				edits.append({"cell": cell, "material": Materials.SKY})
	var removed := _world.apply_edits(edits)
	for body in [_player] + _items.get_children():
		if body == source or body.is_queued_for_deletion():
			continue
		var distance: float = body.global_position.distance_to(center)
		var damage := damage_at(distance, radius, max_damage)
		if damage <= 0.0:
			continue
		var direction: Vector2 = (body.global_position - center).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.UP
		var impulse: Vector2 = direction * (1.0 - distance / radius) * (440.0 if body == _player else 180.0)
		if body == _player:
			_player.receive_damage(damage, impulse)
		elif body is ExplosiveScript:
			body.receive_damage(damage, impulse)
		else:
			body.receive_damage(damage, impulse)
	for material in removed:
		var material_definition: Dictionary = Materials.get_definition(material)
		if material_definition.has("yield_item"):
			get_parent()._spawn_resource(material_definition["yield_item"], int(removed[material]) * int(material_definition["yield_count"]), center)
	_effects.append({"center": center, "time": EFFECT_DURATION, "radius": radius})
	get_parent().get_node("Feedback").emit_chips(center, Color("d7b581"), 24)
	queue_redraw()
	var camera_distance := _player.global_position.distance_to(center)
	if camera_distance < radius * 3.0:
		_player.shake_camera(4.0 * (1.0 - camera_distance / (radius * 3.0)))
	return removed


static func blast_strength(distance: float, radius: float, power: float) -> float:
	return maxf(0.0, power * (1.0 - distance / radius)) if radius > 0.0 else 0.0


static func damage_at(distance: float, radius: float, maximum: float) -> float:
	return maxf(0.0, maximum * (1.0 - distance / radius)) if radius > 0.0 else 0.0


func _process(delta: float) -> void:
	if not _effects.is_empty():
		queue_redraw()
	for index in range(_effects.size() - 1, -1, -1):
		_effects[index]["time"] -= delta
		if _effects[index]["time"] <= 0.0:
			_effects.remove_at(index)


func _draw() -> void:
	for effect in _effects:
		var fraction: float = 1.0 - effect["time"] / EFFECT_DURATION
		var center: Vector2 = to_local(effect["center"])
		var radius: float = effect["radius"]
		for i in 7:
			var angle := i * TAU / 7.0
			var puff := center + Vector2.from_angle(angle) * radius * fraction * 0.48
			draw_circle(puff, radius * (0.12 + fraction * 0.16), Color(0.74, 0.66, 0.46, 0.12 * (1.0 - fraction)))
		draw_circle(center, radius * fraction * 0.5, Color(1.0, 0.7, 0.32, 0.3 * (1.0 - fraction)))
		draw_circle(center, radius * 0.2 * (1.0 - fraction), Color(1.0, 0.93, 0.68, 0.65 * (1.0 - fraction)))
		draw_arc(center, radius * sqrt(fraction), 0.0, TAU, 48, Color(0.94, 0.88, 0.64, 0.6 * (1.0 - fraction)), 2.0, true)
