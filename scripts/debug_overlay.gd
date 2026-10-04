extends CanvasLayer

const Hud = preload("res://scripts/game_hud.gd")
@onready var _label: Label = $Panel/Label
@onready var _world: SandboxWorld = get_parent().get_node("World")
@onready var _liquid: LiquidSystem = get_parent().get_node("Liquid")
@onready var _session: Node2D = get_parent()
var _time_until_refresh := 0.0


func _ready() -> void:
	$Panel.hide()
	$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("203433ee")
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	$Panel.add_theme_stylebox_override("panel", panel_style)
	$Panel.offset_left = 320
	$Panel.offset_top = 24
	$Panel.offset_right = 1012
	$Panel.offset_bottom = 100
	_label.add_theme_font_size_override("font_size", 12)
	var hud := Hud.new()
	hud.name = "GameHud"
	hud.session = _session
	add_child(hud)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		$Panel.visible = not $Panel.visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh <= 0.0:
		_label.text = "FPS: %d   Bodies: %d   Chunks: %d   Dirty: %d   Rebuild: %.2f ms\nWater: %d cells / %d queued   Liquid: %.2f ms   Brush: %.0f px" % [Engine.get_frames_per_second(), _session.physics_object_count(), _world.chunks.size(), _world.dirty_chunks.size(), _world.last_rebuild_us / 1000.0, _liquid.active_cell_count, _liquid._active.size() - _liquid._active_head, _liquid.last_update_us / 1000.0, _session.brush_radius]
		_time_until_refresh = 0.2
