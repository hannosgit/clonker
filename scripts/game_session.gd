extends Node2D

const SPAWN_POSITION := Vector2(-620, 280)
const FALL_LIMIT := 900.0

@onready var _character: CharacterController = $Character


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_sandbox") or _character.global_position.y > FALL_LIMIT:
		_character.reset_at(SPAWN_POSITION)
