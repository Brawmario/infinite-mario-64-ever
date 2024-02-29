class_name BlockNametag extends Node3D

@onready var label_3d = $Label3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_nametag(in_tag : String) -> void:
	label_3d.text = in_tag
