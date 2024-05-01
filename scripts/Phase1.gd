extends State

func enter():
	super.enter()
	owner.alpha = 0.111
	owner.bullet_type = 0
	speed.start()

func transition():
	if can_transition:
		get_parent().change_state("Phase2")
