extends Node
## Autoload. Tracks a single playthrough: which stage you are on, how long it
## has taken, and whether the run is finished.

signal stage_changed(index: int)

var stage_index := 0
var elapsed := 0.0

var _running := false
var _posted := false

## Identity this game reports itself as to the KAMI*MART arcade page.
const ARCADE_GAME := "katsubullet"

## Points per stage cleared, and the most a fast run can add on top. The bonus
## is capped below one stage so finishing further always beats finishing
## faster - the board is "how far did you get, then how quickly".
const STAGE_POINTS := 100000
const TIME_BONUS_MAX := 99999


func _process(delta: float) -> void:
	if _running:
		elapsed += delta


## Begins a fresh run at the chosen difficulty.
func start(level: Difficulty.Level) -> void:
	Difficulty.select(level)
	stage_index = 0
	elapsed = 0.0
	_running = true
	_posted = false
	stage_changed.emit(stage_index)


## Advances to the next stage. Returns false when the run is complete.
func advance() -> bool:
	if is_final_stage():
		_running = false
		return false
	stage_index += 1
	stage_changed.emit(stage_index)
	return true


func current_stage() -> Dictionary:
	return Levels.stage(stage_index)


func is_final_stage() -> bool:
	return stage_index >= Levels.count() - 1


func set_timer_running(value: bool) -> void:
	_running = value


## Stages fully cleared. A run that ends part-way counts the stages behind it,
## not the one it died on.
func stages_cleared(all_cleared: bool) -> int:
	return Levels.count() if all_cleared else stage_index


func score_for(all_cleared: bool) -> int:
	var cleared := stages_cleared(all_cleared)
	var bonus := maxi(0, TIME_BONUS_MAX - int(elapsed) * 10)
	return cleared * STAGE_POINTS + bonus


## Hands the finished run up to the page embedding this build, which posts it to
## the high-score board and asks for a name if it does not have one yet. Does
## nothing outside the browser, and only ever fires once per run.
func report(all_cleared: bool, player_level: int) -> void:
	if _posted or not OS.has_feature("web"):
		return
	_posted = true
	var cleared := stages_cleared(all_cleared)
	var payload := {
		"type": "kamimart.score",
		"game": ARCADE_GAME,
		"score": score_for(all_cleared),
		"rooms": cleared,
		"completion": int(round(cleared * 100.0 / float(Levels.count()))),
		"level": player_level,
		"runSeconds": int(elapsed),
		"difficulty": Difficulty.display_name(),
	}
	# JSON.stringify emits a valid JS object literal, so it drops straight in.
	JavaScriptBridge.eval(
		"window.parent.postMessage(%s, window.location.origin);" % JSON.stringify(payload),
		true)


## "2/5" for the HUD.
func stage_label() -> String:
	return "%d/%d" % [stage_index + 1, Levels.count()]


func elapsed_text() -> String:
	var total := int(elapsed)
	return "%d:%02d" % [total / 60, total % 60]
