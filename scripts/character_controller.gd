extends CharacterBody2D
class_name CharacterController

const Inventory = preload("res://scripts/inventory.gd")
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
var health := 100
var max_health := 100
var inventory: CharacterInventory = Inventory.new()
var tool_cooldown := 0.0
var _shake_strength := 0.0

@onready var _visual: Node2D = $Visual
@onready var _camera: Camera2D = $Camera2D


func _process(delta: float) -> void:
	_shake_strength = move_toward(_shake_strength, 0.0, 22.0 * delta)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength


func shake_camera(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, minf(strength, 4.0))


func _physics_process(delta: float) -> void:
	if health <= 0:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		move_and_slide()
		return
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

	# The cell terrain has 8 px ledges. Step over one cell while grounded.
	if is_on_floor() and not is_zero_approx(direction):
		var ahead := Vector2(direction * 8.0, 0)
		if test_move(transform, ahead) and not test_move(transform, Vector2.UP * 9.0):
			var raised := Transform2D(global_rotation, global_position + Vector2.UP * 9.0)
			if not test_move(raised, ahead):
				global_position.y -= 9.0

	move_and_slide()
	if not is_zero_approx(direction):
		_visual.scale.x = signf(direction)


func reset_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_camera.reset_smoothing()
	_camera.offset = Vector2.ZERO
	_shake_strength = 0.0


func receive_damage(amount: float, impulse: Vector2) -> void:
	if health <= 0:
		return
	health = maxi(0, health - ceili(maxf(amount, 0.0)))
	velocity += impulse


func revive_at(spawn_position: Vector2) -> void:
	health = max_health
	reset_at(spawn_position)
