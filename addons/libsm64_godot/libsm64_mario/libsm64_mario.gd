@icon("res://addons/libsm64_godot/libsm64_mario/libsm64_mario.svg")
class_name LibSM64Mario
extends Node3D

@onready var audio_stream_player = $AudioStreamPlayer
@onready var mario_collision := $MarioCollision as Area3D
@onready var collision_cylinder := $MarioCollision/CollisionCylinder.shape as CylinderShape3D

## Node that instances a Mario into a scenario

## Value that represents Mario being at full health
const FULL_HEALTH = 0x0880
## Value that represents one health wedge
const HEALTH_WEDGE = 0x0100


signal action_changed(action: LibSM64.ActionFlags)
signal flags_changed(flags: LibSM64.MarioFlags)
signal particle_flags_changed(particle_flags: LibSM64.ParticleFlags)
signal health_changed(health: int)
signal health_wedges_changed(health_wedges: int)

## Camera instance that follows Mario
@export var camera: Camera3D

## if [code]true[/code], linearly interpolate Mario and transform
## from the SM64 engine's hardcoded 30 frames per second to the tick rate
## of the current [code]tick_process_mode[/code].
@export var interpolate := true

@export_group("Mario Inputs Actions", "mario_inputs_")
## Action equivalent to pushing the joystick to the left
@export var mario_inputs_stick_left := &"mario_stick_left"
## Action equivalent to pushing the joystick to the right
@export var mario_inputs_stick_right := &"mario_stick_right"
## Action equivalent to pushing the joystick upwards
@export var mario_inputs_stick_up := &"mario_stick_up"
## Action equivalent to pushing the joystick downwards
@export var mario_inputs_stick_down := &"mario_stick_down"
## Action equivalent to pushing the A button
@export var mario_inputs_button_a := &"mario_a"
## Action equivalent to pushing the B button
@export var mario_inputs_button_b := &"mario_b"
## Action equivalent to pushing the Z button
@export var mario_inputs_button_z := &"mario_z"


var _id := -1
## Mario's internal [code]libsm64[/code] ID
var id: int:
	get:
		return _id

var _action := LibSM64.ActionFlags.ACT_UNINITIALIZED:
	set(value):
		if value != _action:
			_action = value
			action_changed.emit(_action)
## Mario's action flags
var action: LibSM64.ActionFlags:
	get:
		return _action
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_action(_id, value)
		_action = value

## Mario's action as StringName
var action_name: StringName:
	get:
		return _to_action_name(_action)

var _flags := 0 as LibSM64.MarioFlags:
	set(value):
		if value != _flags:
			_flags = value
			flags_changed.emit(_flags)
## Mario's state flags
var flags: LibSM64.MarioFlags:
	get:
		return _flags
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_state(_id, value)
		_flags = value

var _particle_flags := 0 as LibSM64.ParticleFlags:
	set(value):
		if value != _particle_flags:
			_particle_flags = value
			particle_flags_changed.emit(_particle_flags)
## Mario's particle flags
var particle_flags: LibSM64.ParticleFlags:
	get:
		return _particle_flags

var _velocity := Vector3()
## Mario's velocity in the libsm64 world
var velocity: Vector3:
	get:
		return _velocity
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_velocity(_id, value)
		_velocity = value
		if _mario_interpolator.mario_state_current:
			_mario_interpolator.mario_state_current.velocity = _velocity
			_mario_interpolator.mario_state_previous.velocity = _velocity

var _face_angle := 0.0:
	set(value):
		global_rotation.y = value
		_face_angle = value
## Mario's facing angle in radians
var face_angle: float:
	get:
		return _face_angle
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_face_angle(_id, value)
		_face_angle = value
		if _mario_interpolator.mario_state_current:
			_mario_interpolator.mario_state_current.face_angle = _face_angle
			_mario_interpolator.mario_state_previous.face_angle = _face_angle

var _health := FULL_HEALTH:
	set(value):
		if value != _health:
			_health = value
			health_changed.emit(_health)
			health_wedges_changed.emit(health_wedges)
## Mario's health (2 bytes, upper byte is the number of health wedges, lower byte portion of next wedge)
var health: int:
	get:
		return _health
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_health(_id, value)
		_health = value

## Mario's amount of health wedges
var health_wedges: int:
	get:
		return _health >> 0x8 if _health > 0 else 0x0
	set(value):
		if _id < 0:
			return
		var new_health := value << 0x8 if value > 0 else 0x0
		LibSM64.set_mario_health(_id, new_health)
		_health = new_health

var _invicibility_time := 0.0
## Mario's invincibility time in seconds
var invicibility_time: float:
	get:
		return _invicibility_time
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_invincibility(_id, value)
		_invicibility_time = value
		if _mario_interpolator.mario_state_current:
			_mario_interpolator.mario_state_current.invicibility_time = _invicibility_time
			_mario_interpolator.mario_state_previous.invicibility_time = _invicibility_time

## Mario's water level
var water_level := -100000.0 / LibSM64.scale_factor:
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_water_level(_id, value)
		water_level = value

## Mario's gas level
var gas_level := -100000.0 / LibSM64.scale_factor:
	set(value):
		if _id < 0:
			return
		LibSM64.set_mario_gas_level(_id, value)
		gas_level = value

var _mesh_instance: MeshInstance3D
var _mesh: ArrayMesh

var _mario_interpolator := LibSM64MarioInterpolator.new()

var _default_material := preload("res://addons/libsm64_godot/libsm64_mario/libsm64_mario_default_material.tres") as StandardMaterial3D
var _vanish_material := preload("res://addons/libsm64_godot/libsm64_mario/libsm64_mario_vanish_material.tres") as StandardMaterial3D
var _metal_material := preload("res://addons/libsm64_godot/libsm64_mario/libsm64_mario_metal_material.tres") as StandardMaterial3D
var _wing_material := preload("res://addons/libsm64_godot/libsm64_mario/libsm64_mario_wing_material.tres") as StandardMaterial3D

var _time_since_last_tick := 0.0
var _last_tick_usec := Time.get_ticks_usec()
var _reset_interpolation_next_tick := false

var _cam_rotation := 0.0
var _cam_rotation_target := 0.0
var _cam_zoom := 1
var _cam_tilt := 0.0
var _cam_height := 0.0
var _cam_target_height := 0.0
var _cam_dist := 0.0
var _cam_target := Vector3(0, 0, 0)
var _cam_dir := Vector3(0, 0, 1)
var _cam_target_dist := 0.0

@onready var seed_label := $SeedLabel as Label
@onready var hint_text := $HintText as Label
@onready var level_timer := $LevelTimer as Label
@onready var coin_counter = $CoinCounter
@onready var power_disp = $PowerDisp
@onready var health_wedges_disp = $PowerDisp/HealthWedges

var _paused : bool = false


func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	_mesh_instance.top_level = true
	_mesh_instance.position = Vector3.ZERO
	_mesh_instance.rotation = Vector3.ZERO

	_mesh = ArrayMesh.new()
	_mesh_instance.mesh = _mesh

	SOGlobal.current_mario = self

@onready var star_arrow := $star_arrow as MeshInstance3D
@onready var star_mesh := $StarMesh as MeshInstance3D
@onready var checkpoint_helper = $CheckpointHelper

func _process(delta: float) -> void:
	if _id < 0:
		return

	if SOGlobal.unfocused:
		return
	if position.y <= -32:
		if checkpoint_flag and is_instance_valid(checkpoint_flag):
			_restore_mario_to_checkpoint()
		else: if !needs_respawning:
			needs_respawning = true
			_respawn_mario()

	if _action == LibSM64.ACT_STAR_DANCE_EXIT and !_paused and ready_to_play:
		if !hide_hud:
			hint_text_3.visible = true
			hint_text_2.visible = true
		if Input.is_action_just_pressed("mario_a"):
			action = LibSM64.ACT_IDLE
		if Input.is_action_just_pressed("mario_b"):
			action = LibSM64.ACT_SPAWN_SPIN_AIRBORNE
			SOGlobal.current_level_manager._create_mario_world()
			hint_text_3.visible = false
			hint_text_2.visible = false
	else:
		hint_text_3.visible = false
		hint_text_2.visible = false

	if _paused or !ready_to_play:
		seed_label.text = "Current Seed: " + str(SOGlobal.current_seed)
		if !hide_hud:
			seed_label.visible = true
			checkpoint_helper.visible = true
		level_timer.visible = false
	else:
		checkpoint_helper.visible = false
		seed_label.visible = false
		if !hide_hud:
			level_timer.visible = true
		var timer_seconds : float = float(finish_time - start_time) * 0.001
		if finish_time < 0:
			timer_seconds = float(Time.get_ticks_msec() - start_time) * 0.001
		level_timer.text = "%02d:%02d.%03d" % [timer_seconds/60.0, fmod(timer_seconds, 60.0), fmod(timer_seconds * 1000, 1000.0)]

	if ready_to_play:
		visible = true
		hint_text.visible = false
	else:
		visible = false
		if !hide_hud:
			hint_text.visible = true

	if _paused:
		return

	#DebugDraw2D.set_text("ACTION", LibSM64.ACT_to_action_name(_action))

	time_since_start += delta

	if Input.is_action_just_pressed("start_button"):
		var pause_menu = preload("res://mario/mario_pause_menu.tscn").instantiate()
		SOGlobal.add_child(pause_menu)
		_paused = true
		return

	var camera_input : Vector2 = Input.get_vector("cam_stick_left", "cam_stick_right", "cam_stick_up", "cam_stick_down")
	if SOGlobal.flip_x:
		camera_input.x *= -1

	var time_minus_start = Time.get_ticks_msec() - SOGlobal.level_start_time
	if !ready_to_play:
		if Input.is_action_just_pressed("mario_a"):
			SOGlobal.play_sound(preload("res://mario/enter_painting.WAV"))
			ready_to_play = true
			start_time = Time.get_ticks_msec()
			_respawn_mario()
		preview_cam_pitch += Input.get_axis(mario_inputs_stick_up, mario_inputs_stick_down) * delta * 90
		preview_cam_yaw += Input.get_axis(mario_inputs_stick_left, mario_inputs_stick_right) * delta * 90
		preview_cam_pan_pitch += camera_input.y * delta * -360
		preview_cam_pan_yaw += camera_input.x * delta * -720
		preview_cam_pan_yaw = lerp(preview_cam_pan_yaw, 0.0, delta * 6)
		preview_cam_pan_pitch = lerp(preview_cam_pan_pitch, 0.0, delta * 6)
		preview_cam_zoom += Input.get_axis("dpad_up", "dpad_down") * delta
		preview_cam_pitch = clamp(preview_cam_pitch, -45.0, 45.0)
		var cam_desired_rotation : Vector3 = Vector3(preview_cam_pitch, preview_cam_yaw, 0)
		var final_position : Vector3 = camera.position
		var final_rotation : Basis = camera.basis
		camera.rotation_degrees = cam_desired_rotation
		camera.position = camera.basis.z * SOGlobal.level_bounds.get_longest_axis_size() * preview_cam_zoom + SOGlobal.level_bounds.get_center()
		camera.rotation_degrees += Vector3(preview_cam_pan_pitch, preview_cam_pan_yaw, 0)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -45.0, 45.0)
		view_stage_transform = camera.global_transform
		return

	mario_collision.position.y = 0.25
	collision_cylinder.radius = 0.5
	collision_cylinder.height = 1.75

	#print(action & LibSM64.ACT_FLAG_STATIONARY > 0)

	if action & LibSM64.ACT_FLAG_STATIONARY > 0:
		if Input.is_action_just_pressed("dpad_up"):
			_create_checkpoint()

	match action:
		LibSM64.ACT_SPAWN_SPIN_AIRBORNE:
			global_position = snapped(global_position, Vector3(0.5, 0, 0.5))
			#teleport(global_position)
			_velocity = _velocity * Vector3(0, 1, 0)
		LibSM64.ACT_GROUND_POUND:
			mario_collision.position.y = -0.5
			collision_cylinder.height = 2.0
			collision_cylinder.radius = 1.25

	if Input.is_action_just_pressed("dpad_down") and checkpoint_flag and is_instance_valid(checkpoint_flag):
		_restore_mario_to_checkpoint()


	if Time.get_ticks_msec() > gravity_set_time + 10000:
		gravity_add = 0

	if gravity_add != 0:
		velocity += Vector3(0, gravity_add * delta, 0)

	var lerp_t = (Time.get_ticks_usec() - _last_tick_usec) / (LibSM64.tick_delta_time * 1000000.0)

	var mario_state: LibSM64MarioState
	if interpolate:
		mario_state = _mario_interpolator.interpolate_mario_state(lerp_t)
	else:
		mario_state = _mario_interpolator.mario_state_current

	global_position = mario_state.position
	_velocity = mario_state.velocity
	_face_angle = mario_state.face_angle
	_invicibility_time = mario_state.invincibility_time

	var material: StandardMaterial3D
	match _flags & LibSM64.MARIO_SPECIAL_CAPS:
		LibSM64.MARIO_VANISH_CAP :
			material = _vanish_material
		LibSM64.MARIO_METAL_CAP :
			material = _metal_material
		LibSM64.MARIO_WING_CAP:
			material = _wing_material
		_:
			material = _default_material

	var array_mesh_triangles: Array
	if interpolate:
		array_mesh_triangles = _mario_interpolator.interpolate_array_mesh_triangles(lerp_t)
	else:
		array_mesh_triangles = _mario_interpolator.array_mesh_triangles_current

	if not array_mesh_triangles[ArrayMesh.ARRAY_VERTEX].is_empty():
		_mesh.clear_surfaces()
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh_triangles)
		_mesh_instance.set_surface_override_material(0, material)

	if ready_to_play:
		_calculate_gameplay_camera(delta)
		var gameplay_camera_transform : Transform3D = camera.global_transform
		if false and time_since_start <= 1.0:
			var ratio : float = 1.0 - time_since_start
			ratio = ease(ratio, -2)
			camera.global_transform = camera.global_transform.interpolate_with(view_stage_transform, ratio)

	RenderingServer.global_shader_parameter_set("aspect_ratio", get_window().size.x / get_window().size.y)
	#DebugDraw2D.set_text("COIN COUNT", current_coin_count)
	coin_counter.text = "$*" + str(current_coin_count)
	health_wedges_disp.material.set_shader_parameter("wedges", health_wedges)
	star_arrow.global_position = camera.position + camera.basis.z * -0.2 + camera.basis.y * 0.065
	star_mesh.global_position = star_arrow.global_position
	star_mesh.global_rotation_degrees = camera.rotation_degrees + Vector3(90, 0, 0)
	star_mesh.scale = Vector3(0.012, 0.012, 0.012)
	star_mesh.basis = star_mesh.basis.rotated(star_mesh.basis.z.normalized(), float(Time.get_ticks_msec()) * 0.001)
	star_arrow.scale = Vector3(0.0035, 0.0035, 0.0035)
	star_arrow.look_at(SOGlobal.main_star_pos)
	if hide_hud and !hide_hud_old:
		seed_label.visible = false
		level_timer.visible = false
		hint_text.visible = false
		hint_text_2.visible = false
		hint_text_3.visible = false
		coin_counter.visible = false
		power_disp.visible = false
		checkpoint_helper.visible = false
		star_arrow.visible = false

	if !hide_hud and hide_hud_old:
		seed_label.visible = true
		level_timer.visible = true
		hint_text.visible = true
		hint_text_2.visible = true
		hint_text_3.visible = true
		coin_counter.visible = true
		power_disp.visible = true
		checkpoint_helper.visible = true
		star_arrow.visible = true

	hide_hud_old = hide_hud
	#DebugDraw3D.draw_sphere(position, 0.1, Color(1, 1, 1), delta)


func _physics_process(delta):
	if _id < 0:
		return

	_time_since_last_tick += delta
	while _time_since_last_tick >= LibSM64.tick_delta_time:
		_tick()
		_last_tick_usec = Time.get_ticks_usec()
		_time_since_last_tick -= LibSM64.tick_delta_time

		# Update the members that aren't interpolated
		_health = _mario_interpolator.mario_state_current.health;
		_action = _mario_interpolator.mario_state_current.action;
		_flags = _mario_interpolator.mario_state_current.flags;
		_particle_flags = _mario_interpolator.mario_state_current.particle_flags;


## Create Mario (requires initializing the libsm64 via the global_init function)
func create() -> void:
	if _id >= 0:
		delete()

	_id = LibSM64.mario_create(global_position)
	if _id < 0:
		return
	face_angle = global_rotation.y

	_mario_interpolator.mario_state_current = LibSM64MarioState.new()
	_mario_interpolator.mario_state_current.position = global_position
	_mario_interpolator.mario_state_current.face_angle = _face_angle
	_mario_interpolator.mario_state_current.health = FULL_HEALTH
	_mario_interpolator.array_mesh_triangles_current = [PackedVector3Array(), PackedVector3Array(), null, PackedColorArray(), PackedVector2Array(), null, null, null, null, null, null, null, null]

	_mario_interpolator.mario_state_previous = _mario_interpolator.mario_state_current
	_mario_interpolator.array_mesh_triangles_previous = _mario_interpolator.array_mesh_triangles_current

	reset_interpolation()

	if not _default_material.albedo_texture:
		_default_material.albedo_texture = LibSM64Global.mario_texture
		_wing_material.albedo_texture = LibSM64Global.mario_texture
		_metal_material.albedo_texture = LibSM64Global.mario_texture
		_vanish_material.albedo_texture = LibSM64Global.mario_texture


## Delete mario inside the libsm64 world
func delete() -> void:
	if _id < 0:
		return
	LibSM64.mario_delete(_id)
	_id = -1


## Teleport mario in the libsm64 world
func teleport(to_global_position: Vector3) -> void:
	if _id < 0:
		return
	LibSM64.set_mario_position(_id, to_global_position)
	global_position = to_global_position
	_mario_interpolator.mario_state_current.position = global_position
	_mario_interpolator.mario_state_previous.position = global_position
	reset_interpolation()


## Set angle of mario in the libsm64 world
func set_angle(to_global_rotation: Quaternion) -> void:
	if _id < 0:
		return
	LibSM64.set_mario_angle(_id, to_global_rotation)
	_face_angle = to_global_rotation.get_euler().y
	_mario_interpolator.mario_state_current.face_angle = _face_angle
	_mario_interpolator.mario_state_previous.face_angle = _face_angle
	reset_interpolation()


## Set Mario's forward velocity in the libsm64 world
func set_forward_velocity(velocity: float) -> void:
	if _id < 0:
		return
	LibSM64.set_mario_forward_velocity(_id, velocity)


## Make Mario take damage in amount of health wedges from a source position
func take_damage(damage: int, subtype: int, source_position: Vector3) -> void:
	if _id < 0:
		return
	LibSM64.mario_take_damage(_id, damage, subtype, source_position)


## Heal Mario a specific amount of wedges
func heal(wedges: int) -> void:
	if _id < 0:
		return
	LibSM64.mario_heal(_id, wedges)


## Kill Mario
func kill() -> void:
	if _id < 0:
		return
	LibSM64.mario_kill(_id)


## Equip special cap (see LibSM64.MarioFlags for values)
func interact_cap(cap_flag: LibSM64.MarioFlags, cap_time := 0.0, play_music := true) -> void:
	if _id < 0:
		return
	LibSM64.mario_interact_cap(_id, cap_flag, cap_time, play_music)


## Extend current special cap time
func extend_cap(cap_time: float) -> void:
	if _id < 0:
		return
	LibSM64.mario_extend_cap(_id, cap_time)


## Reset interpolation next tick
func reset_interpolation() -> void:
	_reset_interpolation_next_tick = true


func _make_mario_inputs() -> LibSM64MarioInputs:
	var mario_inputs := LibSM64MarioInputs.new()

	var pl_input := PlayerInput.from_input()

	mario_inputs.stick = Vector2(pl_input.JoyXAxis, pl_input.JoyYAxis)
	if mario_inputs.stick.length() > 1.0:
		mario_inputs.stick = mario_inputs.stick.normalized()
	#DebugDraw2D.set_text("INPUT", mario_inputs.stick)

	var look_direction := Vector2(0, 1).rotated(-_cam_rotation)
	mario_inputs.cam_look = Vector2(look_direction.x, look_direction.y)
	if action == LibSM64.ACT_STAR_DANCE_NO_EXIT or action == LibSM64.ACT_FALL_AFTER_STAR_GRAB or action == LibSM64.ACT_STAR_DANCE_EXIT:
		mario_inputs.cam_look *= -1

	mario_inputs.button_a = Input.is_action_pressed(mario_inputs_button_a)
	mario_inputs.button_b = Input.is_action_pressed(mario_inputs_button_b)
	mario_inputs.button_z = Input.is_action_pressed(mario_inputs_button_z)

	return mario_inputs


#_cam_rotation - int
#_cam_zoom - int
#_cam_tilt - float
#_cam_target - vector
#_cam_target_dist - float
var finish_time : float = -1.0
var current_coin_count : int = 0

func _get_power_star(in_star_id : String) -> void:
	finish_time = Time.get_ticks_msec()
	var time_in_seconds : float = float(finish_time - start_time) * 0.001
	SOGlobal.save_data.try_submit_save_block(SOGlobal.current_seed, in_star_id, time_in_seconds, current_coin_count, num_checkpoints_used, true)
	action = LibSM64.ACT_FALL_AFTER_STAR_GRAB
	audio_stream_player.play()
	var saysound_playback : AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	saysound_playback.play_stream(preload("res://mario/enter_painting.WAV"), 0, -8, 1.0)
	await get_tree().create_timer(0.5).timeout
	saysound_playback.play_stream(preload("res://mario/star_get.wav"), 0, 0, 1.0)
	#action = LibSM64.ACT_FALL_AFTER_STAR_GRAB
	set_angle(Quaternion.from_euler(camera.position - position).normalized())
	await get_tree().create_timer(1.2).timeout
	saysound_playback.play_stream(preload("res://mario/here_we_go.wav"), 0, 10, 1.0)

var ready_to_play : bool = false
var preview_cam_yaw : float = 0
var preview_cam_pitch : float = 0
var preview_cam_zoom : float = 0
var preview_cam_pan_pitch : float = 0
var preview_cam_pan_yaw : float = 0
@onready var spawn_line_cast := $SpawnLineCast as RayCast3D
@onready var spawn_cast := $SpawnCast as ShapeCast3D
var start_time := 0.0

func _respawn_mario() -> void:
	for block:LevelBlock in SOGlobal.level_meshes:
		block._reset_block()
	await get_tree().create_timer(0.05).timeout
	needs_respawning = false
	position = Vector3(0, 6, 0)
	current_coin_count = 0
	var cant_spawn = true
	var iter : int = 0
	var spawn_random := RandomNumberGenerator.new()
	spawn_random.seed = hash("le spawn seed")
	var dist = 1.0
	while cant_spawn:
		if iter > 0:
			var random_dir := Vector3(spawn_random.randf_range(-1, 1), spawn_random.randf_range(-0.25, 1), spawn_random.randf_range(-1, 1)).normalized()
			dist += (2.0 / iter) + 0.02
			position = Vector3(0, 6, 0) + random_dir * dist
			position = snapped(position, Vector3(1, 1, 1)) + Vector3(0.5, 0, 0.5)
		iter += 1
		spawn_cast.force_shapecast_update()
		if spawn_cast.is_colliding():
			#DebugDraw3D.draw_sphere(position, 0.1, Color(1, 0, 0), 5)
			if dist > SOGlobal.level_bounds.get_longest_axis_size():
				position = Vector3(0, 6, 0)
				cant_spawn = false
		else:
			spawn_line_cast.force_raycast_update()
			if spawn_line_cast.is_colliding() and spawn_line_cast.get_collision_normal().y > 0.8:
				cant_spawn = false
	teleport(position)
	time_since_start = 0
	num_checkpoints_used = 0
	_cam_target_height = position.y
	health_wedges = 8
	_velocity = Vector3.ZERO
	_cam_rotation_target = deg_to_rad(SOGlobal.start_angle)
	_cam_zoom = 1
	action = LibSM64.ACT_SPAWN_SPIN_AIRBORNE
	start_time = Time.get_ticks_msec()
	finish_time = -1.0
	if checkpoint_flag and is_instance_valid(checkpoint_flag):
		checkpoint_flag.queue_free()
	checkpoint_pos = position
	checkpoint_facing = face_angle
	SOGlobal.play_sound(preload("res://mario/enter_painting.WAV"))
	for child in SOGlobal.get_children():
		if child is PowerStar:
			child._respawn()
		if child is Coin:
			child._respawn()
		if child is CorkBox:
			child._reset()

var checkpoint_pos : Vector3 = Vector3.ZERO
var checkpoint_facing : float = 0
var checkpoint_flag : Node3D
@onready var hint_text_3 = $HintText3
@onready var hint_text_2 = $HintText2

func smin(a : float, b : float, k : float) -> float:
	var h : float = clampf(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
	return lerp(a, b, h) - k*h*(1.0-h);

var needs_respawning : bool = false
var num_checkpoints_used : int = 0

func _create_checkpoint() -> void:
	spawn_line_cast.force_raycast_update()
	if !spawn_line_cast.is_colliding():
		return
	var hit_block := spawn_line_cast.get_collider().get_parent() as LevelBlock
	if hit_block.current_move_type != LevelBlock.move_type.NONE:
		return
	checkpoint_pos = global_position
	checkpoint_facing = face_angle
	if checkpoint_flag and is_instance_valid(checkpoint_flag):
		checkpoint_flag.queue_free()
	checkpoint_flag = preload("res://mario/checkpoint_flag.tscn").instantiate()
	checkpoint_flag.position = checkpoint_pos
	SOGlobal.add_child(checkpoint_flag)
	checkpoint_flag.get_node("AnimationPlayer").play("flag_spawn")
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_drop_into_course.wav"))

func _restore_mario_to_checkpoint() -> void:
	num_checkpoints_used += 1
	teleport(checkpoint_pos)
	_cam_target_height = position.y
	set_angle(Quaternion.from_euler(Vector3.FORWARD.rotated(Vector3.UP, checkpoint_facing)))
	velocity = Vector3.ZERO
	_velocity = Vector3.ZERO
	set_forward_velocity(0)
	velocity = Vector3.ZERO
	face_angle =checkpoint_facing
	set_forward_velocity(0.0)
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_spinning_heart.wav"))
	action = LibSM64.ACT_IDLE

var time_since_start : float = 0
var view_stage_transform : Transform3D

func _calculate_gameplay_camera(delta : float):
	if Input.is_action_just_pressed("cam_stick_left"):
		if SOGlobal.flip_x:
			_cam_rotation_target -= deg_to_rad(45)
		else:
			_cam_rotation_target += deg_to_rad(45)
	if Input.is_action_just_pressed("cam_stick_right"):
		if SOGlobal.flip_x:
			_cam_rotation_target += deg_to_rad(45)
		else:
			_cam_rotation_target -= deg_to_rad(45)

	if Input.is_action_just_pressed("cam_stick_down"):
		_cam_zoom += 1
	if Input.is_action_just_pressed("cam_stick_up"):
		_cam_zoom -= 1

	_cam_zoom = clampi(_cam_zoom, 0, 2)

	var target_height : float = 10
	var target_dist : float = 5
	var target_lookat : float = 1.4
	match _cam_zoom:
		0:
			target_height = 4
			target_dist = 10
			target_lookat = 1.6
		1:
			target_height = 6
			target_dist = 14
			target_lookat = 2.0
		2:
			target_height = 8
			target_dist = 18
			target_lookat = 2.6

	_cam_rotation = lerp(_cam_rotation, _cam_rotation_target, delta * 12)
	_cam_height = lerp(_cam_height, target_height, delta * 12)
	_cam_dist = lerp(_cam_dist, target_dist, delta * 12)
	camera.rotation = Vector3(0, _cam_rotation, 0)
	camera.fov = 45
	var height_diff := min(absf(_cam_target_height - position.y), 2)
	_cam_target_height = move_toward(_cam_target_height, position.y, delta * 6 * height_diff)
	var face_dir = Basis.IDENTITY.rotated(Vector3(0, 1, 0), _face_angle)
	var target_look = face_dir.x * -target_lookat + Vector3(0, 1, 0)
	var dist_to_target = (target_look - _cam_target).length() * 2
	_cam_target = _cam_target.move_toward(target_look, minf(dist_to_target, 0.5) * delta * 4)
	var look_to = Vector3(position.x, smin(_cam_target_height, position.y + 4, 1.5), position.z) + _cam_target

	#DebugDraw3D.draw_sphere(look_to, 0.1, Color(1, 0, 0), delta)
	#DebugDraw3D.draw_arrow_line(position + Vector3(0, 0.5, 0), position + Vector3(0, 0.5, 0) - face_dir.x, Color(0, 1, 0), 0.1, true, delta)

	var camera_basis = Basis.IDENTITY.rotated(Vector3(0, 1, 0), _cam_rotation)
	camera.position = Vector3(position.x, _cam_target_height, position.z) + camera_basis.z * _cam_dist + Vector3(0, _cam_height, 0)
	#camera.position = snapped(camera.position, Vector3(1.0 / 32.0, 1.0 / 32.0, 1.0 / 32.0))
	camera.look_at(look_to)
	var angle_snap : float = 360.0 / 65536.0
	camera.global_rotation_degrees = snapped(camera.global_rotation_degrees, Vector3(angle_snap, angle_snap, angle_snap))


var hide_hud : bool = false
var hide_hud_old : bool = false
var gravity_add : float = 0.0
var gravity_set_time : int = 0


func _tick() -> void:
	if _id < 0:
		return

	var mario_inputs := _make_mario_inputs()

	_mario_interpolator.mario_state_previous = _mario_interpolator.mario_state_current
	_mario_interpolator.array_mesh_triangles_previous = _mario_interpolator.array_mesh_triangles_current

	var mario_tick_output := LibSM64.mario_tick(_id, mario_inputs)

	_mario_interpolator.mario_state_current = mario_tick_output[0]
	_mario_interpolator.array_mesh_triangles_current = mario_tick_output[1]

	if _reset_interpolation_next_tick:
		_mario_interpolator.mario_state_previous = _mario_interpolator.mario_state_current
		_mario_interpolator.array_mesh_triangles_previous = _mario_interpolator.array_mesh_triangles_current
		_reset_interpolation_next_tick = false


static func _to_action_name(action: int) -> StringName:
	match action:
		LibSM64.ACT_IDLE:
			return &"ACT_IDLE"
		LibSM64.ACT_START_SLEEPING:
			return &"ACT_START_SLEEPING"
		LibSM64.ACT_SLEEPING:
			return &"ACT_SLEEPING"
		LibSM64.ACT_WAKING_UP:
			return &"ACT_WAKING_UP"
		LibSM64.ACT_PANTING:
			return &"ACT_PANTING"
		LibSM64.ACT_HOLD_PANTING_UNUSED:
			return &"ACT_HOLD_PANTING_UNUSED"
		LibSM64.ACT_HOLD_IDLE:
			return &"ACT_HOLD_IDLE"
		LibSM64.ACT_HOLD_HEAVY_IDLE:
			return &"ACT_HOLD_HEAVY_IDLE"
		LibSM64.ACT_STANDING_AGAINST_WALL:
			return &"ACT_STANDING_AGAINST_WALL"
		LibSM64.ACT_COUGHING:
			return &"ACT_COUGHING"
		LibSM64.ACT_SHIVERING:
			return &"ACT_SHIVERING"
		LibSM64.ACT_IN_QUICKSAND:
			return &"ACT_IN_QUICKSAND"
		LibSM64.ACT_UNKNOWN_0002020E:
			return &"ACT_UNKNOWN_0002020E"
		LibSM64.ACT_CROUCHING:
			return &"ACT_CROUCHING"
		LibSM64.ACT_START_CROUCHING:
			return &"ACT_START_CROUCHING"
		LibSM64.ACT_STOP_CROUCHING:
			return &"ACT_STOP_CROUCHING"
		LibSM64.ACT_START_CRAWLING:
			return &"ACT_START_CRAWLING"
		LibSM64.ACT_STOP_CRAWLING:
			return &"ACT_STOP_CRAWLING"
		LibSM64.ACT_SLIDE_KICK_SLIDE_STOP:
			return &"ACT_SLIDE_KICK_SLIDE_STOP"
		LibSM64.ACT_SHOCKWAVE_BOUNCE:
			return &"ACT_SHOCKWAVE_BOUNCE"
		LibSM64.ACT_FIRST_PERSON:
			return &"ACT_FIRST_PERSON"
		LibSM64.ACT_BACKFLIP_LAND_STOP:
			return &"ACT_BACKFLIP_LAND_STOP"
		LibSM64.ACT_JUMP_LAND_STOP:
			return &"ACT_JUMP_LAND_STOP"
		LibSM64.ACT_DOUBLE_JUMP_LAND_STOP:
			return &"ACT_DOUBLE_JUMP_LAND_STOP"
		LibSM64.ACT_FREEFALL_LAND_STOP:
			return &"ACT_FREEFALL_LAND_STOP"
		LibSM64.ACT_SIDE_FLIP_LAND_STOP:
			return &"ACT_SIDE_FLIP_LAND_STOP"
		LibSM64.ACT_HOLD_JUMP_LAND_STOP:
			return &"ACT_HOLD_JUMP_LAND_STOP"
		LibSM64.ACT_HOLD_FREEFALL_LAND_STOP:
			return &"ACT_HOLD_FREEFALL_LAND_STOP"
		LibSM64.ACT_AIR_THROW_LAND:
			return &"ACT_AIR_THROW_LAND"
		LibSM64.ACT_TWIRL_LAND:
			return &"ACT_TWIRL_LAND"
		LibSM64.ACT_LAVA_BOOST_LAND:
			return &"ACT_LAVA_BOOST_LAND"
		LibSM64.ACT_TRIPLE_JUMP_LAND_STOP:
			return &"ACT_TRIPLE_JUMP_LAND_STOP"
		LibSM64.ACT_LONG_JUMP_LAND_STOP:
			return &"ACT_LONG_JUMP_LAND_STOP"
		LibSM64.ACT_GROUND_POUND_LAND:
			return &"ACT_GROUND_POUND_LAND"
		LibSM64.ACT_BRAKING_STOP:
			return &"ACT_BRAKING_STOP"
		LibSM64.ACT_BUTT_SLIDE_STOP:
			return &"ACT_BUTT_SLIDE_STOP"
		LibSM64.ACT_HOLD_BUTT_SLIDE_STOP:
			return &"ACT_HOLD_BUTT_SLIDE_STOP"
		LibSM64.ACT_WALKING:
			return &"ACT_WALKING"
		LibSM64.ACT_HOLD_WALKING:
			return &"ACT_HOLD_WALKING"
		LibSM64.ACT_TURNING_AROUND:
			return &"ACT_TURNING_AROUND"
		LibSM64.ACT_FINISH_TURNING_AROUND:
			return &"ACT_FINISH_TURNING_AROUND"
		LibSM64.ACT_BRAKING:
			return &"ACT_BRAKING"
		LibSM64.ACT_RIDING_SHELL_GROUND:
			return &"ACT_RIDING_SHELL_GROUND"
		LibSM64.ACT_HOLD_HEAVY_WALKING:
			return &"ACT_HOLD_HEAVY_WALKING"
		LibSM64.ACT_CRAWLING:
			return &"ACT_CRAWLING"
		LibSM64.ACT_BURNING_GROUND:
			return &"ACT_BURNING_GROUND"
		LibSM64.ACT_DECELERATING:
			return &"ACT_DECELERATING"
		LibSM64.ACT_HOLD_DECELERATING:
			return &"ACT_HOLD_DECELERATING"
		LibSM64.ACT_BEGIN_SLIDING:
			return &"ACT_BEGIN_SLIDING"
		LibSM64.ACT_HOLD_BEGIN_SLIDING:
			return &"ACT_HOLD_BEGIN_SLIDING"
		LibSM64.ACT_BUTT_SLIDE:
			return &"ACT_BUTT_SLIDE"
		LibSM64.ACT_STOMACH_SLIDE:
			return &"ACT_STOMACH_SLIDE"
		LibSM64.ACT_HOLD_BUTT_SLIDE:
			return &"ACT_HOLD_BUTT_SLIDE"
		LibSM64.ACT_HOLD_STOMACH_SLIDE:
			return &"ACT_HOLD_STOMACH_SLIDE"
		LibSM64.ACT_DIVE_SLIDE:
			return &"ACT_DIVE_SLIDE"
		LibSM64.ACT_MOVE_PUNCHING:
			return &"ACT_MOVE_PUNCHING"
		LibSM64.ACT_CROUCH_SLIDE:
			return &"ACT_CROUCH_SLIDE"
		LibSM64.ACT_SLIDE_KICK_SLIDE:
			return &"ACT_SLIDE_KICK_SLIDE"
		LibSM64.ACT_HARD_BACKWARD_GROUND_KB:
			return &"ACT_HARD_BACKWARD_GROUND_KB"
		LibSM64.ACT_HARD_FORWARD_GROUND_KB:
			return &"ACT_HARD_FORWARD_GROUND_KB"
		LibSM64.ACT_BACKWARD_GROUND_KB:
			return &"ACT_BACKWARD_GROUND_KB"
		LibSM64.ACT_FORWARD_GROUND_KB:
			return &"ACT_FORWARD_GROUND_KB"
		LibSM64.ACT_SOFT_BACKWARD_GROUND_KB:
			return &"ACT_SOFT_BACKWARD_GROUND_KB"
		LibSM64.ACT_SOFT_FORWARD_GROUND_KB:
			return &"ACT_SOFT_FORWARD_GROUND_KB"
		LibSM64.ACT_GROUND_BONK:
			return &"ACT_GROUND_BONK"
		LibSM64.ACT_DEATH_EXIT_LAND:
			return &"ACT_DEATH_EXIT_LAND"
		LibSM64.ACT_JUMP_LAND:
			return &"ACT_JUMP_LAND"
		LibSM64.ACT_FREEFALL_LAND:
			return &"ACT_FREEFALL_LAND"
		LibSM64.ACT_DOUBLE_JUMP_LAND:
			return &"ACT_DOUBLE_JUMP_LAND"
		LibSM64.ACT_SIDE_FLIP_LAND:
			return &"ACT_SIDE_FLIP_LAND"
		LibSM64.ACT_HOLD_JUMP_LAND:
			return &"ACT_HOLD_JUMP_LAND"
		LibSM64.ACT_HOLD_FREEFALL_LAND:
			return &"ACT_HOLD_FREEFALL_LAND"
		LibSM64.ACT_QUICKSAND_JUMP_LAND:
			return &"ACT_QUICKSAND_JUMP_LAND"
		LibSM64.ACT_HOLD_QUICKSAND_JUMP_LAND:
			return &"ACT_HOLD_QUICKSAND_JUMP_LAND"
		LibSM64.ACT_TRIPLE_JUMP_LAND:
			return &"ACT_TRIPLE_JUMP_LAND"
		LibSM64.ACT_LONG_JUMP_LAND:
			return &"ACT_LONG_JUMP_LAND"
		LibSM64.ACT_BACKFLIP_LAND:
			return &"ACT_BACKFLIP_LAND"
		LibSM64.ACT_JUMP:
			return &"ACT_JUMP"
		LibSM64.ACT_DOUBLE_JUMP:
			return &"ACT_DOUBLE_JUMP"
		LibSM64.ACT_TRIPLE_JUMP:
			return &"ACT_TRIPLE_JUMP"
		LibSM64.ACT_BACKFLIP:
			return &"ACT_BACKFLIP"
		LibSM64.ACT_STEEP_JUMP:
			return &"ACT_STEEP_JUMP"
		LibSM64.ACT_WALL_KICK_AIR:
			return &"ACT_WALL_KICK_AIR"
		LibSM64.ACT_SIDE_FLIP:
			return &"ACT_SIDE_FLIP"
		LibSM64.ACT_LONG_JUMP:
			return &"ACT_LONG_JUMP"
		LibSM64.ACT_WATER_JUMP:
			return &"ACT_WATER_JUMP"
		LibSM64.ACT_DIVE:
			return &"ACT_DIVE"
		LibSM64.ACT_FREEFALL:
			return &"ACT_FREEFALL"
		LibSM64.ACT_TOP_OF_POLE_JUMP:
			return &"ACT_TOP_OF_POLE_JUMP"
		LibSM64.ACT_BUTT_SLIDE_AIR:
			return &"ACT_BUTT_SLIDE_AIR"
		LibSM64.ACT_FLYING_TRIPLE_JUMP:
			return &"ACT_FLYING_TRIPLE_JUMP"
		LibSM64.ACT_SHOT_FROM_CANNON:
			return &"ACT_SHOT_FROM_CANNON"
		LibSM64.ACT_FLYING:
			return &"ACT_FLYING"
		LibSM64.ACT_RIDING_SHELL_JUMP:
			return &"ACT_RIDING_SHELL_JUMP"
		LibSM64.ACT_RIDING_SHELL_FALL:
			return &"ACT_RIDING_SHELL_FALL"
		LibSM64.ACT_VERTICAL_WIND:
			return &"ACT_VERTICAL_WIND"
		LibSM64.ACT_HOLD_JUMP:
			return &"ACT_HOLD_JUMP"
		LibSM64.ACT_HOLD_FREEFALL:
			return &"ACT_HOLD_FREEFALL"
		LibSM64.ACT_HOLD_BUTT_SLIDE_AIR:
			return &"ACT_HOLD_BUTT_SLIDE_AIR"
		LibSM64.ACT_HOLD_WATER_JUMP:
			return &"ACT_HOLD_WATER_JUMP"
		LibSM64.ACT_TWIRLING:
			return &"ACT_TWIRLING"
		LibSM64.ACT_FORWARD_ROLLOUT:
			return &"ACT_FORWARD_ROLLOUT"
		LibSM64.ACT_AIR_HIT_WALL:
			return &"ACT_AIR_HIT_WALL"
		LibSM64.ACT_RIDING_HOOT:
			return &"ACT_RIDING_HOOT"
		LibSM64.ACT_GROUND_POUND:
			return &"ACT_GROUND_POUND"
		LibSM64.ACT_SLIDE_KICK:
			return &"ACT_SLIDE_KICK"
		LibSM64.ACT_AIR_THROW:
			return &"ACT_AIR_THROW"
		LibSM64.ACT_JUMP_KICK:
			return &"ACT_JUMP_KICK"
		LibSM64.ACT_BACKWARD_ROLLOUT:
			return &"ACT_BACKWARD_ROLLOUT"
		LibSM64.ACT_CRAZY_BOX_BOUNCE:
			return &"ACT_CRAZY_BOX_BOUNCE"
		LibSM64.ACT_SPECIAL_TRIPLE_JUMP:
			return &"ACT_SPECIAL_TRIPLE_JUMP"
		LibSM64.ACT_BACKWARD_AIR_KB:
			return &"ACT_BACKWARD_AIR_KB"
		LibSM64.ACT_FORWARD_AIR_KB:
			return &"ACT_FORWARD_AIR_KB"
		LibSM64.ACT_HARD_FORWARD_AIR_KB:
			return &"ACT_HARD_FORWARD_AIR_KB"
		LibSM64.ACT_HARD_BACKWARD_AIR_KB:
			return &"ACT_HARD_BACKWARD_AIR_KB"
		LibSM64.ACT_BURNING_JUMP:
			return &"ACT_BURNING_JUMP"
		LibSM64.ACT_BURNING_FALL:
			return &"ACT_BURNING_FALL"
		LibSM64.ACT_SOFT_BONK:
			return &"ACT_SOFT_BONK"
		LibSM64.ACT_LAVA_BOOST:
			return &"ACT_LAVA_BOOST"
		LibSM64.ACT_GETTING_BLOWN:
			return &"ACT_GETTING_BLOWN"
		LibSM64.ACT_THROWN_FORWARD:
			return &"ACT_THROWN_FORWARD"
		LibSM64.ACT_THROWN_BACKWARD:
			return &"ACT_THROWN_BACKWARD"
		LibSM64.ACT_WATER_IDLE:
			return &"ACT_WATER_IDLE"
		LibSM64.ACT_HOLD_WATER_IDLE:
			return &"ACT_HOLD_WATER_IDLE"
		LibSM64.ACT_WATER_ACTION_END:
			return &"ACT_WATER_ACTION_END"
		LibSM64.ACT_HOLD_WATER_ACTION_END:
			return &"ACT_HOLD_WATER_ACTION_END"
		LibSM64.ACT_DROWNING:
			return &"ACT_DROWNING"
		LibSM64.ACT_BACKWARD_WATER_KB:
			return &"ACT_BACKWARD_WATER_KB"
		LibSM64.ACT_FORWARD_WATER_KB:
			return &"ACT_FORWARD_WATER_KB"
		LibSM64.ACT_WATER_DEATH:
			return &"ACT_WATER_DEATH"
		LibSM64.ACT_WATER_SHOCKED:
			return &"ACT_WATER_SHOCKED"
		LibSM64.ACT_BREASTSTROKE:
			return &"ACT_BREASTSTROKE"
		LibSM64.ACT_SWIMMING_END:
			return &"ACT_SWIMMING_END"
		LibSM64.ACT_FLUTTER_KICK:
			return &"ACT_FLUTTER_KICK"
		LibSM64.ACT_HOLD_BREASTSTROKE:
			return &"ACT_HOLD_BREASTSTROKE"
		LibSM64.ACT_HOLD_SWIMMING_END:
			return &"ACT_HOLD_SWIMMING_END"
		LibSM64.ACT_HOLD_FLUTTER_KICK:
			return &"ACT_HOLD_FLUTTER_KICK"
		LibSM64.ACT_WATER_SHELL_SWIMMING:
			return &"ACT_WATER_SHELL_SWIMMING"
		LibSM64.ACT_WATER_THROW:
			return &"ACT_WATER_THROW"
		LibSM64.ACT_WATER_PUNCH:
			return &"ACT_WATER_PUNCH"
		LibSM64.ACT_WATER_PLUNGE:
			return &"ACT_WATER_PLUNGE"
		LibSM64.ACT_CAUGHT_IN_WHIRLPOOL:
			return &"ACT_CAUGHT_IN_WHIRLPOOL"
		LibSM64.ACT_METAL_WATER_STANDING:
			return &"ACT_METAL_WATER_STANDING"
		LibSM64.ACT_HOLD_METAL_WATER_STANDING:
			return &"ACT_HOLD_METAL_WATER_STANDING"
		LibSM64.ACT_METAL_WATER_WALKING:
			return &"ACT_METAL_WATER_WALKING"
		LibSM64.ACT_HOLD_METAL_WATER_WALKING:
			return &"ACT_HOLD_METAL_WATER_WALKING"
		LibSM64.ACT_METAL_WATER_FALLING:
			return &"ACT_METAL_WATER_FALLING"
		LibSM64.ACT_HOLD_METAL_WATER_FALLING:
			return &"ACT_HOLD_METAL_WATER_FALLING"
		LibSM64.ACT_METAL_WATER_FALL_LAND:
			return &"ACT_METAL_WATER_FALL_LAND"
		LibSM64.ACT_HOLD_METAL_WATER_FALL_LAND:
			return &"ACT_HOLD_METAL_WATER_FALL_LAND"
		LibSM64.ACT_METAL_WATER_JUMP:
			return &"ACT_METAL_WATER_JUMP"
		LibSM64.ACT_HOLD_METAL_WATER_JUMP:
			return &"ACT_HOLD_METAL_WATER_JUMP"
		LibSM64.ACT_METAL_WATER_JUMP_LAND:
			return &"ACT_METAL_WATER_JUMP_LAND"
		LibSM64.ACT_HOLD_METAL_WATER_JUMP_LAND:
			return &"ACT_HOLD_METAL_WATER_JUMP_LAND"
		LibSM64.ACT_DISAPPEARED:
			return &"ACT_DISAPPEARED"
		LibSM64.ACT_INTRO_CUTSCENE:
			return &"ACT_INTRO_CUTSCENE"
		LibSM64.ACT_STAR_DANCE_EXIT:
			return &"ACT_STAR_DANCE_EXIT"
		LibSM64.ACT_STAR_DANCE_WATER:
			return &"ACT_STAR_DANCE_WATER"
		LibSM64.ACT_FALL_AFTER_STAR_GRAB:
			return &"ACT_FALL_AFTER_STAR_GRAB"
		LibSM64.ACT_READING_AUTOMATIC_DIALOG:
			return &"ACT_READING_AUTOMATIC_DIALOG"
		LibSM64.ACT_READING_NPC_DIALOG:
			return &"ACT_READING_NPC_DIALOG"
		LibSM64.ACT_STAR_DANCE_NO_EXIT:
			return &"ACT_STAR_DANCE_NO_EXIT"
		LibSM64.ACT_READING_SIGN:
			return &"ACT_READING_SIGN"
		LibSM64.ACT_JUMBO_STAR_CUTSCENE:
			return &"ACT_JUMBO_STAR_CUTSCENE"
		LibSM64.ACT_WAITING_FOR_DIALOG:
			return &"ACT_WAITING_FOR_DIALOG"
		LibSM64.ACT_DEBUG_FREE_MOVE:
			return &"ACT_DEBUG_FREE_MOVE"
		LibSM64.ACT_STANDING_DEATH:
			return &"ACT_STANDING_DEATH"
		LibSM64.ACT_QUICKSAND_DEATH:
			return &"ACT_QUICKSAND_DEATH"
		LibSM64.ACT_ELECTROCUTION:
			return &"ACT_ELECTROCUTION"
		LibSM64.ACT_SUFFOCATION:
			return &"ACT_SUFFOCATION"
		LibSM64.ACT_DEATH_ON_STOMACH:
			return &"ACT_DEATH_ON_STOMACH"
		LibSM64.ACT_DEATH_ON_BACK:
			return &"ACT_DEATH_ON_BACK"
		LibSM64.ACT_EATEN_BY_BUBBA:
			return &"ACT_EATEN_BY_BUBBA"
		LibSM64.ACT_END_PEACH_CUTSCENE:
			return &"ACT_END_PEACH_CUTSCENE"
		LibSM64.ACT_CREDITS_CUTSCENE:
			return &"ACT_CREDITS_CUTSCENE"
		LibSM64.ACT_END_WAVING_CUTSCENE:
			return &"ACT_END_WAVING_CUTSCENE"
		LibSM64.ACT_PULLING_DOOR:
			return &"ACT_PULLING_DOOR"
		LibSM64.ACT_PUSHING_DOOR:
			return &"ACT_PUSHING_DOOR"
		LibSM64.ACT_WARP_DOOR_SPAWN:
			return &"ACT_WARP_DOOR_SPAWN"
		LibSM64.ACT_EMERGE_FROM_PIPE:
			return &"ACT_EMERGE_FROM_PIPE"
		LibSM64.ACT_SPAWN_SPIN_AIRBORNE:
			return &"ACT_SPAWN_SPIN_AIRBORNE"
		LibSM64.ACT_SPAWN_SPIN_LANDING:
			return &"ACT_SPAWN_SPIN_LANDING"
		LibSM64.ACT_EXIT_AIRBORNE:
			return &"ACT_EXIT_AIRBORNE"
		LibSM64.ACT_EXIT_LAND_SAVE_DIALOG:
			return &"ACT_EXIT_LAND_SAVE_DIALOG"
		LibSM64.ACT_DEATH_EXIT:
			return &"ACT_DEATH_EXIT"
		LibSM64.ACT_UNUSED_DEATH_EXIT:
			return &"ACT_UNUSED_DEATH_EXIT"
		LibSM64.ACT_FALLING_DEATH_EXIT:
			return &"ACT_FALLING_DEATH_EXIT"
		LibSM64.ACT_SPECIAL_EXIT_AIRBORNE:
			return &"ACT_SPECIAL_EXIT_AIRBORNE"
		LibSM64.ACT_SPECIAL_DEATH_EXIT:
			return &"ACT_SPECIAL_DEATH_EXIT"
		LibSM64.ACT_FALLING_EXIT_AIRBORNE:
			return &"ACT_FALLING_EXIT_AIRBORNE"
		LibSM64.ACT_UNLOCKING_KEY_DOOR:
			return &"ACT_UNLOCKING_KEY_DOOR"
		LibSM64.ACT_UNLOCKING_STAR_DOOR:
			return &"ACT_UNLOCKING_STAR_DOOR"
		LibSM64.ACT_ENTERING_STAR_DOOR:
			return &"ACT_ENTERING_STAR_DOOR"
		LibSM64.ACT_SPAWN_NO_SPIN_AIRBORNE:
			return &"ACT_SPAWN_NO_SPIN_AIRBORNE"
		LibSM64.ACT_SPAWN_NO_SPIN_LANDING:
			return &"ACT_SPAWN_NO_SPIN_LANDING"
		LibSM64.ACT_BBH_ENTER_JUMP:
			return &"ACT_BBH_ENTER_JUMP"
		LibSM64.ACT_BBH_ENTER_SPIN:
			return &"ACT_BBH_ENTER_SPIN"
		LibSM64.ACT_TELEPORT_FADE_OUT:
			return &"ACT_TELEPORT_FADE_OUT"
		LibSM64.ACT_TELEPORT_FADE_IN:
			return &"ACT_TELEPORT_FADE_IN"
		LibSM64.ACT_SHOCKED:
			return &"ACT_SHOCKED"
		LibSM64.ACT_SQUISHED:
			return &"ACT_SQUISHED"
		LibSM64.ACT_HEAD_STUCK_IN_GROUND:
			return &"ACT_HEAD_STUCK_IN_GROUND"
		LibSM64.ACT_BUTT_STUCK_IN_GROUND:
			return &"ACT_BUTT_STUCK_IN_GROUND"
		LibSM64.ACT_FEET_STUCK_IN_GROUND:
			return &"ACT_FEET_STUCK_IN_GROUND"
		LibSM64.ACT_PUTTING_ON_CAP:
			return &"ACT_PUTTING_ON_CAP"
		LibSM64.ACT_HOLDING_POLE:
			return &"ACT_HOLDING_POLE"
		LibSM64.ACT_GRAB_POLE_SLOW:
			return &"ACT_GRAB_POLE_SLOW"
		LibSM64.ACT_GRAB_POLE_FAST:
			return &"ACT_GRAB_POLE_FAST"
		LibSM64.ACT_CLIMBING_POLE:
			return &"ACT_CLIMBING_POLE"
		LibSM64.ACT_TOP_OF_POLE_TRANSITION:
			return &"ACT_TOP_OF_POLE_TRANSITION"
		LibSM64.ACT_TOP_OF_POLE:
			return &"ACT_TOP_OF_POLE"
		LibSM64.ACT_START_HANGING:
			return &"ACT_START_HANGING"
		LibSM64.ACT_HANGING:
			return &"ACT_HANGING"
		LibSM64.ACT_HANG_MOVING:
			return &"ACT_HANG_MOVING"
		LibSM64.ACT_LEDGE_GRAB:
			return &"ACT_LEDGE_GRAB"
		LibSM64.ACT_LEDGE_CLIMB_SLOW_1:
			return &"ACT_LEDGE_CLIMB_SLOW_1"
		LibSM64.ACT_LEDGE_CLIMB_SLOW_2:
			return &"ACT_LEDGE_CLIMB_SLOW_2"
		LibSM64.ACT_LEDGE_CLIMB_DOWN:
			return &"ACT_LEDGE_CLIMB_DOWN"
		LibSM64.ACT_LEDGE_CLIMB_FAST:
			return &"ACT_LEDGE_CLIMB_FAST"
		LibSM64.ACT_GRABBED:
			return &"ACT_GRABBED"
		LibSM64.ACT_IN_CANNON:
			return &"ACT_IN_CANNON"
		LibSM64.ACT_TORNADO_TWIRLING:
			return &"ACT_TORNADO_TWIRLING"
		LibSM64.ACT_PUNCHING:
			return &"ACT_PUNCHING"
		LibSM64.ACT_PICKING_UP:
			return &"ACT_PICKING_UP"
		LibSM64.ACT_DIVE_PICKING_UP:
			return &"ACT_DIVE_PICKING_UP"
		LibSM64.ACT_STOMACH_SLIDE_STOP:
			return &"ACT_STOMACH_SLIDE_STOP"
		LibSM64.ACT_PLACING_DOWN:
			return &"ACT_PLACING_DOWN"
		LibSM64.ACT_THROWING:
			return &"ACT_THROWING"
		LibSM64.ACT_HEAVY_THROW:
			return &"ACT_HEAVY_THROW"
		LibSM64.ACT_PICKING_UP_BOWSER:
			return &"ACT_PICKING_UP_BOWSER"
		LibSM64.ACT_HOLDING_BOWSER:
			return &"ACT_HOLDING_BOWSER"
		LibSM64.ACT_RELEASING_BOWSER:
			return &"ACT_RELEASING_BOWSER"
		_:
			return &"ACT_UNKNOWN"
