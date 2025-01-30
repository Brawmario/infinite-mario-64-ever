class_name LevelBlock extends MeshInstance3D

enum move_type {
	NONE,
	LINEAR_PINGPONG,
	ROTATE_PINGPONG,
	ROTATE_REPEAT,
	CHILD,
	KEYFRAMED
}

enum coin_spawn_type {
	BOX,
	CIRCLE,
}

var coin_surface : coin_spawn_type = coin_spawn_type.BOX
var block_size : Vector3 = Vector3.ZERO
var current_move_type : move_type = move_type.NONE
var movement_keyframes : Array[AnimKeyframe]
var start_position : Vector3 = Vector3.ZERO
var start_rotation : Basis = Basis.IDENTITY
var target_delta_position : Vector3 = Vector3.ZERO
var target_delta_rotation : Basis = Basis.IDENTITY
var temp_basis : Basis = Basis.IDENTITY
var continuous_rotation : Vector3 = Vector3.ZERO
var move_time : float = 3
var pause_time : float = 3
var forward_or_backward : int = 1
var cur_time : float = 0
var cur_frame : int = 0
var movement_parent : Node3D
var base_transform : Transform3D = Transform3D.IDENTITY
var additive_transform : Transform3D = Transform3D.IDENTITY

func add_keyframe(in_pos : Vector3, in_rot : Quaternion, in_time : float) -> void:
	var new_keyframe : AnimKeyframe = AnimKeyframe.new()
	new_keyframe.position = in_pos
	new_keyframe.rotation = in_rot
	new_keyframe.time = in_time
	movement_keyframes.append(new_keyframe)
	movement_keyframes.sort_custom(func(a, b): return a.time < b.time)

func add_keyframe_euler(in_pos : Vector3, in_rot : Vector3, in_time : float) -> void:
	var new_keyframe : AnimKeyframe = AnimKeyframe.new()
	new_keyframe.position = in_pos
	new_keyframe.rotation_euler = in_rot
	new_keyframe.time = in_time
	movement_keyframes.append(new_keyframe)
	movement_keyframes.sort_custom(func(a, b): return a.time < b.time)

func _update_transform():
	start_rotation = basis
	start_position = position
	base_transform = Transform3D(basis, position)
	if movement_parent:
		base_transform = movement_parent.global_transform.inverse() * base_transform
		additive_transform = movement_parent.global_transform
	temp_basis = base_transform.basis
	_change_block_move_mode(current_move_type)

func _ready():
	_update_transform()
	cur_time = 0
	forward_or_backward = 1

func _reset_block() -> void:
	transform = Transform3D(start_rotation, start_position)
	_ready()

func _change_block_move_mode(in_type : move_type) -> void:
	current_move_type = in_type
	remove_from_group("libsm64_static_surfaces")
	remove_from_group("libsm64_surface_objects")
	match in_type:
		move_type.NONE:
			add_to_group("libsm64_static_surfaces")
		move_type.LINEAR_PINGPONG:
			add_to_group("libsm64_surface_objects")
		move_type.ROTATE_PINGPONG:
			add_to_group("libsm64_surface_objects")
		move_type.ROTATE_REPEAT:
			add_to_group("libsm64_surface_objects")
			target_delta_rotation = base_transform.basis.rotated(continuous_rotation.normalized(), deg_to_rad(continuous_rotation.length()))
		move_type.KEYFRAMED:
			add_to_group("libsm64_surface_objects")
		move_type.CHILD:
			add_to_group("libsm64_surface_objects")


func _process(delta : float):
	if SOGlobal.current_mario._paused:
		return
	if movement_parent:
		additive_transform = movement_parent.global_transform
	var move_duration : float = move_time + pause_time
	cur_time += delta * forward_or_backward

	if cur_time >= move_duration:
		match current_move_type:
			move_type.LINEAR_PINGPONG or move_type.ROTATE_PINGPONG:
				forward_or_backward *= -1
			move_type.ROTATE_REPEAT:
				cur_time = cur_time - move_duration
				temp_basis = base_transform.basis
				target_delta_rotation = base_transform.basis.rotated(continuous_rotation.normalized(), deg_to_rad(continuous_rotation.length()))
			move_type.KEYFRAMED:
				cur_time = fmod(cur_time, movement_keyframes[movement_keyframes.size()].time)

	var ratio : float = minf(1.0, cur_time / move_time)

	match current_move_type:
		move_type.NONE:
			return
		move_type.LINEAR_PINGPONG:
			base_transform.origin = start_position.lerp(start_position + target_delta_position, ratio)
		move_type.ROTATE_PINGPONG:
			base_transform.basis = start_rotation.slerp(target_delta_rotation * start_rotation, ratio)
		move_type.ROTATE_REPEAT:
			#print(ratio)
			base_transform.basis = temp_basis.slerp(target_delta_rotation, ratio)
		move_type.KEYFRAMED:
			if cur_time > movement_keyframes[cur_frame].time:
				cur_frame = (cur_frame + 1) % movement_keyframes.size() - 1
			var current_keyframe : AnimKeyframe = movement_keyframes[cur_frame]
			var next_keyframe : AnimKeyframe
			if cur_frame + 1 < movement_keyframes.size():
				next_keyframe = movement_keyframes[cur_frame + 1]
			else:
				next_keyframe = movement_keyframes[0]
			var keyframe_ratio = (cur_time - current_keyframe.time) / (next_keyframe.time - current_keyframe.time)
			base_transform.origin = current_keyframe.position.lerp(next_keyframe.position, keyframe_ratio)
			base_transform.basis = current_keyframe.rotation.slerp(next_keyframe.rotation, keyframe_ratio)
	base_transform.basis = base_transform.basis.orthonormalized()

	global_transform = additive_transform * base_transform
