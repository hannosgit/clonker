extends SceneTree

const FRAMES := 180


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var blasts: Node2D = sandbox.get_node("Explosions")
	var world: SandboxWorld = sandbox.get_node("World")
	for i in 30:
		await process_frame
	var total_us := 0
	var worst_us := 0
	var slow_frames := 0
	var previous := Time.get_ticks_usec()
	for i in FRAMES:
		if i % 12 == 0:
			var position := Vector2(-544 + (i / 12) * 13, 430)
			blasts.explode(position, 112, 8, 85)
		await process_frame
		var now := Time.get_ticks_usec()
		var frame_us := now - previous
		total_us += frame_us
		worst_us = maxi(worst_us, frame_us)
		if frame_us > 16667:
			slow_frames += 1
			print("Slow frame %d: %.2fms, rebuild %.2fms" % [i, frame_us / 1000.0, world.last_rebuild_us / 1000.0])
		previous = now
	print("Explosion benchmark 1920x1080: frames=%d blasts=%d average=%.2fms worst=%.2fms over_16.67ms=%d chunks=%d rebuilds=%d" % [FRAMES, FRAMES / 12, total_us / float(FRAMES) / 1000.0, worst_us / 1000.0, slow_frames, world.chunks.size(), world.rebuild_count])
	quit(0)
