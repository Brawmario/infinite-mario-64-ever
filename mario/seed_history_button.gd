extends Button

var pause_menu : MarioPauseMenu

@onready var seed_label := $HBoxContainer/VBoxContainer/SeedLabel as Label
@onready var stats_label := $HBoxContainer/VBoxContainer/StatsLabel as Label
@onready var time_label := $HBoxContainer/VBoxContainer/TimeLabel as Label
@onready var seed_pic = $HBoxContainer/SeedPic
var seed_text := "dkdsfkdf"

func _ready():
	seed_label.text = "Seed: " + seed_text
	stats_label.text = ""
	var block := SOGlobal.save_data.get_block_by_seed(seed_text)
	if block.star_data.size() > 0:
		var fastest_time : float = block.star_data[0].time
		if block.star_data.size() > 1:
			for star in block.star_data:
				fastest_time = minf(fastest_time, star.time)
				stats_label.text = stats_label.text + "*"
		else:
			stats_label.text = "*"
		time_label.text = "%02d:%02d.%03d" % [fastest_time/60.0, fmod(fastest_time, 60.0), fmod(fastest_time * 1000, 1000.0)]
		stats_label.text += "    $x" + str(block.coins)
	else:
		time_label.text = "No clear..."
	

func _on_pressed():
	SOGlobal.current_level_manager._create_mario_world(seed_text)
	await get_tree().create_timer(0.05).timeout
	SOGlobal.current_mario._paused = false
	pause_menu.queue_free()
