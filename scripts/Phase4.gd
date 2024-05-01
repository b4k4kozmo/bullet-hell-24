extends State

func enter():
	super.enter()
	owner.alpha = 3
	#can change music in different states
	#Bgm.stop()
	owner.bullet_type = 3
	speed.start()

func transition():
	if can_transition:
		get_parent().change_state("Phase1")
