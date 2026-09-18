extends CanvasLayer

@onready var _label: Label = $Panel/Label
var _time_until_refresh := 0.0


func _process(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh <= 0.0:
		_label.text = "FPS: %d\nA/D or arrows: move   Space/W/Up: jump   R: reset" % Engine.get_frames_per_second()
		_time_until_refresh = 0.2
