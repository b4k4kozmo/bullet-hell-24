extends RefCounted
class_name Levels
## The stage table. Every boss appears in every playthrough - difficulty scales
## how hard the fight is, not which bosses you are allowed to see.
##
## Adding, reordering or retuning a stage is an edit to STAGES and nothing else.

const SPAGHETTI := "res://spaghetti.tscn"
const KAMIJACK := "res://kamijack.tscn"
const SNOWMAN := "res://snowman.tscn"
const FROGOBLIN := "res://frogoblin.tscn"

## Each stage: a display name, a subtitle, and the bosses to place.
## A boss entry may override `alpha` (the angular step that shapes the spiral)
## and `phase` (which phase it opens on).
const STAGES := [
	{
		"name": "FROGOBLIN",
		"subtitle": "it will not stop moving",
		"bosses": [
			{"scene": FROGOBLIN, "pos": Vector2(324, 140)},
		],
	},
	{
		"name": "SNOWMAN",
		"subtitle": "cold open",
		"bosses": [
			{"scene": SNOWMAN, "pos": Vector2(324, 140)},
		],
	},
	{
		"name": "THE TWINS",
		"subtitle": "two Kamijacks, out of step",
		"bosses": [
			{"scene": KAMIJACK, "pos": Vector2(221, 149)},
			{"scene": KAMIJACK, "pos": Vector2(449, 149), "phase": "Jackphase2"},
		],
	},
	{
		"name": "SPAGHETTI",
		"subtitle": "four phases, and it speeds up",
		"bosses": [
			{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
		],
	},
	{
		"name": "ALL AT ONCE",
		"subtitle": "the original room",
		"bosses": [
			{"scene": SPAGHETTI, "pos": Vector2(343, 191), "alpha": 3.043},
			{"scene": KAMIJACK, "pos": Vector2(221, 149)},
			{"scene": KAMIJACK, "pos": Vector2(449, 149)},
			{"scene": SNOWMAN, "pos": Vector2(525, 114)},
			{"scene": FROGOBLIN, "pos": Vector2(86, 81)},
		],
	},
]

## Where difficulty-added duplicate bosses go, relative to the original.
const CLONE_OFFSETS := [Vector2(-46, 52), Vector2(46, 52), Vector2(0, -58)]


static func count() -> int:
	return STAGES.size()


static func stage(index: int) -> Dictionary:
	return STAGES[clampi(index, 0, STAGES.size() - 1)]
