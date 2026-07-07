# Warrior's Art — Architecture

How the code is organized and why. Read this before touching core systems.

## Engine choice: Godot 4.x

Chosen over Unity because: free/open-source (no per-seat licensing for a 3-person team), first-class 2D, and — critically for a team — **scenes and resources are text** (`.tscn`, `.tres`), so they diff and merge in Git far better than Unity's binary/YAML assets. GDScript keeps the ramp short. The trade-off (fewer fighting-game tutorials than Unity) is acceptable given the collaboration win.

## Layering (the golden rule)

```
┌─────────────────────────────────────────────┐
│ Presentation: sprites, VFX, camera, audio,   │  reacts to sim state
│ UI, screen-shake, hit-stop visuals           │  — never drives it
├─────────────────────────────────────────────┤
│ Simulation (deterministic, fixed 60Hz tick): │  the source of truth
│ fighter state machines, input, hit/hurtbox   │
│ resolution, health/meter, round logic        │
├─────────────────────────────────────────────┤
│ Data: character resources (.tres),           │  no logic, pure data
│ frame data, move lists, tuning constants     │
└─────────────────────────────────────────────┘
```

**The simulation must never depend on the presentation layer.** VFX/audio/camera read sim state each frame. This separation is what makes future rollback netcode *possible* without a rewrite (see Determinism).

## Directory layout

```
warriors-art/
├── project.godot
├── src/
│   ├── autoload/            # singletons (GameState, Rng, Log, Sfx)
│   ├── core/               # deterministic sim
│   │   ├── fighter_state_machine.gd
│   │   ├── fighter.gd, fighter_ai.gd
│   │   ├── input_buffer.gd, input_buttons.gd
│   │   └── combat/         # hitbox.gd, hurtbox.gd, projectile.gd
│   ├── data/               # resource classes (CharacterData, MoveData, FrameData, ProjectileData)
│   ├── characters/         # one folder per fighter: .tres data + generated SpriteFrames
│   ├── game/               # main/title, match/ (controller, camera, juice, backdrop), fighter_visual
│   └── ui/                 # HUD, character select, pause menu, debug overlay
├── assets/                 # sprites/, audio/ (Git LFS; all generated placeholders)
├── scenes/                 # Main, CharacterSelect, Match, Training, Fighter, stages/
├── tests/                  # headless runners: unit, gameplay smoke, AI smoke
├── tools/                  # generators (sprites, audio), SpriteFrames builder, screenshot
└── docs/
```

## Core systems

### Fighter state machine
Each fighter is a hierarchical state machine: `Idle, Walk, Dash, Jump, Crouch, Block, Attack, HitStun, BlockStun, Knockdown, KO`. States own their enter/exit/tick. Transitions are driven by buffered input + current-move cancel rules. Skeleton: [`src/core/fighter_state_machine.gd`](../src/core/fighter_state_machine.gd).

### Input system
Inputs are sampled once per fixed tick into a **ring buffer** (last N ticks). A motion parser reads the buffer for special-move commands (QCF, DP, charge). Buffering gives fighting-game-grade responsiveness and is deterministic. Local 2P maps two devices; the buffer format is netcode-ready. Skeleton: [`src/core/input_buffer.gd`](../src/core/input_buffer.gd).

### Hit / hurtbox & resolution
Per animation frame, an attack exposes **hitboxes**; a fighter exposes **hurtboxes**. Each fixed tick the resolver checks overlaps, applies the winning hit once (no double-trigger), and produces damage/knockback/hitstun/hitstop from the move's `FrameData`. Boxes are authored as data per frame, not hard-coded. Dir: `src/core/combat/`.

### Data model (data-driven characters)
```
CharacterData (.tres)
├── display_name, state, martial_art
├── walk_speed, jump_height, health, weight ...
├── moves: Array[MoveData]
│   └── MoveData: name, input, damage, startup/active/recovery,
│                 on_block, hitstop, knockback, meter_gain,
│                 hitbox_frames: Array[FrameData], animation_name
└── super: MoveData (with technique_cam flag)
```
A character = animations + these resources. **Adding a fighter must not require engine changes** — that's the Phase 2 exit gate.

### Projectiles
`ProjectileData` (speed, lifetime, spawn offset, FrameData, pierce) is referenced from `MoveData.projectile` and fired once on the move's first active tick. The `Projectile` node advances on the fixed tick and polls hurtbox overlaps exactly like `Hitbox`; hits resolve through the controller (victim-only hit-stop, knockback follows travel direction). Lifetime doubles as a range limit (the vita's tether). Projectiles are swept on round reset.

### Throws
System-level (per-character command grabs are future data): light+medium together attempts a grab; the `MatchController` resolves range/throwability during the active window, gives the victim an 8-tick tech window, then deals damage into a knockdown. Throws beat blocking — the strike/block/throw triangle.

### CPU AI
`FighterAI` (`src/core/fighter_ai.gd`) is an **input-level** brain: each tick it returns an `InputButtons` snapshot (motions are rolled frame-by-frame from a queue), which `Fighter._sample_inputs` consumes instead of the keyboard. The AI has no privileged sim access and uses a locally seeded RNG, so CPU matches remain deterministic/replayable. Difficulty 1–7 scales reaction cooldown, block reactions, and special/EX usage.

### Round / match loop
`MatchController` owns rounds, timer, best-of-3, win/KO/rematch, central hit + throw + projectile resolution, arcade ladder continuation (via duck-typed GameState access — sim scripts never name autoloads at compile time so headless `-s` test runs still load them), and the announcement banner. Training mode is the same controller with `training = true`.

### Presentation
`AnimationPlayer`/`SpriteFrames` for sprites; a VFX layer for dust/rim-light/impact particles; a camera that frames both fighters; a "juice" service for screen-shake + hit-stop that *reads* sim events. Technique cams are short scripted camera cuts triggered by super activation.

## Determinism rules (enforced in review)

- Sim runs in `_physics_process` at a fixed 60 Hz tick; count ticks, never trust wall-clock.
- All randomness routes through the `Rng` autoload with an explicit, replayable seed. No bare `randf()`/`randi()` in sim.
- Sim state is fully derivable from (initial state + input stream). No hidden state in the render layer.
- Floats are used but kept deterministic per-platform for v1 (local only). If/when rollback lands, revisit fixed-point only if desync appears.

See [Coding Standards §4](CODING_STANDARDS.md) for how these are reviewed.

## Autoloads (singletons)

| Name | Responsibility |
|---|---|
| `GameState` | mode, roster list, character picks, arcade ladder, scene routing |
| `Rng` | seeded deterministic RNG for the sim (`seed_match`, `next_int`, `next_float`) |
| `Log` | leveled logging (replaces stray `print`) |
| `Sfx` | audio buses (SFX/Music), pooled players, percussion loops; disabled headless |

(Device→player mapping lives in the input actions themselves — `p1_*`/`p2_*` carry keyboard + per-device gamepad events; a dedicated InputManager autoload proved unnecessary. Remapping UI is a Phase 4 options-menu item.)

## Post-v1 seam: rollback netcode

Because the sim is deterministic and decoupled, adding rollback means: serialize sim state, feed remote inputs into the same buffer, and re-simulate on correction. No gameplay rewrite — just a netcode layer around the existing sim. Deliberately deferred to Phase 5.
