extends SceneTree

var _player: CharacterController
var _camera: Camera2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	_player = sandbox.get_node("Character")
	_camera = _player.get_node("Camera2D")
	await _frames(100)
	for action in ["move_left", "move_right", "jump", "restart_sandbox"]:
		if not _check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), action + " has a default key binding"):
			return
	if not _check(sandbox.get_node("DebugOverlay/Panel/Label").text.begins_with("FPS:"), "FPS overlay is visible"):
		return
	if not _check(_camera.position_smoothing_enabled, "camera smoothing is enabled"):
		return
	if not _check(_player.is_on_floor() and absf(_player.global_position.y - 321.0) < 3.0, "spawn lands on flat ground"):
		return

	Input.action_press("move_right")
	await _frames(195)
	Input.action_release("move_right")
	if not _check(_player.global_position.x > 100.0 and _player.global_position.y < 245.0 and _player.is_on_floor(), "walk up slope onto upper flat ground"):
		return

	_player.reset_at(Vector2(80, 200))
	await _frames(40)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _frames(45)
	Input.action_release("jump")
	Input.action_release("move_right")
	await _frames(55)
	if not _check(_player.is_on_floor() and absf(_player.global_position.y - 136.0) < 4.0, "jump onto raised platform"):
		return

	_player.reset_at(Vector2(1040, 240))
	await _frames(45)
	Input.action_press("move_right")
	await _frames(45)
	Input.action_release("move_right")
	if not _check(_player.global_position.x < 1091.0, "wall blocks horizontal movement"):
		return

	_player.reset_at(Vector2(690, 280))
	await _frames(100)
	if not _check(_player.is_on_floor() and _player.global_position.y > 480.0, "pit catches falling character below surrounding terrain"):
		return

	_player.reset_at(Vector2(-620, 280))
	await _frames(30)
	var camera_start := _camera.get_screen_center_position().x
	_player.reset_at(Vector2(400, 180))
	await _frames(50)
	if not _check(_camera.get_screen_center_position().x > camera_start + 300.0, "camera follows player"):
		return

	print("Sandbox smoke check passed: ground, slope, platform, wall, pit, camera")
	quit(0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Sandbox smoke check failed: " + message + " (position: " + str(_player.global_position) + ")")
	quit(1)
	return false
