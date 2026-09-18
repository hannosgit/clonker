extends RefCounted
class_name ToolAction

const Materials = preload("res://scripts/material_catalog.gd")


static func can_mine(material_id: int, tool: Dictionary) -> bool:
	var powers: Dictionary = tool.get("power", {})
	return float(powers.get(str(material_id), 0.0)) >= float(Materials.get_definition(material_id)["dig_resistance"])


static func execute(world: SandboxWorld, origin: Vector2, target: Vector2, tool: Dictionary) -> Dictionary:
	if origin.distance_to(target) > float(tool["reach"]):
		return {}
	var radius: float = tool["radius"]
	var first := world.world_to_cell(target - Vector2.ONE * radius)
	var last := world.world_to_cell(target + Vector2.ONE * radius)
	var edits: Array = []
	for y in range(maxi(first.y, 0), mini(last.y, world.HEIGHT - 1) + 1):
		for x in range(maxi(first.x, 0), mini(last.x, world.WIDTH - 1) + 1):
			var cell := Vector2i(x, y)
			var middle := world.cell_to_world(cell) + Vector2.ONE * world.CELL_SIZE * 0.5
			var material := world.get_cell_material(cell)
			if middle.distance_squared_to(target) <= radius * radius and Materials.is_solid(material) and can_mine(material, tool):
				edits.append({"cell": cell, "material": Materials.SKY})
	return world.apply_edits(edits)
