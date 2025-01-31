class_name SaveBlock extends Resource

var seed : String
var coins : int
var star_data : Array[StarSaveData]
var star_data_lookup : Dictionary

func _init(in_seed : String):
	seed = in_seed
	coins = 0
	star_data = []
	star_data_lookup = {}

func try_add_star_data_entry(in_id : String, in_time : float, in_coins : int, in_num_checkpoints : int):
	#print("trying to add star data entry \"" + in_id + "\"")
	if star_data_lookup.has(in_id):
		#print("we have this star id already in this block")
		#save block has this star
		if in_time < star_data[star_data_lookup[in_id]].time:
			#print("that being said, this submission has a faster time, so let's update it")
			#new time for this star is faster, so assign it to existing star data
			star_data[star_data_lookup[in_id]].time = in_time
		if in_num_checkpoints < star_data[star_data_lookup[in_id]].checkpoints_used:
			star_data[star_data_lookup[in_id]].checkpoints_used = in_num_checkpoints
	else:
		#print("we don't have this star submitted yet, so let's add it")
		var new_data := StarSaveData.new()
		new_data.star_id = in_id
		#save block does not have this star,
		#so set time on new star data and add it to the save block
		new_data.time = in_time
		new_data.checkpoints_used = in_num_checkpoints
		star_data_lookup[in_id] = star_data.size()
		star_data.append(new_data)

	#did we collect more coins this time?
	if in_coins > coins:
		#print("this star also has more coins, so let's update the coin count on this block")
		#yes, assign new coin value
		coins = in_coins

func get_star_data(in_id : String) -> StarSaveData:
	if star_data_lookup.has(in_id):
		return star_data[star_data_lookup[in_id]]
	else:
		return null
