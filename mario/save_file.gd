class_name MarioSaveFile extends Resource

const current_version : String = "v0.3"

var save_blocks : Array[SaveBlock] = []
var save_blocks_lookup : Dictionary = {}

func get_block_by_seed(in_seed : String) -> SaveBlock:
	return save_blocks[save_blocks_lookup[in_seed]]

func try_submit_save_block(in_seed : String, in_star_id : String = "", in_time : float = 0, in_coins : int = 0, in_checkpoints_used : int = 0, in_wants_save : bool = false) -> void:
	#print("trying to submit a new save block for seed \"" + in_seed + "\"")
	#print("we currently have " + str(save_blocks.size()) + " save blocks")
	if in_star_id == "":
		#not a clear, just seed history!
		#print("not a clear, just saving history")
		if !save_blocks_lookup.has(in_seed):
			var new_block := SaveBlock.new(in_seed)
			save_blocks_lookup[in_seed] = save_blocks.size()
			save_blocks.append(new_block)
		if in_wants_save:
			save_game()
		return
	if save_blocks_lookup.has(in_seed):
		#we have save data from this seed
		#print("we have this seed, submitting star data entry to existing block")
		save_blocks[save_blocks_lookup[in_seed]].try_add_star_data_entry(in_star_id, in_time, in_coins, in_checkpoints_used)
	else:
		#print("we don't have this seed, so let's make a new block and submit the star data entry to it")
		var new_block := SaveBlock.new(in_seed)
		new_block.try_add_star_data_entry(in_star_id, in_time, in_coins, in_checkpoints_used)
		save_blocks_lookup[in_seed] = save_blocks.size()
		save_blocks.append(new_block)
	if in_wants_save:
		save_game()

#func _unhandled_input(event:InputEvent):
	#if !currently_binding:
		#return
	#if event.is_pressed():
		#if event is InputEventKey:
			#if event.pressed:
				#match event.keycode:
					#KEY_ESCAPE:
						#currently_binding = false
						#return
					#KEY_BACKSPACE:
						#InputMap.action_erase_events(currently_binding_action)
						#currently_binding = false
						#return
		#InputMap.action_add_event(currently_binding_action, event)
		#currently_binding = false

func save_game():
	var save_bytes := StreamPeerBuffer.new()
	save_bytes.put_u32(current_version.length()) # length of version string
	save_bytes.put_data(current_version.to_utf8_buffer())
	
	save_bytes.put_float(SOGlobal.inner_deadzone)
	save_bytes.put_float(SOGlobal.outer_deadzone)
	save_bytes.put_u8(int(SOGlobal.flip_x))
	
	for i in InputMap.get_actions().size():
		var action := InputMap.get_actions()[i]
		if action.begins_with("ui"):
			continue
		var num_events_on_this_action : int = InputMap.action_get_events(action).size()
		save_bytes.put_u8(num_events_on_this_action)
		for k in num_events_on_this_action:
			var event = InputMap.action_get_events(action)[k]
			if event is InputEventKey:
				save_bytes.put_u8(0)
				save_bytes.put_u32(event.physical_keycode)
			if event is InputEventJoypadMotion:
				print(event.axis)
				print(event.axis_value)
				save_bytes.put_u8(1)
				save_bytes.put_u8(event.axis)
				save_bytes.put_float(event.axis_value)
			if event is InputEventJoypadButton:
				save_bytes.put_u8(2)
				save_bytes.put_u8(event.button_index)
				save_bytes.put_u8(event.pressed)
	
	save_bytes.put_u32(save_blocks.size()) # amount of save blocks
	var block_num : int = 0
	for entry in save_blocks:
		block_num += 1
		# entry = the saveblock
		var seed_string : PackedByteArray = entry.seed.to_utf8_buffer()
		save_bytes.put_u32(seed_string.size())
		save_bytes.put_data(seed_string)
		save_bytes.put_u32(entry.coins)
		save_bytes.put_u32(entry.star_data.size()) # amount of star data entries in this block
		for star in entry.star_data:
			# star = star data
			var star_string : PackedByteArray = star.star_id.to_utf8_buffer()
			save_bytes.put_u32(star_string.size())
			save_bytes.put_data(star_string)
			save_bytes.put_float(star.time)
			save_bytes.put_u32(star.checkpoints_used)
	#save_bytes.resize(save_bytes.get_position())
	var save = FileAccess.open("user://infinite_mario_save.dat", FileAccess.WRITE)
	save.store_buffer(save_bytes.data_array)

func load_game():
	if not FileAccess.file_exists("user://infinite_mario_save.dat"):
		return
	var backup_save = FileAccess.open("user://infinite_mario_save_backup.dat", FileAccess.WRITE)
	var file_bytes : PackedByteArray = FileAccess.get_file_as_bytes("user://infinite_mario_save.dat")
	backup_save.store_buffer(file_bytes)
	backup_save.close()
	var save = FileAccess.open("user://infinite_mario_save.dat", FileAccess.READ)
	var version_string_length : int = save.get_32()
	var in_version = save.get_buffer(version_string_length).get_string_from_utf8()
	match in_version:
		"v0.1":
			var backup_save_01 = FileAccess.open("user://infinite_mario_save_v01_backup.dat", FileAccess.WRITE)
			backup_save_01.store_buffer(file_bytes)
			backup_save_01.close()
			save_blocks.clear()
			save_blocks_lookup.clear()
			var block_count : int = save.get_32()
			for block_num in block_count:
				var seed_length : int = save.get_32()
				var seed_string : String = save.get_buffer(seed_length).get_string_from_utf8()
				var coin_count : int = save.get_32()
				var star_data_entries : int = save.get_32()
				for star_data in star_data_entries:
					var star_id_string_length : int = save.get_32()
					var star_id_string : String = save.get_buffer(star_id_string_length).get_string_from_utf8()
					var star_time : float = save.get_float()
					#new_star_data.star_id = star_id_string
					#new_star_data.time = star_time
					#new_block.star_data[star_id_string] = new_star_data
					try_submit_save_block(seed_string, star_id_string, star_time, coin_count, 0)
					#print("ack")
					#print(save_blocks[save_blocks.size() - 1].star_data[0].star_id)
				#save_blocks[new_block.seed] = new_block
		"v0.2":
			var backup_save_02 = FileAccess.open("user://infinite_mario_save_v02_backup.dat", FileAccess.WRITE)
			backup_save_02.store_buffer(file_bytes)
			backup_save_02.close()
			save_blocks.clear()
			save_blocks_lookup.clear()
			var block_count : int = save.get_32()
			for block_num in block_count:
				var seed_length : int = save.get_32()
				var seed_string : String = save.get_buffer(seed_length).get_string_from_utf8()
				var coin_count : int = save.get_32()
				var star_data_entries : int = save.get_32()
				for star_data in star_data_entries:
					var star_id_string_length : int = save.get_32()
					var star_id_string : String = save.get_buffer(star_id_string_length).get_string_from_utf8()
					var star_time : float = save.get_float()
					var star_checkpoints : int = save.get_32()
					#new_star_data.star_id = star_id_string
					#new_star_data.time = star_time
					#new_block.star_data[star_id_string] = new_star_data
					try_submit_save_block(seed_string, star_id_string, star_time, coin_count, star_checkpoints)
				#save_blocks[new_block.seed] = new_block
		"v0.3":
			SOGlobal.inner_deadzone = save.get_float()
			SOGlobal.outer_deadzone = save.get_float()
			SOGlobal.flip_x = bool(save.get_8())
			print("loading bindings")
			for i in InputMap.get_actions().size():
				var action := InputMap.get_actions()[i]
				if action.begins_with("ui"):
					continue
				#print(action)
				InputMap.action_erase_events(action)
				var num_events_on_this_action : int = save.get_8()
				for k in num_events_on_this_action:
					var event_type_identifier = save.get_8()
					if event_type_identifier == 0:
						var new_event := InputEventKey.new()
						new_event.physical_keycode = save.get_32()
						new_event.device = -1
						#print(new_event)
						InputMap.action_add_event(action, new_event)
					if event_type_identifier == 1:
						var new_event := InputEventJoypadMotion.new()
						new_event.axis = save.get_8()
						new_event.axis_value = save.get_float()
						new_event.device = -1
						#print(new_event)
						InputMap.action_add_event(action, new_event)
					if event_type_identifier == 2:
						var new_event := InputEventJoypadButton.new()
						new_event.button_index = save.get_8()
						new_event.pressed = save.get_8()
						new_event.device = -1
						#print(new_event)
						InputMap.action_add_event(action, new_event)
			print("bindings loaded")
			save_blocks.clear()
			save_blocks_lookup.clear()
			var block_count : int = save.get_32()
			for block_num in block_count:
				var seed_length : int = save.get_32()
				var seed_string : String = save.get_buffer(seed_length).get_string_from_utf8()
				var coin_count : int = save.get_32()
				var star_data_entries : int = save.get_32()
				for star_data in star_data_entries:
					var star_id_string_length : int = save.get_32()
					var star_id_string : String = save.get_buffer(star_id_string_length).get_string_from_utf8()
					var star_time : float = save.get_float()
					var star_checkpoints : int = save.get_32()
					#new_star_data.star_id = star_id_string
					#new_star_data.time = star_time
					#new_block.star_data[star_id_string] = new_star_data
					try_submit_save_block(seed_string, star_id_string, star_time, coin_count, star_checkpoints)
				#save_blocks[new_block.seed] = new_block
				
func get_total_star_count():
	var star_count : int = 0
	for entry in save_blocks:
		star_count += entry.star_data.size()
	return star_count

func get_total_coin_coint():
	var coin_count : int = 0
	for entry in save_blocks:
		coin_count += entry.coins
	return coin_count

# star identifiers:
# "main" - the main level star
# "coin" - spawned when the player collects min(100, total_coins * 0.95) coins
# "red" - spawned when the player collects all red coins
# "cork" - chance to be spawned by a random cork block in the level

func is_star_collected(in_seed : String, in_star_id : String) -> bool:
	if save_blocks_lookup.has(in_seed):
		return save_blocks[save_blocks_lookup[in_seed]].star_data_lookup.has(in_star_id)
	return false
