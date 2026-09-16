extends Node
## Autoload. Scales how hard a fight is - never which bosses you get to see.
## Every stage in Levels.STAGES is played on every difficulty; see Run.gd.
##
## Historically each difficulty was a separate executable that differed by how
## many Spaghetti copies were placed in the room. That idea survives as the
## `clones` knob: the higher modes duplicate bosses already present in the
## stage, opening on later phases so their spirals layer out of sync.

enum Level { EASY, NORMAL, HARD, LUNATIC, PSYCHOSIS }

const NAMES := {
	Level.EASY: "EASY",
	Level.NORMAL: "NORMAL",
	Level.HARD: "HARD",
	Level.LUNATIC: "LUNATIC",
	Level.PSYCHOSIS: "PSYCHOSIS",
}

const BLURBS := {
	Level.EASY: "Slower bullets. Learn the spirals.",
	Level.NORMAL: "The intended fight.",
	Level.HARD: "Faster, denser, tougher bosses.",
	Level.LUNATIC: "Every boss brings a phase-offset double.",
	Level.PSYCHOSIS: "Two doubles each. Good luck.",
}

## fire_rate: >1 means bosses shoot more often.
## bullet_speed: scales enemy bullet velocity only, never the player's.
## hp: scales boss health.
## clones: extra phase-offset duplicates added per boss in the stage.
const TUNING := {
	Level.EASY: {"fire_rate": 0.85, "bullet_speed": 0.8, "hp": 0.8, "clones": 0},
	Level.NORMAL: {"fire_rate": 1.0, "bullet_speed": 1.0, "hp": 1.0, "clones": 0},
	Level.HARD: {"fire_rate": 1.2, "bullet_speed": 1.1, "hp": 1.1, "clones": 0},
	Level.LUNATIC: {"fire_rate": 1.45, "bullet_speed": 1.3, "hp": 1.25, "clones": 1},
	Level.PSYCHOSIS: {"fire_rate": 1.75, "bullet_speed": 1.5, "hp": 1.4, "clones": 2},
}

## The full stage roster is a lot of bosses already; do not let Psychosis turn
## the final stage into fifteen of them.
const MAX_BOSSES_PER_STAGE := 9

var current: Level = Level.NORMAL
var fire_rate_mult := 1.0
var bullet_speed_mult := 1.0
var boss_hp_mult := 1.0
var clones_per_boss := 0


func _ready() -> void:
	select(current)


func select(level: Level) -> void:
	current = level
	var t: Dictionary = TUNING[level]
	fire_rate_mult = t["fire_rate"]
	bullet_speed_mult = t["bullet_speed"]
	boss_hp_mult = t["hp"]
	clones_per_boss = t["clones"]


func display_name() -> String:
	return NAMES[current]
