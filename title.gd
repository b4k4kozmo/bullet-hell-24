extends Control
var anim_frame = 0
var boss_room = preload("res://boss_room.tscn").instantiate()

var simultaneous_scene = preload("res://boss_room.tscn").instantiate()

func _add_a_scene_manually():
	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
	get_tree().root.add_child(boss_room)
	get_tree().current_scene = boss_room
	queue_free()

func _process(delta):
	#get_tree().change_scene_to_file(boss_room)
	if Input.is_action_just_pressed("action"):
		Bgm.stream = load("res://sounds/KatsuBoySong.wav")
		Bgm.play()
		_add_a_scene_manually()

func _on_timer_timeout():
	if anim_frame == 0:
		$Sprite2D.texture = load("res://sprites/title_screen2.png")
		anim_frame = 1
	elif anim_frame == 1:
		$Sprite2D.texture = load("res://sprites/title_screen2.png")
		anim_frame = 2
	elif anim_frame == 2:
		$Sprite2D.texture = load("res://sprites/title_screen4.png")
		anim_frame = 3
	elif anim_frame == 3:
		$Sprite2D.texture = load("res://sprites/title_screen1.png")
		anim_frame = 0
