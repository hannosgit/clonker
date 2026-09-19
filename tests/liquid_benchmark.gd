extends SceneTree

const FRAMES := 180


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var sandbox: Node2D = load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(sandbox)
	var world: SandboxWorld = sandbox.get_node("World")
	var liquid: LiquidSystem = sandbox.get_node("Liquid")
	for i in 60:
		await process_frame
	await _measure("settled lake", liquid, world)
	for y in range(522, 599, 12):
		world.remove_circle(Vector2(700, y), 15.0)
	await _measure("flooding mine", liquid, world)
	quit(0)


func _measure(label: String, liquid: LiquidSystem, world: SandboxWorld) -> void:
	var total_us := 0
	var worst_us := 0
	var slow_frames := 0
	var peak_active := 0
	var peak_liquid_us := 0
	var previous := Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		var frame_us := now - previous
		total_us += frame_us
		worst_us = maxi(worst_us, frame_us)
		if frame_us > 16667:
			slow_frames += 1
		peak_active = maxi(peak_active, liquid._active.size() - liquid._active_head)
		peak_liquid_us = maxi(peak_liquid_us, liquid.last_update_us)
		previous = now
	print("Liquid benchmark %s 1920x1080: frames=%d average=%.2fms worst=%.2fms over_16.67ms=%d water_cells=%d peak_active=%d peak_update=%.2fms chunks=%d" % [label, FRAMES, total_us / float(FRAMES) / 1000.0, worst_us / 1000.0, slow_frames, liquid.active_cell_count, peak_active, peak_liquid_us / 1000.0, world.chunks.size()])
