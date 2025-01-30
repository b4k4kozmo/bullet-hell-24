extends Area2D

@export var texture_array : Array[Texture2D]

var speed = 100
var direction = Vector2.RIGHT
var bullet_type: int = 0

var player_bullet: bool
var player_spiral_bullet: bool
var enemy_bullet: bool

func _physics_process(delta):
	position += direction * speed * delta

func _on_screen_exited():
	queue_free()

func set_property(type):
	bullet_type = type
	$Sprite2D.texture = texture_array[type]
	


func _on_body_entered(body):
	body.set_status(bullet_type)
	if body.is_in_group("enemy"):
		if player_bullet:
			queue_free()
	if body.is_in_group("player"):
		if enemy_bullet:
			queue_free()


func _on_timer_timeout():
	if bullet_type == 4:
		set_property(5)
	elif bullet_type == 5:
		set_property(4)
 


func _on_area_entered(area):
	if "enemy_bullet" in area:
		if area.enemy_bullet && player_spiral_bullet:
			area.queue_free()
			$DespawnTimer.start()


func _on_despawn_timer_timeout():
	queue_free()
