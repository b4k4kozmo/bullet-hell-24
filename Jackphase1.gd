extends State

func enter():
	super.enter()
	owner.alpha = -.333
	owner.bullet_type = 0
	speed.start()


func transition():
	if can_transition:
		get_parent().change_state("Jackphase2")
