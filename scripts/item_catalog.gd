extends RefCounted
class_name ItemCatalog

const PATH := "res://data/items.json"
static var _definitions: Dictionary = {}


static func load_definitions() -> void:
	if not _definitions.is_empty():
		return
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for entry in entries:
		var id: String = entry["id"]
		assert(not _definitions.has(id), "Duplicate item ID: " + id)
		assert(int(entry["max_stack"]) > 0, "Invalid stack size: " + id)
		_definitions[id] = entry
	for required in ["shovel", "pickaxe", "explosive", "coal", "ore", "gold"]:
		assert(_definitions.has(required), "Missing item: " + required)


static func get_definition(id: String) -> Dictionary:
	load_definitions()
	assert(_definitions.has(id), "Unknown item: " + id)
	return _definitions[id].duplicate(true)


static func max_stack(id: String) -> int:
	return int(get_definition(id)["max_stack"])
