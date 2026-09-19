extends SceneTree

const Materials = preload("res://scripts/material_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var world: SandboxWorld = sandbox.get_node("World")
	var liquid: LiquidSystem = sandbox.get_node("Liquid")
	var player: CharacterController = sandbox.get_node("Character")
	await _frames(4)
	var initial := liquid.total_water_units()
	if not _check(initial > 80000 and liquid.active_cell_count > 300, "generated lake has water"):
		return
	await _frames(160)
	if not _check(liquid.total_water_units() == initial and liquid._active.size() == liquid._active_head and liquid.simulated_cells_last_step == 0, "closed lake conserves volume and settles"):
		return
	player.reset_at(Vector2(700, 465))
	await _frames(4)
	if not _check(player.submersion > 0.5, "character senses submersion"):
		return
	var submerged_y := player.global_position.y
	Input.action_press("jump")
	await _frames(20)
	Input.action_release("jump")
	if not _check(player.global_position.y < submerged_y - 15.0, "holding jump swims upward"):
		return
	player.reset_at(sandbox.SPAWN_POSITION)
	var bank := world.world_to_cell(Vector2(700, 400))
	if not _check(liquid.get_amount(bank) > 0, "displacement test starts in water"):
		return
	world.apply_edits([{"cell": bank, "material": Materials.ROCK}])
	await _frames(3)
	if not _check(liquid.get_amount(bank) == 0 and liquid.total_water_units() == initial, "new solid displaces water without losing volume"):
		return
	world.apply_edits([{"cell": bank, "material": Materials.SKY}])
	await _frames(6)
	# The mine is sealed below the lake until the roof is excavated.
	var cave := world.world_to_cell(Vector2(700, 640))
	if not _check(liquid.get_amount(cave) == 0, "mine begins dry"):
		return
	for y in range(522, 599, 12):
		world.remove_circle(Vector2(700, y), 15.0)
	await _frames(240)
	var flooded := 0
	for y in range(590, 660, 8):
		flooded += liquid.get_amount(world.world_to_cell(Vector2(700, y)))
	if not _check(flooded > 0 and liquid.get_amount(world.world_to_cell(Vector2(700, 680))) > 0 and liquid.total_water_units() == initial, "excavation wakes lake, fills the mine floor, and conserves water"):
		return
	# Start an isolated closed-cave test beside the x=736 chunk seam.
	liquid.clear_all()
	var source := world.world_to_cell(Vector2(720, 640))
	for y in range(source.y - 2, source.y + 3):
		for x in range(source.x - 2, source.x + 1):
			liquid.add_water(Vector2i(x, y), liquid.CELL_CAPACITY)
	var cave_volume := liquid.total_water_units()
	if not _check(cave_volume > 0, "closed cave accepts water"):
		return
	await _frames(180)
	var across_seam := 0
	for y in range(120, 140):
		for x in range(192, 196):
			across_seam += liquid.get_amount(Vector2i(x, y))
	if not _check(across_seam > 0 and liquid.total_water_units() == cave_volume and liquid._active.size() == liquid._active_head, "water crosses chunk seam, settles, and conserves closed-cave volume"):
		return
	liquid.clear_all()
	var sealed := Vector2i(100, 135)
	world.apply_edits([{"cell": sealed, "material": Materials.SKY}])
	liquid.add_water(sealed, liquid.CELL_CAPACITY)
	world.apply_edits([{"cell": sealed, "material": Materials.ROCK}])
	if not _check(liquid.get_amount(sealed) == 0 and liquid.displaced_units == liquid.CELL_CAPACITY and liquid.total_water_units() == liquid.CELL_CAPACITY, "blocked construction retains displaced water in reserve"):
		return
	world.apply_edits([{"cell": sealed, "material": Materials.SKY}])
	if not _check(liquid.get_amount(sealed) == liquid.CELL_CAPACITY and liquid.displaced_units == 0, "opening space restores reserved water"):
		return
	print("Liquid smoke passed: settled lake, swimming, displacement, excavation flooding, chunk seam, conservation")
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Liquid smoke failed: " + message)
	quit(1)
	return false
