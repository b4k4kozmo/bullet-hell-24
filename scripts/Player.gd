extends CharacterBody2D

var speed = 250
@onready var debug = $Debug
@onready var progress_bar = $ProgressBar

var health = 100:
	#updates health bar
	set(value):
		health = value
		progress_bar.value = value

func _physics_process(_delta):
	if Input.is_action_pressed('walk'):
		speed = 100
	if Input.is_action_just_released('walk'):
		speed = 250
	if health <= 0:
		debug.text = "dead"
	velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * speed
	
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

func fire():
	debug.text = "fire"
	health -= 10
	$AudioStreamPlayer2D.play()
	for i in range(5):
		health -= 1
		await get_tree().create_timer(0.5).timeout

func poison():
	debug.text = "poison"
	$AudioStreamPlayer2D.play()
	for i in range(5):
		health -= 2
		await get_tree().create_timer(1).timeout

func slow():
	debug.text = "slow"
	$AudioStreamPlayer2D.play()
	speed = 50
	health -= 5
	await get_tree().create_timer(2.5).timeout
	speed = 250

func stun():
	debug.text = "stun"
	$AudioStreamPlayer2D.play()
	speed = 0
	health -= 1
	await get_tree().create_timer(2.5).timeout
	speed = 250

func restart():
	get_tree().reload_current_scene()
