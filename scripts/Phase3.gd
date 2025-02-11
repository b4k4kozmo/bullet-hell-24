extends State

func enter():
	super.enter()
	owner.alpha = 4
	owner.bullet_type = 2
	speed.start()
	

func transition():
	if can_transition:
		$"../AudioStreamPlayer2D".play()
		get_parent().change_state("Phase4")
