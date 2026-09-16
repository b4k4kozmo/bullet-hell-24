# bullet-hell-24

A single-arena boss-rush bullet hell, built in **Godot 4.4**.

You are Katsu Boy. Several bosses share one 648×400 room and fill it with
rotating spiral patterns. Stand still to throw shurikens, move to swing the
sword, and hold focus to see your real hitbox.

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

## Difficulty

Chosen on the title screen. Difficulty controls both the boss roster and the
stat multipliers:

| | Bosses | Fire rate | Bullet speed | Boss HP |
|---|---|---|---|---|
| Easy | Spaghetti | 1.0× | 0.8× | 0.8× |
| Normal | + Kamijack | 1.0× | 1.0× | 1.0× |
| Hard | + Snowman, Frogoblin | 1.2× | 1.1× | 1.0× |
| Lunatic | all five | 1.5× | 1.3× | 1.15× |
| Psychosis | all five + two phase-offset Spaghetti clones | 1.8× | 1.5× | 1.3× |

All of this lives in `scripts/Difficulty.gd` — rosters and tuning are data, so
adding a mode is a table entry, not a new build.

## Project layout

```
scripts/
  Difficulty.gd   autoload: roster + tuning table
  Arena.gd        spawns the roster, tracks how many bosses are left
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
the remaining road to a release. The biggest gap: **there is still no win
condition** — `Arena` emits `run_cleared` when the last boss dies, but nothing
listens to it yet.
