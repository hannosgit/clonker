extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var construction: ConstructionSystem = sandbox.get_node("Construction")
	var world: SandboxWorld = sandbox.get_node("World")
	var player: CharacterController = sandbox.get_node("Character")
	var base: SettlementBuilding = construction.get_child(0)
	if not _check(base.building_id == "base" and base.contents == {"wood":24,"stone":24,"metal":5} and construction._has_support(base.footprint(), 0.75), "supplied base stands on terrain and bootstraps furnace"):
		return
	var initial_contents := base.contents.duplicate()
	var initial_bag: Array = sandbox.inventory.slots.duplicate(true)
	for check in [
		["furnace", Vector2(-560, 288), "Needs solid ground"],
		["furnace", Vector2(-560, 400), "Terrain blocks footprint"],
		["furnace", Vector2(-736, 344), "Overlaps a building"],
		["furnace", Vector2(-620, 344), "Character blocks footprint"],
		["furnace", Vector2(-792, 344), "Outside construction area"]
	]:
		var reason: String = construction.placement_reason(check[0], check[1])
		if not _check(reason == check[2], "placement reason: %s (got %s)" % [check[2], reason]):
			return
		if not _check(construction.place(check[0], check[1]) == null and base.contents == initial_contents and sandbox.inventory.slots == initial_bag, "invalid placement changes nothing"):
			return
	base.withdraw("metal", 5)
	var missing_reason := construction.placement_reason("furnace", Vector2(-560, 344))
	if not _check(missing_reason == "Need 5 metal" and construction.place("furnace", Vector2(-560, 344)) == null and base.contents.get("stone", 0) == 24, "missing metal consumes no stone (got %s)" % missing_reason):
		return
	base.deposit("metal", 5)
	player.global_position = Vector2(-620, 220)
	var workshop := construction.place("workshop", Vector2(-648, 344))
	var furnace := construction.place("furnace", Vector2(-560, 344))
	var storage := construction.place("storage", Vector2(-480, 344))
	if not _check(workshop != null and furnace != null and storage != null and construction.get_child_count() == 4, "four building types stand on terrain"):
		return
	if not _check(workshop.construction_state == "complete" and furnace.construction_state == "complete" and storage.construction_state == "complete", "construction state is separate from validation"):
		return
	if not _check(base.contents == {"wood":8,"stone":5} and sandbox.inventory.slots == initial_bag, "costs charged once from settlement storage"):
		return
	player.global_position = Vector2(-648, 276)
	sandbox.spawn_world_item("coal", 6, player.global_position + Vector2(10, 0))
	if not _check(sandbox.pickup_nearest() and sandbox.inventory.count("coal") == 6, "physical resource can be collected for supply"):
		return
	sandbox.inventory.select_slot(2)
	if not _check(not workshop.deposit("coal", 49) and workshop.stored_count() == 0, "over-capacity deposit is atomic"):
		return
	if not _check(construction.nearest_storage() == workshop and construction.deposit_selected() and workshop.contents.get("coal", 0) == 6 and sandbox.inventory.count("coal") == 0, "inventory deposit is accounted"):
		return
	if not _check(not workshop.deposit("coal", 43) and workshop.stored_count() == 6, "failed deposit preserves contents"):
		return
	construction.selected_resource = construction.RESOURCE_IDS.find("coal")
	var withdrawn: WorldItem = construction.withdraw_selected()
	if not _check(withdrawn != null and withdrawn.item_id == "coal" and withdrawn.quantity == 6 and workshop.stored_count() == 0, "withdrawal recreates physical item"):
		return
	player.global_position = Vector2(-600, 318)
	withdrawn.global_position = player.global_position + Vector2(16, 0)
	if not _check(sandbox.pickup_nearest() and sandbox.inventory.count("coal") == 6, "withdrawn item can be collected"):
		return
	# Deposit again so collapse must release serialized contents.
	player.global_position = Vector2(-648, 276)
	if not _check(construction.deposit_selected() and workshop.stored_count() == 6, "building can be resupplied"):
		return
	player.global_position = Vector2(-620, 220)
	world.remove_circle(Vector2(-648, 344), 39.0)
	await _frames(3)
	if not _check(not is_instance_valid(workshop) and construction.get_child_count() == 3, "undermined workshop collapses"):
		return
	var spilled := 0
	for item in sandbox.get_node("Items").get_children():
		if item.item_id == "coal":
			spilled += item.quantity
	if not _check(spilled == 6 and is_instance_valid(furnace) and is_instance_valid(storage), "contents spill physically without collapsing neighbors"):
		return
	sandbox.inventory.add("wood", 8)
	sandbox.inventory.add("stone", 8)
	var second_base := construction.place("base", Vector2(-400, 344))
	if not _check(second_base != null and sandbox.inventory.count("wood") == 0 and sandbox.inventory.count("stone") == 0 and base.contents == {"wood":8,"stone":5}, "base can be placed with carried materials before stored stock is used"):
		return
	construction.build_mode = true
	Input.action_press("terrain_paint")
	var cancel := InputEventMouseButton.new()
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	construction._unhandled_input(cancel)
	if not _check(not construction.build_mode and sandbox._suppress_paint_until_release, "right click cancels preview without painting terrain"):
		return
	Input.action_release("terrain_paint")
	print("Construction smoke passed: validation, bootstrap, four buildings, storage transfers, support collapse")
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Construction smoke failed: " + message)
	quit(1)
	return false
