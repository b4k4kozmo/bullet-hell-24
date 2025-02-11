extends State

func enter():
	super.enter()
	owner.alpha = -.333
	owner.bullet_type = 0
	speed.start()
	if Bgm.stream != load("res://sounds/Dreaming through the Jungle.mp3"):
		Bgm.stream = load("res://sounds/Dreaming through the Jungle.mp3")
		Bgm.play()

func transition():
	if can_transition:
		get_parent().change_state("Jackphase2")
