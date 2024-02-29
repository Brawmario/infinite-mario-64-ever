class_name PowerStar extends Node3D

@onready var area_3d := $Area3D as Area3D
@onready var shape_cast_3d: = $ShapeCast3D as ShapeCast3D
@onready var star_mesh := $StarMesh as MeshInstance3D
@export var star_gotten : bool = false
var destroy_on_retry : bool = false
var star_id : String
var star_old_pos : Vector3
var star_target_pos : Vector3
var star_state : int = 0
var star_state_time : float = float(Time.get_ticks_msec()) * 0.001
var main_star : bool = false

func _ready():
	visible = false
	var new_star_mat := ShaderMaterial.new() as ShaderMaterial
	new_star_mat.shader = preload("res://EnvironmentMap.gdshader")
	new_star_mat.set_shader_parameter("albedo", Color(1.0, 0.75, 0.25, 1.0))
	new_star_mat.set_shader_parameter("albedo_texture", preload("res://mario/env_map_shiny_blurry.png"))
	if star_gotten:
		new_star_mat.set_shader_parameter("albedo", Color(0.05, 0.1, 0.3, 0.75))
		new_star_mat.set_shader_parameter("albedo_texture", preload("res://mario/env_map_balanced.png"))
	star_mesh.material_override = new_star_mat
	
	await get_tree().create_timer(0.1).timeout
	var intersecting = true
	while intersecting:
		shape_cast_3d.force_shapecast_update()
		if shape_cast_3d.is_colliding():
			position += Vector3.UP
		else:
			intersecting = false

var star_spawn_height_curve := preload("res://mario/star_spawn_height_curve.tres") as Curve
var star_spawn_horizontal_curve := preload("res://mario/star_spawn_horizontal_curve.tres") as Curve

func _process(delta):
	if main_star:
		SOGlobal.main_star_pos = global_position
	match star_state:
		0:
			rotation_degrees += Vector3(0, 180 * delta, 0)
		1:
			SOGlobal.current_mario._paused = true
			var look_basis : Basis = Basis.looking_at(position - SOGlobal.current_mario.camera.position, Vector3.UP)
			SOGlobal.current_mario.camera.basis = SOGlobal.current_mario.camera.basis.slerp(look_basis, delta * 12)
			visible = true
			rotation_degrees += Vector3(0, 360 * delta, 0)
			var cur_time : float = float(Time.get_ticks_msec()) * 0.001
			var ratio : float = (cur_time - star_state_time) * 0.333
			position.y = lerpf(star_old_pos.y, star_target_pos.y, star_spawn_height_curve.sample_baked(ratio))
			position.x = lerpf(star_old_pos.x, star_target_pos.x, star_spawn_horizontal_curve.sample_baked(ratio))
			position.z = lerpf(star_old_pos.z, star_target_pos.z, star_spawn_horizontal_curve.sample_baked(ratio))
			if ratio >= 1.0:
				star_state = 0
				star_state_time = cur_time
				SOGlobal.current_mario._paused = false
				_activate_star()

func play_star_spawn_animation(target_pos : Vector3):
	star_state = 1
	star_state_time = float(Time.get_ticks_msec()) * 0.001
	star_old_pos = position
	star_target_pos = target_pos
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_star_appears.wav"))
	area_3d.set_deferred("monitorable", false)
	area_3d.set_deferred("monitoring", false)

func _collect():
	area_3d.set_deferred("monitorable", false)
	area_3d.set_deferred("monitoring", false)
	visible = false
	star_gotten = true

func _activate_star():
	area_3d.set_deferred("monitorable", true)
	area_3d.set_deferred("monitoring", true)
	visible = true

func _respawn():
	await get_tree().create_timer(0.1).timeout
	if destroy_on_retry:
		queue_free()
		return
	area_3d.monitorable = true
	area_3d.monitoring = true
	visible = true
	if star_gotten:
		var shader_mat := star_mesh.get_active_material(0) as ShaderMaterial
		shader_mat.set_shader_parameter("albedo", Color(0.05, 0.1, 0.3, 0.75))
		shader_mat.set_shader_parameter("albedo_texture", preload("res://mario/env_map_balanced.png"))

func _on_area_3d_area_entered(area: Area3D):
	if !visible:
		return
	if area.get_parent() is SM64Mario:
		area.get_parent()._get_power_star(star_id)
		_collect()
	else:
		position += Vector3.UP
