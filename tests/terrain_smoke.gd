extends SceneTree

var world: SandboxWorld
var player: CharacterController


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	world = sandbox.get_node("World")
	player = sandbox.get_node("Character")
	await _frames(3)
	if not _check(world.chunks.size() == 45, "all map chunks built"):
		return
	if not _check(sandbox.get_node("DebugOverlay/Panel/Label").text.contains("Chunks: 45"), "terrain metrics appear in overlay"):
		return
	var catalog = load("res://scripts/material_catalog.gd")
	if not _check(catalog.get_definition(1)["dig_resistance"] == 1.0 and catalog.get_definition(2)["density"] == 2.7, "material definitions load"):
		return
	var seam := Vector2(-544, 390)
	var before := world.rebuild_count
	var removed: Dictionary = {}
	for x in range(-624, -463, 24):
		var result: Dictionary = world.remove_circle(Vector2(x, 390), 32)
		for id in result:
			removed[id] = removed.get(id, 0) + result[id]
	if not _check(removed.get(1, 0) > 0 and world.rebuild_count == before, "batched edits return earth and wait for rebuild"):
		return
	await _frames(3)
	if not _check(world.rebuild_count > before and world.dirty_chunks.is_empty(), "dirty chunks rebuilt"):
		return
	if not _check(world.get_cell_material(world.world_to_cell(seam)) == 0, "seam cells removed"):
		return
	if not _check(_ray_clear(Vector2(-620, 390), Vector2(-465, 390)), "tunnel has no collision barrier across seam"):
		return
	var paint := world.paint_circle(seam, 16, 2)
	await _frames(3)
	if not _check(paint.is_empty() and not _ray_clear(Vector2(-560, 390), Vector2(-528, 390)), "paint adds solid rock collision"):
		return
	world.remove_circle(seam, 20)
	await _frames(3)
	if not _check(_ray_clear(Vector2(-560, 390), Vector2(-528, 390)), "repeated edit clears collision"):
		return
	player.reset_at(Vector2(-600, 390))
	await _frames(5)
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	if not _check(player.global_position.x > -530, "character traverses tunnel seam"):
		return
	for x in range(380, 573, 16):
		world.remove_circle(Vector2(x, 500), 24)
	await _frames(3)
	player.reset_at(Vector2(400, 500))
	await _frames(5)
	Input.action_press("move_right")
	await _frames(38)
	Input.action_release("move_right")
	if not _check(player.global_position.x > 530 and player.global_position.y < 520, "character traverses narrow rock passage"):
		return
	var occupied := world.world_to_cell(player.global_position)
	world.apply_edits([{"cell": occupied, "material": 2}])
	await _frames(3)
	if not _check(world.get_cell_material(occupied) == 0, "painting does not embed the player"):
		return
	if not _check(InputMap.has_action("terrain_dig") and InputMap.has_action("terrain_paint"), "brush bindings exist"):
		return
	print("Terrain smoke passed: data, batching, seam, removal, paint, collision, traversal, actor safety")
	quit(0)


func _ray_clear(a: Vector2, b: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(a, b, 1)
	return world.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Terrain smoke failed: " + message + " (player: " + str(player.global_position) + ")")
	quit(1)
	return false
