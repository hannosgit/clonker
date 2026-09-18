extends CanvasLayer

@onready var _label: Label = $Panel/Label
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _session: Node2D = get_parent()
var _time_until_refresh := 0.0


func _process(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh <= 0.0:
		_label.text = "FPS: %d   Chunks: %d   Dirty: %d   Rebuild: %.2f ms\nA/D: move   Space: jump   R: reset\nLeft: dig   Right: earth   Shift+Right: rock   Wheel: brush (%.0f px)" % [Engine.get_frames_per_second(), _world.chunks.size(), _world.dirty_chunks.size(), _world.last_rebuild_us / 1000.0, _session.brush_radius]
		_time_until_refresh = 0.2
