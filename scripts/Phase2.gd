extends State

func enter():
	super.enter()
	owner.alpha = 1.776
	owner.bullet_type = 1
	speed.start()

func transition():
	if can_transition:
		$"../AudioStreamPlayer2D".play()
		get_parent().change_state("Phase3")
