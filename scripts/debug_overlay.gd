extends CanvasLayer

@onready var _label: Label = $Panel/Label
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _liquid: LiquidSystem = get_parent().get_node("Liquid")
@onready var _session: Node2D = get_parent()
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
		_label.text = "FPS: %d   Physics objects: %d   Chunks: %d   Dirty: %d   Rebuild: %.2f ms   Water: %d cells/%d active   Liquid: %.2f ms\nHealth: %d%s   Selected: %d   Inventory: %s\nA/D move   Space jump/swim   1-6 select   Left mine/throw charge   E pickup   Q drop   F throw\nRight paint earth   Shift+Right rock   Wheel brush (%.0f px)   R recover" % [Engine.get_frames_per_second(), _session.physics_object_count(), _world.chunks.size(), _world.dirty_chunks.size(), _world.last_rebuild_us / 1000.0, _liquid.active_cell_count, _liquid._active.size() - _liquid._active_head, _liquid.last_update_us / 1000.0, _session.get_node("Character").health, "   DEAD: press R" if dead else "", _session.inventory.selected + 1, inventory_text, _session.brush_radius]
		_time_until_refresh = 0.2
