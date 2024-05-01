extends State

func enter():
	super.enter()
	owner.alpha = 4
	owner.bullet_type = 2
	speed.start()

func transition():
	if can_transition:
		get_parent().change_state("Phase4")
