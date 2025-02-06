extends State

func enter():
	super.enter()
	owner.alpha = 7.77
	owner.bullet_type = 8
	speed.start()

func transition():
	if can_transition:
		get_parent().change_state("Jackphase3")
