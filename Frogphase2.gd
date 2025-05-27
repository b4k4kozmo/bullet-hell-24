extends State

func enter():
	super.enter()
	owner.alpha = -.444
	owner.bullet_type = 7
	speed.start()

func transition():
	if can_transition:
		get_parent().change_state("Frogphase1")
