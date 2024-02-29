extends Control

var pause_menu : MarioPauseMenu
var last_stick_value : Vector2 = Vector2.ZERO
var h_das_timer : int = 0
var h_last_das_trigger : int = 0
var v_das_timer : int = 0
var v_last_das_trigger : int = 0
const das : int = 200
const arr : int = 60


func close():
	pause_menu.hide_pause_menu = false
	queue_free()

func toggle_transparency():
	if ProjectSettings.get_setting("display/window/size/transparent") == false:
		ProjectSettings.set_setting("display/window/size/transparent", true)
		ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)
		ProjectSettings.set_setting("rendering/viewport/transparent_background", true)
		get_window().transparent = true
		get_window().transparent_bg = true
		get_viewport().transparent_bg = true
	else:
		ProjectSettings.set_setting("display/window/size/transparent", false)
		ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", false)
		ProjectSettings.set_setting("rendering/viewport/transparent_background", false)
		get_window().transparent = false
		get_window().transparent_bg = false
		get_viewport().transparent_bg = false
	ProjectSettings.save()
	SOGlobal.restart_desired = true

var selected_menu_option : int = 0
@onready var label_container = $Control/LabelContainer
@onready var screen_res_label = $Control/LabelContainer/ScreenResLabel
@onready var transparency_label = $Control/LabelContainer/TransparencyLabel
@onready var fullscreen_label = $Control/LabelContainer/FullscreenLabel
@onready var border_label = $Control/LabelContainer/BorderLabel

var resolutions : Array[Vector2] = []
var picked_res : int = 0
func _ready():
	resolutions.append(Vector2(320, 240))
	resolutions.append(Vector2(640, 360))
	resolutions.append(Vector2(640, 480))
	resolutions.append(Vector2(1024, 576))
	resolutions.append(Vector2(1024, 768))
	resolutions.append(Vector2(1280, 720))
	resolutions.append(Vector2(1280, 960))
	resolutions.append(Vector2(1366, 768))
	resolutions.append(Vector2(1600, 900))
	resolutions.append(Vector2(1600, 1200))
	resolutions.append(Vector2(1920, 1080))
	var closest_res_index : int = 0
	var current_closest_res_value : int = 0
	var current_smallest_diff : int = 0xFFFFFFFF
	var window_res_value : int = get_viewport().size.x * get_viewport().size.y
	for i in resolutions.size():
		var this_res_value : int = resolutions[i].x * resolutions[i].y
		var cur_diff : int = absi(this_res_value - window_res_value)
		if cur_diff < current_smallest_diff:
			current_smallest_diff = cur_diff
			current_closest_res_value = this_res_value
			closest_res_index = i
	
	picked_res = closest_res_index
	
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	screen_res_label.label_settings.font_color = Color(1, 1, 1)

func change_menu_selection(desired_selected : int) -> void:
	
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	
	selected_menu_option = desired_selected
	if selected_menu_option < 0:
		selected_menu_option = 3
	if selected_menu_option > 3:
		selected_menu_option = 0
	
	match selected_menu_option:
		0:
			screen_res_label.label_settings.font_color = Color(1, 1, 1)
		1:
			fullscreen_label.label_settings.font_color = Color(1, 1, 1)
		2:
			border_label.label_settings.font_color = Color(1, 1, 1)
		3:
			transparency_label.label_settings.font_color = Color(1, 1, 1)

func call_change_function(desired_button : int, dir : int) -> void:
	match desired_button:
		0: # res
			picked_res += dir
			if picked_res >= resolutions.size():
				picked_res = 0
			if picked_res < 0:
				picked_res = resolutions.size() - 1
			get_window().size = resolutions[picked_res]
		1: # fs
			if get_window().mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
				get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			else:
				get_window().mode = Window.MODE_WINDOWED
		2: # border
			var old_res : Vector2 = get_window().size
			get_window().borderless = !get_window().borderless
			get_window().size = old_res
		3: # trans
			toggle_transparency()

func _process(delta):
	if !visible:
		return
	
	var inp = Input.get_vector("mario_stick_left", "mario_stick_right", "mario_stick_up", "mario_stick_down", 0)
	
	inp.x = move_toward(inp.x, 0, 0.5)
	inp.y = move_toward(inp.y, 0, 0.5)
	
	var h_dir : int = 0
	var v_dir : int = 0
	
	if inp.x != 0:
		h_dir = sign(inp.x)
		if last_stick_value.x == 0:
			h_das_timer = Time.get_ticks_msec()
			call_change_function(selected_menu_option, h_dir)
		if Time.get_ticks_msec() > h_das_timer + das:
			if Time.get_ticks_msec() > h_last_das_trigger + arr:
				h_last_das_trigger = Time.get_ticks_msec()
				# we probably actually don't want to auto-repeat a settings change LOL
				#call_change_function(selected_menu_option, h_dir)
	if inp.y != 0:
		v_dir = sign(inp.y)
		if last_stick_value.y == 0:
			v_das_timer = Time.get_ticks_msec()
			change_menu_selection(selected_menu_option + v_dir)
		if Time.get_ticks_msec() > v_das_timer + das:
			if Time.get_ticks_msec() > v_last_das_trigger + arr:
				v_last_das_trigger = Time.get_ticks_msec()
				change_menu_selection(selected_menu_option + v_dir)
	
	
	last_stick_value = inp
	
	if Input.is_action_just_pressed("mario_b") or Input.is_action_just_pressed("start_button"):
		close()
	
	# this is such a stupid way to do this and so is pretty much everything else in these menu UI scripts
	# but it works and it doesn't matter during gameplay so YAY
	
	var viewport_res : Vector2 = get_viewport().size
	screen_res_label.text = "Screen Resolution\n" + str(viewport_res.x) + "x" + str(viewport_res.y)
	
	var fs_string : String = "Disabled"
	if get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		fs_string  = "Enabled"
	fullscreen_label.text = "Fullscreen\n" + fs_string
	
	var border_string : String = "Disabled"
	if get_window().borderless == true:
		border_string  = "Enabled"
	border_label.text = "Borderless\n" + border_string
	
	var transparency_string : String = "Disabled"
	if get_window().transparent == true:
		transparency_string  = "Enabled"
	transparency_label.text = "Transparent Background\n" + transparency_string
