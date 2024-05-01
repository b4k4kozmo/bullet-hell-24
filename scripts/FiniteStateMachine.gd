extends Node2D

#for storing state
var current_state: State
var previous_state: State

func _ready():
	
	#enter idle state
	current_state = get_child(0) as State
	previous_state = current_state
	current_state.enter()

func change_state(state):
	if state == previous_state.name:
		return
	
	#enter state
	current_state = find_child(state) as State
	current_state.enter()
	
	#exit state
	previous_state.exit()
	previous_state = current_state
