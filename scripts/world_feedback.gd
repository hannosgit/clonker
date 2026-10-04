extends Node2D

const Items = preload("res://scripts/item_catalog.gd")
const MAX_CHIPS := 96
var _chips: Array[Dictionary] = []
var _last_state: Array = []
@onready var _session: Node2D = get_parent()
@onready var _player: CharacterController = get_parent().get_node("Character")
@onready var _construction: ConstructionSystem = get_parent().get_node("Construction")


func emit_chips(center: Vector2, color := Color("b99a6b"), count := 8) -> void:
	for i in mini(count, MAX_CHIPS - _chips.size()):
		_chips.append({"origin": center, "velocity": Vector2(randf_range(-75, 75), randf_range(-110, -35)), "life": 0.0, "duration": randf_range(0.3, 0.55), "color": color, "size": randf_range(1.5, 3.0)})


func _process(delta: float) -> void:
	var had_chips := not _chips.is_empty()
	for i in range(_chips.size() - 1, -1, -1):
		_chips[i]["life"] += delta
		if _chips[i]["life"] >= _chips[i]["duration"]:
			_chips.remove_at(i)
	var state := [get_global_mouse_position(), _player.global_position, _player.health, hash(_session.inventory.slots), _session.inventory.selected, _construction.build_mode, _session.get_node("DebugOverlay/GameHud").guide_open]
	if had_chips or state != _last_state or _session.get_node("Items").get_child_count() > 0:
		_last_state = state
		queue_redraw()


func _draw() -> void:
	for chip in _chips:
		var time: float = chip["life"]
		var point: Vector2 = chip["origin"] + chip["velocity"] * time + Vector2(0, 150 * time * time)
		var color: Color = chip["color"]
		color.a *= 1.0 - time / chip["duration"]
		draw_rect(Rect2(to_local(point), Vector2.ONE * chip["size"]), color)
	if not is_instance_valid(_player) or _player.health <= 0 or _construction.build_mode:
		return
	if _session.get_node("DebugOverlay/GameHud").guide_open:
		return
	var stack: Dictionary = _session.inventory.selected_stack()
	if stack.is_empty():
		return
	var definition := Items.get_definition(stack["id"])
	var target := get_global_mouse_position()
	var distance := _player.global_position.distance_to(target)
	if definition.has("tool"):
		var radius: float = definition["tool"]["radius"]
		var reachable: bool = distance <= float(definition["tool"]["reach"])
		var color := Color("e6cd8b") if reachable else Color(0.73, 0.8, 0.68, 0.35)
		var local := to_local(target)
		for i in 4:
			var angle := i * PI * 0.5 + PI * 0.08
			draw_arc(local, radius, angle, angle + PI * 0.32, 8, color, 1.0, true)
		draw_circle(local, 1.5, color)
	# A small contextual key prompt makes collectible piles easier to notice.
	var closest: WorldItem
	var best := 56.0
	for child in _session.get_node("Items").get_children():
		var d: float = child.global_position.distance_to(_player.global_position)
		if d < best and _session.inventory.capacity_for(child.item_id) > 0 and not (child is TimedExplosive and child.armed):
			best = d
			closest = child
	if closest != null:
		var position := to_local(closest.global_position) + Vector2(-8, -36)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("203633")
		style.border_color = Color("d7b875")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		draw_style_box(style, Rect2(position, Vector2(16, 17)))
		draw_string(ThemeDB.fallback_font, position + Vector2(4, 12), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e7d5a0"))
