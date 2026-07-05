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
│   ├── autoload/            # singletons (GameState, Rng, Log, InputManager)
│   ├── core/               # deterministic sim
│   │   ├── fighter_state_machine.gd
│   │   ├── fighter.gd
│   │   ├── input_buffer.gd
│   │   └── combat/         # hitbox.gd, hurtbox.gd, hit_resolver.gd
│   ├── data/               # resource *classes* (CharacterData, MoveData, FrameData)
│   ├── characters/         # one folder per fighter: scene + .tres + sprites ref
│   ├── stages/             # region backdrops (parallax)
│   ├── game/               # match/round loop, mode controllers (1v1, 2v2)
│   └── ui/                 # menus, HUD, character select
├── assets/                 # sprites/, audio/, fonts/  (Git LFS)
├── scenes/                 # top-level composed scenes (main menu, match)
├── tests/                  # GUT unit tests
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

### Round / match loop
`MatchController` owns rounds, timer, best-of-3, win/KO/rematch, and (for 2v2) tag state. Mode controllers (`OneVsOne`, `TwoVsTwo`) configure it.

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
| `GameState` | current mode, match config, scene routing |
| `InputManager` | device→player mapping, remap config |
| `Rng` | seeded deterministic RNG for the sim |
| `Log` | leveled logging (replaces stray `print`) |

## Post-v1 seam: rollback netcode

Because the sim is deterministic and decoupled, adding rollback means: serialize sim state, feed remote inputs into the same buffer, and re-simulate on correction. No gameplay rewrite — just a netcode layer around the existing sim. Deliberately deferred to Phase 5.
