extends Node
## Autoload. Tracks a single playthrough: which stage you are on, how long it
## has taken, and whether the run is finished.

signal stage_changed(index: int)

var stage_index := 0
var elapsed := 0.0

var _running := false


func _process(delta: float) -> void:
	if _running:
		elapsed += delta


## Begins a fresh run at the chosen difficulty.
func start(level: Difficulty.Level) -> void:
	Difficulty.select(level)
	stage_index = 0
	elapsed = 0.0
	_running = true
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


## "2/5" for the HUD.
func stage_label() -> String:
	return "%d/%d" % [stage_index + 1, Levels.count()]


func elapsed_text() -> String:
	var total := int(elapsed)
	return "%d:%02d" % [total / 60, total % 60]
