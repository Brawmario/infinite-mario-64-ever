extends RayCast3D


@export var width := 1.0
@export var texture: Texture2D

@onready var _sprite_3d: Sprite3D = $Sprite3D


func _ready() -> void:
	if not SOGlobal.compat_renderer:
		queue_free()
		return

	global_rotation = Vector3.ZERO

	if texture:
		_sprite_3d.texture = texture

	var shadow_texture_width_pixels := _sprite_3d.texture.get_width()
	var shadow_texture_width := shadow_texture_width_pixels * _sprite_3d.pixel_size
	var new_sprite_3d_scale := width / shadow_texture_width
	_sprite_3d.scale = new_sprite_3d_scale * Vector3.ONE


func _physics_process(_delta: float) -> void:
	global_position = get_parent().global_position + Vector3(0.0, 0.1, 0.0)

	force_raycast_update()
	if not is_colliding():
		_sprite_3d.hide()
		return

	_sprite_3d.show()
	var collision_point := get_collision_point()
	_sprite_3d.global_position = collision_point + Vector3(0.0, 0.01, 0.0)
