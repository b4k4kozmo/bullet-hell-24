extends CharacterBody2D

var theta: float = 0.0
@export_range(0,2*PI) var alpha: float = 0.0
@export var health = 999

@export var bullet_node: PackedScene
var bullet_type: int = 0
var starting_phase = "Phase2"

func _process(_delta):
	$ProgressBar2.value = health
	if health <= 0:
		queue_free()
func set_status(bullet_type):
	match bullet_type:
		4:
			if $"../Player".debug.text == "debug":
				health -= 8
			else:
				health -= 6
		5:
			if $"../Player".debug.text == "debug":
				health -= 6
				for i in range(4):
					health -= 1
					await get_tree().create_timer(1).timeout
			else:
				health -= 4
		6:
			if $"../Player".health < 100:
				if $"../Player".debug.text == "debug":
					health -= 10
					$"../Player".health += .1
				else:
					health -= 8
			elif $"../Player".health == 100:
				health -= 12
func get_vector(angle):
	theta = angle + alpha
	return Vector2(cos(theta),sin(theta))
	
func shoot(angle):
	var bullet = bullet_node.instantiate()
	
	bullet.position = global_position
	bullet.direction = get_vector(angle)
	bullet.set_property(bullet_type)
	
	get_tree().current_scene.call_deferred("add_child", bullet)


func _on_speed_timeout():
	shoot(theta)
