extends State

func enter():
	super.enter()
	owner.alpha = 4.44
	#can change music in different states
	#Bgm.stop()
	owner.bullet_type = 9
	speed.start()

func transition():
	if can_transition:
		#speed.wait_time = speed.wait_time/2
		get_parent().change_state("Jackphase1")
