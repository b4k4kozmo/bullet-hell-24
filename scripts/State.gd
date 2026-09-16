extends Node2D
class_name State

@onready var debug: Label = owner.find_child("Debug")
@onready var speed: Timer = owner.find_child("Speed")
@onready var duration: Timer = owner.find_child("Duration")

var can_transition := false


func _ready() -> void:
	set_physics_process(false)
	duration.timeout.connect(_on_duration_timeout)


func _on_duration_timeout() -> void:
	can_transition = true


func enter() -> void:
	set_physics_process(true)
	can_transition = false
	duration.start()


func exit() -> void:
	set_physics_process(false)


func transition() -> void:
	pass


func _physics_process(_delta: float) -> void:
	transition()
	if debug:
		debug.text = name
