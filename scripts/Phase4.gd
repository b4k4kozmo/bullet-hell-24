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
		speed.wait_time -= 0.01
		get_parent().change_state("Phase1")
