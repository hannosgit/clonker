extends Control
## A compact HUD with contextual storage, construction and an optional field guide.

const Art = preload("res://scripts/item_art.gd")
const Items = preload("res://scripts/item_catalog.gd")
const Buildings = preload("res://scripts/building_catalog.gd")
const INK := Color("e7e5ce")
const MUTED := Color("94aca0")
const GOLD := Color("e1bd77")
const PANEL := Color("203633ed")
const BORDER := Color("567063")
var session: Node2D
var guide_open := false
var _font: Font
var _health_display := 100.0
var _last_status := ""
var _status_time := 0.0
var _last_state: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	var player: CharacterController = session.get_node("Character")
	_health_display = move_toward(_health_display, player.health, 100.0 * delta)
	var construction: ConstructionSystem = session.get_node("Construction")
	if construction.status_text != _last_status:
		_last_status = construction.status_text
		_status_time = 3.5
	_status_time = maxf(0.0, _status_time - delta)
	var storage := construction.nearest_storage()
	var state := [hash(session.inventory.slots), session.inventory.selected, _health_display, player.health, player.submersion >= 0.5, construction.build_mode, construction.selected_id, construction._preview_reason, construction.selected_resource, _last_status, _status_time > 0, guide_open, get_viewport_rect().size, storage.get_instance_id() if storage != null else 0, hash(storage.contents) if storage != null else 0]
	if state != _last_state:
		_last_state = state
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			guide_open = not guide_open
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and guide_open:
			guide_open = false
			get_viewport().set_input_as_handled()


func _draw() -> void:
	if _font == null or session == null:
		return
	var viewport := get_viewport_rect().size
	var player: CharacterController = session.get_node("Character")
	var construction: ConstructionSystem = session.get_node("Construction")
	_card(Rect2(24, 24, 276, 76), PANEL, BORDER)
	draw_colored_polygon(PackedVector2Array([Vector2(54, 39), Vector2(74, 60), Vector2(54, 82), Vector2(34, 60)]), Color("39594a"))
	Art.draw_icon(self, "pickaxe", Vector2(54, 61), 0.8)
	_text(Vector2(88, 59), "CLONKER", 25, INK)
	_text(Vector2(89, 80), "S E T T L E M E N T   S A N D B O X", 9, MUTED)
	_text(Vector2(27, 125), "01  /  WOODLAND OUTPOST", 11, Color("304b43"))
	var hp := Rect2(viewport.x - 244, 24, 220, 76)
	_card(hp, PANEL, BORDER)
	_text(hp.position + Vector2(16, 24), "VITALITY", 10, MUTED)
	_text(hp.position + Vector2(148, 25), "%d / %d" % [player.health, player.max_health], 12, INK)
	_card(Rect2(hp.position + Vector2(16, 39), Vector2(188, 7)), Color("152a27"), Color.TRANSPARENT, 3)
	if _health_display > 0:
		_card(Rect2(hp.position + Vector2(16, 39), Vector2(188 * _health_display / player.max_health, 7)), GOLD if player.health > 30 else Color("d37a60"), Color.TRANSPARENT, 3)
	_text(hp.position + Vector2(16, 63), "Swimming" if player.submersion >= 0.5 else ("Recover with R" if player.health <= 0 else "Ready to explore"), 10, MUTED)
	_storage(construction)
	_hotbar(construction, viewport)
	_text(Vector2(26, viewport.y - 20), "A / D  Move     SPACE  Jump     E  Gather", 11, INK)
	var right_hint := "F1  Field guide    F3  Diagnostics"
	_text(Vector2(viewport.x - _font.get_string_size(right_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x - 26, viewport.y - 20), right_hint, 11, INK)
	if _status_time > 0 and not _last_status.is_empty() and not construction.build_mode:
		var width := _font.get_string_size(_last_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 36
		_card(Rect2((viewport.x - width) * 0.5, 116, width, 38), PANEL, BORDER)
		_text(Vector2((viewport.x - width) * 0.5 + 18, 140), _last_status, 13, INK)
	if player.health <= 0:
		_card(Rect2(viewport.x * 0.5 - 180, viewport.y * 0.42 - 36, 360, 88), PANEL, Color("d37a60"))
		_center_text(Vector2(viewport.x * 0.5, viewport.y * 0.42), "A moment to catch your breath", 19, INK)
		_center_text(Vector2(viewport.x * 0.5, viewport.y * 0.42 + 26), "Press R to return to the outpost", 12, GOLD)
	if guide_open:
		_guide(viewport)


func _hotbar(construction: ConstructionSystem, viewport: Vector2) -> void:
	var inventory: CharacterInventory = session.inventory
	var start := Vector2((viewport.x - 496) * 0.5, viewport.y - 125)
	_center_text(Vector2(viewport.x * 0.5, start.y - 12), "CONSTRUCTION" if construction.build_mode else "E Q U I P M E N T", 10, Color("d4d8bd"))
	for i in 6:
		var rect := Rect2(start + Vector2(i * 84, 0), Vector2(76, 82))
		var stack: Dictionary = inventory.slots[i]
		var id: String = stack.get("id", "")
		var selected := i == inventory.selected
		var title := ""
		if construction.build_mode:
			id = Buildings.ids()[i] if i < 4 else ""
			selected = id == construction.selected_id
			if i < 4: title = Buildings.get_definition(id)["name"]
		_card(rect, Color("364d3d") if selected else PANEL, GOLD if selected else BORDER, 8)
		if selected:
			draw_line(rect.position + Vector2(14, 1), rect.position + Vector2(62, 1), GOLD, 2.0, true)
		_text(rect.position + Vector2(9, 17), str(i + 1), 10, GOLD if selected else MUTED)
		if not id.is_empty():
			if construction.build_mode:
				_building_icon(id, rect.position + Vector2(38, 38))
			else:
				Art.draw_icon(self, id, rect.position + Vector2(38, 39), 0.95)
				title = "Charge" if id == "explosive" else Items.get_definition(id)["name"]
				var quantity: int = stack.get("quantity", 0)
				if quantity > 1: _text(rect.position + Vector2(57, 17), str(quantity), 11, INK)
			_center_text(rect.position + Vector2(38, 71), title, 10, INK if selected else MUTED)
		else:
			draw_circle(rect.position + Vector2(38, 39), 2.0, Color("5c7465"))
	var held := inventory.selected_stack()
	var left := Rect2(24, start.y + 4, 222, 72)
	_card(left, PANEL, BORDER)
	_text(left.position + Vector2(14, 21), "BUILD SITE" if construction.build_mode else "IN YOUR HAND", 9, MUTED)
	if construction.build_mode:
		var data := Buildings.get_definition(construction.selected_id)
		_text(left.position + Vector2(14, 41), data["name"], 16, GOLD)
		var costs := ""
		for id: String in data["cost"]: costs += "%d %s  " % [data["cost"][id], id]
		_text(left.position + Vector2(14, 60), costs, 10, INK)
	else:
		_text(left.position + Vector2(14, 42), "Empty hands" if held.is_empty() else Items.get_definition(held["id"])["name"], 16, GOLD)
		_text(left.position + Vector2(14, 60), "1–6  Select a slot" if held.is_empty() else ("LMB  Throw charge   F  Throw" if held["id"] == "explosive" else ("Hold LMB to mine" if Items.get_definition(held["id"])["kind"] == "tool" else "G  Store    Q  Drop    F  Throw")), 10, INK)
	var build_card := Rect2(viewport.x - 230, start.y + 4, 206, 72)
	_card(build_card, PANEL, GOLD if construction.build_mode else BORDER)
	_key(build_card.position + Vector2(14, 17), "B")
	_text(build_card.position + Vector2(49, 36), "Building" if construction.build_mode else "Build an outpost", 14, GOLD)
	_text(build_card.position + Vector2(14, 59), "LMB  Place    ESC  Cancel" if construction.build_mode else "Open construction menu", 10, MUTED)
	if construction.build_mode:
		var reason := construction._preview_reason
		_center_text(Vector2(viewport.x * 0.5, start.y - 36), "Click to place on solid ground" if reason.is_empty() else reason, 13, Color("b9d7a1") if reason.is_empty() else Color("f0b091"))


func _storage(construction: ConstructionSystem) -> void:
	var storage := construction.nearest_storage()
	if storage == null:
		return
	var panel := Rect2(24, 150, 250, 158)
	_card(panel, PANEL, BORDER)
	_text(panel.position + Vector2(14, 23), storage.definition["name"].to_upper() + "  /  STORAGE", 11, GOLD)
	_text(panel.position + Vector2(14, 44), "%d / %d supplies" % [storage.stored_count(), storage.definition["storage_capacity"]], 11, MUTED)
	for i in construction.RESOURCE_IDS.size():
		var id: String = construction.RESOURCE_IDS[i]
		var origin := panel.position + Vector2(14 + (i % 3) * 76, 68 + (i / 3) * 21)
		var amount: int = storage.contents.get(id, 0)
		_text(origin, "%s %d" % [id.capitalize(), amount], 10, INK if amount > 0 else MUTED)
	draw_line(panel.position + Vector2(14, 103), panel.position + Vector2(236, 103), BORDER, 1)
	_text(panel.position + Vector2(14, 123), "G  Deposit held resources", 11, INK)
	_text(panel.position + Vector2(14, 144), "[ / ]  %s    H  Withdraw" % construction.RESOURCE_IDS[construction.selected_resource].capitalize(), 11, GOLD)


func _guide(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.06, 0.13, 0.12, 0.66))
	var pos := Vector2((viewport.x - 600) * 0.5, (viewport.y - 420) * 0.5)
	_card(Rect2(pos, Vector2(600, 420)), Color("203633"), BORDER, 12)
	_text(pos + Vector2(30, 43), "FIELD GUIDE", 24, INK)
	_text(pos + Vector2(30, 68), "A little digging. A little building. A place of your own.", 13, MUTED)
	draw_line(pos + Vector2(30, 86), pos + Vector2(570, 86), BORDER)
	var entries := [
		["EXPLORE", "A / D or arrows   Move", "Space / W / Up   Jump or swim", "R   Recover at the outpost"],
		["GATHER", "1–6   Select equipment", "Hold left mouse   Mine nearby", "E   Pick up    Q   Drop    F   Throw"],
		["SETTLE", "B   Open construction    1–4   Choose", "Left mouse   Place    Esc / Right   Cancel", "G   Deposit    [ / ]   Resource    H   Withdraw"],
		["EXPERIMENT", "Right mouse   Paint earth", "Shift + Right   Paint rock    Wheel   Brush", "F3   Show performance diagnostics"]
	]
	for i in 4:
		var origin := pos + Vector2(30 + (i % 2) * 282, 118 + (i / 2) * 122)
		_text(origin, entries[i][0], 10, GOLD)
		for row in 3:
			_text(origin + Vector2(0, 26 + row * 23), entries[i][row + 1], 11, INK)
	draw_line(pos + Vector2(30, 362), pos + Vector2(570, 362), BORDER)
	_text(pos + Vector2(30, 390), "The supplied base holds wood, stone and metal to get you started.", 11, MUTED)
	_text(pos + Vector2(473, 43), "F1  Close", 11, GOLD)


func _building_icon(id: String, center: Vector2) -> void:
	var tint := Color("b58961")
	if id == "base": tint = Color("759788")
	if id == "furnace": tint = Color("9d7770")
	draw_rect(Rect2(center + Vector2(-15, -5), Vector2(30, 22)), tint)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-19, -5), center + Vector2(0, -20), center + Vector2(19, -5)]), GOLD)
	draw_rect(Rect2(center + Vector2(-4, 4), Vector2(8, 13)), Color("243b3b"))
	if id == "furnace": draw_rect(Rect2(center + Vector2(7, -22), Vector2(6, 17)), tint)
	if id == "storage": draw_line(center + Vector2(-12, -2), center + Vector2(12, 14), INK, 2)


func _card(rect: Rect2, color: Color, border: Color, radius := 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.04, 0.1, 0.08, 0.15)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	draw_style_box(style, rect)


func _text(position: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center_text(position: Vector2, value: String, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(position - Vector2(width * 0.5, 0), value, font_size, color)


func _key(position: Vector2, value: String) -> void:
	_card(Rect2(position, Vector2(25, 25)), Color("3c5143"), BORDER, 4)
	_center_text(position + Vector2(12.5, 17), value, 12, GOLD)
