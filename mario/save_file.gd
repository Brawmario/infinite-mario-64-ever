class_name MarioSaveFile extends Resource

const current_version : String = "v0.2"

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

func save_game():
	#print("let's try to save game!")
	var save_bytes := StreamPeerBuffer.new()
	#print("putting current version length")
	save_bytes.put_u32(current_version.length()) # length of version string
	#print(save_bytes.data_array)
	#print("putting current version string")
	save_bytes.put_data(current_version.to_utf8_buffer())
	#print(save_bytes.data_array)
	#print("putting amount of save blocks")
	save_bytes.put_u32(save_blocks.size()) # amount of save blocks
	#print(save_bytes.data_array)
	var block_num : int = 0
	for entry in save_blocks:
		block_num += 1
		##print("putting save block # " + str(block_num))
		# entry = the saveblock
		var seed_string : PackedByteArray = entry.seed.to_utf8_buffer()
		save_bytes.put_u32(seed_string.size())
		save_bytes.put_data(seed_string)
		save_bytes.put_u32(entry.coins)
		save_bytes.put_u32(entry.star_data.size()) # amount of star data entries in this block
		for star in entry.star_data:
			##print("putting star data from block " + str(block_num))
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
	var save = FileAccess.open("user://infinite_mario_save.dat", FileAccess.READ)
	var version_string_length : int = save.get_32()
	var in_version = save.get_buffer(version_string_length).get_string_from_utf8()
	match in_version:
		"v0.1":
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
