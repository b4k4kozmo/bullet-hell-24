extends CharacterBody2D
class_name Boss
## Shared behaviour for every boss. Replaces four near-identical copies
## (scripts/Spaghetti.gd, spaghetti2.gd, snowman.gd, frogoblin.gd) whose
## set_status blocks were byte-for-byte the same.

signal died(boss: Boss)

@export var max_health: int = 444
@export var xp_reward: int = 7
@export var bullet_node: PackedScene

## Current angular offset, driven by the active BossPhase.
@export var alpha: float = 0.0

var theta: float = 0.0
var bullet_type: int = 0
var health: int

## Running fire-rate multiplier. Phases with escalate_on_exit < 1 shrink it,
## so a boss speeds up each time it completes a cycle.
var rate_scale := 1.0

var _dying := false

@onready var _health_bar: ProgressBar = $ProgressBar2


func _ready() -> void:
	add_to_group("enemy")
	max_health = maxi(1, int(round(max_health * Difficulty.boss_hp_mult)))
	health = max_health
	_health_bar.max_value = max_health
	_health_bar.value = max_health


func _process(_delta: float) -> void:
	_health_bar.value = health
	if health <= 0 and not _dying:
		_die()


func _die() -> void:
	_dying = true
	# The XP award used to sit on the line *above* queue_free(), reached through
	# $"../Player". If that path missed, the award threw and the free never ran,
	# leaving the boss immortal at 0 HP and still firing. Freeing is now
	# unconditional and the player is looked up by group, not by sibling path.
	var player := _player()
	if player:
		player.experience += xp_reward
	died.emit(self)
	queue_free()


func _player() -> Node:
	var p := get_tree().get_first_node_in_group("player")
	return p if is_instance_valid(p) else null


## Called by Bullet when one lands on this boss. `incoming` is the bullet type:
## 4/5 are the player's shuriken frames, 6 is the sword.
func set_status(incoming: int) -> void:
	var player := _player()
	if player == null or _dying:
		return
	# The player's status-effect state currently lives in the text of its Debug
	# label; "debug" means no effect is active. Preserved as-is here - moving it
	# to a real enum is tracked in docs/SHIPPING_PLAN.md (S3).
	var unhindered: bool = player.debug.text == "debug"

	match incoming:
		4:
			health -= player.dexterity if unhindered else player.dexterity - 2
			$AudioStreamPlayer2D.play()
		5:
			$AudioStreamPlayer2D.play()
			if unhindered:
				health -= player.dexterity - 1
				for i in range(4):
					await get_tree().create_timer(1.0).timeout
					# The boss can die or the scene can reload mid-tick.
					if _dying or not is_instance_valid(self):
						return
					health -= 1
			else:
				health -= player.dexterity / 2
		6:
			if player.shuriken_count < 100:
				player.shuriken_count += 1
			if player.health < 100:
				health -= player.power
				if unhindered:
					player.health += .1
			elif player.health == 100:
				health -= player.power * 1.5
			$AudioStreamPlayer2D.play()


## Starts this boss's attack cycle immediately.
func engage() -> void:
	var fsm := find_child("FiniteStateMachine", false, false) as BossFSM
	if fsm:
		fsm.engage()


func get_vector(angle: float) -> Vector2:
	theta = angle + alpha
	return Vector2(cos(theta), sin(theta))


func shoot(angle: float) -> void:
	if bullet_node == null:
		return
	var bullet := bullet_node.instantiate()
	bullet.position = global_position
	bullet.direction = get_vector(angle)
	bullet.enemy_bullet = true
	bullet.set_property(bullet_type)
	var host := _bullet_host()
	if host:
		host.call_deferred("add_child", bullet)
	else:
		bullet.queue_free()


## Bullets live under a dedicated container when the scene provides one, so the
## arena can pause and clear them without touching the rest of the room.
func _bullet_host() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var host := scene.get_node_or_null("Bullets")
	return host if host else scene


func _on_speed_timeout() -> void:
	shoot(theta)
