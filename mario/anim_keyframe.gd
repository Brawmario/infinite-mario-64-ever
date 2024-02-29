class_name AnimKeyframe extends Resource

@export var time : float
@export var position : Vector3
@export var rotation : Basis
@export var rotation_euler : Vector3:
	get:
		return rotation.get_euler()
	set(in_euler):
		rotation = Basis.from_euler(in_euler)
		rotation_euler = in_euler
	
