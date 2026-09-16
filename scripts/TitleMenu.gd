extends Control
## Difficulty picker on the title screen. Keyboard, gamepad and mouse.

signal difficulty_chosen(level: int)

const LEVELS := [
	Difficulty.Level.EASY,
	Difficulty.Level.NORMAL,
	Difficulty.Level.HARD,
	Difficulty.Level.LUNATIC,
	Difficulty.Level.PSYCHOSIS,
]

## Psychosis is the loudest thing on the menu; open on Normal instead.
var _index := 1
var _locked := false

@onready var _list: VBoxContainer = %List
@onready var _blurb: Label = %Blurb


func _ready() -> void:
	for level in LEVELS:
		var row := Label.new()
		row.text = Difficulty.NAMES[level]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 12)
		_list.add_child(row)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event.is_action_pressed("move_down"):
		_move(1)
	elif event.is_action_pressed("move_up"):
		_move(-1)
	elif event.is_action_pressed("action"):
		_confirm()


func _move(step: int) -> void:
	_index = wrapi(_index + step, 0, LEVELS.size())
	_refresh()


func _refresh() -> void:
	for i in _list.get_child_count():
		var row: Label = _list.get_child(i)
		var selected := i == _index
		row.text = "> %s <" % Difficulty.NAMES[LEVELS[i]] if selected else Difficulty.NAMES[LEVELS[i]]
		row.modulate = Color.WHITE if selected else Color(1, 1, 1, 0.45)
	_blurb.text = Difficulty.BLURBS[LEVELS[_index]]


func _confirm() -> void:
	_locked = true
	difficulty_chosen.emit(LEVELS[_index])
