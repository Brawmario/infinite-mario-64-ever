class_name MarioPauseMenu extends Control

@onready var resume_label = $Control/LabelContainer/ResumeLabel
@onready var respawn_label = $Control/LabelContainer/RespawnLabel
@onready var generate_new_level_label = $Control/LabelContainer/GenerateNewLevelLabel
@onready var view_stage_label = $Control/LabelContainer/ViewStageLabel
@onready var history_label = $Control/LabelContainer/HistoryLabel
@onready var settings_label = $Control/LabelContainer/SettingsLabel
@onready var exit_label = $Control/LabelContainer/ExitLabel
@onready var label_container = $Control/LabelContainer
@onready var generate_prompt = $GeneratePrompt
@onready var seed_text := $GeneratePrompt/ColorRect/HBoxContainer/SeedText as LineEdit
@onready var seed_button = $GeneratePrompt/ColorRect/HBoxContainer/SeedButton
@onready var restart_request = $RestartRequest

var selected_menu_option : int = 0
var restart_requested : bool = false
var hide_pause_menu : bool = false
var last_stick_value : Vector2 = Vector2.ZERO
var h_das_timer : int = 0
var h_last_das_trigger : int = 0
var v_das_timer : int = 0
var v_last_das_trigger : int = 0
const das : int = 200
const arr : int = 60

# Called when the node enters the scene tree for the first time.
func _ready():
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	resume_label.label_settings.font_color = Color(1, 1, 1)
	star_counter.text = "* x " + str(SOGlobal.save_data.get_total_star_count())
	coin_counter.text = "$ x " + str(SOGlobal.save_data.get_total_coin_coint())

func change_menu_selection(desired_selected : int) -> void:
	
	for label in label_container.get_children():
		label.label_settings.font_color = Color(0.5, 0.5, 0.5)
	
	selected_menu_option = desired_selected
	if selected_menu_option < 0:
		selected_menu_option = 6
	if selected_menu_option > 6:
		selected_menu_option = 0
	
	match selected_menu_option:
		0:
			resume_label.label_settings.font_color = Color(1, 1, 1)
		1:
			respawn_label.label_settings.font_color = Color(1, 1, 1)
		2:
			generate_new_level_label.label_settings.font_color = Color(1, 1, 1)
		3:
			view_stage_label.label_settings.font_color = Color(1, 1, 1)
		4:
			history_label.label_settings.font_color = Color(1, 1, 1)
		5:
			settings_label.label_settings.font_color = Color(1, 1, 1)
		6:
			exit_label.label_settings.font_color = Color(1, 1, 1)

func call_selection_function(desired_button : int) -> void:
	match desired_button:
		0: # resume
			_unpause()
		1: # retry
			SOGlobal.current_mario._respawn_mario()
			SOGlobal.play_sound(preload("res://mario/enter_painting.WAV"))
			for child in SOGlobal.get_children():
				if child is PowerStar:
					child._respawn()
				if child is Coin:
					child._respawn()
			_unpause()
		2: # generate new level
			SOGlobal.current_level_manager._create_mario_world()
			_unpause()
		3: # view level
			print("todo")
		4: # seed history
			var seed_history_ui = preload("res://mario/seed_history.tscn").instantiate()
			seed_history_ui.pause_menu = self
			add_child(seed_history_ui)
			hide_pause_menu = true
		5: # open settings
			var settings_ui = preload("res://mario/settings_menu.tscn").instantiate()
			settings_ui.pause_menu = self
			add_child(settings_ui)
			hide_pause_menu = true
		6: # quit
			SOGlobal.save_data.save_game()
			get_tree().quit()

func _unpause() -> void:
	await get_tree().create_timer(0.05).timeout
	SOGlobal.current_mario._paused = false
	SOGlobal.current_mario._last_tick_usec = Time.get_ticks_usec()
	queue_free()

@onready var star_counter = $Control/StatDisplay/HBoxContainer/StarCounter
@onready var coin_counter = $Control/StatDisplay/HBoxContainer/CoinCounter
@onready var control = $Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hide_pause_menu:
		control.visible = false
		generate_prompt.visible = false
		return
	else:
		control.visible = true
		generate_prompt.visible = true
	
	if SOGlobal.unfocused:
		return
	
	restart_request.visible = SOGlobal.restart_desired
	
	var inp = Input.get_vector("mario_stick_left", "mario_stick_right", "mario_stick_up", "mario_stick_down", 0)
	
	inp.x = move_toward(inp.x, 0, 0.5)
	inp.y = move_toward(inp.y, 0, 0.5)
	
	var h_dir : int = 0
	var v_dir : int = 0
	
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
	
	if Input.is_action_just_pressed("mario_a"):
		call_selection_function(selected_menu_option)
	
	if Input.is_action_just_pressed("mario_b") or Input.is_action_just_pressed("start_button"):
		_unpause()

func _on_seed_button_pressed():
	SOGlobal.current_level_manager._create_mario_world(seed_text.text)
	_unpause()

func _on_seed_text_text_submitted(new_text):
	SOGlobal.current_level_manager._create_mario_world(seed_text.text)
	_unpause()
