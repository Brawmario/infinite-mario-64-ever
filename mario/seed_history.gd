extends Control

var pause_menu : MarioPauseMenu

var last_stick_value : Vector2 = Vector2.ZERO
var h_das_timer : int = 0
var h_last_das_trigger : int = 0
var v_das_timer : int = 0
var v_last_das_trigger : int = 0
const das : int = 200
const arr : int = 60
@onready var grid_container = $ColorRect/ScrollContainer/GridContainer


func close():
	pause_menu.hide_pause_menu = false
	queue_free()

func _ready():
	for block:SaveBlock in SOGlobal.save_data.save_blocks:
		var new_seed_button = preload("res://mario/seed_history_button.tscn").instantiate()
		new_seed_button.pause_menu = pause_menu
		new_seed_button.seed_text = block.seed
		grid_container.add_child(new_seed_button)

func _process(delta):
	if !visible:
		return
	
	if Input.is_action_just_pressed("mario_stick_down") or Input.is_action_just_pressed("dpad_down"):
		print("todo")
	
	if Input.is_action_just_pressed("mario_stick_up") or Input.is_action_just_pressed("dpad_up"):
		print("todo")
	
	if Input.is_action_just_pressed("mario_stick_right"):
		print("todo")
	
	if Input.is_action_just_pressed("mario_stick_left"):
		print("todo")
	
	if Input.is_action_just_pressed("mario_b") or Input.is_action_just_pressed("start_button"):
		close()
