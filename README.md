# bullet-hell-24

A single-arena boss-rush bullet hell, built in **Godot 4.4**.

You are Katsu Boy. A run is five stages of boss fights in one 648×400 arena,
each filling the screen with rotating spiral patterns. Stand still to throw
shurikens, move to swing the sword, and hold focus to see your real hitbox.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | `WASD` / arrows | Left stick |
| Fire | `Space` (hold) | A |
| Focus (slow, show hitbox) | `Shift` (hold) | L3 |
| Restart | `R` | Y |
| Quit | `Esc` | Back |

Standing still throws **shurikens** (spiral spread, costs ammo). Moving swings
the **sword** (straight, free, and refunds ammo on hit).

## Stages

A run is five stages, cleared in order. Every boss appears in every run on every
difficulty — difficulty changes how hard the fight is, not what you get to see.

| | Stage | Bosses |
|---|---|---|
| 1 | FROGOBLIN | Frogoblin |
| 2 | SNOWMAN | Snowman |
| 3 | THE TWINS | two Kamijacks, the second opening a phase out of step |
| 4 | SPAGHETTI | Spaghetti (four phases, speeds up each lap) |
| 5 | ALL AT ONCE | all five at their original positions |

Clearing a stage shows STAGE CLEAR and advances. Dying shows GAME OVER and
retries the stage you died on, keeping your progress. Clearing stage 5 shows
ALL CLEAR with your difficulty and run time.

The table is `Levels.STAGES` in `scripts/Levels.gd`; reordering, retuning or
adding a stage is an edit to that array and nothing else.

## Difficulty

Chosen on the title screen. It scales the fight, never the roster:

| | Fire rate | Bullet speed | Boss HP | Duplicates |
|---|---|---|---|---|
| Easy | 0.85× | 0.8× | 0.8× | — |
| Normal | 1.0× | 1.0× | 1.0× | — |
| Hard | 1.2× | 1.1× | 1.1× | — |
| Lunatic | 1.45× | 1.3× | 1.25× | 1 per boss |
| Psychosis | 1.75× | 1.5× | 1.4× | 2 per boss |

"Duplicates" is the old psychosis build's trick kept as a knob: the higher modes
copy bosses *already in the stage*, each opening a phase further round its cycle
so the spirals layer out of sync. A stage is capped at
`Difficulty.MAX_BOSSES_PER_STAGE` so stage 5 does not become fifteen bosses.

All of this lives in `scripts/Difficulty.gd`.

## Project layout

```
scripts/
  Levels.gd       the stage table
  Run.gd          autoload: which stage you are on, and the run clock
  Difficulty.gd   autoload: tuning table
  Arena.gd        spawns a stage, owns stage clear / game over / all clear
  Boss.gd         shared boss behaviour (health, damage, firing)
  BossFSM.gd      phase machine; transitions are NodePaths
  BossPhase.gd    one attack phase, configured from the inspector
  State.gd        base state
  Idle.gd         waits for the player, then enters the opening phase
  Player.gd       movement, weapons, XP, status effects
  Bullet.gd       movement, collision, despawn
*.tscn            scenes: title, boss_room, player, bullet, one per boss
```

### Adding or editing a boss phase

Phases are data. Add a `Node2D` under a boss's `FiniteStateMachine`, attach
`BossPhase.gd`, and fill in the inspector:

- `alpha` — angular step added to the fire vector each shot. This is what shapes
  the spiral; it is the single most important number in the game.
- `bullet_type` — index into `Bullet.texture_array`, and also the status effect
  applied on hit.
- `fire_rate` / `phase_duration` — seconds.
- `next_phase` — the phase to enter next.
- `music` — optional track to switch to.
- `escalate_on_exit` — multiplies the boss's fire-rate scale on the way out, so
  a cycle can speed up each lap (Spaghetti's Phase4 uses `0.5`).

`next_phase` accepts either the form the editor writes when you pick a sibling
(`../Phase2`) or the form that reads naturally by hand (`Phase2`).

## Building

Needs Godot 4.4 and the matching export templates.

```bash
godot --headless --import --path .              # import + smoke test

mkdir -p builds/web                             # Godot will not create it
godot --headless --path . --export-release "Web"              # -> builds/web/
godot --headless --path . --export-release "Windows Desktop"  # -> builds/
```

The Web preset has `thread_support` **off** on purpose: threads require
`SharedArrayBuffer`, which only works when the host sends cross-origin isolation
headers. With threads off the build runs anywhere, including itch.io without the
SharedArrayBuffer option enabled.

`builds/` is gitignored — publish through GitHub Releases or itch.io rather than
committing binaries.

## Where things stand

See [`docs/SHIPPING_PLAN.md`](docs/SHIPPING_PLAN.md) for the full analysis and
the remaining road to a release. Still open: a pause menu with volume control,
and the status-effect system currently storing its state in the text of a UI
label.
