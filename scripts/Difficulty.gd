extends Node
## Autoload. Owns the difficulty ladder: which bosses spawn and how hard they hit.
##
## Historically each difficulty was a separate executable that differed by how
## many Spaghetti copies were placed in the room. That is preserved here as data:
## higher difficulties add bosses to the roster, and Psychosis still spawns the
## phase-offset Spaghetti clones the original psychosis build used.

enum Level { EASY, NORMAL, HARD, LUNATIC, PSYCHOSIS }

const NAMES := {
	Level.EASY: "EASY",
	Level.NORMAL: "NORMAL",
	Level.HARD: "HARD",
	Level.LUNATIC: "LUNATIC",
	Level.PSYCHOSIS: "PSYCHOSIS",
}

const BLURBS := {
	Level.EASY: "One boss. Learn the spirals.",
	Level.NORMAL: "Two bosses. The intended fight.",
	Level.HARD: "Four bosses. Patterns overlap.",
	Level.LUNATIC: "All five, faster and denser.",
	Level.PSYCHOSIS: "All five, plus phase-offset clones.",
}

const SPAGHETTI := "res://spaghetti.tscn"
const KAMIJACK := "res://kamijack.tscn"
const SNOWMAN := "res://snowman.tscn"
const FROGOBLIN := "res://frogoblin.tscn"

## Each entry: scene, spawn position, and optional overrides for alpha (the
## angular step that shapes the spiral) and the phase the boss opens on.
const ROSTERS := {
	Level.EASY: [
		{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
	],
	Level.NORMAL: [
		{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
		{"scene": KAMIJACK, "pos": Vector2(221, 149)},
	],
	Level.HARD: [
		{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
		{"scene": KAMIJACK, "pos": Vector2(221, 149)},
		{"scene": SNOWMAN, "pos": Vector2(525, 114)},
		{"scene": FROGOBLIN, "pos": Vector2(86, 81)},
	],
	Level.LUNATIC: [
		{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
		{"scene": KAMIJACK, "pos": Vector2(221, 149)},
		{"scene": KAMIJACK, "pos": Vector2(449, 149)},
		{"scene": SNOWMAN, "pos": Vector2(525, 114)},
		{"scene": FROGOBLIN, "pos": Vector2(86, 81)},
	],
	Level.PSYCHOSIS: [
		{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
		{"scene": KAMIJACK, "pos": Vector2(221, 149)},
		{"scene": KAMIJACK, "pos": Vector2(449, 149)},
		{"scene": SNOWMAN, "pos": Vector2(525, 114)},
		{"scene": FROGOBLIN, "pos": Vector2(86, 81)},
		# The original psychosis build: extra Spaghettis at alpha 0, opening on
		# later phases so their spirals layer out of sync with the first one.
		{"scene": SPAGHETTI, "pos": Vector2(367, 228), "alpha": 0.0, "phase": "Phase2"},
		{"scene": SPAGHETTI, "pos": Vector2(324, 228), "alpha": 0.0, "phase": "Phase3"},
	],
}

## fire_rate: >1 means bosses shoot more often. hp: scales boss health.
## bullet_speed: scales enemy bullet velocity only, never the player's.
const TUNING := {
	Level.EASY: {"fire_rate": 1.0, "bullet_speed": 0.8, "hp": 0.8},
	Level.NORMAL: {"fire_rate": 1.0, "bullet_speed": 1.0, "hp": 1.0},
	Level.HARD: {"fire_rate": 1.2, "bullet_speed": 1.1, "hp": 1.0},
	Level.LUNATIC: {"fire_rate": 1.5, "bullet_speed": 1.3, "hp": 1.15},
	Level.PSYCHOSIS: {"fire_rate": 1.8, "bullet_speed": 1.5, "hp": 1.3},
}

var current: Level = Level.NORMAL
var fire_rate_mult := 1.0
var bullet_speed_mult := 1.0
var boss_hp_mult := 1.0


func _ready() -> void:
	select(current)


func select(level: Level) -> void:
	current = level
	var t: Dictionary = TUNING[level]
	fire_rate_mult = t["fire_rate"]
	bullet_speed_mult = t["bullet_speed"]
	boss_hp_mult = t["hp"]


func roster() -> Array:
	return ROSTERS[current]


func display_name() -> String:
	return NAMES[current]
