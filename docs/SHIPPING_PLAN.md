# bullet-hell-24 — State of the Project & Path to Ship

Analysis date: 2026-09-16 · HEAD at time of writing: `a7363a9` "added frogoblins"
Engine: Godot 4.4 (Forward+) · ~780 lines of GDScript · 41 commits, 2024-05-01 → 2025-05-27

Every claim below was verified by importing the project in Godot 4.4 headless and
running probes against the real scene tree, not by reading code alone.

---

## 1. What the game actually is

A single-room boss-rush bullet hell. `title.tscn` → press **Space** → `boss_room.tscn`,
which spawns **five bosses at once** in a 648×400 arena:

| Boss | Script | HP | Fire rate | Phase length |
|---|---|---|---|---|
| Spaghetti | `scripts/Spaghetti.gd` | 999 | 0.05s | 15s |
| Kamijack | `spaghetti2.gd` | 444 | 0.1s | 3s |
| Kamijack2 | `spaghetti2.gd` | 444 | 0.1s | 3s |
| Snowman | `snowman.gd` | 444 | 0.1s | 3s |
| Frogoblin | `frogoblin.gd` | 250 | 0.05s | 0.5s |

Each boss is a `CharacterBody2D` + a `FiniteStateMachine` node whose children are
phase states. A phase sets `alpha` (the angular step added to each shot) and
`bullet_type`, then a `Speed` timer fires one bullet per tick along a rotating
vector. That single mechanic — *rotate the spawn angle by a constant every shot* —
is what produces all the spiral patterns. It is a genuinely good core: cheap,
readable, and every distinct pattern in the game is one float.

**Controls:** WASD/arrows move · Space fires · Shift = focus (slow move, shows
hitbox) · R restarts · Esc quits · full gamepad bindings.

**Player systems that exist and work:** two weapons (moving = sword, standing
still = spiral shuriken with 255 ammo), HP/ammo bars, an XP/level curve that
raises HP, ammo, power, dexterity and fire rate, and four status effects
(fire/poison/slow/stun) that enemy bullet types inflict.

### The good part

The rotating-angle bullet system, the focus-mode hitbox reveal, the sword/shuriken
weapon split, and the shuriken-cancels-enemy-bullets interaction are a real,
coherent arcade game. Nothing below argues for redesigning that. The problems are
all wiring, structure and packaging.

---

## 2. The most solid version

**The most structurally sound the project has ever been is the window
`a881d26` → `a110564` (2025-02-06 → 2025-02-14), four commits.**

I audited the boss state machines at all 41 commits — for every boss, whether
`starting_phase` resolves to a real node, whether every `change_state("X")`
target exists, and which phase nodes are reachable from the start state:

| Era | Commits | Bosses | Phase nodes | Reachable | Dead | Broken transitions |
|---|---|---|---|---|---|---|
| Spaghetti only | 1–35 (2024-05 → 2025-02-06) | 1 | 4 | 4 | 0 | 0 |
| **+ Kamijack** | **36–39 (2025-02-06 → 02-14)** | **2** | **7** | **7** | **0** | **0** |
| + Snowman/Frogoblin | 40 (2025-05-21) | 4 | 13 | 8 | 5 | 2 |
| HEAD | 41 (2025-05-27) | 4 | 13 | 9 | 4 | 2 |

Corroborating evidence: **the last Windows build you shipped yourself,
`builds/kb-alpha_v2.2.exe`, was built from `ab82cb8` — inside that window.**
You stopped building right at the point the project was healthiest.

### But do *not* revert to it

HEAD is strictly better content: it has the shuriken ammo system, the Frogoblin,
a working 2-phase Frogoblin cycle, and more music. The Feb build's only advantage
is that Kamijack had all three of its phases.

**The most solid version of this game is HEAD with three wiring mistakes undone.**
That's roughly an hour of work, not a revert.

### The regression, precisely

Commit `3d1113d` ("added enemies and bullets", 2025-05-21) built the Snowman by
copying `kamijack.tscn` and reusing its phase scripts. Two edits broke Kamijack:

1. `Jackphase1.gd` line 12: `change_state("Jackphase2")` → `change_state("Jackphase3")`
2. `kamijack.tscn`: the `Jackphase2` node's script was repointed from
   `res://Jackphase2.gd` to `res://Snowphase1.gd`

Net effect: **Kamijack permanently lost a third of its fight** (it now cycles
phase 1 ↔ 3 forever), and `Jackphase2.gd` became an orphaned file no scene
references. This is a shared-script aliasing bug — `Jackphase1.gd` and
`Jackphase3.gd` are attached to nodes on *three different bosses*, so editing
one boss silently edits the others. Section 4 fixes the class of bug, not just
this instance.

---

## 3. What is broken right now, ranked

### Ship blockers

**B1 — There is no win condition.** Verified at runtime: set all five bosses to
0 HP and nothing happens. No win screen, no scene change, no credits, no score.
The game cannot be completed. This is the single biggest gap between "tech demo"
and "game".

**B2 — Kamijack is missing phase 2.** `kamijack.tscn`'s `Jackphase2` node runs
`Snowphase1.gd`, which tries to transition to a node named `"Snowphase 1"` that
does not exist on Kamijack. The node is currently unreachable so it doesn't
crash — but it is a live crash waiting for anyone who rewires that boss.

**B3 — The Snowman is a static turret.** Its only reachable state is
`Snowphase 1`, whose `transition()` is `pass`. It never changes phase, ever. Its
`Jackphase1` and `Jackphase3` nodes are unreachable dead weight. Its node name
also contains a space (`"Snowphase 1"`), which `snowman.gd` has to match exactly.

**B4 — Frogoblin carries a broken dead node.** Its `Jackphase3` node targets
`"Jackphase1"`, which doesn't exist on the Frogoblin. Unreachable today, a crash
the moment it isn't.

**B5 — Enemy death is behind a fragile node lookup.**
```gdscript
func _process(_delta):
    $ProgressBar2.value = health
    if health <= 0:
        $"../Player".experience += 21   # throws if Player isn't an exact sibling
        queue_free()                    # ...so this never runs
```
Verified at runtime: rename the Player node and the boss becomes **immortal** —
stuck at 0 HP, still in the tree, still shooting, spamming an error every single
frame. Any scene layout where a boss isn't a direct sibling of a node named
exactly `Player` hits this.

**B6 — No pause, no options, no volume control.** `sounds/pause.wav` exists and
is never used. Esc calls `get_tree().quit()` instantly with no confirmation. For
a game that ships 54MB of loud audio, a volume slider is not optional.

### Serious

**S1 — Bullets have no lifetime cap.** The only despawn path is
`VisibleOnScreenEnabler2D.screen_exited`. Any bullet that stays on screen lives
forever. With five bosses firing ~70 bullets/sec combined, this is the first
thing that will tank framerate on a web export or a low-end laptop. Add a hard
lifetime timer as a floor.

**S2 — The title screen leaks a whole boss room.** `title.gd` instantiates
`boss_room.tscn` **twice** at script load (`boss_room` and `simultaneous_scene`)
and only ever adds one to the tree. Verified: one boss_room is 118 nodes, so
**118 nodes leak permanently** every time the title screen loads. `simultaneous_scene`
is unused — delete the line.

**S3 — Game state is stored in a UI label.** Every boss decides your damage by
reading `$"../Player".debug.text == "debug"`. Status effects work by *writing a
string into a Label*. This is why `Debug` can never be renamed, hidden differently
or localised. It needs to be a real state variable.

**S4 — Status effects don't stack safely.** `fire()`, `poison()`, `slow()` and
`stun()` all `await` and then unconditionally reset `speed = 250` and
`cantWalk = false`. Get slowed while in focus mode and the effect ending will
silently cancel your focus. Overlapping applications stomp each other.

**S5 — Friendly fire is prevented only by coincidence.** `bullet_type` is
simultaneously a sprite index, a damage id and a faction marker.
`Bullet._on_body_entered` calls `body.set_status(bullet_type)` on *whatever it
hits*. Player bullets don't hurt the player, and bosses don't hurt each other,
purely because the player uses types 4/5/6 and enemies use 0–3/7–10 and neither
`match` block has the other's cases. Add one new bullet type in the wrong range
and you have friendly fire.

**S6 — Level-ups scale fire rate without a floor.**
`sword_speed /= 1.25` and `shuriken_speed /= 1.11` every level, forever. By
level 20 the fire-rate timer is ~0.002s — the player alone spawns a bullet every
frame. Clamp it.

**S7 — Repo weight.** `.git` is 127MB; `builds/` is 608MB of committed `.exe`/`.pck`
files across 8 historical builds. `sounds/katsuboy_nightcore.wav` is **25MB and
completely unreferenced**. All WAVs import at `compress/mode=0` (uncompressed PCM).
54MB of assets for a 648×400 pixel game.

### Cleanup

- `block` input action is bound to B / gamepad button 9 and **read by nothing**.
- 6 unused sounds (~26MB) and 13 unused sprites.
- Orphaned scripts: `Jackphase2.gd`, `scripts/Jackphase1.gd` (a duplicate variant
  of the root one, never referenced by any scene at HEAD), `snowphase_1.gd` (a
  one-line stub).
- `.DS_Store` files committed at repo root and in `sounds/`.
- No README, no LICENSE, no `.gitattributes` for binaries, no CI.
- The Web export preset still points at `bulletweb/folderbullet/index.html`, a
  directory deleted in `3d1113d`.

---

## 4. Path forward

### Phase 0 — Stop the bleeding (half a day)

1. Delete `simultaneous_scene` from `title.gd`. (S2)
2. Add a lifetime `Timer` to `bullet.tscn` as a despawn floor. (S1)
3. Delete `sounds/katsuboy_nightcore.wav` and the other unused assets. (S7)
4. `git rm -r --cached builds/` and add it to `.gitignore`; publish builds as
   GitHub Releases or itch.io uploads instead. Keep the history for now — a
   rewrite can wait until you actually need the clone to be small.
5. Set every SFX to `compress/mode=2` (QOA) and re-encode the three music tracks
   to `.ogg`. This alone should take the export from ~26MB to a few MB.
6. Add `README.md`, `LICENSE`, and `.gitattributes`.

### Phase 1 — Make the bosses data-driven (1–2 days)

This kills the entire class of bug that caused the regression. Replace the eleven
one-off phase scripts with **one** `BossPhase.gd`:

```gdscript
extends State
class_name BossPhase

@export var alpha: float = 0.0
@export var bullet_type: int = 0
@export var fire_rate: float = 0.1
@export var phase_duration: float = 3.0
@export var next_phase: NodePath
@export var music: AudioStream

func enter():
    super.enter()
    owner.alpha = alpha
    owner.bullet_type = bullet_type
    speed.wait_time = fire_rate
    duration.wait_time = phase_duration
    speed.start()
    if music and Bgm.stream != music:
        Bgm.stream = music
        Bgm.play()

func transition():
    if can_transition and not next_phase.is_empty():
        get_parent().change_state(get_node(next_phase).name)
```

Every phase becomes a node with inspector values. `next_phase` is a `NodePath`,
so a mistyped transition is impossible — it's a broken reference the editor shows
you, not a string that silently fails at runtime. Eleven scripts become one, and
no two bosses can ever share mutable phase state again.

While doing this, fix `FiniteStateMachine.change_state` to fail loudly:

```gdscript
func change_state(state):
    if state == previous_state.name:
        return
    var next := find_child(state) as State
    if next == null:
        push_error("%s: no state '%s'" % [owner.name, state])
        return
    ...
```

Then rebuild each boss's phase graph: Kamijack gets its phase 2 back (B2), the
Snowman gets a real second phase (B3), the Frogoblin's dead `Jackphase3` node
goes (B4). Rename `"Snowphase 1"` → `"Snowphase1"`.

### Phase 2 — Make it a game (3–5 days)

This is the work that converts a tech demo into something shippable.

1. **An `Arena` / run controller.** Owns the boss list, tracks how many are
   alive, and fires `run_cleared` when the last one dies. This is B1.
2. **A win screen** — time, score, level reached, damage taken. `fanfare.wav`
   is already in the project and unused for this.
3. **A death screen** instead of a silent `reload_current_scene()`. Retry / quit.
4. **A pause menu** on Esc, with master/music/SFX volume sliders. `pause.wav`
   is sitting right there. Esc must stop being an instant-quit.
5. **Move the difficulty modes in-game.** You already built `kb-alpha`,
   `-hard`, `-lunatic` and `-psychosis` as *four separate executables*. That's
   four things to build, upload and support forever. Make difficulty a data
   table (HP multiplier, fire-rate multiplier, bullet-speed multiplier) chosen
   from the title screen. Four builds collapse into one, and the psychosis mode
   becomes a selling point instead of a separate download.
6. **Replace the debug-label state machine** (S3) with a real `status: Status`
   enum on the Player, and give status effects proper stacking rules (S4).
7. **Give bullets a `faction` field** so friendly fire is impossible by
   construction rather than by luck (S5).
8. **Clamp fire-rate scaling** (S6) and fix the `shuriken_count < 100` regen cap
   that contradicts `max_ammo = 255`.

### Phase 3 — Structure the content (1 week)

Right now all five bosses are in one room simultaneously, which is why the game
has no arc. Two options:

- **Boss rush (recommended).** One boss per room, sequential, with a short
  between-fight beat. You already have distinct music per boss wired up. This is
  the smaller change and it makes the existing content feel intentional.
- **Survival/horde.** Keep the single arena, spawn bosses in waves, score by
  time survived. Leans into the chaos you already have.

Either way: the five bosses you have are enough content for a 10–15 minute
arcade game. Don't add a sixth before shipping.

### Phase 4 — Ship (2–3 days)

1. **Restore the Web export.** It existed until `3d1113d` and got deleted. itch.io
   is the natural home for this game and a browser build is the difference between
   50 plays and 5. Fix the preset path, and confirm S1/S7 are done first — web is
   where the bullet count and the 54MB of PCM audio will actually hurt.
2. **CI**: a GitHub Action that runs `godot --headless --import` and exports Web +
   Windows on tag. The headless import is also a free smoke test — it catches
   broken resource references before you ship them.
3. **itch.io page**: 4–5 screenshots, a 20s gif of a spiral pattern (that's the
   hook), the control list, and the web build embedded.
4. **Tag `v0.1.0`** and stop calling it alpha.

---

## 5. Suggested order

The dependency chain that matters:

```
Phase 0 (cleanup)  ─┐
                    ├─→ Phase 2 (game shell) ─→ Phase 3 (structure) ─→ Phase 4 (ship)
Phase 1 (data FSM) ─┘
```

Phases 0 and 1 are independent and both are prerequisites for touching boss
content. Phase 2's win/lose/pause shell is the highest-value work in this
document — it is the difference between a thing you can show someone and a thing
someone can play.

**If you only do one thing:** Phase 2, item 1 and 2. A win condition.

---

## Appendix — how to reproduce this analysis

```bash
# import + smoke test (catches broken resource refs, no display needed)
godot --headless --import --path .

# the FSM reachability audit that produced the table in section 2
# (probe scripts were temporary; the approach: load each enemy .tscn,
#  read FiniteStateMachine children, regex change_state("X") out of each
#  attached script, and BFS from the root script's starting_phase)
```
