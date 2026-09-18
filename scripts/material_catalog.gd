extends RefCounted

const SKY := 0
const EARTH := 1
const ROCK := 2
const PATH := "res://data/materials.json"
static var _definitions: Dictionary = {}


static func load_definitions() -> void:
	if not _definitions.is_empty():
		return
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for entry in data:
		var id: int = entry["id"]
		assert(not _definitions.has(id), "Duplicate material ID")
		_definitions[id] = entry
	for required in [SKY, EARTH, ROCK]:
		assert(_definitions.has(required), "Missing required material")


static func has_id(id: int) -> bool:
	load_definitions()
	return _definitions.has(id)


static func is_solid(id: int) -> bool:
	load_definitions()
	return _definitions[id]["solid"]


static func color_for(id: int) -> Color:
	load_definitions()
	return Color.html(_definitions[id]["color"])


static func get_definition(id: int) -> Dictionary:
	load_definitions()
	return _definitions[id].duplicate(true)
