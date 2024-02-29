extends Gift

@onready var audio_stream_player = $AudioStreamPlayer
@onready var mario_node : SM64Mario = $"../RandomMario"
@onready var sm_64_static_surface_handler = $"../SM64StaticSurfaceHandler"
@onready var sm_64_surface_objects_handler = $"../SM64SurfaceObjectsHandler"
var enable_twitch : bool = false

var cooldown_list = {}

func _ready() -> void:
	if !enable_twitch:
		return
	event.connect(on_event)
	chat_message.connect(on_chat)

	# I use a file in the working directory to store auth data
	# so that I don't accidentally push it to the repository.
	# Replace this or create a auth file with 3 lines in your
	# project directory:
	# <client_id>
	# <client_secret>
	# <initial channel>
	var authfile := FileAccess.open("./example/auth.txt", FileAccess.READ)
	client_id = authfile.get_line()
	client_secret = authfile.get_line()
	var initial_channel = authfile.get_line()

	# When calling this method, a browser will open.
	# Log in to the account that should be used.
	await(authenticate(client_id, client_secret))
	var success = await(connect_to_irc())
	if (success):
		request_caps()
		join_channel(initial_channel)
		await(channel_data_received)
	await(connect_to_eventsub()) # Only required if you want to receive EventSub events.
	# Refer to https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/ for details on
	# what events exist, which API versions are available and which conditions are required.
	# Make sure your token has all required scopes for the event.
	subscribe_event("channel.follow", 2, {"broadcaster_user_id": user_id, "moderator_user_id": user_id})
	subscribe_event("channel.subscribe", 1, {"broadcaster_user_id": user_id})
	subscribe_event("channel.channel_points_custom_reward_redemption.add", 1, {"broadcaster_user_id": user_id})

	# Adds a command with a specified permission flag.
	# All implementations must take at least one arg for the command info.
	# Implementations that recieve args requrires two args,
	# the second arg will contain all params in a PackedStringArray
	# This command can only be executed by VIPS/MODS/SUBS/STREAMER
	#add_command("test", command_test, 0, 0, PermissionFlag.NON_REGULAR)
	
	add_command("spawnblock", chat_spawn_block)
	add_command("spawnbrick", chat_spawn_brick)
	add_command("spawncoin", chat_spawn_coin)
	add_command("banmyself", ban_myself)
	add_command("burn", chat_set_mario_burning)
	add_command("lowgrav", chat_set_mario_gravity_lw)
	add_command("highgrav", chat_set_mario_gravity_hi)
	
	# These two commands can be executed by everyone
	#add_command("helloworld", hello_world)
	#add_command("greetme", greet_me)

	# This command can only be executed by the streamer
	#add_command("streamer_only", streamer_only, 0, 0, PermissionFlag.STREAMER)

	# Command that requires exactly 1 arg.
	#add_command("greet", greet, 1, 1)

	# Command that prints every arg seperated by a comma (infinite args allowed), at least 2 required
	#add_command("list", list, -1, 2)

	# Adds a command alias
	#add_alias("test","test1")
	#add_alias("test","test2")
	#add_alias("test","test3")
	# Or do it in a single line
	# add_aliases("test", ["test1", "test2", "test3"])

	# Remove a single command
	#remove_command("test2")

	# Now only knows commands "test", "test1" and "test3"
	#remove_command("test")
	# Now only knows commands "test1" and "test3"

	# Remove all commands that call the same function as the specified command
	#purge_command("test1")
	# Now no "test" command is known

	# Send a chat message to the only connected channel (<channel_name>)
	# Fails, if connected to more than one channel.
#	chat("TEST")

	# Send a chat message to channel <channel_name>
#	chat("TEST", initial_channel)

	# Send a whisper to target user (requires user:manage:whispers scope)
#	whisper("TEST", initial_channel)

func on_event(type : String, data : Dictionary) -> void:
	match(type):
		"channel.follow":
			print("%s followed your channel!" % data["user_name"])
		"channel.subscribe":
			print("OHH FUUUCK A SUPIPER!!")
		"channel.channel_points_custom_reward_redemption.add":
			for i in data:
				print(i)
				print(data[i])
				print("---")

var block_spawn_sounds : Array = [preload("res://mario/sfx/sm64_boo.wav"), preload("res://mario/sfx/sm64_warp.wav"), preload("res://mario/sfx/sm64_transition_sound.wav")]

func ban_myself(cmd_info : CommandInfo):
	chat("/ban " + cmd_info.sender_data.user)

func check_cooldown(in_name : String) -> bool:
	if in_name == "twilightpb":
		return true
	if cooldown_list.has(in_name):
		return Time.get_ticks_msec() > cooldown_list[in_name] + 20000
	return true

func set_cooldown(in_name : String) -> void:
	cooldown_list[in_name] = Time.get_ticks_msec()

func chat_spawn_block(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	var new_block_pos : Vector3 = mario_node.position + Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), mario_node._face_angle - deg_to_rad(90)) * 6
	new_block_pos = snapped(new_block_pos, Vector3(1.0, 1.0, 1.0))
	var new_block_size : Vector3 = Vector3(randf_range(2, 6), randf_range(2, 6), randf_range(2, 6))
	new_block_size = snapped(new_block_size, Vector3(2, 2, 2))
	var new_block : MeshInstance3D = SOGlobal.generate_block_from_pos_and_size(new_block_pos, new_block_size, 0, 0, 0, 0, SOGlobal, LevelBlock.move_type.NONE, true)
	sm_64_surface_objects_handler.load_surface_object(new_block)
	var new_label = preload("res://mario/player_block_nametag.tscn").instantiate()
	SOGlobal.add_child(new_label)
	new_label.set_nametag(cmd_info.sender_data.user)
	new_label.position = new_block_pos + Vector3(0, new_block_size.y * 0.5 + 0.5, 0)
	SOGlobal.play_sound(block_spawn_sounds.pick_random())

func chat_spawn_brick(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	var new_block_pos : Vector3 = mario_node.position + Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), mario_node._face_angle - deg_to_rad(90)) * 6
	new_block_pos = snapped(new_block_pos, Vector3(1.0, 1.0, 1.0)) + Vector3(0.5, 0.5, 0.5)
	var new_block_size : Vector3 = Vector3(1, 1, 1)
	var new_block : MeshInstance3D = SOGlobal.generate_block_from_pos_and_size(new_block_pos, new_block_size, 0, 0, 0, 0, SOGlobal, LevelBlock.move_type.NONE, true)
	sm_64_surface_objects_handler.load_surface_object(new_block)
	var new_label = preload("res://mario/player_block_nametag.tscn").instantiate()
	SOGlobal.add_child(new_label)
	new_label.set_nametag(cmd_info.sender_data.user)
	new_label.position = new_block_pos + Vector3(0, new_block_size.y * 0.5 + 0.5, 0)
	new_label.scale = Vector3(0.5, 0.5, 0.5)
	SOGlobal.play_sound(block_spawn_sounds.pick_random(), 0.0, 1.5)

func chat_spawn_coin(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	var new_coin_pos : Vector3 = mario_node.position + Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), mario_node._face_angle - deg_to_rad(90)) * 6 + Vector3(0, 1, 0)
	var new_coin := SOGlobal.generate_yellow_coin_at_pos(new_coin_pos, false, true, Vector3(randf() * 2, randf() * 2 + 6, randf() * 2)) as Coin
	new_coin.destroy_on_retry = true
	#SOGlobal.play_sound(block_spawn_sounds.pick_random(), 0.0, 1.5)

func chat_set_mario_burning(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	SOGlobal.current_mario._internal.set_action(SM64MarioAction.LAVA_BOOST)

func chat_set_mario_gravity_lw(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	SOGlobal.current_mario.gravity_add = 20
	SOGlobal.current_mario.gravity_set_time = Time.get_ticks_msec()

func chat_set_mario_gravity_hi(cmd_info : CommandInfo):
	if !check_cooldown(cmd_info.sender_data.user):
		return
	set_cooldown(cmd_info.sender_data.user)
	SOGlobal.current_mario.gravity_add = -20
	SOGlobal.current_mario.gravity_set_time = Time.get_ticks_msec()
#gravity_add
#gravity_set_time
var sound_dictionary = {}

func play_say_sound(inSound : String) -> void:
	audio_stream_player.play()
	var saysound_playback : AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	sound_dictionary[inSound] = saysound_playback.play_stream(load(inSound), 0, -10, 1.0)

func on_chat(data : SenderData, msg : String) -> void:
	match msg:
		"cashews":
			play_say_sound("res://soundalerts/cashews.wav")
		"911":
			play_say_sound("res://soundalerts/911.wav")
		"aaha":
			play_say_sound("res://soundalerts/aaha.wav")
		"ahhh":
			play_say_sound("res://soundalerts/aaha.wav")
		"rory":
			play_say_sound("res://soundalerts/rory.wav")
		"bababooey":
			play_say_sound("res://soundalerts/bababooey.wav")
		"coin":
			play_say_sound("res://soundalerts/coin.wav")
		"assistance":
			play_say_sound("res://soundalerts/assistance.wav")
		"cornflakes":
			play_say_sound("res://soundalerts/cornflakes.wav")
		"cum":
			play_say_sound("res://soundalerts/cum.wav")
		"die":
			play_say_sound("res://soundalerts/die.wav")
		"drinkbeer":
			play_say_sound("res://soundalerts/drinkbeer.wav")
		"drown":
			play_say_sound("res://soundalerts/drown.wav")
		"dud":
			play_say_sound("res://soundalerts/dud.wav")
		"eddie":
			play_say_sound("res://soundalerts/eddie.wav")
		"fuckyou":
			play_say_sound("res://soundalerts/fuckyou.wav")
		"glass":
			play_say_sound("res://soundalerts/glass.wav")
		"goahead":
			play_say_sound("res://soundalerts/goahead.wav")
		"goku":
			play_say_sound("res://soundalerts/goku.wav")
		"goobebe":
			play_say_sound("res://soundalerts/goobebe.wav")
		"gorp":
			play_say_sound("res://soundalerts/gorp.wav")
		"greetings":
			play_say_sound("res://soundalerts/greetings.wav")
		"hellyeah":
			play_say_sound("res://soundalerts/hellyeah.wav")
		"hoh":
			play_say_sound("res://soundalerts/hoh.wav")
		"jokes":
			play_say_sound("res://soundalerts/jokes.wav")
		"lala":
			play_say_sound("res://soundalerts/lala2.wav")
		"lit":
			play_say_sound("res://soundalerts/lit.wav")
		"medicbag":
			play_say_sound("res://soundalerts/medicbag.wav")
		"mikey":
			play_say_sound("res://soundalerts/mikey.wav")
		"mymovie":
			play_say_sound("res://soundalerts/mymovie.wav")
		"no":
			play_say_sound("res://soundalerts/no.wav")
		"nooo":
			play_say_sound("res://soundalerts/no2.wav")
		"ooo":
			play_say_sound("res://soundalerts/ooo2.wav")
		"permanently":
			play_say_sound("res://soundalerts/permanently.wav")
		"poot":
			play_say_sound("res://soundalerts/poot.wav")
		"popping":
			play_say_sound("res://soundalerts/popping.wav")
		"puzzle":
			play_say_sound("res://soundalerts/puzzle.wav")
		"raisehell":
			play_say_sound("res://soundalerts/raisehell.wav")
		"roots":
			play_say_sound("res://soundalerts/roots.wav")
		"sonic":
			play_say_sound("res://soundalerts/sonic.wav")
		"splat":
			play_say_sound("res://soundalerts/splat.wav")
		"stonecold":
			play_say_sound("res://soundalerts/stonecold.wav")
		"swaggy":
			play_say_sound("res://soundalerts/swaggy.wav")
		"thatsit":
			play_say_sound("res://soundalerts/thatsit.wav")
		"unimaginablepain":
			play_say_sound("res://soundalerts/unimaginablepain.wav")
		"wawawewawu":
			play_say_sound("res://soundalerts/wawawewawu.wav")
		"what":
			play_say_sound("res://soundalerts/what.wav")
		"who":
			play_say_sound("res://soundalerts/who.wav")
		"woowoo":
			play_say_sound("res://soundalerts/woowoo.wav")
		"wub":
			play_say_sound("res://soundalerts/wub.wav")
		"xboxlive":
			play_say_sound("res://soundalerts/xboxlive.wav")
		"youbitch":
			play_say_sound("res://soundalerts/youbitch.wav")
		"yup":
			play_say_sound("res://soundalerts/yup.wav")
