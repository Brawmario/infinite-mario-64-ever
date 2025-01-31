extends RayCast3D


@export var free_if_not_compatibility_renderer := true
@export var size := Vector2(1.0, 1.0):
	set(value):
		size = value
		_set_sprite_3d_scale()
@export var texture: Texture2D:
	set(value):
		texture = value
		if _sprite_3d:
			_sprite_3d.texture = texture
		_set_sprite_3d_scale()

@onready var _sprite_3d: Sprite3D = $Sprite3D


func _ready() -> void:
	if free_if_not_compatibility_renderer and not SOGlobal.compat_renderer:
		queue_free()
		return

	global_rotation = Vector3.ZERO

	if texture:
		_sprite_3d.texture = texture

	_set_sprite_3d_scale()


func _physics_process(_delta: float) -> void:
	# Update position and prevent the raycast from starting already through the ground
	global_position = get_parent().global_position + Vector3(0.0, 0.1, 0.0)

	force_raycast_update()
	if not is_colliding():
		_sprite_3d.hide()
		return

	_sprite_3d.show()
	var collision_point := get_collision_point()
	# Put the sprite ever so slightly above the ground
	_sprite_3d.global_position = collision_point + Vector3(0.0, 0.01, 0.0)


func _set_sprite_3d_scale() -> void:
	if not _sprite_3d:
		return
	var shadow_texture := _sprite_3d.texture
	if not shadow_texture:
		return
	var shadow_texture_size_pixels := shadow_texture.get_size()
	var shadow_texture_size := shadow_texture_size_pixels * _sprite_3d.pixel_size
	var sprite_3d_scale_xy := size / shadow_texture_size
	_sprite_3d.scale = Vector3(sprite_3d_scale_xy.x, sprite_3d_scale_xy.y, 1.0)
