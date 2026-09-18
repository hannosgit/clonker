extends SceneTree

const EDIT_FRAMES := 180
var world: SandboxWorld


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	world = sandbox.get_node("World")
	for i in 30:
		await process_frame
	var frame_us := 0
	var worst_us := 0
	var slow_frames := 0
	var rebuild_us := 0
	var rebuilt := world.rebuild_count
	var rebuild_samples := 0
	var start := Time.get_ticks_usec()
	var previous := start
	for i in EDIT_FRAMES:
		var x := -350 + (i % 60) * 9
		var y := 420 + (i / 60) * 24
		world.remove_circle(Vector2(x, y), 24)
		await process_frame
		var now := Time.get_ticks_usec()
		var duration := now - previous
		frame_us += duration
		worst_us = maxi(worst_us, duration)
		if duration > 16667:
			slow_frames += 1
		if world.rebuild_count > rebuilt:
			rebuild_us += world.last_rebuild_us
			rebuild_samples += 1
			rebuilt = world.rebuild_count
		previous = now
	print("Terrain benchmark 1920x1080: frames=%d average=%.2fms worst=%.2fms over_16.67ms=%d elapsed=%.2fs chunks=%d rebuilds=%d average_rebuild=%.2fms" % [EDIT_FRAMES, frame_us / float(EDIT_FRAMES) / 1000.0, worst_us / 1000.0, slow_frames, (Time.get_ticks_usec() - start) / 1000000.0, world.chunks.size(), world.rebuild_count, rebuild_us / float(maxi(rebuild_samples, 1)) / 1000.0])
	quit(0)
