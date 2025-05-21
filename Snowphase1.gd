extends State

func enter():
	super.enter()
	owner.alpha = 50
	owner.bullet_type = 8
	speed.start()

func transition():
	if can_transition:
		#get_parent().change_state("Snowphase 1")
		pass
