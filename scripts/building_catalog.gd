extends RefCounted
class_name BuildingCatalog

const PATH := "res://data/buildings.json"
const Items = preload("res://scripts/item_catalog.gd")
static var _definitions: Dictionary = {}


static func load_definitions() -> void:
	if not _definitions.is_empty():
		return
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for entry in entries:
		var id: String = entry["id"]
		assert(not _definitions.has(id), "Duplicate building ID: " + id)
		assert(entry["size"].size() == 2 and int(entry["size"][0]) > 0 and int(entry["size"][1]) > 0)
		assert(float(entry["support_fraction"]) > 0.0 and float(entry["support_fraction"]) <= 1.0)
		assert(int(entry["storage_capacity"]) >= 0)
		assert(entry["interaction_offset"].size() == 2 and float(entry["interaction_radius"]) > 0.0)
		for item_id in entry["cost"]:
			assert(int(entry["cost"][item_id]) > 0 and Items.get_definition(item_id)["kind"] == "resource")
		_definitions[id] = entry


static func get_definition(id: String) -> Dictionary:
	load_definitions()
	assert(_definitions.has(id), "Unknown building: " + id)
	return _definitions[id].duplicate(true)


static func ids() -> Array:
	load_definitions()
	return _definitions.keys()
