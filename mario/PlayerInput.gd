class_name PlayerInput extends RefCounted

static var Neutral := PlayerInput.new()

enum PressedState {
	Released,
	JustReleased,
	Pressed,
	JustPressed
}

static func get_pressed_state( action:String ) -> PressedState:
	if Input.is_action_just_pressed(action):
		return PressedState.JustPressed
	if Input.is_action_pressed(action):
		return PressedState.Pressed
	if Input.is_action_just_released(action):
		return PressedState.JustReleased
	return PressedState.Released

var JoyXAxis := 0.0
var JoyYAxis := 0.0
var CUp := PressedState.Released
var CDown := PressedState.Released
var CLeft := PressedState.Released
var CRight := PressedState.Released
var AButton := PressedState.Released
var BButton := PressedState.Released
var ZButton := PressedState.Released
var CPSet := PressedState.Released
var CPLoad := PressedState.Released


static func from_input() -> PlayerInput:
	var result := PlayerInput.new()
	var x_fix = move_toward(Input.get_axis("mario_stick_left", "mario_stick_right"), 0, SOGlobal.inner_deadzone)
	var y_fix = move_toward(Input.get_axis("mario_stick_up", "mario_stick_down"), 0, SOGlobal.inner_deadzone)
	result.JoyXAxis = clampf(remap(x_fix, 0, SOGlobal.outer_deadzone - SOGlobal.inner_deadzone, 0.0, 1.0), -1.0, 1.0)
	result.JoyYAxis = clampf(remap(y_fix, 0, SOGlobal.outer_deadzone - SOGlobal.inner_deadzone, 0.0, 1.0), -1.0, 1.0)
	result.CUp = PlayerInput.get_pressed_state("cam_stick_up")
	result.CDown = PlayerInput.get_pressed_state("cam_stick_down")
	result.CLeft = PlayerInput.get_pressed_state("cam_stick_left")
	result.CRight = PlayerInput.get_pressed_state("cam_stick_right")
	result.AButton = PlayerInput.get_pressed_state("mario_a")
	result.BButton = PlayerInput.get_pressed_state("mario_b")
	result.ZButton = PlayerInput.get_pressed_state("mario_z")
	result.CPSet = PlayerInput.get_pressed_state("dpad_up")
	result.CPLoad = PlayerInput.get_pressed_state("dpad_down")
	return result
