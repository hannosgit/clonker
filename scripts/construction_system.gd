extends Node2D
class_name ConstructionSystem

const Catalog = preload("res://scripts/building_catalog.gd")
const Building = preload("res://scripts/building.gd")
const Items = preload("res://scripts/item_catalog.gd")
const Materials = preload("res://scripts/material_catalog.gd")
const BUILD_REACH := 320.0
const STORAGE_ACCESS := 256.0
const RESOURCE_IDS := ["stone", "wood", "metal", "coal", "ore", "gold"]

@onready var _session: Node2D = get_parent()
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _player: CharacterController = get_parent().get_node("Character")
var build_mode := false
var selected_id := "base"
var selected_resource := 0
var status_text := ""
var _preview_position := Vector2.ZERO
var _preview_reason := ""
var _support_check_queued := false


func _ready() -> void:
	_world.terrain_changed.connect(_on_terrain_changed)
	# The sample settlement begins with a supplied base. Metal in this base
	# makes the first furnace possible before refining exists.
	var base := _make_building("base", Vector2(-736, 344))
	base.deposit("wood", 24)
	base.deposit("stone", 24)
	base.deposit("metal", 5)


func _process(_delta: float) -> void:
	if build_mode:
		_preview_position = snap_position(get_global_mouse_position())
		_preview_reason = placement_reason(selected_id, _preview_position)
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			build_mode = not build_mode
			status_text = "Build mode" if build_mode else "Build mode closed"
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif build_mode and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			selected_id = Catalog.ids()[event.physical_keycode - KEY_1]
			get_viewport().set_input_as_handled()
		elif build_mode and event.physical_keycode == KEY_ESCAPE:
			build_mode = false
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_G:
			deposit_selected()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_H:
			withdraw_selected()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_BRACKETLEFT:
			selected_resource = posmod(selected_resource - 1, RESOURCE_IDS.size())
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_BRACKETRIGHT:
			selected_resource = (selected_resource + 1) % RESOURCE_IDS.size()
			get_viewport().set_input_as_handled()
	if build_mode and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place(selected_id, snap_position(get_global_mouse_position()))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			build_mode = false
			_session.suppress_paint_until_release()
			queue_redraw()
			get_viewport().set_input_as_handled()


func snap_position(position: Vector2) -> Vector2:
	return Vector2(roundf(position.x / 8.0) * 8.0, roundf(position.y / 8.0) * 8.0)


func placement_reason(id: String, position: Vector2) -> String:
	var definition := Catalog.get_definition(id)
	var size := Vector2(float(definition["size"][0]), float(definition["size"][1]))
	var rect := Rect2(position - Vector2(size.x * 0.5, size.y), size)
	if _player.health <= 0 or _player.global_position.distance_to(position) > BUILD_REACH:
		return "Out of reach"
	var map_rect := Rect2(Vector2(_world.ORIGIN), Vector2(_world.WIDTH, _world.HEIGHT) * _world.CELL_SIZE)
	if not map_rect.encloses(rect.grow(8.0)):
		return "Outside construction area"
	if _world.solid_intersects(rect.grow(-1.0)):
		return "Terrain blocks footprint"
	if rect.intersects(Rect2(_player.global_position - Vector2(11, 18), Vector2(22, 36))):
		return "Character blocks footprint"
	for child in get_children():
		if child is SettlementBuilding and not child.is_queued_for_deletion() and rect.intersects(child.footprint().grow(2.0)):
			return "Overlaps a building"
	if not _has_support(rect, float(definition["support_fraction"])):
		return "Needs solid ground"
	for resource_id in definition["cost"]:
		if available_resource(resource_id, position) < int(definition["cost"][resource_id]):
			return "Need %d %s" % [int(definition["cost"][resource_id]), resource_id]
	return ""


func _has_support(rect: Rect2, fraction: float) -> bool:
	var supported := 0
	var count := 0
	for x in range(floori(rect.position.x / 8.0), ceili(rect.end.x / 8.0)):
		var probe := Vector2(x * 8.0 + 4.0, rect.end.y + 4.0)
		if probe.x < rect.position.x or probe.x >= rect.end.x:
			continue
		count += 1
		if Materials.is_solid(_world.get_cell_material(_world.world_to_cell(probe))):
			supported += 1
	return count > 0 and float(supported) / count >= fraction


func available_resource(id: String, position: Vector2) -> int:
	var total: int = _session.inventory.count(id)
	for building in get_children():
		if building is SettlementBuilding and not building.is_queued_for_deletion() and building.global_position.distance_to(position) <= STORAGE_ACCESS:
			total += int(building.contents.get(id, 0))
	return total


func place(id: String, position: Vector2) -> SettlementBuilding:
	var reason := placement_reason(id, position)
	if not reason.is_empty():
		status_text = reason
		return null
	var definition := Catalog.get_definition(id)
	# Validation and deductions are synchronous in one main-thread operation.
	for resource_id in definition["cost"]:
		var remaining: int = int(definition["cost"][resource_id])
		var from_bag: int = mini(remaining, _session.inventory.count(resource_id))
		if from_bag > 0:
			_session.inventory.remove(resource_id, from_bag)
			remaining -= from_bag
		for building in get_children():
			if remaining == 0:
				break
			if building is SettlementBuilding and not building.is_queued_for_deletion() and building.global_position.distance_to(position) <= STORAGE_ACCESS:
				var amount: int = mini(remaining, int(building.contents.get(resource_id, 0)))
				if amount > 0:
					building.withdraw(resource_id, amount)
					remaining -= amount
	var result := _make_building(id, position)
	status_text = "%s complete" % definition["name"]
	return result


func _make_building(id: String, position: Vector2) -> SettlementBuilding:
	var building: SettlementBuilding = Building.new()
	building.configure(id, Catalog.get_definition(id))
	add_child(building)
	building.global_position = position
	return building


func nearest_storage() -> SettlementBuilding:
	var best: SettlementBuilding
	var distance := INF
	for child in get_children():
		if child is SettlementBuilding and not child.is_queued_for_deletion():
			var d: float = _player.global_position.distance_to(child.interaction_point())
			if d <= float(child.definition["interaction_radius"]) and d < distance:
				best = child
				distance = d
	return best


func deposit_selected() -> bool:
	var building := nearest_storage()
	var stack: Dictionary = _session.inventory.selected_stack()
	if building == null or stack.is_empty() or Items.get_definition(stack["id"])["kind"] != "resource":
		status_text = "Select a resource near a building"
		return false
	if not building.deposit(stack["id"], int(stack["quantity"])):
		status_text = "Storage full"
		return false
	_session.inventory.take_selected()
	status_text = "Stored %d %s" % [int(stack["quantity"]), stack["id"]]
	return true


func withdraw_selected() -> WorldItem:
	var building := nearest_storage()
	var id: String = RESOURCE_IDS[selected_resource]
	if building == null or int(building.contents.get(id, 0)) == 0:
		status_text = "No %s in nearby storage" % id
		return null
	var size: Vector2 = building.footprint().size
	var position: Vector2 = building.global_position + Vector2(size.x * 0.5 + 15.0, -12.0)
	if _world.solid_intersects(Rect2(position - Vector2(7, 7), Vector2(14, 14))):
		position = building.global_position + Vector2(0, -size.y - 12.0)
	if _world.solid_intersects(Rect2(position - Vector2(7, 7), Vector2(14, 14))):
		status_text = "Output blocked"
		return null
	var amount: int = mini(int(building.contents[id]), Items.max_stack(id))
	var item: WorldItem = _session.spawn_world_item(id, amount, position)
	building.withdraw(id, amount)
	status_text = "Withdrew %d %s" % [amount, id]
	return item


func _on_terrain_changed(changed_cells: Array[Vector2i]) -> void:
	if _support_check_queued:
		return
	for cell in changed_cells:
		var point := _world.cell_to_world(cell)
		for child in get_children():
			if child is SettlementBuilding and child.footprint().grow(8.0).has_point(point):
				_support_check_queued = true
				call_deferred("_recheck_support")
				return


func _recheck_support() -> void:
	_support_check_queued = false
	for child in get_children():
		if child is SettlementBuilding and not child.is_queued_for_deletion() and not _has_support(child.footprint(), float(child.definition["support_fraction"])):
			for id in child.contents.keys():
				var remaining: int = int(child.contents[id])
				while remaining > 0:
					var amount: int = mini(remaining, Items.max_stack(id))
					_session.spawn_world_item(id, amount, child.global_position + Vector2(0, -child.footprint().size.y - 12.0))
					remaining -= amount
			status_text = "%s collapsed; stored items spilled" % child.definition["name"]
			child.queue_free()


func _draw() -> void:
	if not build_mode:
		return
	var data := Catalog.get_definition(selected_id)
	var size := Vector2(float(data["size"][0]), float(data["size"][1]))
	var rect := Rect2(_preview_position - Vector2(size.x * 0.5, size.y), size)
	var color := Color(0.3, 0.9, 0.5, 0.45) if _preview_reason.is_empty() else Color(1.0, 0.25, 0.2, 0.5)
	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.2), false, 2.0)
