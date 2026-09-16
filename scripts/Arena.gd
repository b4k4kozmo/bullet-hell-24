extends Node2D
## Runs one stage: spawns its bosses, applies the difficulty's clone modifier,
## and owns what happens when the stage is won or the player dies.
##
## The boss line-up used to be hard-coded into boss_room.tscn, which is why
## shipping a new difficulty once meant shipping a new executable.

signal run_cleared

enum Phase { FIGHTING, STAGE_CLEAR, ALL_CLEAR, GAME_OVER }

## Grace period between a stage opening and its bosses opening fire.
const ENGAGE_DELAY := 0.8

@onready var _bosses: Node2D = $Bosses
@onready var _banner: Label = %Banner
@onready var _sub: Label = %Sub
@onready var _hint: Label = %Hint
@onready var _tag: Label = %StageTag

var _alive := 0
var _phase: Phase = Phase.FIGHTING


func _ready() -> void:
	_set_overlay("", "", "")
	_tag.text = "STAGE %s  %s  %s" % [
		Run.stage_label(), Run.current_stage()["name"], Difficulty.display_name()]
	var player := get_node_or_null("Player")
	if player:
		player.died.connect(_on_player_died)
	# Deferred: _ready() can run while this node's own parent is still being
	# set up, and add_child() is refused in that window.
	_spawn_stage.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.FIGHTING:
		return
	if event.is_action_pressed("action"):
		_confirm()
	elif event.is_action_pressed("exit"):
		_to_title()


# --------------------------------------------------------------------------
# Spawning
# --------------------------------------------------------------------------

func _spawn_stage() -> void:
	var stage := Run.current_stage()
	var roster: Array = stage["bosses"]

	for entry in roster:
		_spawn(entry, 0)

	# Difficulty duplicates bosses already in the stage rather than adding new
	# ones, so no difficulty can gate a boss behind itself.
	if Difficulty.clones_per_boss > 0:
		for copy in range(1, Difficulty.clones_per_boss + 1):
			for entry in roster:
				if _alive >= Difficulty.MAX_BOSSES_PER_STAGE:
					break
				_spawn(entry, copy)

	if _alive == 0:
		push_error("Arena: stage '%s' spawned no bosses" % stage["name"])
		_show_stage_clear()
		return

	# A short beat so the stage title registers before the screen fills.
	await get_tree().create_timer(ENGAGE_DELAY).timeout
	if _phase != Phase.FIGHTING:
		return
	for boss in _bosses.get_children():
		if boss is Boss:
			boss.engage()


func _spawn(entry: Dictionary, copy: int) -> void:
	var packed: PackedScene = load(entry["scene"])
	if packed == null:
		push_error("Arena: cannot load boss scene '%s'" % entry["scene"])
		return
	var boss := packed.instantiate() as Boss
	# Without this, duplicates come out named @CharacterBody2D@589.
	boss.name = "%s%d" % [entry["scene"].get_file().get_basename().capitalize(), _alive + 1]
	boss.position = entry["pos"]
	if copy > 0:
		boss.position += Levels.CLONE_OFFSETS[(copy - 1) % Levels.CLONE_OFFSETS.size()]
	if entry.has("alpha"):
		boss.alpha = entry["alpha"]
	_bosses.add_child(boss)

	# Phase overrides run after add_child so the FSM node exists.
	var fsm := boss.find_child("FiniteStateMachine", false, false) as BossFSM
	if fsm:
		if entry.has("phase"):
			fsm.initial_phase = NodePath(entry["phase"])
		if copy > 0:
			fsm.initial_phase = _offset_phase(fsm, copy)

	boss.died.connect(_on_boss_died)
	_alive += 1


## Starts a duplicate `copy` phases further round its own cycle, so its spiral
## layers against the original instead of tracing it exactly.
func _offset_phase(fsm: BossFSM, copy: int) -> NodePath:
	var phases: Array[String] = []
	for c in fsm.get_children():
		if c is BossPhase:
			phases.append(String(c.name))
	if phases.is_empty():
		return fsm.initial_phase
	var start := phases.find(String(fsm.initial_phase))
	if start < 0:
		start = 0
	return NodePath(phases[(start + copy) % phases.size()])


# --------------------------------------------------------------------------
# Run flow
# --------------------------------------------------------------------------

func _on_boss_died(_boss: Boss) -> void:
	_alive -= 1
	if _alive <= 0 and _phase == Phase.FIGHTING:
		run_cleared.emit()
		_show_stage_clear()


func _on_player_died() -> void:
	if _phase != Phase.FIGHTING:
		return
	_phase = Phase.GAME_OVER
	Run.set_timer_running(false)
	Bgm.stream = load("res://sounds/Silent Way.mp3")
	Bgm.play()
	_set_overlay("GAME OVER", "stage %s - %s" % [Run.stage_label(), Run.current_stage()["name"]],
		"SPACE retry stage    ESC title")
	_freeze()


func _show_stage_clear() -> void:
	# The clock stops while the banner is up, so reading it costs nothing.
	Run.set_timer_running(false)
	if Run.is_final_stage():
		_phase = Phase.ALL_CLEAR
		$Fanfare.play()
		Run.report(true, _player_level())
		_set_overlay("ALL CLEAR", "%s  -  %s" % [Difficulty.display_name(), Run.elapsed_text()],
			"SPACE to return to the title")
	else:
		_phase = Phase.STAGE_CLEAR
		$Fanfare.play()
		var next: Dictionary = Levels.stage(Run.stage_index + 1)
		_set_overlay("STAGE CLEAR", "next: %s - %s" % [next["name"], next["subtitle"]],
			"SPACE to continue")
	_freeze()


func _confirm() -> void:
	match _phase:
		Phase.STAGE_CLEAR:
			Run.advance()
			Run.set_timer_running(true)
			_reload()
		Phase.GAME_OVER:
			Run.set_timer_running(true)
			_reload()
		Phase.ALL_CLEAR:
			_to_title()


func _reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_title() -> void:
	# Walking away from a game over ends the run, so it is worth posting.
	# Choosing "retry stage" instead keeps the run - and its clock - going.
	if _phase == Phase.GAME_OVER:
		Run.report(false, _player_level())
	get_tree().paused = false
	Bgm.stream = load("res://sounds/KatsuBoySong.wav")
	Bgm.play()
	get_tree().change_scene_to_file("res://title.tscn")


func _player_level() -> int:
	var player := get_node_or_null("Player")
	return player.player_level if player else 1


func _freeze() -> void:
	# Clear the screen so the banner reads, and so a retry does not begin with
	# a wall of bullets already in flight.
	for b in $Bullets.get_children():
		b.queue_free()
	# Arena and HUD are PROCESS_MODE_ALWAYS; Bosses, Bullets and Player are
	# PROCESS_MODE_PAUSABLE, so the fight stops but the confirm press lands.
	get_tree().paused = true


func _set_overlay(banner: String, sub: String, hint: String) -> void:
	_banner.text = banner
	_sub.text = sub
	_hint.text = hint
	%Overlay.visible = banner != ""


func bosses_alive() -> int:
	return _alive
