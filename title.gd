extends Control

const FRAMES := [
	"res://sprites/title_screen1.png",
	"res://sprites/title_screen2.png",
	"res://sprites/title_screen3.png",
	"res://sprites/title_screen4.png",
]

var anim_frame := 0


func _ready() -> void:
	$Menu.difficulty_chosen.connect(_start_run)


func _start_run(id: int) -> void:
	Run.start(id)
	Bgm.stream = load("res://sounds/KatsuBoySong.wav")
	Bgm.play()
	get_tree().change_scene_to_file("res://boss_room.tscn")


func _on_timer_timeout() -> void:
	anim_frame = (anim_frame + 1) % FRAMES.size()
	$Sprite2D.texture = load(FRAMES[anim_frame])
