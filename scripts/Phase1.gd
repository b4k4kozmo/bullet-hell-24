extends State

func enter():
	super.enter()
	owner.alpha = 0.111
	owner.bullet_type = 0
	speed.start()
	$"../AudioStreamPlayer2D".play()
	if Bgm.stream != load("res://sounds/loop_nice.wav"):
		Bgm.stream = load("res://sounds/loop_nice.wav")
		Bgm.play()

func transition():
	if can_transition:
		$"../AudioStreamPlayer2D".play()
		get_parent().change_state("Phase2")
