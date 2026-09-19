extends SceneTree

const Materials = preload("res://scripts/material_catalog.gd")
const Explosions = preload("res://scripts/explosion_system.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var world: SandboxWorld = sandbox.get_node("World")
	var player: CharacterController = sandbox.get_node("Character")
	var blasts: Node2D = sandbox.get_node("Explosions")
	await _frames(3)
	if not _check(is_equal_approx(Explosions.damage_at(0, 100, 80), 80) and is_equal_approx(Explosions.damage_at(50, 100, 80), 40) and Explosions.damage_at(100, 100, 80) == 0, "damage falls off linearly"):
		return
	if not _check(Explosions.blast_strength(50, 100, 8) == 4 and Explosions.blast_strength(100, 100, 8) == 0, "blast strength falls off"):
		return
	# The generated sandbox caves lie on opposite sides of the x=-544 chunk seam.
	var barrier := Vector2(-544, 440)
	if not _check(world.get_cell_material(world.world_to_cell(Vector2(-615, 440))) == Materials.SKY and world.get_cell_material(world.world_to_cell(Vector2(-465, 440))) == Materials.SKY and world.get_cell_material(world.world_to_cell(barrier)) != Materials.SKY and not _ray_clear(world, Vector2(-615, 440), Vector2(-465, 440)), "generated caves are separated by a barrier"):
		return
	player.reset_at(Vector2(-544, 310))
	var near_health := player.health
	var far_item: WorldItem = sandbox.spawn_world_item("coal", 1, Vector2(-445, 310))
	var before_velocity := far_item.linear_velocity
	var ore_before := _count_cells(world, Materials.ORE)
	var first_removed: Dictionary = blasts.explode(Vector2(-544, 385), 112, 8, 85)
	await _frames(3)
	if not _check(first_removed.size() > 0 and _ray_clear(world, Vector2(-615, 440), Vector2(-465, 440)), "blast connects cavities through seam"):
		return
	blasts.explode(Vector2(-520, 420), 112, 8, 85)
	await _frames(3)
	if not _check(_ray_clear(world, Vector2(-615, 440), Vector2(-465, 440)) and world.dirty_chunks.is_empty(), "consecutive seam blasts leave current collision"):
		return
	if not _check(player.health < near_health and player.velocity.length() > 0, "nearby player is damaged and pushed"):
		return
	if not _check(far_item.linear_velocity != before_velocity, "loose item receives impulse"):
		return
	var fragile_item: WorldItem = sandbox.spawn_world_item("coal", 1, Vector2(-200, 140))
	fragile_item.receive_damage(101, Vector2.ZERO)
	await _frames(1)
	if not _check(not is_instance_valid(fragile_item), "damageable world item can be destroyed"):
		return
	var second_removed: Dictionary = blasts.explode(Vector2(-390, 425), 112, 8, 85)
	await _frames(3)
	if not _check(int(second_removed.get(Materials.ORE, 0)) > 0 and _count_cells(world, Materials.ORE) < ore_before and _world_quantity(sandbox, "ore") == int(second_removed.get(Materials.ORE, 0)), "blast exposes ore as physical yield"):
		return
	var before_count: int = blasts.detonation_count
	sandbox.inventory.select_slot(5)
	var charge_from_inventory = sandbox.throw_explosive(Vector2(300, 120))
	if not _check(charge_from_inventory != null and charge_from_inventory.armed and sandbox.inventory.count("explosive") == 2, "throwing arms one inventory charge"):
		return
	charge_from_inventory.queue_free()
	var charge_a = sandbox.spawn_world_item("explosive", 1, Vector2(210, 120))
	var charge_b = sandbox.spawn_world_item("explosive", 1, Vector2(242, 120))
	charge_a.arm(0.05)
	charge_b.arm(20.0)
	await _frames(12)
	if not _check(blasts.detonation_count == before_count + 2 and blasts.pending.is_empty(), "fuse causes one detonation and queues nearby charge"):
		return
	await _frames(12)
	if not _check(blasts.detonation_count == before_count + 2, "charges detonate only once"):
		return
	var chain_before: int = blasts.detonation_count
	for i in 24:
		var charge = sandbox.spawn_world_item("explosive", 1, Vector2(480 + i * 2, 120))
		charge.arm(20.0)
		if i == 0:
			charge.request_detonation()
	await _frames(1)
	if not _check(blasts.last_batch_count <= blasts.MAX_DETONATIONS_PER_TICK and blasts.detonation_count - chain_before <= blasts.MAX_DETONATIONS_PER_TICK, "chain processing is bounded per tick"):
		return
	await _frames(12)
	if not _check(blasts.detonation_count == chain_before + 24 and blasts.pending.is_empty(), "large chain drains without recursion or repeats"):
		return
	player.receive_damage(1000, Vector2.ZERO)
	if not _check(player.health == 0, "damage can kill player"):
		return
	Input.action_press("restart_sandbox")
	await _frames(2)
	Input.action_release("restart_sandbox")
	if not _check(player.health == 100 and player.global_position.distance_to(sandbox.SPAWN_POSITION) < 3.0, "restart restores health and position"):
		return
	print("Explosion smoke passed: falloff, collision seam, resources, damage, impulse, fuse, chain, recovery")
	quit(0)


func _ray_clear(world: SandboxWorld, a: Vector2, b: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(a, b, 1)
	return world.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _count_cells(world: SandboxWorld, material: int) -> int:
	var count := 0
	for id in world.cells:
		if id == material:
			count += 1
	return count


func _world_quantity(sandbox: Node2D, id: String) -> int:
	var total := 0
	for item in sandbox.get_node("Items").get_children():
		if item.item_id == id and not item.is_queued_for_deletion():
			total += item.quantity
	return total


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Explosion smoke failed: " + message)
	quit(1)
	return false
