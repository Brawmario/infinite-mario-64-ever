extends RayCast3D


@export var width := 1.0
@export var texture: Texture2D


@onready var sprite_3d: Sprite3D = $Sprite3D


func _ready() -> void:
	if not SOGlobal.compat_renderer:
		queue_free()
		return

	if texture:
		sprite_3d.texture = texture
	sprite_3d.modulate.a = 0.75

	global_rotation = Vector3.ZERO

	var shadow_width_pixels := sprite_3d.texture.get_width()
	var shadow_width := shadow_width_pixels * sprite_3d.pixel_size
	var new_scale := width / shadow_width

	sprite_3d.scale = new_scale * Vector3.ONE


func _physics_process(_delta: float) -> void:
	global_position = get_parent().global_position + Vector3(0.0, 0.05, 0.0)

	force_raycast_update()
	if not is_colliding():
		hide()
		return

	show()
	var collision_point := get_collision_point()
	global_position = collision_point + Vector3(0.0, 0.05, 0.0)
