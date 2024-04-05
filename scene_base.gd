extends Node3D

@onready var sm_64_mario := $RandomMario as SM64Mario
@onready var sm_64_static_surface_handler: Node = $SM64StaticSurfaceHandler
@onready var sm_64_surface_objects_handler: Node = $SM64SurfaceObjectsHandler
@onready var mesh_instance_3d = $MeshInstance3D
@onready var start_displ = $StartDispl
@onready var world_environment := $WorldEnvironment as WorldEnvironment

func _process(delta):
	
	start_displ.position = sm_64_mario.position
	SOGlobal.block_material.set_shader_parameter("outer_time", float(Time.get_ticks_msec()) * 0.001)
	
	if !sm_64_mario.ready_to_play:
		start_displ.visible = true
	else:
		start_displ.visible = false
	start_displ.rotation.y += delta * PI * 0.5

var level_root_position_table : Array[Vector3] = []

func _generate_random_level(useSeed) -> void:
	
	SOGlobal.level_bounds = AABB()
	
	level_root_position_table.clear()
	var root_random = RandomNumberGenerator.new()
	var root_random_iterational = RandomNumberGenerator.new()
	var baseblock_random = RandomNumberGenerator.new()
	var top_random = RandomNumberGenerator.new()
	var pepper_random = RandomNumberGenerator.new()
	var mirror_random = RandomNumberGenerator.new()
	var environment_random = RandomNumberGenerator.new()
	var coin_random = RandomNumberGenerator.new()
	var movement_random = RandomNumberGenerator.new()
	var pillar_random = RandomNumberGenerator.new()
	var slope_random = RandomNumberGenerator.new()
	var cork_random = RandomNumberGenerator.new()
	
	var apple_seed = RandomNumberGenerator.new()
	apple_seed.seed = hash(useSeed)
	
	root_random.seed = apple_seed.randi()
	root_random_iterational.seed = apple_seed.randi()
	baseblock_random.seed = apple_seed.randi()
	top_random.seed = apple_seed.randi()
	pepper_random.seed = apple_seed.randi()
	mirror_random.seed = apple_seed.randi()
	environment_random.seed = apple_seed.randi()
	coin_random.seed = apple_seed.randi()
	movement_random.seed = apple_seed.randi()
	pillar_random.seed = apple_seed.randi()
	slope_random.seed = apple_seed.randi()
	cork_random.seed = apple_seed.randi()
	
	var block_colors := Gradient.new()
	var color_count : int = environment_random.randi_range(3, 12)
	var avg_dist : float = 1.0 / color_count
	for i in range(color_count - 1):
		var hue : float = environment_random.randf_range(0, 1)
		var saturation : float = environment_random.randf_range(0.3, 1)
		var value : float = environment_random.randf_range(0.3, 1)
		var color_offset : float = avg_dist * 0.5 * environment_random.randf_range(-1, 1)
		var final_point_pos : float = float(i + 1) * avg_dist + color_offset
		block_colors.add_point(final_point_pos, Color.from_hsv(hue, saturation, value))
	var hue : float = environment_random.randf_range(0, 1)
	var saturation : float = environment_random.randf_range(0.3, 1)
	var value : float = environment_random.randf_range(0.3, 1)
	block_colors.add_point(0, Color.from_hsv(hue, saturation, value))
	block_colors.add_point(0.999, Color.from_hsv(hue, saturation, value))
	
	
	var new_gradient_texture : GradientTexture2D = GradientTexture2D.new()
	new_gradient_texture.width = 256
	new_gradient_texture.height = 1
	new_gradient_texture.fill_from = Vector2(-0.001, 0)
	new_gradient_texture.fill_to = Vector2(1.001, 0)
	new_gradient_texture.gradient = block_colors
	
	SOGlobal.block_material.set_shader_parameter("texture_gradient", new_gradient_texture)
	
	#world_environment.environment.sky.sky_material = SOGlobal.sky_material
	
	var level_gen_source : Vector3 = Vector3.ZERO
	var level_gen_source_velocity : float = root_random.randf_range(2.0, 6.0)
	var level_gen_source_angle : float = root_random.randf_range(0, PI * 2)
	SOGlobal.start_angle = snappedf(rad_to_deg(level_gen_source_angle), 45) + 180
	var level_gen_source_angle_velocity : float = root_random.randf_range(PI * -0.2, PI * 0.2)
	var vertical_vel : float = root_random.randf_range(0, 1)
	var max_block_width = root_random.randf_range(8, 24)
	var max_block_length = root_random.randf_range(8, 24)
	var max_block_height = root_random.randf_range(8, 20)
	var block_height_bias = pow(root_random.randf_range(2, 3.5), 1.4)
	var min_vert_vel_change = root_random.randf_range(-0.2, 0.1)
	var max_vert_vel_change = root_random.randf_range(0.1, 0.4)
	var min_vert_vel_reduction = root_random.randf_range(0.75, 0.88)
	var max_vert_vel_reduction = root_random.randf_range(0.88, 0.95)
	var min_pepper_blocks = root_random.randi_range(0, 3)
	var max_pepper_blocks = root_random.randi_range(4, 12)
	var min_surface_blocks_per_4x4 = 0
	var max_surface_blocks_per_4x4 = root_random.randi_range(1, 2)
	var min_surface_block_chance = root_random.randf_range(0.4, 0.8)
	var max_surface_block_chance = root_random.randf_range(0.8, 1)
	var min_velocity_change = root_random.randf_range(-1, 0)
	var max_velocity_change = root_random.randf_range(1, 3)
	var min_angle_velocity_change = root_random.randf_range(-0.2, 0)
	var max_angle_velocity_change = root_random.randf_range(0, 0.2)
	var min_velocity_change_reduction = root_random.randf_range(0.80, 0.88)
	var max_velocity_change_reduction = root_random.randf_range(0.88, 0.96)
	var min_angle_velocity_change_reduction = root_random.randf_range(0.65, 0.72)
	var max_angle_velocity_change_reduction = root_random.randf_range(0.72, 0.85)
	
	var iter : int = root_random.randi_range(25, 65)
	var pillar_chance = root_random.randf_range(0.025, 0.05)
	
	var north_slope_chance = root_random.randf_range(0.0, 0.6)
	var east_slope_chance = root_random.randf_range(0.0, 0.6)
	var south_slope_chance = root_random.randf_range(0.0, 0.6)
	var west_slope_chance = root_random.randf_range(0.0, 0.6)
	var max_north_slope = root_random.randi_range(1, 6)
	var max_east_slope = root_random.randi_range(1, 6)
	var max_south_slope = root_random.randi_range(1, 6)
	var max_west_slope = root_random.randi_range(1, 6)
	var should_generate_cork_star : bool = root_random.randf() > 0.8
	var corks : Array[CorkBox] = []
	#var iter : int = root_random.randi_range(5, 10)
	for i in range(iter):
		level_root_position_table.append(level_gen_source)
		level_gen_source_velocity += root_random_iterational.randf_range(min_velocity_change, max_velocity_change)
		level_gen_source_angle_velocity += root_random_iterational.randf_range(min_angle_velocity_change, max_angle_velocity_change)
		vertical_vel += root_random_iterational.randf_range(min_vert_vel_change, max_vert_vel_change)
		#vertical_vel = max(root_random_iterational.randf_range(-5, -1), vertical_vel)
		level_gen_source_velocity = max(level_gen_source_velocity, root_random_iterational.randf_range(2, 4))
		vertical_vel *= root_random_iterational.randf_range(min_vert_vel_reduction, max_vert_vel_reduction)
		level_gen_source_velocity *= root_random_iterational.randf_range(min_velocity_change_reduction, max_velocity_change_reduction)
		level_gen_source_angle_velocity *= root_random_iterational.randf_range(min_angle_velocity_change_reduction, max_angle_velocity_change_reduction)
		level_gen_source_angle += level_gen_source_angle_velocity
		var ang_deg = rad_to_deg(level_gen_source_angle)
		ang_deg = snapped(ang_deg, 45)
		
		level_gen_source_velocity = minf(level_gen_source_velocity, 12.5)
		
		var src_no_y : Vector3 = (level_gen_source * Vector3(1, 0, 1))
		if src_no_y.length() > 100:
			level_gen_source_angle = root_random_iterational.randf_range(0, PI * 2)
		var block_pos : Vector3 = level_gen_source + Vector3(baseblock_random.randf_range(-12, 12), 0, baseblock_random.randf_range(-12, 12))
		if i == 0:
			block_pos = level_gen_source
		block_pos = snapped(block_pos, Vector3(1.0, 1.0, 1.0))
		var block_height = baseblock_random.randf_range(1.0 / max_block_height, 1.0)
		block_height = pow(block_height, block_height_bias) * max_block_height + 1
		var block_size : Vector3 = Vector3(baseblock_random.randf_range(4, max_block_width), block_height, baseblock_random.randf_range(4, max_block_length))
		block_size = snapped(block_size, Vector3(1.0, 1.0, 1.0))
		
		var top_area : float = block_size.x * block_size.z
		
		var new_block : LevelBlock
		if absf(block_size.x - block_size.z) < 2 and baseblock_random.randf() > 0.5:
			block_size.z = block_size.x
			if fmod(block_size.x, 2) == 1:
				block_pos.x += 0.5
			if fmod(block_size.y, 2) == 1:
				block_pos.y -= 0.5
			if fmod(block_size.z, 2) == 1:
				block_pos.z += 0.5
			new_block = SOGlobal.generate_cylinder(block_pos, block_size.y, block_size.x * 0.5, block_size.x * 0.5)
			top_area = pow(PI * block_size.x * 0.5, 2)
		else:
			if fmod(block_size.x, 2) == 1:
				block_pos.x += 0.5
			if fmod(block_size.y, 2) == 1:
				block_pos.y -= 0.5
			if fmod(block_size.z, 2) == 1:
				block_pos.z += 0.5
			var cur_n_slope : float = 0
			var cur_e_slope : float = 0
			var cur_s_slope : float = 0
			var cur_w_slope : float = 0
			if slope_random.randf() < north_slope_chance:
				cur_n_slope = slope_random.randi_range(0, max_north_slope)
			if slope_random.randf() < east_slope_chance:
				cur_e_slope = slope_random.randi_range(0, max_east_slope)
			if slope_random.randf() < south_slope_chance:
				cur_s_slope = slope_random.randi_range(0, max_south_slope)
			if slope_random.randf() < west_slope_chance:
				cur_w_slope = slope_random.randi_range(0, max_west_slope)
			new_block = SOGlobal.generate_block_from_pos_and_size(block_pos, block_size, cur_n_slope, cur_e_slope, cur_s_slope, cur_w_slope) as LevelBlock
			#new_block.basis = new_block.basis.rotated(Vector3.UP, deg_to_rad(ang_deg))
			#new_block._update_transform()
		
		# types of moving blocks to consider:
		# constantly rotating
		# periods of rotation and pause
		# rotate back and forth
		# linear back and forth horizontally
		# linear back and forth vertically
		
		if pillar_random.randf() < pillar_chance:
			var pillar_side_offset := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(ang_deg + 90)) * pillar_random.randi_range(10, 18)
			var pillar_height := pillar_random.randi_range(12, 32)
			var pillar_radius := pillar_random.randi_range(2, 6)
			var pillar_pos := block_pos + pillar_side_offset + Vector3(0, pillar_height * 0.2, 0)
			var new_cylinder : LevelBlock = SOGlobal.generate_cylinder(pillar_pos, pillar_height, pillar_radius, pillar_radius)
			var num_sticks : int = ceil(pillar_height * pillar_random.randf_range(0.1, 0.2))
			for stick_iter in range(num_sticks):
				var random_angle_offset : float = pillar_random.randf_range(-PI, PI)
				var pillar_stick_height : float = float(stick_iter * pillar_height) / num_sticks
				var pillar_stick_extrusion : float = pillar_radius * 2 + pillar_random.randi_range(4, 12)
				var pillar_stick_width : float = pillar_random.randi_range(2, pillar_radius)
				var pillar_stick_tallness : float = pillar_random.randi_range(1, pillar_stick_width)
				var pillar_stick_size : Vector3 = Vector3(pillar_stick_width, pillar_stick_tallness, pillar_stick_extrusion)
				var pillar_stick_offset_for_material : Vector3 = Vector3.ZERO
				if fmod(pillar_stick_size.x, 2) == 1:
					pillar_stick_offset_for_material.x += 0.5
				if fmod(pillar_stick_size.y, 2) == 1:
					pillar_stick_offset_for_material.y -= 0.5
				if fmod(pillar_stick_size.z, 2) == 1:
					pillar_stick_offset_for_material.z += 0.5
				var cur_n_slope : float = 0
				var cur_e_slope : float = 0
				var cur_s_slope : float = 0
				var cur_w_slope : float = 0
				if slope_random.randf() < north_slope_chance:
					cur_n_slope = slope_random.randi_range(0, max_north_slope)
				if slope_random.randf() < east_slope_chance:
					cur_e_slope = slope_random.randi_range(0, max_east_slope)
				if slope_random.randf() < south_slope_chance:
					cur_s_slope = slope_random.randi_range(0, max_south_slope)
				if slope_random.randf() < west_slope_chance:
					cur_w_slope = slope_random.randi_range(0, max_west_slope)
				var pillar_stick_instance := SOGlobal.generate_block_from_pos_and_size(pillar_stick_offset_for_material, pillar_stick_size, cur_n_slope, cur_e_slope, cur_s_slope, cur_w_slope)  as LevelBlock
				pillar_stick_instance.position = pillar_pos + Vector3(0, -pillar_height * 0.4, 0) + Vector3(0, pillar_stick_height, 0)
				pillar_stick_instance.start_position = pillar_stick_instance.position
				pillar_stick_instance.basis = Basis.IDENTITY.rotated(Vector3.UP, random_angle_offset)
				pillar_stick_instance.start_rotation = pillar_stick_instance.basis
		
		var is_moving : bool = false
		var longest_axis : Vector3 = Vector3.UP
		var longest_axis_length : float = block_size.y
		var significantly_longest_axis : bool = false
		if block_size.y - block_size.x > 3 and block_size.y - block_size.z > 3 and absf(block_size.x - block_size.z) < 3:
			significantly_longest_axis = true
		
		if block_size.z > block_size.x and block_size.z > block_size.y:
			longest_axis = Vector3.FORWARD
			longest_axis_length = block_size.z
			if block_size.z - block_size.x > 3 and block_size.z - block_size.y > 3 and absf(block_size.x - block_size.y) < 3:
				significantly_longest_axis = true
		
		if block_size.x > block_size.z and block_size.x > block_size.y:
			longest_axis = Vector3.RIGHT
			longest_axis_length = block_size.x
			if block_size.x - block_size.y > 3 and block_size.x - block_size.z > 3 and absf(block_size.y - block_size.z) < 3:
				significantly_longest_axis = true
		
		if significantly_longest_axis and movement_random.randf() > 0.5 and level_gen_source_velocity > 7 and i > 3:
			is_moving = true
			var cw_or_ccw : int = movement_random.randi_range(0, 1) * 2 - 1
			var rotate_speed : float = 90
			new_block.continuous_rotation = longest_axis * rotate_speed
			new_block.move_time = movement_random.randf_range(1, 4)
			var should_pause : int = movement_random.randi_range(0, 1)
			new_block.pause_time = movement_random.randf_range(2, 4) * should_pause
			new_block._change_block_move_mode(LevelBlock.move_type.ROTATE_REPEAT)
		
		if top_area >= 24 and i != iter - 1:
			if movement_random.randf() > 0.5 and block_size.x == block_size.z and !is_moving and level_gen_source_velocity > 7 and i > 3:
				is_moving = true
				var cw_or_ccw : int = movement_random.randi_range(0, 1) * 2 - 1
				new_block.continuous_rotation = Vector3(0, (360 * cw_or_ccw) / movement_random.randf_range(8, 32), 0)
				new_block.pause_time = 0
				var vertical_offset : float = movement_random.randi_range(0, 1) * 2 - 1
				new_block.position += Vector3(0, vertical_offset * 0.5, 0)
				new_block.start_position += Vector3(0, vertical_offset * 0.5, 0)
				new_block._change_block_move_mode(LevelBlock.move_type.ROTATE_REPEAT)
			var num_surface_blocks_to_gen : int = floor(top_random.randi_range(min_surface_blocks_per_4x4, max_surface_blocks_per_4x4) * (top_area / 16))
			for b in range(num_surface_blocks_to_gen):
				if top_random.randf_range(0, 1) < top_random.randf_range(min_surface_block_chance, max_surface_block_chance):
					continue
				var top_block_size = Vector3(top_random.randf_range(1, 4), top_random.randf_range(1, 4), top_random.randf_range(1, 4))
				top_block_size = snapped(top_block_size, Vector3(1.0, 1.0, 1.0))
				var x_offset_range : float = (block_size.x - top_block_size.x) * 0.5
				var z_offset_range : float = (block_size.z - top_block_size.z) * 0.5
				var total_offset = Vector3(top_random.randf_range(-x_offset_range, x_offset_range), block_size.y * 0.5 + top_block_size.y * 0.5, top_random.randf_range(-z_offset_range, z_offset_range))
				total_offset = snapped(total_offset, Vector3(1, 1, 1))
				if fmod(top_block_size.x + block_size.x, 2) == 1:
					total_offset.x += 0.5
				if fmod(top_block_size.y + block_size.y, 2) == 1:
					total_offset.y -= 0.5
				if fmod(top_block_size.z + block_size.z, 2) == 1:
					total_offset.z += 0.5
				var cur_n_slope : float = 0
				var cur_e_slope : float = 0
				var cur_s_slope : float = 0
				var cur_w_slope : float = 0
				if slope_random.randf() < north_slope_chance:
					cur_n_slope = slope_random.randi_range(0, max_north_slope)
				if slope_random.randf() < east_slope_chance:
					cur_e_slope = slope_random.randi_range(0, max_east_slope)
				if slope_random.randf() < south_slope_chance:
					cur_s_slope = slope_random.randi_range(0, max_south_slope)
				if slope_random.randf() < west_slope_chance:
					cur_w_slope = slope_random.randi_range(0, max_west_slope)
				var top_block := SOGlobal.generate_block_from_pos_and_size(block_pos + total_offset, top_block_size, cur_n_slope, cur_e_slope, cur_s_slope, cur_w_slope, new_block) as LevelBlock
				if is_moving:
					top_block._change_block_move_mode(LevelBlock.move_type.CHILD)
		
		var block_volume = block_size.x * block_size.y * block_size.z
		if block_volume >= 320:
			for b in range(pepper_random.randi_range(min_pepper_blocks, max_pepper_blocks)):
				var gen_dist = 0
				var x_or_z_pep = pepper_random.randi_range(0, 1)
				var neg_or_pos = pepper_random.randi_range(0, 1) * 2 - 1
				var rand_dir = Vector3(x_or_z_pep * neg_or_pos, 0, (1 - x_or_z_pep) * neg_or_pos)
				var pepper_block_size = Vector3(pepper_random.randf_range(1, 6), pepper_random.randf_range(1, block_size.y), pepper_random.randf_range(1, 6))
				pepper_block_size = snapped(pepper_block_size, Vector3(1.0, 1.0, 1.0))
				var horiz_offset = Vector3.ZERO
				if rand_dir.x != 0:
					gen_dist = block_size.x * 0.5 + pepper_block_size.x * 0.5
					var offset_range : float = (block_size.z - pepper_block_size.z) * 0.5
					horiz_offset = Vector3(0, 0, pepper_random.randf_range(-offset_range, offset_range))
				else:
					gen_dist = block_size.z * 0.5 + pepper_block_size.z * 0.5
					var offset_range : float = (block_size.x - pepper_block_size.x) * 0.5
					horiz_offset = Vector3(pepper_random.randf_range(-offset_range, offset_range), 0, 0)
				horiz_offset = snapped(horiz_offset, Vector3(1, 1, 1))
				var height_adjust : float = snappedf(pepper_random.randf_range(-block_size.y + pepper_block_size.y, block_size.y - pepper_block_size.y) * 0.5, 1)
				var final_pos = block_pos + gen_dist * rand_dir + Vector3(0, height_adjust, 0) + horiz_offset
				if fmod(pepper_block_size.x + block_size.x, 2) == 1 and x_or_z_pep == 0:
					final_pos.x += 0.5
				if fmod(pepper_block_size.y + block_size.y, 2) == 1:
					final_pos.y += 0.5
				if fmod(pepper_block_size.z + block_size.z, 2) == 1 and x_or_z_pep == 1:
					final_pos.z += 0.5
				var cur_n_slope : float = 0
				var cur_e_slope : float = 0
				var cur_s_slope : float = 0
				var cur_w_slope : float = 0
				if slope_random.randf() < north_slope_chance:
					cur_n_slope = slope_random.randi_range(0, max_north_slope)
				if slope_random.randf() < east_slope_chance:
					cur_e_slope = slope_random.randi_range(0, max_east_slope)
				if slope_random.randf() < south_slope_chance:
					cur_s_slope = slope_random.randi_range(0, max_south_slope)
				if slope_random.randf() < west_slope_chance:
					cur_w_slope = slope_random.randi_range(0, max_west_slope)
				var new_pepper_block := SOGlobal.generate_block_from_pos_and_size(final_pos, pepper_block_size, cur_n_slope, cur_e_slope, cur_s_slope, cur_w_slope, new_block) as LevelBlock
				if is_moving:
					new_pepper_block._change_block_move_mode(LevelBlock.move_type.CHILD)
		if block_height >= 7.9:
			var rand_dist = mirror_random.randi_range(4, 6)
			var x_or_z = mirror_random.randi_range(0, 1)
			var neg_or_pos = mirror_random.randi_range(0, 1) * 2 - 1
			var rand_dir = Vector3(x_or_z * neg_or_pos, 0, (1 - x_or_z) * neg_or_pos)
			if rand_dir.x != 0:
				rand_dist += block_size.x
			else:
				rand_dist += block_size.z
			var mirror_pos = block_pos + rand_dist * rand_dir
			SOGlobal.generate_block_from_pos_and_size(mirror_pos, block_size)
			if block_volume >= 320:
				for b in range(pepper_random.randi_range(min_pepper_blocks, max_pepper_blocks)):
					var gen_dist = 0
					var x_or_z_pep = pepper_random.randi_range(0, 1)
					var neg_or_pos_pep = pepper_random.randi_range(0, 1) * 2 - 1
					var rand_dir_pep = Vector3(x_or_z_pep * neg_or_pos_pep, 0, (1 - x_or_z_pep) * neg_or_pos_pep)
					var pepper_block_size = Vector3(pepper_random.randf_range(1, 6), pepper_random.randf_range(1, block_size.y), pepper_random.randf_range(1, 6))
					pepper_block_size = snapped(pepper_block_size, Vector3(2.0, 2.0, 2.0))
					var horiz_offset = Vector3.ZERO
					if rand_dir_pep.x != 0:
						gen_dist = block_size.x * 0.5 + pepper_block_size.x * 0.5
						var offset_range : float = (block_size.z - pepper_block_size.z) * 0.5
						horiz_offset = Vector3(0, 0, pepper_random.randf_range(-offset_range, offset_range))
					else:
						gen_dist = block_size.z * 0.5 + pepper_block_size.z * 0.5
						var offset_range : float = (block_size.x - pepper_block_size.x) * 0.5
						horiz_offset = Vector3(pepper_random.randf_range(-offset_range, offset_range), 0, 0)
					horiz_offset = snapped(horiz_offset, Vector3(1, 1, 1))
					var height_adjust : float = snappedf(pepper_random.randf_range(-block_size.y + pepper_block_size.y, block_size.y - pepper_block_size.y) * 0.5, 1)
					var final_pos = mirror_pos + gen_dist * rand_dir_pep + Vector3(0, height_adjust, 0) + horiz_offset
					if fmod(pepper_block_size.x + block_size.x, 2) == 1 and x_or_z_pep == 0:
						final_pos.x += 0.5
					if fmod(pepper_block_size.y + block_size.y, 2) == 1:
						final_pos.y += 0.5
					if fmod(pepper_block_size.z + block_size.z, 2) == 1 and x_or_z_pep == 1:
						final_pos.z += 0.5
					
					var cur_n_slope : float = 0
					var cur_e_slope : float = 0
					var cur_s_slope : float = 0
					var cur_w_slope : float = 0
					if slope_random.randf() < north_slope_chance:
						cur_n_slope = slope_random.randi_range(0, max_north_slope)
					if slope_random.randf() < east_slope_chance:
						cur_e_slope = slope_random.randi_range(0, max_east_slope)
					if slope_random.randf() < south_slope_chance:
						cur_s_slope = slope_random.randi_range(0, max_south_slope)
					if slope_random.randf() < west_slope_chance:
						cur_w_slope = slope_random.randi_range(0, max_west_slope)
					SOGlobal.generate_block_from_pos_and_size(final_pos, pepper_block_size, cur_n_slope, cur_e_slope, cur_s_slope, cur_w_slope)
					
		if i == iter - 1:
			var new_star_pos : Vector3 = block_pos + Vector3(0, block_size.y * 0.5, 0) + Vector3(0, 3.5, 0)
			var new_star := SOGlobal.generate_power_star("main", new_star_pos) as PowerStar
			new_star.main_star = true
			new_star._activate_star()
		
		level_gen_source += Vector3(0, vertical_vel, level_gen_source_velocity).rotated(Vector3(0, 1, 0), deg_to_rad(ang_deg))
	
	await get_tree().create_timer(0.02).timeout
	var num_coins_spawned = 0
	var coin_cast : RayCast3D = RayCast3D.new()
	coin_cast.set_collision_mask_value(1, true)
	SOGlobal.add_child(coin_cast)
	for mesh:LevelBlock in SOGlobal.level_meshes:
		if mesh.coin_surface == LevelBlock.coin_spawn_type.BOX:
			var cur_box_size : Vector3 = mesh.block_size
			var cur_box_halfsize : Vector3 = cur_box_size * 0.5
			var cur_box_pos : Vector3 = mesh.position
			var coin_height : float = cur_box_pos.y + cur_box_halfsize.y + 0.75
			for bx in cur_box_size.x:
				for bz in cur_box_size.z:
					if cork_random.randf() > 0.9994:
						var corner_1 : Vector3 = Vector3(cur_box_pos.x - cur_box_halfsize.x + 0.5, coin_height, cur_box_pos.z - cur_box_halfsize.z + 0.5)
						var possible_contents : Array = [["coin", "coin", "coin"], ["coin", "coin", "coin", "coin", "coin"], ["coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin", "coin"]]
						var new_cork : CorkBox = SOGlobal.generate_cork_box_with_contents(corner_1 + Vector3(bx, 0, bz) + Vector3(0, 3, 0), possible_contents[cork_random.randi_range(0, possible_contents.size() - 1)])
						corks.append(new_cork)
			
			
			for bx in cur_box_size.x:
				for bz in cur_box_size.z:
					if coin_random.randf_range(0, 1) > 0.99975:
						var num_coins : int = coin_random.randi_range(3, 6)
						var corner_1 : Vector3 = Vector3(cur_box_pos.x - cur_box_halfsize.x + 0.5, coin_height, cur_box_pos.z - cur_box_halfsize.z + 0.5)
						for nc in num_coins:
							SOGlobal.generate_yellow_coin_at_pos(corner_1 + Vector3(bx, nc, bz), false)
			if coin_random.randf_range(0, 1) > 0.9 and cur_box_size.x > 3 and cur_box_size.z > 3:
				var corner_1 : Vector3 = Vector3(cur_box_pos.x - cur_box_halfsize.x + 0.5, coin_height, cur_box_pos.z - cur_box_halfsize.z + 0.5)
				var corner_2 : Vector3 = Vector3(cur_box_pos.x + cur_box_halfsize.x - 0.5, coin_height, cur_box_pos.z - cur_box_halfsize.z + 0.5)
				var corner_3 : Vector3 = Vector3(cur_box_pos.x - cur_box_halfsize.x + 0.5, coin_height, cur_box_pos.z + cur_box_halfsize.z - 0.5)
				var corner_4 : Vector3 = Vector3(cur_box_pos.x + cur_box_halfsize.x - 0.5, coin_height, cur_box_pos.z + cur_box_halfsize.z - 0.5)
				if coin_random.randf_range(0, 1) > 0.8:
					SOGlobal.generate_yellow_coin_at_pos(corner_1)
					SOGlobal.generate_yellow_coin_at_pos(corner_1 + Vector3(1, 0, 0))
					SOGlobal.generate_yellow_coin_at_pos(corner_1 + Vector3(0, 0, 1))
					if cur_box_size.x > 5 and cur_box_size.z > 5 and coin_random.randf_range(0, 1) > 0.75:
						SOGlobal.generate_yellow_coin_at_pos(corner_1 + Vector3(2, 0, 0))
						SOGlobal.generate_yellow_coin_at_pos(corner_1 + Vector3(0, 0, 2))
				if coin_random.randf_range(0, 1) > 0.8:
					SOGlobal.generate_yellow_coin_at_pos(corner_2)
					SOGlobal.generate_yellow_coin_at_pos(corner_2 + Vector3(-1, 0, 0))
					SOGlobal.generate_yellow_coin_at_pos(corner_2 + Vector3(0, 0, 1))
					if cur_box_size.x > 5 and cur_box_size.z > 5 and coin_random.randf_range(0, 1) > 0.75:
						SOGlobal.generate_yellow_coin_at_pos(corner_2 + Vector3(-2, 0, 0))
						SOGlobal.generate_yellow_coin_at_pos(corner_2 + Vector3(0, 0, 2))
				if coin_random.randf_range(0, 1) > 0.8:
					SOGlobal.generate_yellow_coin_at_pos(corner_3)
					SOGlobal.generate_yellow_coin_at_pos(corner_3 + Vector3(1, 0, 0))
					SOGlobal.generate_yellow_coin_at_pos(corner_3 + Vector3(0, 0, -1))
					if cur_box_size.x > 5 and cur_box_size.z > 5 and coin_random.randf_range(0, 1) > 0.75:
						SOGlobal.generate_yellow_coin_at_pos(corner_3 + Vector3(2, 0, 0))
						SOGlobal.generate_yellow_coin_at_pos(corner_3 + Vector3(0, 0, -2))
				if coin_random.randf_range(0, 1) > 0.8:
					SOGlobal.generate_yellow_coin_at_pos(corner_4)
					SOGlobal.generate_yellow_coin_at_pos(corner_4 + Vector3(-1, 0, 0))
					SOGlobal.generate_yellow_coin_at_pos(corner_4 + Vector3(0, 0, -1))
					if cur_box_size.x > 5 and cur_box_size.z > 5 and coin_random.randf_range(0, 1) > 0.75:
						SOGlobal.generate_yellow_coin_at_pos(corner_4 + Vector3(-2, 0, 0))
						SOGlobal.generate_yellow_coin_at_pos(corner_4 + Vector3(0, 0, -2))
			if coin_random.randf_range(0, 1) > 0.85 and cur_box_size.x > 4 and cur_box_size.z > 4:
				#ring case
				var random_horiz_offset = Vector3(coin_random.randf_range(-cur_box_halfsize.x + 2.5, cur_box_halfsize.x - 2.5), 0, coin_random.randf_range(-cur_box_halfsize.z + 2.5, cur_box_halfsize.z - 2.5))
				random_horiz_offset = round(random_horiz_offset)
				var ring_origin = Vector3(cur_box_pos.x, 0, cur_box_pos.z) + Vector3(0, coin_height, 0) + random_horiz_offset
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(45)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(90)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(135)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(180)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(-45)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(-90)))
				SOGlobal.generate_yellow_coin_at_pos(ring_origin + Vector3(0, 0, 2).rotated(Vector3.UP, deg_to_rad(-135)))
			if coin_random.randf_range(0, 1) > 0.85 and cur_box_size.x > 4 and cur_box_size.z > 4:
				#line case
				var random_horiz_offset = Vector3(coin_random.randf_range(-cur_box_halfsize.x + 2.5, cur_box_halfsize.x - 2.5), 0, coin_random.randf_range(-cur_box_halfsize.z + 2.5, cur_box_halfsize.z - 2.5))
				random_horiz_offset = round(random_horiz_offset)
				var line_origin = Vector3(cur_box_pos.x, 0, cur_box_pos.z) + Vector3(0, coin_height, 0) + random_horiz_offset
				var coin_line_angle = coin_random.randi_range(0, 7) * 45
				var line_dir = Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(coin_line_angle))
				SOGlobal.generate_yellow_coin_at_pos(line_origin + line_dir * 2)
				SOGlobal.generate_yellow_coin_at_pos(line_origin + line_dir * 1)
				SOGlobal.generate_yellow_coin_at_pos(line_origin)
				SOGlobal.generate_yellow_coin_at_pos(line_origin + line_dir * -1)
				SOGlobal.generate_yellow_coin_at_pos(line_origin + line_dir * -2)
				
		else:
			continue
	if corks.size() > 0 and should_generate_cork_star:
		var which_cork : int = cork_random.randi_range(0, corks.size() - 1)
		corks[which_cork].contained_items = ["star"]
		#print("GENERATED CORK STAR")
		#DebugDraw3D.draw_sphere(corks[which_cork].position, 1.0, Color(1, 0, 0), 100)

func _create_mario_world(useSeed = str(randi())) -> void:
	
	SOGlobal.current_seed = useSeed
	
	SM64Global.rom_filepath = OS.get_executable_path().get_base_dir() + "/SM64.z64"
	
	SM64Global.scale_factor = 110.0
	
	SOGlobal.total_coins = 0
	
	if SM64Global.is_init():
		for mesh in SOGlobal.level_meshes:
			if mesh and is_instance_valid(mesh):
				mesh.free()
		for node in SOGlobal.get_children():
			if node is BlockNametag:
				node.queue_free()
			if node is PowerStar:
				node.queue_free()
			if node is Coin:
				node.queue_free()
			if node is CorkBox:
				node.queue_free()
		SOGlobal.level_meshes.clear()
		SM64Global.terminate()
	
	SM64Global.init()
	
	_generate_random_level(useSeed)
	
	await get_tree().create_timer(0.2).timeout
	
	SOGlobal.save_data.try_submit_save_block(useSeed)
	
	sm_64_static_surface_handler.load_static_surfaces()
	sm_64_surface_objects_handler.load_all_surface_objects()
	
	sm_64_mario.create()
	SOGlobal.level_start_time = Time.get_ticks_msec()
	sm_64_mario.preview_cam_yaw = 45
	sm_64_mario.preview_cam_pitch = -20
	sm_64_mario.preview_cam_zoom = 1
	sm_64_mario.preview_cam_pan_pitch = 0
	sm_64_mario.preview_cam_pan_yaw = 0
	sm_64_mario.ready_to_play = false
	
	if ProjectSettings.get_setting("display/window/size/transparent") == true:
		world_environment.environment.sky.sky_material = null
		return
	
	var sky_random = RandomNumberGenerator.new()
	sky_random.seed = hash(useSeed)
	
	var sky_colors := Gradient.new()
	var color_count : int = sky_random.randi_range(3, 12)
	var avg_dist : float = 1.0 / color_count
	for i in range(color_count - 1):
		var hue : float = sky_random.randf_range(0, 1)
		var saturation : float = sky_random.randf_range(0.16, 0.75)
		var value : float = sky_random.randf_range(0.15, 0.6)
		var color_offset : float = avg_dist * 0.5 * sky_random.randf_range(-1, 1)
		var final_point_pos : float = float(i + 1) * avg_dist + color_offset
		sky_colors.add_point(final_point_pos, Color.from_hsv(hue, saturation, value))
	var hue : float = sky_random.randf_range(0, 1)
	var saturation : float = sky_random.randf_range(0.3, 1)
	var value : float = sky_random.randf_range(0.3, 1)
	sky_colors.add_point(0, Color.from_hsv(hue, saturation, value))
	sky_colors.add_point(0.999, Color.from_hsv(hue, saturation, value))
	
	var sky_ramp := Gradient.new()
	color_count = sky_random.randi_range(3, 12)
	avg_dist = 1.0 / color_count
	for i in range(color_count - 1):
		hue = sky_random.randf_range(0, 1)
		saturation = sky_random.randf_range(0.2, 0.75)
		value = sky_random.randf_range(0.2, 0.6)
		var color_offset : float = avg_dist * 0.5 * sky_random.randf_range(-1, 1)
		var final_point_pos : float = lerp(float(i + 1) * avg_dist + color_offset, 0.75, 0.5)
		sky_ramp.add_point(final_point_pos, Color.from_hsv(hue, saturation, value))
	hue = sky_random.randf_range(0, 1)
	saturation = sky_random.randf_range(0.6, 1)
	value = sky_random.randf_range(0.01, 0.05)
	sky_ramp.add_point(0, Color.from_hsv(hue, saturation, value))
	sky_ramp.add_point(0.999, Color.from_hsv(hue, saturation, value))
	
	
	
	var sky_gradient_texture : GradientTexture2D = GradientTexture2D.new()
	sky_gradient_texture.width = 256
	sky_gradient_texture.height = 1
	sky_gradient_texture.fill_from = Vector2(-0.001, 0)
	sky_gradient_texture.fill_to = Vector2(1.001, 0)
	sky_gradient_texture.gradient = sky_colors
	
	var sky_ramp_texture : GradientTexture2D = GradientTexture2D.new()
	sky_ramp_texture.width = 256
	sky_ramp_texture.height = 1
	sky_ramp_texture.fill_from = Vector2(-0.001, 0)
	sky_ramp_texture.fill_to = Vector2(1.001, 0)
	sky_ramp_texture.gradient = sky_ramp
	
	if false:
		var debug_gradient : TextureRect = TextureRect.new()
		debug_gradient.size = Vector2(256, 256)
		debug_gradient.custom_minimum_size = Vector2(256, 256)
		debug_gradient.texture = sky_ramp_texture
		SOGlobal.add_child(debug_gradient)
	
	SOGlobal.sky_material.set_shader_parameter("sky_color_ramp", sky_ramp_texture)
	
	var sky_noise_texture := NoiseTexture2D.new()
	sky_noise_texture.seamless = true
	sky_noise_texture.color_ramp = sky_colors
	var sky_noise := FastNoiseLite.new()
	sky_noise.seed = sky_random.randi()
	sky_noise.noise_type = sky_random.randi_range(0, 5)
	sky_noise.fractal_type = sky_random.randi_range(0, 3)
	sky_noise.cellular_return_type = sky_random.randi_range(0, 6)
	sky_noise.cellular_distance_function = sky_random.randi_range(0, 3)
	sky_noise.domain_warp_enabled = bool(sky_random.randi_range(0, 1))
	sky_noise.domain_warp_fractal_type = sky_random.randi_range(0, 2)
	sky_noise.cellular_jitter = sky_random.randf_range(0.0, 3.0)
	sky_noise.domain_warp_amplitude = sky_random.randf_range(0, 60)
	sky_noise.domain_warp_fractal_gain = sky_random.randf_range(0.0, 2.0)
	sky_noise.domain_warp_fractal_lacunarity = sky_random.randf_range(0.0, 15.0)
	sky_noise.domain_warp_fractal_octaves = sky_random.randi_range(0, 5)
	sky_noise.domain_warp_frequency = sky_random.randf_range(0.0, 0.5)
	sky_noise.fractal_gain = sky_random.randf_range(0.0, 2.0)
	sky_noise.fractal_lacunarity = sky_random.randf_range(0.0, 4.0)
	sky_noise.fractal_octaves = sky_random.randi_range(0, 5)
	sky_noise.fractal_ping_pong_strength = sky_random.randf_range(0.0, 4.0)
	sky_noise.fractal_weighted_strength = sky_random.randf_range(0.0, 2.0)
	sky_noise.frequency = sky_random.randf_range(0.001, 0.05)
	sky_noise_texture.width = 256
	sky_noise_texture.height = 256
	sky_noise_texture.noise = sky_noise
	await sky_noise_texture.changed
	SOGlobal.sky_material.set_shader_parameter("sky_texture", sky_noise_texture)
	world_environment.environment.fog_density = sky_random.randf_range(0.0005, 0.01)

func _ready() -> void:
	_create_mario_world()
	SOGlobal.current_level_manager = self


func _on_tree_exiting() -> void:
#	pass
	# Clean up the `libsm64` world when the scene is freed.
	sm_64_mario.delete()
	SM64Global.terminate()


#func _process(delta):
	#pass
	#mesh_instance_3d.rotation = mesh_instance_3d.rotation + Vector3(0, 0.1 * delta, 0)
