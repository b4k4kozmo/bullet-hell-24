extends State
## Waits for the player to enter detection range, then hands off to the boss's
## opening phase.

@onready var collision: CollisionShape2D = %CollisionShape2D

var player_entered := false:
	set(value):
		player_entered = value
		collision.set_deferred("disabled", value)


func _on_player_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered = true


func transition() -> void:
	if not player_entered:
		return
	var fsm := get_parent() as BossFSM
	$"../AudioStreamPlayer2D".play()
	fsm.change_to_path(fsm.initial_phase)
