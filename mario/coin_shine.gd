extends AnimatedSprite3D

var spawn_time : int = Time.get_ticks_msec()

func _ready():
	play("new_animation")

func _on_animation_finished():
	queue_free()
