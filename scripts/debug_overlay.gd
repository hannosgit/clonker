extends CanvasLayer

@onready var _label: Label = $Panel/Label
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _liquid: LiquidSystem = get_parent().get_node("Liquid")
@onready var _session: Node2D = get_parent()
@onready var _construction: ConstructionSystem = get_parent().get_node("Construction")
var _time_until_refresh := 0.0


func _process(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh <= 0.0:
		var inventory_text := ""
		for i in _session.inventory.slots.size():
			var stack: Dictionary = _session.inventory.slots[i]
			var name: String = stack.get("id", "empty")
			var quantity: int = stack.get("quantity", 0)
			inventory_text += "%s%d:%s%s  " % ["[" if i == _session.inventory.selected else "", i + 1, name, (" x%d]" % quantity) if i == _session.inventory.selected else (" x%d" % quantity if quantity > 0 else "")]
		var dead: bool = _session.get_node("Character").health <= 0
		var build_text := "Build: off"
		if _construction.build_mode:
			var data: Dictionary = BuildingCatalog.get_definition(_construction.selected_id)
			build_text = "Build: %s %s   Cost: %s" % [data["name"], "VALID" if _construction._preview_reason.is_empty() else _construction._preview_reason, str(data["cost"])]
		var storage: SettlementBuilding = _construction.nearest_storage()
		var storage_text := "none nearby" if storage == null else "%s %d/%d %s" % [storage.definition["name"], storage.stored_count(), int(storage.definition["storage_capacity"]), str(storage.contents)]
		_label.text = "FPS: %d   Physics objects: %d   Chunks: %d   Dirty: %d   Rebuild: %.2f ms   Water: %d cells/%d active   Liquid: %.2f ms\nHealth: %d%s   Selected: %d   Inventory: %s\n%s   Storage: %s   Withdraw: %s   %s\nB build   1-4 building   Left place   Right/Esc cancel   G deposit stack   [/] resource   H withdraw\nA/D move   Space jump/swim   E pickup   Q drop   F throw   Right paint   Wheel brush (%.0f px)   R recover" % [Engine.get_frames_per_second(), _session.physics_object_count(), _world.chunks.size(), _world.dirty_chunks.size(), _world.last_rebuild_us / 1000.0, _liquid.active_cell_count, _liquid._active.size() - _liquid._active_head, _liquid.last_update_us / 1000.0, _session.get_node("Character").health, "   DEAD: press R" if dead else "", _session.inventory.selected + 1, inventory_text, build_text, storage_text, _construction.RESOURCE_IDS[_construction.selected_resource], _construction.status_text, _session.brush_radius]
		_time_until_refresh = 0.2
