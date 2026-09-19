extends WorldItem
class_name TimedExplosive

var armed := false
var fuse_remaining := 0.0
var detonation_requested := false


func arm(fuse: float) -> void:
	armed = true
	fuse_remaining = maxf(fuse, 0.0)
	$Count.text = "%.1f" % fuse_remaining


func _physics_process(delta: float) -> void:
	if not armed or detonation_requested:
		return
	fuse_remaining -= delta
	$Count.text = "%.1f" % maxf(fuse_remaining, 0.0)
	if fuse_remaining <= 0.0:
		request_detonation()


func request_detonation() -> void:
	if detonation_requested or is_queued_for_deletion():
		return
	detonation_requested = true
	armed = false
	freeze = true
	get_parent().get_parent().get_node("Explosions").enqueue(self)


func receive_damage(_amount: float, _impulse: Vector2) -> void:
	request_detonation()
