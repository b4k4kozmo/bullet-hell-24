extends Node2D
class_name BossFSM
## Phase machine for a boss. States are child nodes; transitions are NodePaths,
## so a mistyped transition is a broken reference the editor shows you rather
## than a string that silently fails at runtime.

## The phase entered when the player is first detected.
@export var initial_phase: NodePath

var current_state: State
var previous_state: State


func _ready() -> void:
	current_state = get_child(0) as State
	previous_state = current_state
	current_state.enter()


## Enters `state`. Never fails silently: a bad target is reported and ignored
## rather than crashing on a null, which is how the old string lookup behaved.
func change_to(state: State) -> void:
	if state == null:
		push_error("%s: change_to() got null - check a phase's next_phase path" % _boss_name())
		return
	if state == current_state:
		return
	var leaving := current_state
	current_state = state
	current_state.enter()
	leaving.exit()
	previous_state = leaving


## Forces the machine out of Idle into its opening phase.
##
## Idle waits for the player to wander into a detection radius, which suited a
## single room with bosses scattered around it. A stage is an explicit fight, so
## the arena starts it instead - otherwise a stage whose boss happens to sit
## further than the detection radius from the player spawn never begins.
func engage() -> void:
	if current_state is BossPhase:
		return
	var announce := get_node_or_null("AudioStreamPlayer2D")
	if announce:
		announce.play()
	change_to_path(initial_phase)


## Resolves a NodePath relative to this machine and enters it.
func change_to_path(path: NodePath) -> void:
	if path.is_empty():
		push_error("%s: empty phase path" % _boss_name())
		return
	var target := get_node_or_null(path)
	if target == null:
		push_error("%s: no phase node at '%s'" % [_boss_name(), path])
		return
	change_to(target as State)


func _boss_name() -> String:
	return owner.name if owner else name
