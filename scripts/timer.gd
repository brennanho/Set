extends Label
var timer

func _process(delta):
	self.text = str(stepify(timer.time_left, 1))
	if timer.is_stopped():
		global.refresh_globals()
		get_tree().change_scene("Main.tscn")
	
func _ready():
	timer = get_parent()
	timer.start()
	self.text = str(timer.time_left)
	self.add_color_override("font_color", Color(0,0,0))
	set_process(true)