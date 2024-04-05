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
	SOGlobal.current_mario.hide_hud = false
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
var selected_column : int = 0
@onready var label_container = $Control/LabelContainer
@onready var screen_res_label = $Control/LabelContainer/ScreenResLabel
@onready var transparency_label = $Control/LabelContainer/TransparencyLabel
@onready var fullscreen_label = $Control/LabelContainer/FullscreenLabel
@onready var border_label = $Control/LabelContainer/BorderLabel
@onready var fps_label = $Control/LabelContainer/FPSLabel
@onready var vsync_label = $Control/LabelContainer/VsyncLabel

@onready var controls_label_container = $Control/ControlsLabelContainer
@onready var raw_dot = $Control/ControlsLabelContainer/ColorRect/coord_disp_root/raw_dot
@onready var adj_dot = $Control/ControlsLabelContainer/ColorRect/coord_disp_root/adj_dot
@onready var rawcoord_x = $Control/ControlsLabelContainer/ColorRect/rawcoord_x
@onready var rawcoord_y = $Control/ControlsLabelContainer/ColorRect/rawcoord_y
@onready var adjcoord_x = $Control/ControlsLabelContainer/ColorRect/adjcoord_x
@onready var adjcoord_y = $Control/ControlsLabelContainer/ColorRect/adjcoord_y
@onready var inner_deadzone_label = $Control/ControlsLabelContainer/InnerDeadzoneLabel
@onready var outer_deadzone_label = $Control/ControlsLabelContainer/OuterDeadzoneLabel
@onready var horizontal_axis_label = $Control/ControlsLabelContainer/HorizontalAxisLabel

@onready var rebinding_label_container = $Control/ScrollContainer/RebindingLabelContainer
@onready var joy_left_label = $Control/ScrollContainer/RebindingLabelContainer/JoyLeftLabel
@onready var joy_right_label = $Control/ScrollContainer/RebindingLabelContainer/JoyRightLabel
@onready var joy_up_label = $Control/ScrollContainer/RebindingLabelContainer/JoyUpLabel
@onready var joy_down_label = $Control/ScrollContainer/RebindingLabelContainer/JoyDownLabel
@onready var c_up_label = $Control/ScrollContainer/RebindingLabelContainer/CUpLabel
@onready var c_down_label = $Control/ScrollContainer/RebindingLabelContainer/CDownLabel
@onready var c_left_label = $Control/ScrollContainer/RebindingLabelContainer/CLeftLabel
@onready var c_right_label = $Control/ScrollContainer/RebindingLabelContainer/CRightLabel
@onready var a_label = $Control/ScrollContainer/RebindingLabelContainer/ALabel
@onready var b_label = $Control/ScrollContainer/RebindingLabelContainer/BLabel
@onready var z_label = $Control/ScrollContainer/RebindingLabelContainer/ZLabel
@onready var cp_label = $Control/ScrollContainer/RebindingLabelContainer/CPLabel
@onready var cpl_label = $Control/ScrollContainer/RebindingLabelContainer/CPLLabel


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
	SOGlobal.current_mario.hide_hud = true
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
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	screen_res_label.label_settings.font_color = Color(1, 1, 1)

func change_menu_selection(desired_selected : int) -> void:
	
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	for label in controls_label_container.get_children():
		if label is Label:
			label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	for label in rebinding_label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	
	selected_menu_option = desired_selected
	match selected_column:
		0:
			if selected_menu_option < 0:
				selected_menu_option = 5
			if selected_menu_option > 5:
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
				4:
					fps_label.label_settings.font_color = Color(1, 1, 1)
				5:
					vsync_label.label_settings.font_color = Color(1, 1, 1)
		1:
			if selected_menu_option < 0:
				selected_menu_option = 2
			if selected_menu_option > 2:
				selected_menu_option = 0
			match selected_menu_option:
				0:
					inner_deadzone_label.label_settings.font_color = Color(1, 1, 1)
				1:
					outer_deadzone_label.label_settings.font_color = Color(1, 1, 1)
				2:
					horizontal_axis_label.label_settings.font_color = Color(1, 1, 1)
		2:
			if selected_menu_option < 0:
				selected_menu_option = 12
			if selected_menu_option > 12:
				selected_menu_option = 0
			match selected_menu_option:
				0:
					joy_left_label.label_settings.font_color = Color(1, 1, 1)
				1:
					joy_right_label.label_settings.font_color = Color(1, 1, 1)
				2:
					joy_up_label.label_settings.font_color = Color(1, 1, 1)
				3:
					joy_down_label.label_settings.font_color = Color(1, 1, 1)
				4:
					c_up_label.label_settings.font_color = Color(1, 1, 1)
				5:
					c_down_label.label_settings.font_color = Color(1, 1, 1)
				6:
					c_left_label.label_settings.font_color = Color(1, 1, 1)
				7:
					c_right_label.label_settings.font_color = Color(1, 1, 1)
				8:
					a_label.label_settings.font_color = Color(1, 1, 1)
				9:
					b_label.label_settings.font_color = Color(1, 1, 1)
				10:
					z_label.label_settings.font_color = Color(1, 1, 1)
				11:
					cp_label.label_settings.font_color = Color(1, 1, 1)
				12:
					cpl_label.label_settings.font_color = Color(1, 1, 1)

func call_change_function(desired_button : int, dir : int) -> void:
	print(selected_column)
	match selected_column:
		0:
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
				4: # fps
					Engine.max_fps = max(1, Engine.max_fps + dir)
				5: # vsync
					match DisplayServer.window_get_vsync_mode():
						DisplayServer.VSYNC_DISABLED:
							if dir == 1:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
							else:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
						DisplayServer.VSYNC_ENABLED:
							if dir == 1:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
							else:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
						DisplayServer.VSYNC_ADAPTIVE:
							if dir == 1:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
							else:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
						DisplayServer.VSYNC_MAILBOX:
							if dir == 1:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
							else:
								DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		1:
			match desired_button:
				0:
					SOGlobal.inner_deadzone = clamp(SOGlobal.inner_deadzone + (0.01 * dir), 0.0, SOGlobal.outer_deadzone)
				1:
					SOGlobal.outer_deadzone = clamp(SOGlobal.outer_deadzone + (0.01 * dir), SOGlobal.inner_deadzone, 1.0)
				2:
					SOGlobal.flip_x = !SOGlobal.flip_x
		2:
			print("ah")
			match desired_button:
				0:
					currently_binding_action = "mario_stick_left"
				1:
					currently_binding_action = "mario_stick_right"
				2:
					currently_binding_action = "mario_stick_up"
				3:
					currently_binding_action = "mario_stick_down"
				4:
					currently_binding_action = "cam_stick_left"
				5:
					currently_binding_action = "cam_stick_right"
				6:
					currently_binding_action = "cam_stick_up"
				7:
					currently_binding_action = "cam_stick_down"
				8:
					currently_binding_action = "mario_a"
				9:
					currently_binding_action = "mario_b"
				10:
					currently_binding_action = "mario_z"
				11:
					currently_binding_action = "dpad_up"
				11:
					currently_binding_action = "dpad_down"
			currently_binding = true

var currently_binding : bool = false
var currently_binding_action : String = "mario_a"
@onready var binding_menu_label = $Control/binding_menu_box/VBoxContainer/binding_menu_label
@onready var binding_menu_box = $Control/binding_menu_box


func _unhandled_input(event:InputEvent):
	if !currently_binding:
		return
	if event.is_pressed():
		if event is InputEventKey:
			event.physical_keycode = event.keycode
			event.keycode = 0
			if event.pressed:
				match event.physical_keycode:
					KEY_ESCAPE:
						currently_binding = false
						return
					KEY_BACKSPACE:
						InputMap.action_erase_events(currently_binding_action)
						currently_binding = false
						return
		InputMap.action_add_event(currently_binding_action, event)
		currently_binding = false
		grace_frames = 15

func prettify_action_name(in_action : String) -> String:
	match in_action:
		"mario_stick_left":
			return "Joystick Left"
		"mario_stick_right":
			return "Joystick Right"
		"mario_stick_up":
			return "Joystick Up"
		"mario_stick_down":
			return "Joystick Down"
		"cam_stick_left":
			return "C Left"
		"cam_stick_right":
			return "C Right"
		"cam_stick_up":
			return "C Up"
		"cam_stick_down":
			return "C Down"
		"mario_a":
			return "A Button"
		"mario_b":
			return "B Button"
		"mario_z":
			return "Z Button"
		"dpad_up":
			return "Place Checkpoint"
		"dpad_down":
			return "Return to Checkpoint"
	return "Unknown"

@onready var control_settings_guide = $Control/control_settings_guide
@onready var action_rebind_guide = $Control/action_rebind_guide

var grace_frames := 0

func _process(delta):
	if !visible:
		return
	
	if currently_binding:
		grace_frames = 15
		binding_menu_box.visible = true
		var binding_name : String = prettify_action_name(currently_binding_action)
		binding_menu_label.text = "Binding " + binding_name + "\n\nWaiting for input...\n\nESC to cancel, BACKSPACE to clear bindings"
		return
	else:
		if Input.is_action_just_pressed("start_button") and grace_frames == 0:
			close()
		binding_menu_box.visible = false
	
	grace_frames = maxf(0, grace_frames - 1)
	
	var inp = Input.get_vector("menu_left", "menu_right", "menu_up", "menu_down", 0)
	
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
	
	label_container.visible = false
	controls_label_container.visible = false
	rebinding_label_container.visible = false
	
	control_settings_guide.visible = false
	action_rebind_guide.visible = false
	# this is such a stupid way to do this and so is pretty much everything else in these menu UI scripts
	# but it works and it doesn't matter during gameplay so YAY
	match selected_column:
		0:
			control_settings_guide.visible = true
			action_rebind_guide.visible = true
			label_container.visible = true
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
			
			fps_label.text = "Max Framerate\n" + str(Engine.max_fps)
			
			var vsync_string : String = "Disabled"
			match DisplayServer.window_get_vsync_mode():
				DisplayServer.VSYNC_DISABLED:
					vsync_string = "Disabled"
				DisplayServer.VSYNC_ENABLED:
					vsync_string = "Enabled"
				DisplayServer.VSYNC_ADAPTIVE:
					vsync_string = "Adaptive"
				DisplayServer.VSYNC_MAILBOX:
					vsync_string = "Mailbox"
			vsync_label.text = "Vsync\n" + vsync_string
			if Input.is_action_just_pressed("menu_pageleft") and grace_frames == 0:
				selected_column = 2
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_pageright") and grace_frames == 0:
				selected_column = 1
				change_menu_selection(0)
		1:
			controls_label_container.visible = true
			var pl_input := PlayerInput.from_input()
			raw_dot.position = Vector2(Input.get_axis("mario_stick_left", "mario_stick_right"), Input.get_axis("mario_stick_up", "mario_stick_down")) * 64 - Vector2(2, 2)
			adj_dot.position = Vector2(pl_input.JoyXAxis, pl_input.JoyYAxis) * 64 - Vector2(2, 2)
			rawcoord_x.text = "x: " + str(snappedf(Input.get_axis("mario_stick_left", "mario_stick_right"), 0.001))
			rawcoord_y.text = "y: " + str(snappedf(Input.get_axis("mario_stick_up", "mario_stick_down"), 0.001))
			adjcoord_x.text = "x: " + str(snappedf(pl_input.JoyXAxis, 0.001))
			adjcoord_y.text = "y: " + str(snappedf(pl_input.JoyYAxis, 0.001))
			inner_deadzone_label.text = "Inner Deadzone\n" + str(snapped(SOGlobal.inner_deadzone, 0.01))
			outer_deadzone_label.text = "Outer Deadzone\n" + str(snapped(SOGlobal.outer_deadzone, 0.01))
			var xflipstring : String = "Enabled"
			if !SOGlobal.flip_x:
				xflipstring = "Disabled"
			horizontal_axis_label.text = "Camera Horizontal Axis Invert\n" + xflipstring
			if Input.is_action_just_pressed("menu_confirm") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_back") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_pageleft") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_pageright") and grace_frames == 0:
				selected_column = 2
				change_menu_selection(0)
		2:
			if Input.is_action_just_pressed("menu_confirm") and grace_frames == 0:
				call_change_function(selected_menu_option, 1)
			if Input.is_action_just_pressed("menu_back") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_pageleft") and grace_frames == 0:
				selected_column = 1
				change_menu_selection(0)
			if Input.is_action_just_pressed("menu_pageright") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)
			rebinding_label_container.visible = true
			joy_left_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_stick_left"):
				joy_left_label.text += event.as_text() + "\n"
				
			joy_right_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_stick_right"):
				joy_right_label.text += event.as_text() + "\n"
				
			joy_up_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_stick_up"):
				joy_up_label.text += event.as_text() + "\n"
				
			joy_down_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_stick_down"):
				joy_down_label.text += event.as_text() + "\n"
				
			c_up_label.text = ""
			for event:InputEvent in InputMap.action_get_events("cam_stick_left"):
				c_up_label.text += event.as_text() + "\n"
				
			c_down_label.text = ""
			for event:InputEvent in InputMap.action_get_events("cam_stick_right"):
				c_down_label.text += event.as_text() + "\n"
				
			c_left_label.text = ""
			for event:InputEvent in InputMap.action_get_events("cam_stick_up"):
				c_left_label.text += event.as_text() + "\n"
				
			c_right_label.text = ""
			for event:InputEvent in InputMap.action_get_events("cam_stick_down"):
				c_right_label.text += event.as_text() + "\n"
				
			a_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_a"):
				a_label.text += event.as_text() + "\n"
				
			b_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_b"):
				b_label.text += event.as_text() + "\n"
				
			z_label.text = ""
			for event:InputEvent in InputMap.action_get_events("mario_z"):
				z_label.text += event.as_text() + "\n"
				
			cp_label.text = ""
			for event:InputEvent in InputMap.action_get_events("dpad_up"):
				cp_label.text += event.as_text() + "\n"
				
			cpl_label.text = ""
			for event:InputEvent in InputMap.action_get_events("dpad_down"):
				cpl_label.text += event.as_text() + "\n"
			if Input.is_action_just_pressed("menu_back") and grace_frames == 0:
				selected_column = 0
				change_menu_selection(0)

func event_map_to_string(in_event : InputEvent) -> String:
	if in_event is InputEventJoypadButton:
		return "Button " + str(in_event.button_index)
	if in_event is InputEventJoypadMotion:
		return "Axis " + str(in_event.axis)
	return in_event.as_text()
