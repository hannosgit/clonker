extends CharacterBody2D
class_name CharacterController

@export var move_speed := 265.0
@export var acceleration := 1900.0
@export var ground_friction := 2300.0
@export var air_acceleration := 1200.0
@export var jump_speed := 550.0
@export var gravity := 1100.0
@export var max_fall_speed := 900.0
@export var coyote_duration := 0.10
@export var jump_buffer_duration := 0.12

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

@onready var _visual: Node2D = $Visual
@onready var _camera: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var rate := acceleration if is_on_floor() else air_acceleration
	if is_zero_approx(direction) and is_on_floor():
		rate = ground_friction
	velocity.x = move_toward(velocity.x, direction * move_speed, rate * delta)

	if is_on_floor():
		_coyote_timer = coyote_duration
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_duration
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -jump_speed
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < -160.0:
		velocity.y *= 0.55

	move_and_slide()
	if not is_zero_approx(direction):
		_visual.scale.x = signf(direction)


func reset_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_camera.reset_smoothing()
