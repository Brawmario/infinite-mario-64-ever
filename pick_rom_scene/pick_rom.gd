extends Control


func _on_prompt_rom_button_pressed() -> void:
	%RomPickerDialog.pick_rom()


func _on_rom_picker_dialog_rom_loaded() -> void:
	get_tree().change_scene_to_file("res://overlay_main.tscn")
