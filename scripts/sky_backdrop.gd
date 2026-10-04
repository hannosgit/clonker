extends Control
## Screen-space atmosphere; distant layers move at a fraction of camera speed.

var camera: Camera2D
var _sky: GradientTexture2D
var _last_center := Vector2.INF


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.set_color(0, Color("75a8a4"))
	gradient.add_point(0.56, Color("b6cbb4"))
	gradient.set_color(1, Color("e6d6af"))
	_sky = GradientTexture2D.new()
	_sky.gradient = gradient
	_sky.fill_from = Vector2(0, 0)
	_sky.fill_to = Vector2(0, 1)


func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		var center := camera.get_screen_center_position()
		if not center.is_equal_approx(_last_center):
			_last_center = center
			queue_redraw()


func _draw() -> void:
	if _sky == null:
		return
	var viewport := get_viewport_rect().size
	var sx := viewport.x / 1280.0
	var sy := viewport.y / 720.0
	var travel := _last_center.x if _last_center != Vector2.INF else 0.0
	draw_texture_rect(_sky, Rect2(Vector2.ZERO, viewport), false)
	var sun := Vector2(viewport.x * 0.76 - travel * 0.018, viewport.y * 0.22)
	for radius in [96, 73, 51]:
		draw_circle(sun, radius * sy, Color(1.0, 0.91, 0.66, 0.045))
	draw_circle(sun, 34 * sy, Color("f2dfaa"))
	for i in 6:
		var x := fposmod(i * 279.0 - travel * 0.04 + 90.0, 1600.0) - 160.0
		var y := (105.0 + sin(i * 2.3) * 43.0) * sy
		_cloud(Vector2(x * sx, y), sx, Color("b7cbb5"))
	_ridge(viewport, travel * 0.09, 355.0, 113.0, Color("9db9a7"), 0.3)
	_ridge(viewport, travel * 0.17, 411.0, 105.0, Color("7fa496"), 2.4)
	_ridge(viewport, travel * 0.27, 477.0, 74.0, Color("5e8b7c"), 4.8)
	# A distant tree line gives the landscape scale without adding colliders.
	for i in range(-3, 37):
		var x := i * 48.0 - fposmod(travel * 0.34, 48.0)
		var height := 27.0 + (sin(i * 7.1) + 1.0) * 26.0
		var y := 498.0 + sin((x + travel * 0.34) * 0.008) * 16.0
		_pine(Vector2(x * sx, y * sy), height * sy, Color("517b6b"))
	_ridge(viewport, travel * 0.34, 525.0, 17.0, Color("517b6b"), 0.0)


func _cloud(origin: Vector2, scale_factor: float, color: Color) -> void:
	draw_style_box(_cloud_style(color), Rect2(origin + Vector2(-8, -3) * scale_factor, Vector2(104, 23) * scale_factor))
	for i in 3:
		draw_circle(origin + Vector2(i * 26 + 14, -sin(i * 1.1) * 8) * scale_factor, (15.0 + sin(i * 2.0) * 5) * scale_factor, color)


func _cloud_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	return style


func _ridge(viewport: Vector2, offset: float, baseline: float, height: float, color: Color, phase: float) -> void:
	var points := PackedVector2Array([Vector2(-20, viewport.y)])
	for i in range(-1, 66):
		var x := i * viewport.x / 64.0
		var coordinate := x * 1280.0 / viewport.x + offset
		var y := baseline - absf(sin(coordinate * 0.0038 + phase)) * height - sin(coordinate * 0.011 + phase) * height * 0.16
		points.append(Vector2(x, y * viewport.y / 720.0))
	points.append(Vector2(viewport.x + 20, viewport.y))
	draw_colored_polygon(points, color)


func _pine(root_position: Vector2, height: float, color: Color) -> void:
	for tier in 3:
		var top := root_position + Vector2(0, -height + tier * height * 0.23)
		var width := height * (0.18 + tier * 0.055)
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(width, height * 0.46), top + Vector2(-width, height * 0.46)]), color)
