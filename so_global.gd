extends Node

var level_bounds : AABB = AABB()
var level_meshes : Array[LevelBlock] = []
var level_start_time : int = 0
var current_mario : LibSM64Mario
var current_level_manager
var current_seed : String
var block_material : ShaderMaterial
var sky_material := preload("res://mario/sky_material.tres") as ShaderMaterial
var global_sound := AudioStreamPlayer.new() as AudioStreamPlayer
var global_sound_stream := AudioStreamPolyphonic.new() as AudioStreamPolyphonic
var libsm64_sound := LibSM64AudioStreamPlayer.new()
var start_angle := 0.0
var save_data := MarioSaveFile.new()
var total_coins : int = 0
var main_star_pos : Vector3 = Vector3.ZERO
var restart_desired : bool = false
var inner_deadzone : float = 0.05
var outer_deadzone : float = 0.95
var flip_x : bool = true
var compat_renderer : bool = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"

func play_sound(inSound, volume : float = 0, pitch : float = 1) -> void:
	var playback : AudioStreamPlaybackPolyphonic = global_sound.get_stream_playback()
	playback.play_stream(inSound, 0, volume, pitch)

func generate_power_star(in_star_id : String, in_pos : Vector3, in_target_pos : Vector3 = Vector3.ZERO) -> PowerStar:
	var new_star : PowerStar = preload("res://mario/power_star.tscn").instantiate()
	new_star.star_gotten = save_data.is_star_collected(current_seed, in_star_id)
	print(new_star.star_gotten)
	new_star.position = in_pos
	new_star.star_id = in_star_id
	add_child(new_star)
	if in_target_pos != Vector3.ZERO:
		new_star.play_star_spawn_animation(in_target_pos)
	return new_star

func generate_cork_box_with_contents(in_pos : Vector3, contents : Array) -> CorkBox:
	var new_box : CorkBox = preload("res://mario/cork_block.tscn").instantiate()
	new_box.position = in_pos
	new_box.contained_items = contents
	add_child(new_box)
	return new_box
	#new_box.add_to_droplist()
	#var new_box : C

func generate_yellow_coin_at_pos(inPos : Vector3, in_drop_to_ground : bool = true, in_physics : bool = false, in_velocity : Vector3 = Vector3.ZERO) -> Coin:
	var new_coin := preload("res://mario/coin.tscn").instantiate() as Coin
	new_coin.position = inPos
	new_coin.velocity = in_velocity
	new_coin.drop_to_ground = in_drop_to_ground
	SOGlobal.add_child(new_coin)
	if in_physics:
		new_coin._set_physics_enabled(true)
	return new_coin

func generate_block_from_pos_and_size(inPos : Vector3, inSize : Vector3, north_slope : float = 0, east_slope : float = 0, south_slope : float = 0, west_slope : float = 0, in_parent = SOGlobal, move_mode : LevelBlock.move_type = LevelBlock.move_type.NONE, chatter : bool = false) -> LevelBlock:
	var new_block := LevelBlock.new()
	new_block.block_size = inSize
	var new_mesh : BoxMesh = BoxMesh.new()
	new_block.position = inPos
	new_mesh.size = inSize
	SOGlobal.level_bounds = SOGlobal.level_bounds.expand(new_block.position)
	var mesh_faces : PackedVector3Array = new_mesh.get_faces()
	var mesh_normals : PackedVector3Array = []
	mesh_normals.resize(mesh_faces.size())
	for i in range(mesh_faces.size()):
		if mesh_faces[i].y < 0:
			if mesh_faces[i].x > 0:
				mesh_faces[i] += Vector3(east_slope, 0, 0)
			else:
				mesh_faces[i] -= Vector3(west_slope, 0, 0)
			if mesh_faces[i].z > 0:
				mesh_faces[i] += Vector3(0, 0, north_slope)
			else:
				mesh_faces[i] -= Vector3(0, 0, south_slope)
	for i in range(mesh_faces.size()):
		match i % 3:
			0:
				var dir_one : Vector3 = (mesh_faces[i + 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i + 2] - mesh_faces[i])
				mesh_normals[i] = -dir_one.cross(dir_two).normalized()
			1:
				var dir_one : Vector3 = (mesh_faces[i - 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i + 1] - mesh_faces[i])
				mesh_normals[i] = dir_one.cross(dir_two).normalized()
			2:
				var dir_one : Vector3 = (mesh_faces[i - 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i - 2] - mesh_faces[i])
				mesh_normals[i] = dir_one.cross(dir_two).normalized()
		#DebugDraw3D.draw_arrow_line(mesh_faces[i] + new_block.position, mesh_faces[i] + mesh_normals[i] + new_block.position, Color(1, 0, 0), 0.25, true, 10)
	var arr_mesh : ArrayMesh = ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mesh_faces
	arrays[Mesh.ARRAY_NORMAL] = mesh_normals
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	new_block.mesh = arr_mesh
	new_block.material_override = block_material
	if in_parent != SOGlobal:
		new_block.movement_parent = in_parent
	new_block.current_move_type = move_mode
	add_child(new_block)
	var surface_properties := LibSM64SurfacePropertiesComponent.new()
	surface_properties.surface_properties = LibSM64SurfaceProperties.new()
	surface_properties.surface_properties.surface_type = LibSM64.SURFACE_DEFAULT
	new_block.add_child(surface_properties)
	new_block.set_instance_shader_parameter("fade_in", (float(Time.get_ticks_msec()) / 1000) + float(level_meshes.size()) * 0.01 + 0.2)
	new_block.set_instance_shader_parameter("spawn_dir", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
	new_block.set_instance_shader_parameter("spawn_pos", new_block.position)
	new_block.set_instance_shader_parameter("fade_in_distance", randf_range(2, 10))
	new_block.set_instance_shader_parameter("fade_in_duration", randf_range(0.3, 0.8))
	if chatter:
		new_block.set_instance_shader_parameter("fade_in_duration", 0.125)
		new_block.set_instance_shader_parameter("fade_in_distance", 0.0)
		new_block.set_instance_shader_parameter("fade_in", (float(Time.get_ticks_msec()) / 1000))
	var new_collider := StaticBody3D.new()
	var new_collider_shape := CollisionShape3D.new()
	var new_box_shape := arr_mesh.create_convex_shape(true, false)
	new_collider_shape.shape = new_box_shape
	new_collider.set_collision_layer_value(1, true)
	new_collider.set_collision_mask_value(1, true)

	new_block.add_child(new_collider)
	new_collider.add_child(new_collider_shape)

	level_meshes.append(new_block)
	return new_block


func generate_cylinder(inPos : Vector3, in_height : float, in_radius_bot : float, in_radius_top : float, in_parent = SOGlobal, move_mode : LevelBlock.move_type = LevelBlock.move_type.NONE, chatter : bool = false) -> LevelBlock:
	var new_block := LevelBlock.new()
	new_block.coin_surface = LevelBlock.coin_spawn_type.CIRCLE
	new_block.block_size = Vector3(in_radius_top, in_radius_bot, 0)
	var new_mesh : CylinderMesh = CylinderMesh.new()
	new_mesh.height = in_height
	new_mesh.bottom_radius = in_radius_bot
	new_mesh.top_radius = in_radius_top
	new_mesh.radial_segments = 16
	new_block.position = inPos
	SOGlobal.level_bounds = SOGlobal.level_bounds.expand(new_block.position)
	new_block.mesh = new_mesh
	new_block.material_override = block_material
	var surface_properties := LibSM64SurfacePropertiesComponent.new()
	surface_properties.surface_properties = LibSM64SurfaceProperties.new()
	surface_properties.surface_properties.surface_type = LibSM64.SURFACE_DEFAULT
	new_block.current_move_type = move_mode
	if in_parent != SOGlobal:
		new_block.movement_parent = in_parent
	add_child(new_block)
	new_block.add_child(surface_properties)
	new_block.set_instance_shader_parameter("fade_in", (float(Time.get_ticks_msec()) / 1000) + float(level_meshes.size()) * 0.01 + 0.2)
	new_block.set_instance_shader_parameter("spawn_dir", Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
	new_block.set_instance_shader_parameter("spawn_pos", new_block.position)
	new_block.set_instance_shader_parameter("fade_in_distance", randf_range(2, 10))
	new_block.set_instance_shader_parameter("fade_in_duration", randf_range(0.3, 0.8))
	if chatter:
		new_block.set_instance_shader_parameter("fade_in_duration", 0.125)
		new_block.set_instance_shader_parameter("fade_in_distance", 0.0)
		new_block.set_instance_shader_parameter("fade_in", (float(Time.get_ticks_msec()) / 1000))
	var new_collider := StaticBody3D.new()
	var new_collider_shape := CollisionShape3D.new()
	var new_collision_shape := new_mesh.create_convex_shape(true, false)
	new_collider_shape.shape = new_collision_shape
	new_collider.set_collision_layer_value(1, true)
	new_collider.set_collision_mask_value(1, true)

	new_block.add_child(new_collider)
	new_collider.add_child(new_collider_shape)

	level_meshes.append(new_block)
	return new_block

# save block structure:
# seed : string
# coins : int
# star_data : Dictionary{StarSaveData} with the star ID as the key

# star save data structure:
# star_id : string
# time : float


func _ready():
	add_child(global_sound)
	global_sound.stream = global_sound_stream
	global_sound.play()
	add_child(libsm64_sound)
	libsm64_sound.play()
	print("INITIAL BINDINGS!")
	for i in InputMap.get_actions().size():
		var action := InputMap.get_actions()[i]
		if action.begins_with("ui"):
			continue
		print(action)
		for k in InputMap.action_get_events(action).size():
			var event = InputMap.action_get_events(action)[k]
			print(event)
			print(event.device)
	save_data.load_game()

	if compat_renderer:
		block_material = load("res://mario/block_material_compat.tres")
	else:
		block_material = load("res://mario/block_material.tres")


var unfocused := false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SOGlobal.save_data.save_game()
		get_tree().quit()
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		unfocused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		unfocused = false
