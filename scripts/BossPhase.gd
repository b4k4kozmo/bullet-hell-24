extends State
class_name BossPhase
## One attack phase, configured entirely from the inspector.
##
## This replaces the eleven near-identical per-phase scripts the project used to
## carry. Those were attached to nodes on several different bosses at once, so
## editing one boss silently edited the others - that aliasing is what removed
## Kamijack's second phase in commit 3d1113d.

## Angular step added to the fire vector each shot. This is what shapes the
## spiral: small values sweep slowly, large values scatter.
@export var alpha: float = 0.0

## Index into Bullet.texture_array; also selects the status effect on hit.
@export var bullet_type: int = 0

## Seconds between shots, before difficulty scaling.
@export var fire_rate: float = 0.1

## How long this phase lasts before moving on.
@export var phase_duration: float = 3.0

## The phase to enter next. Accepts either form a NodePath can take here:
## what the editor writes when you pick a sibling ("../Phase2") and what is
## natural to write by hand ("Phase2").
@export var next_phase: NodePath

## Optional track to switch the BGM to when this phase starts.
@export var music: AudioStream

## Multiplies the boss's running fire-rate scale on the way out, so a cycle can
## escalate. 1.0 leaves it alone; 0.5 makes the next lap twice as fast.
@export var escalate_on_exit: float = 1.0

## Never let difficulty or escalation drive the timer below one frame at 60fps.
const MIN_FIRE_RATE := 0.016


func enter() -> void:
	duration.wait_time = phase_duration
	super.enter()
	owner.alpha = alpha
	owner.bullet_type = bullet_type
	speed.wait_time = maxf(fire_rate * owner.rate_scale / Difficulty.fire_rate_mult, MIN_FIRE_RATE)
	speed.start()
	if music and Bgm.stream != music:
		Bgm.stream = music
		Bgm.play()


func exit() -> void:
	super.exit()
	if escalate_on_exit != 1.0:
		owner.rate_scale *= escalate_on_exit


func transition() -> void:
	if not can_transition:
		return
	var target := resolve_next()
	if target == null:
		push_error("%s/%s: next_phase '%s' resolves to nothing" % [owner.name, name, next_phase])
		return
	(get_parent() as BossFSM).change_to(target)


## Resolves next_phase against this node first (the form the editor writes),
## then against the state machine (the form that reads naturally by hand).
func resolve_next() -> State:
	if next_phase.is_empty():
		return null
	var target := get_node_or_null(next_phase)
	if target == null:
		target = get_parent().get_node_or_null(next_phase)
	return target as State
