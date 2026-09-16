extends Node2D
## Builds the fight from the selected difficulty's roster and tracks how many
## bosses are left. The boss line-up used to be hard-coded into boss_room.tscn,
## which is why shipping a new difficulty meant shipping a new executable.

signal run_cleared

@onready var _bosses: Node2D = $Bosses

var _alive := 0


func _ready() -> void:
	# Deferred: _ready() can run while this node's own parent is still being
	# set up, and add_child() is refused in that window.
	_spawn_roster.call_deferred()


func _spawn_roster() -> void:
	for entry in Difficulty.roster():
		var packed: PackedScene = load(entry["scene"])
		if packed == null:
			push_error("Arena: cannot load boss scene '%s'" % entry["scene"])
			continue
		var boss := packed.instantiate() as Boss
		# Duplicates would otherwise come out as @CharacterBody2D@589.
		boss.name = "%s%d" % [entry["scene"].get_file().get_basename().capitalize(), _alive + 1]
		boss.position = entry["pos"]
		if entry.has("alpha"):
			boss.alpha = entry["alpha"]
		_bosses.add_child(boss)
		# Phase overrides run after add_child so the FSM node exists.
		if entry.has("phase"):
			var fsm := boss.find_child("FiniteStateMachine", false, false) as BossFSM
			if fsm:
				fsm.initial_phase = NodePath(entry["phase"])
		boss.died.connect(_on_boss_died)
		_alive += 1

	if _alive == 0:
		push_error("Arena: difficulty '%s' spawned no bosses" % Difficulty.display_name())


func _on_boss_died(_boss: Boss) -> void:
	_alive -= 1
	if _alive <= 0:
		run_cleared.emit()


func bosses_alive() -> int:
	return _alive
