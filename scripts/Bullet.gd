extends Area2D

@export var texture_array : Array[Texture2D]

var speed = 100
var direction = Vector2.RIGHT
var bullet_type: int = 0

func _physics_process(delta):
	position += direction * speed * delta

func _on_screen_exited():
	queue_free()

func set_property(type):
	bullet_type = type
	$Sprite2D.texture = texture_array[type]
	


func _on_body_entered(body):
	body.set_status(bullet_type)


func _on_timer_timeout():
	if bullet_type == 4:
		set_property(5)
	elif bullet_type == 5:
		set_property(4)
