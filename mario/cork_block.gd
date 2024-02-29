class_name CorkBox extends Node3D

@onready var box_collision := $Cube as MeshInstance3D
var busted : bool = false
var bust_time : int = 0
var last_drop_time : int = 0
var contained_items : Array = []
var item_drop_index : int = 0
@onready var area_3d = $Area3D
@onready var shape_cast_3d = $ShapeCast3D
var on_bust : bool = false

func _ready():
	await get_tree().create_timer(0.1).timeout
	var intersecting = true
	while intersecting:
		shape_cast_3d.force_shapecast_update()
		if shape_cast_3d.is_colliding():
			position += Vector3.UP
		else:
			intersecting = false

func add_to_droplist(in_item_type : String) -> void:
	contained_items.append(in_item_type)

func _process(delta):
	if busted:
		scale += Vector3.ONE * delta
	if busted and Time.get_ticks_msec() > bust_time + 250:
		scale = Vector3.ONE
		visible = false
		if !on_bust:
			var our_surface_handler := SOGlobal.current_level_manager.sm_64_surface_objects_handler as SM64SurfaceObjectsHandler
			our_surface_handler.delete_surface_object(box_collision)
			SOGlobal.play_sound(preload("res://mario/sfx/sm64_breaking_box.wav"))
		on_bust = true
		if Time.get_ticks_msec() > last_drop_time + 50 and item_drop_index < contained_items.size():
			match contained_items[item_drop_index]:
				"coin":
					var new_coin := SOGlobal.generate_yellow_coin_at_pos(position, false, true, Vector3(randf() * 2, randf() * 2 + 2, randf() * 2)) as Coin
					new_coin.destroy_on_retry = true
				"star":
					var new_star := SOGlobal.generate_power_star("cork", position, position + Vector3(0, 1.5, 0)) as PowerStar
					new_star.destroy_on_retry = true
					
			item_drop_index += 1
			last_drop_time = Time.get_ticks_msec()

func _bust() -> void:
	area_3d.set_deferred("monitorable", false)
	area_3d.set_deferred("monitoring", false)
	busted = true
	bust_time = Time.get_ticks_msec()
	
func _reset() -> void:
	scale = Vector3.ONE
	area_3d.set_deferred("monitorable", true)
	area_3d.set_deferred("monitoring", true)
	busted = false
	bust_time = 0
	last_drop_time = 0
	item_drop_index = 0
	visible = true
	if on_bust:
		var our_surface_handler := SOGlobal.current_level_manager.sm_64_surface_objects_handler as SM64SurfaceObjectsHandler
		our_surface_handler.load_surface_object(box_collision)
	on_bust = false

func _on_area_3d_area_entered(area):
	if !visible:
		return
	if area.get_parent() is SM64Mario:
		_bust()
	else:
		position += Vector3.UP
