extends Node2D

const SPAWN_POSITION := Vector2(-620, 280)
const FALL_LIMIT := 900.0

@onready var _character: CharacterController = $Character
@onready var _world: SandboxWorld = $World
var brush_radius := 24.0


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart_sandbox") or _character.global_position.y > FALL_LIMIT:
		_character.reset_at(SPAWN_POSITION)
	if Input.is_action_pressed("terrain_dig"):
		_world.remove_circle(get_global_mouse_position(), brush_radius)
	elif Input.is_action_pressed("terrain_paint"):
		var material := 2 if Input.is_key_pressed(KEY_SHIFT) else 1
		_world.paint_circle(get_global_mouse_position(), brush_radius, material)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush_radius = minf(brush_radius + 8.0, 80.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush_radius = maxf(brush_radius - 8.0, 8.0)
