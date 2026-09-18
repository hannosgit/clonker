extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const Items = preload("res://scripts/item_catalog.gd")
const Materials = preload("res://scripts/material_catalog.gd")
const Action = preload("res://scripts/tool_action.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var bag: CharacterInventory = Inventory.new()
	if not _check(bag.add("shovel", 1) and bag.add("pickaxe", 1), "starter equipment fits"):
		return
	if not _check(bag.add("ore", 32) and bag.add("coal", 32) and bag.add("gold", 32), "resources fill stacks"):
		return
	if not _check(not bag.add("ore", 33) and bag.count("ore") == 32, "failed transfer is atomic"):
		return
	if not _check(bag.add("ore", 32) and not bag.add("ore", 1), "capacity is enforced"):
		return
	if not _check(Action.can_mine(Materials.EARTH, Items.get_definition("shovel")["tool"]) and not Action.can_mine(Materials.ORE, Items.get_definition("shovel")["tool"]), "shovel effectiveness"):
		return
	if not _check(Action.can_mine(Materials.ORE, Items.get_definition("pickaxe")["tool"]) and Action.can_mine(Materials.GOLD, Items.get_definition("pickaxe")["tool"]), "pickaxe effectiveness"):
		return
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var world: SandboxWorld = sandbox.get_node("World")
	var session = sandbox
	var player: CharacterController = sandbox.get_node("Character")
	await _frames(3)
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	if not _check(player.global_position.distance_to(Vector2(-385, 320)) < 70, "player can reach the ore from spawn"):
		return
	var ore_before := _count_cells(world, Materials.ORE)
	session.inventory.select_slot(0)
	var shovel_removed: Dictionary = session._use_selected_tool(Vector2(-385, 389))
	if not _check(shovel_removed.get(Materials.ORE, 0) == 0 and _count_cells(world, Materials.ORE) == ore_before, "shovel leaves ore intact"):
		return
	session.inventory.select_slot(1)
	var mined: Dictionary = session._use_selected_tool(Vector2(-385, 389))
	var ore_yield: int = mined.get(Materials.ORE, 0)
	if not _check(ore_yield > 0 and ore_before - _count_cells(world, Materials.ORE) == ore_yield, "ore cell removal is accounted"):
		return
	var pile: WorldItem = sandbox.get_node("Items").get_child(0)
	if not _check(pile.item_id == "ore" and pile.quantity == ore_yield and session.physics_object_count() == 2, "ore yield becomes one physical pile"):
		return
	pile.global_position = player.global_position + Vector2(20, 0)
	if not _check(session.pickup_nearest() and session.inventory.count("ore") == ore_yield and sandbox.get_node("Items").get_child_count() == 0, "pickup transfers all yield"):
		return
	var pickup_position := player.global_position
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	if not _check(player.global_position.x > pickup_position.x + 70 and session.inventory.count("ore") == ore_yield, "player transports ore in inventory"):
		return
	session.inventory.select_slot(2)
	for i in 8:
		var dropped: WorldItem = session.drop_selected(false)
		if not _check(dropped != null and session.inventory.count("ore") == 0 and dropped.quantity == ore_yield, "drop transfers stack to world"):
			return
		dropped.global_position = player.global_position + Vector2(20, 0)
		if not _check(session.pickup_nearest() and session.inventory.count("ore") == ore_yield and sandbox.get_node("Items").get_child_count() == 0, "repeated pickup preserves stack"):
			return
	var falling: WorldItem = session.spawn_world_item("coal", 1, Vector2(-620, 200))
	await _frames(180)
	if not _check(falling.global_position.y > 250 and falling.sleeping, "world item falls and sleeps on terrain"):
		return
	session.inventory = Inventory.new()
	session.inventory.add("gold", 30)
	for i in 5:
		session.inventory.add("shovel", 1)
	var extra: WorldItem = session.spawn_world_item("gold", 10, player.global_position + Vector2(16, 0))
	if not _check(session.pickup_nearest() and session.inventory.count("gold") == 32 and extra.quantity == 8, "partial pickup respects stack capacity and keeps remainder"):
		return
	while session._resource_pile_count() < session.MAX_RESOURCE_PILES:
		session._spawn_resource("coal", 1, Vector2(-620, 260))
	var coal_before := _world_quantity(sandbox, "coal")
	session._spawn_resource("coal", 7, Vector2(-620, 260))
	if not _check(session._resource_pile_count() == session.MAX_RESOURCE_PILES and _world_quantity(sandbox, "coal") == coal_before + 7, "pile cap merges same-resource yields without loss"):
		return
	session._spawn_resource("ore", 5, Vector2(-620, 260))
	if not _check(session._pending_yields.get("ore", 0) == 5, "new resource waits when pile cap is full"):
		return
	var old_pile: WorldItem = sandbox.get_node("Items").get_child(0)
	sandbox.get_node("Items").remove_child(old_pile)
	old_pile.queue_free()
	session._flush_pending_yields()
	if not _check(session._resource_pile_count() == session.MAX_RESOURCE_PILES and _world_quantity(sandbox, "ore") == 5, "waiting yield spawns when capacity opens"):
		return
	print("Mining and inventory smoke passed: capacity, effectiveness, yields, physical transfer")
	quit(0)


func _count_cells(world: SandboxWorld, material: int) -> int:
	var count := 0
	for id in world.cells:
		if id == material:
			count += 1
	return count


func _world_quantity(sandbox: Node2D, id: String) -> int:
	var total := 0
	for item in sandbox.get_node("Items").get_children():
		if item.item_id == id:
			total += item.quantity
	return total


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Mining and inventory smoke failed: " + message)
	quit(1)
	return false
