extends CharacterBody2D

var speed = 250
var shuriken_count = 255
var cantWalk = false
@onready var debug = $Debug
@onready var progress_bar = $ProgressBar2
@export var bullet_node: PackedScene
var bullet_type: int = 4
var bullet_type2: int = 6
var theta: float = 0.0
@export_range(0,2*PI) var alpha: float = 0.0

var health = 100:
	#updates health bar
	set(value):
		health = value
		progress_bar.value = value

func _ready():
	$HitboxDisplay.hide()
func get_vector(angle):
	theta = angle + alpha
	return Vector2(cos(theta),sin(theta))
func shoot(angle):
	var bullet = bullet_node.instantiate()
	
	bullet.position = global_position
	if velocity != Vector2.ZERO:
		bullet.set_property(bullet_type2)
		bullet.player_spiral_bullet = false
		bullet.direction = Vector2.UP
		$Speed.wait_time = .21
	else:
		if shuriken_count > 0:
			bullet.set_property(bullet_type)
			bullet.player_spiral_bullet = true
			bullet.direction = get_vector(angle)
			$Speed.wait_time = .0444
			shuriken_count -= 1
		else:
			return
	
	bullet.player_bullet = true
	get_tree().current_scene.call_deferred("add_child", bullet)
	

func _physics_process(_delta):
	if Input.is_action_just_pressed('action'):
		$Speed.start()
	if Input.is_action_just_released("action"):
		$Speed.stop()
	if Input.is_action_pressed('walk'):
		$HitboxDisplay.show()
		if not cantWalk:
			speed = 100
	if Input.is_action_just_released('walk'):
		if not cantWalk:
			speed = 250
		$HitboxDisplay.hide()
	if health <= 0:
		restart()
		debug.text = "dead"
	velocity = Input.get_vector("move_left","move_right","move_up","move_down") * speed
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("restart"):
		restart()
		
	move_and_slide()

func set_status(bullet_type):
	match bullet_type:
		0:
			fire()
		1:
			poison()
		2:
			slow()
		3:
			stun()
		7:
			$AudioStreamPlayer2D.play()
			health -= 7
		8:
			slow()
		9:
			$AudioStreamPlayer2D.play()
			health += 5

func fire():
	debug.text = "fire"
	#health -= 10
	$AudioStreamPlayer2D.play()
	for i in range(5):
		health -= 1
		await get_tree().create_timer(0.5).timeout
	debug.text = "debug"

func poison():
	debug.text = "poison"
	$AudioStreamPlayer2D.play()
	for i in range(5):
		health -= 2
		await get_tree().create_timer(1).timeout
	debug.text = "debug"

func slow():
	debug.text = "slow"
	$AudioStreamPlayer2D.play()
	cantWalk = true
	speed = 50
	health -= 5
	await get_tree().create_timer(2.5).timeout
	cantWalk = false
	speed = 250
	debug.text = "debug"

func stun():
	debug.text = "stun"
	$AudioStreamPlayer2D.play()
	speed = 0
	cantWalk = true
	health -= 1
	await get_tree().create_timer(2.5).timeout
	cantWalk = false
	speed = 250
	debug.text = "debug"

func restart():
	get_tree().reload_current_scene()
	Bgm.stream = load("res://sounds/Silent Way.mp3")
	Bgm.play()


func _on_speed_timeout():
	shoot(theta)
