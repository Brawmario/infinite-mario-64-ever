@icon("res://addons/libsm64-godot/mario/mario-godot.svg")
class_name SM64Mario
extends Node3D

@onready var audio_stream_player = $AudioStreamPlayer
@onready var mario_collision := $MarioCollision as Area3D
@onready var collision_cylinder := $MarioCollision/CollisionCylinder.shape as CylinderShape3D

## Node that instances a Mario into a scenario

## Value that represents Mario being at full health
const FULL_HEALTH = 0x0880
## Value that represents one health wedge
const HEALTH_WEDGE = 0x0100
## Special Caps mask
const SPECIAL_CAPS = SM64Mario.Caps.VANISH | SM64Mario.Caps.METAL | SM64Mario.Caps.WING

enum TickProcessMode {
	PHYSICS, ## Process tick during the physics process.
	IDLE,    ## Process tick during the idle process.
}

enum Caps {
	NORMAL = 0x1,
	VANISH = 0x2,
	METAL  = 0x4,
	WING   = 0x8,
}

signal action_changed(action: int)
signal flags_changed(flags: int)
signal health_changed(health: int)
signal health_wedges_changed(health_wedges: int)
# signal lives_changed(lives: int)

## Camera instance that follows Mario
@export var camera: Camera3D

## The process notification in which to tick.
@export var tick_process_mode := TickProcessMode.IDLE:
	set(value):
		match value:
			TickProcessMode.PHYSICS:
				set_physics_process(true)
				set_process(false)
				tick_process_mode = value
			TickProcessMode.IDLE:
				set_physics_process(false)
				set_process(true)
				tick_process_mode = value

@export_group("Input Actions")
## Action equivalent to pushing the joystick to the left
@export var stick_left := &"mario_stick_left"
## Action equivalent to pushing the joystick to the right
@export var stick_right := &"mario_stick_right"
## Action equivalent to pushing the joystick upwards
@export var stick_up := &"mario_stick_up"
## Action equivalent to pushing the joystick downwards
@export var stick_down := &"mario_stick_down"
## Action equivalent to pushing the A button
@export var input_a := &"mario_a"
## Action equivalent to pushing the B button
@export var input_b := &"mario_b"
## Action equivalent to pushing the Z button
@export var input_z := &"mario_z"

var _internal := SM64MarioInternal.new()

var _action := 0x0:
	set(value):
		_action = value
		action_changed.emit(_action)
## Mario's action flags
var action: int:
	get:
		return _action
	set(value):
		if _id < 0:
			return
		_internal.set_action(value)
		_action = value
## Mario's action as StringName
var action_name: StringName:
	get:
		return SM64MarioAction.to_action_name(_action)

var _flags := 0x0:
	set(value):
		_flags = value
		flags_changed.emit(_flags)
## Mario's state flags
var flags: int:
	get:
		return _flags
	set(value):
		if _id < 0:
			return
		_internal.set_state(value)
		_flags = value

var _velocity := Vector3()
## Mario's velocity in the libsm64 world
var velocity: Vector3:
	get:
		return _velocity
	set(value):
		if _id < 0:
			return
		_internal.set_velocity(value)
		_velocity = value

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
		_internal.set_face_angle(value)
		_face_angle = value

var _health := FULL_HEALTH:
	set(value):
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
		_internal.set_health(value)
		_health = value

## Mario's amount of health wedges
var health_wedges: int:
	get:
		return _health >> 0x8 if _health > 0 else 0x0
	set(value):
		if _id < 0:
			return
		var new_health := value << 0x8 if value > 0 else 0x0
		_internal.set_health(new_health)
		_health = new_health

var _invicibility_time := 0.0
## Mario's invincibility time in seconds
var invicibility_time: float:
	get:
		return _invicibility_time
	set(value):
		if _id < 0:
			return
		_internal.set_invincibility(value)
		_invicibility_time = value

# var hurt_counter := 0

#var _lives := 4:
#	set(value):
#		_lives = value
#		lives_changed.emit(_lives)
## Mario's lives
#var lives: int:
#	get:
#		return _lives
#	set(value):
#		if _id < 0:
#			return
#		_internal.set_lives(value)
#		_lives = value

## Mario's water level
var water_level := -100000.0:
	set(value):
		if _id < 0:
			return
		_internal.set_water_level(value)
		water_level = value

## Mario's gas level
var gas_level := -100000.0:
	set(value):
		if _id < 0:
			return
		_internal.set_gas_level(value)
		gas_level = value

var _mesh_instance: MeshInstance3D
var _mesh: ArrayMesh
var _default_material := preload("res://addons/libsm64-godot/mario/mario_default_material.tres") as StandardMaterial3D
var _vanish_material := preload("res://addons/libsm64-godot/mario/mario_vanish_material.tres") as StandardMaterial3D
var _metal_material := preload("res://addons/libsm64-godot/mario/mario_metal_material.tres") as StandardMaterial3D
var _wing_material := preload("res://addons/libsm64-godot/mario/mario_wing_material.tres") as StandardMaterial3D
var _material: StandardMaterial3D
var _id := -1
# FIXME: SM64Input stopped working in beta 15
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
var _mario_input := {}
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
	
	if tick_process_mode == TickProcessMode.PHYSICS:
		set_process(false)
	else:
		set_physics_process(false)

@onready var star_arrow := $star_arrow as MeshInstance3D
@onready var star_mesh := $StarMesh as MeshInstance3D
@onready var checkpoint_helper = $CheckpointHelper

func _process(delta: float) -> void:
	_tick(delta)
	RenderingServer.global_shader_parameter_set("camera_angles", camera.rotation)
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
	if hide_hud:
		seed_label.visible = false
		level_timer.visible = false
		hint_text.visible = false
		hint_text_2.visible = false
		hint_text_3.visible = false
		coin_counter.visible = false
		power_disp.visible = false
		checkpoint_helper.visible = false
	#DebugDraw3D.draw_sphere(position, 0.1, Color(1, 1, 1), delta)


func _physics_process(delta: float) -> void:
	_tick(delta)


## Create Mario (requires initializing the libsm64 via the global_init function)
func create() -> void:
	if SM64Global.is_init():
		if _id >= 0:
			delete()
		_id = _internal.mario_create(global_position, global_rotation)
		if _id < 0:
			return

		if not _default_material.detail_albedo:
			var detail_texture := SM64Global.get_mario_image_texture() as ImageTexture
			_default_material.detail_albedo = detail_texture
			_wing_material.detail_albedo = detail_texture
			_metal_material.detail_albedo = detail_texture
			_vanish_material.detail_albedo = detail_texture


## Delete mario inside the libsm64 world
func delete() -> void:
	if _id < 0:
		return
	_internal.mario_delete()
	_id = -1


## Teleport mario in the libsm64 world
func teleport(to_global_position: Vector3) -> void:
	if _id < 0:
		return
	_internal.set_position(to_global_position)
	global_position = to_global_position


## Set angle of mario in the libsm64 world
func set_angle(to_global_rotation: Vector3) -> void:
	if _id < 0:
		return
	_internal.set_angle(to_global_rotation)
	# global_rotation = to_global_rotation


## Set Mario's forward velocity in the libsm64 world
func set_forward_velocity(velocity: float) -> void:
	if _id < 0:
		return
	_internal.set_forward_velocity(velocity)


## Override the floor properties
# func set_floor_override(surface_properties: SM64SurfaceProperties) -> void:
# 	if _id < 0:
# 		return
# 	_internal.set_floor_override(surface_properties)


## Reset overriden floor properties
# func reset_floor_override() -> void:
# 	if _id < 0:
# 		return
# 	_internal.reset_floor_override()


## Make Mario take damage in amount of health wedges from a source position
func take_damage(damage: int, source_position: Vector3, big_knockback := false) -> void:
	if _id < 0:
		return
	_internal.take_damage(damage, source_position, big_knockback)


## Heal Mario a specific amount of wedges
func heal(wedges: int) -> void:
	if _id < 0:
		return
	_internal.heal(wedges)


## Kill Mario
func kill() -> void:
	if _id < 0:
		return
	_internal.kill()


## Equip special cap (see SM64Mario.Caps for values)
func interact_cap(cap: Caps, cap_time := 0.0, play_music := true) -> void:
	if _id < 0:
		return
	_internal.interact_cap(cap, cap_time, play_music)


## Extend current special cap time
func extend_cap(cap_time: float) -> void:
	if _id < 0:
		return
	_internal.extend_cap(cap_time)


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
	_internal.set_action(SM64MarioAction.FALL_AFTER_STAR_GRAB)
	audio_stream_player.play()
	var saysound_playback : AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	saysound_playback.play_stream(preload("res://mario/enter_painting.WAV"), 0, -8, 1.0)
	await get_tree().create_timer(0.5).timeout
	saysound_playback.play_stream(preload("res://mario/star_get.wav"), 0, 0, 1.0)
	#_internal.set_action(SM64MarioAction.FALL_AFTER_STAR_GRAB)
	set_angle((camera.position - position).normalized())
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
	action = SM64MarioAction.SPAWN_SPIN_AIRBORNE
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
	set_angle(Vector3.FORWARD.rotated(Vector3.UP, checkpoint_facing))
	velocity = Vector3.ZERO
	_velocity = Vector3.ZERO
	set_forward_velocity(0)
	_internal.set_velocity(Vector3.ZERO)
	_internal.set_face_angle(checkpoint_facing)
	_internal.set_forward_velocity(0.0)
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_spinning_heart.wav"))
	_internal.set_action(SM64MarioAction.IDLE)

var time_since_start : float = 0
var view_stage_transform : Transform3D

func _calculate_gameplay_camera(delta : float):
	if Input.is_action_just_pressed("cam_stick_left"):
		_cam_rotation_target -= deg_to_rad(45)
	if Input.is_action_just_pressed("cam_stick_right"):
		_cam_rotation_target += deg_to_rad(45)
	
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
var gravity_add : float = 0.0
var gravity_set_time : int = 0

func _tick(delta: float) -> void:
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
	
	if _action == SM64MarioAction.STAR_DANCE_EXIT and !_paused and ready_to_play:
		hint_text_3.visible = true
		hint_text_2.visible = true
		if Input.is_action_just_pressed("mario_a"):
			_internal.set_action(SM64MarioAction.IDLE)
		if Input.is_action_just_pressed("mario_b"):
			_internal.set_action(SM64MarioAction.SPAWN_SPIN_AIRBORNE)
			SOGlobal.current_level_manager._create_mario_world()
			hint_text_3.visible = false
			hint_text_2.visible = false
	else:
		hint_text_3.visible = false
		hint_text_2.visible = false
	
	if _paused or !ready_to_play:
		seed_label.text = "Current Seed: " + str(SOGlobal.current_seed)
		seed_label.visible = true
		level_timer.visible = false
		checkpoint_helper.visible = true
	else:
		checkpoint_helper.visible = false
		seed_label.visible = false
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
		hint_text.visible = true
	
	if _paused:
		return
	
	#DebugDraw2D.set_text("ACTION", SM64MarioAction.to_action_name(_action))
	
	time_since_start += delta
	
	if Input.is_action_just_pressed("start_button"):
		var pause_menu = preload("res://mario/mario_pause_menu.tscn").instantiate()
		SOGlobal.add_child(pause_menu)
		_paused = true
		return
	
	_mario_input.stick = Input.get_vector(stick_left, stick_right, stick_up, stick_down, 0)
	_mario_input.stick.x = move_toward(_mario_input.stick.x, 0, 0.05)
	_mario_input.stick.y = move_toward(_mario_input.stick.y, 0, 0.05)
	_mario_input.stick = _mario_input.stick * 1.1
	if _mario_input.stick.length() > 1.0:
		_mario_input.stick = _mario_input.stick.normalized()
	#DebugDraw2D.set_text("INPUT", _mario_input.stick)
	var camera_input : Vector2 = Input.get_vector("cam_stick_left", "cam_stick_right", "cam_stick_up", "cam_stick_down")
	
	var look_direction := Vector2(0, 1).rotated(-_cam_rotation)
	_mario_input.cam_look = Vector2(look_direction.x, look_direction.y)
	if action == SM64MarioAction.STAR_DANCE_NO_EXIT or action == SM64MarioAction.FALL_AFTER_STAR_GRAB or action == SM64MarioAction.STAR_DANCE_EXIT:
		_mario_input.cam_look *= -1
	
	_mario_input.a = Input.is_action_pressed(input_a)
	_mario_input.b = Input.is_action_pressed(input_b)
	_mario_input.z = Input.is_action_pressed(input_z)
	
	
	var time_minus_start = Time.get_ticks_msec() - SOGlobal.level_start_time
	if !ready_to_play:
		if Input.is_action_just_pressed("mario_a"):
			SOGlobal.play_sound(preload("res://mario/enter_painting.WAV"))
			ready_to_play = true
			start_time = Time.get_ticks_msec()
			_respawn_mario()
		preview_cam_pitch += Input.get_axis(stick_up, stick_down) * delta * 90
		preview_cam_yaw += Input.get_axis(stick_left, stick_right) * delta * 90
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
	
	collision_cylinder.radius = 0.5
	
	#print(action & SM64MarioAction.FLAG_STATIONARY > 0)
	
	if action & SM64MarioAction.FLAG_STATIONARY > 0:
		if Input.is_action_just_pressed("dpad_up"):
			_create_checkpoint()
	
	match action:
		SM64MarioAction.SPAWN_SPIN_AIRBORNE:
			global_position = snapped(global_position, Vector3(0.5, 0, 0.5))
			#teleport(global_position)
			_velocity = _velocity * Vector3(0, 1, 0)
		SM64MarioAction.GROUND_POUND:
			collision_cylinder.radius = 1.25
	
	if Input.is_action_just_pressed("dpad_down") and checkpoint_flag and is_instance_valid(checkpoint_flag):
		_restore_mario_to_checkpoint()
		
	
	if Time.get_ticks_msec() > gravity_set_time + 10000:
		gravity_add = 0
	
	if gravity_add != 0:
		velocity += Vector3(0, gravity_add * delta, 0)
	
	var tick_output := _internal.tick(delta, _mario_input)
	
	#DebugDraw2D.set_text("POS", global_position)
	
	#_internal.set_action(SM64MarioAction.STAR_DANCE_NO_EXIT)
	
	global_position = tick_output.position as Vector3
	_velocity = tick_output.velocity as Vector3
	
	_face_angle = tick_output.face_angle as float
	
	var new_health := tick_output.health as float
	if new_health != _health:
		_health = new_health

	var new_action := tick_output.action as int
	if new_action != _action:
		_action = new_action

	var new_flags := tick_output.flags as int
	if new_flags != _flags:
		_flags = new_flags

	_invicibility_time = tick_output.invinc_timer as float
	# hurt_counter = tick_output.hurt_counter as int

	# var new_lives := tick_output.num_lives as int
	# if new_lives != _lives:
	# 	_lives = new_lives

	match _flags & SPECIAL_CAPS:
		SM64Mario.Caps.VANISH:
			_material = _vanish_material
		SM64Mario.Caps.METAL:
			_material = _metal_material
		SM64Mario.Caps.WING:
			_material = _wing_material
		_:
			_material = _default_material

	var mesh_array := tick_output.mesh_array as Array
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	_mesh_instance.set_surface_override_material(0, _material)
	
	if ready_to_play:
		_calculate_gameplay_camera(delta)
		var gameplay_camera_transform : Transform3D = camera.global_transform
		if false and time_since_start <= 1.0:
			var ratio : float = 1.0 - time_since_start
			ratio = ease(ratio, -2)
			camera.global_transform = camera.global_transform.interpolate_with(view_stage_transform, ratio)
