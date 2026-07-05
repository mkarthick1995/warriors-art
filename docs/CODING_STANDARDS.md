# Warrior's Art — Coding Standards

These rules keep a three-person codebase consistent and reviewable. When in doubt, match the surrounding code and the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

## 1. Language & engine

- **Godot 4.x**, **GDScript**. Pin the exact editor version in [`ONBOARDING.md`](ONBOARDING.md); everyone uses the same one.
- Prefer built-in Godot features over custom frameworks. Don't add plugins without the systems lead's sign-off.
- `@tool` scripts only when genuinely needed (they run in-editor and can corrupt scenes if buggy).

## 2. Naming

| Thing | Convention | Example |
|---|---|---|
| Files / directories | `snake_case` | `fighter_state_machine.gd`, `hitbox.tscn` |
| Classes (`class_name`) | `PascalCase` | `class_name FighterStateMachine` |
| Nodes in a scene | `PascalCase` | `HurtboxArea`, `AnimationPlayer` |
| Functions / variables | `snake_case` | `func apply_knockback()`, `var health_current` |
| Private members (intended internal) | leading `_` | `var _state_time`, `func _resolve_hit()` |
| Constants / enums | `CONSTANT_CASE` | `const MAX_HEALTH := 1000`, `enum State { IDLE, WALK }` |
| Signals | `snake_case`, past-tense | `signal took_damage(amount)`, `signal state_changed(new_state)` |
| Booleans | `is_/has_/can_` prefix | `is_grounded`, `can_cancel` |

## 3. Typing & structure

- **Always use static types.** `var health: int = 1000`, `func take_damage(amount: int) -> void:`. Typed code catches bugs and is faster.
- Use `:=` inferred typing when the type is obvious from the right-hand side.
- One `class_name` per file; the filename matches the class in `snake_case`.
- Order within a script (Godot convention):
  1. `class_name` / `extends`
  2. `## docstring`
  3. signals
  4. enums, constants
  5. `@export` vars, then public vars, then `_private` vars, then `@onready`
  6. `_init`, `_ready`, `_process`/`_physics_process`, other virtuals
  7. public methods, then `_private` methods
- Keep functions short and single-purpose. Extract combat rules into named functions.

## 4. Gameplay-specific rules (fighting-game critical)

- **Determinism:** the fight simulation must be deterministic. In sim code:
  - Advance gameplay in `_physics_process` at a **fixed tick** (60 Hz). Never gate gameplay logic on `_process` / frame rate / `delta` wall-clock.
  - **No `randf()`/`randi()` in the sim** unless seeded from a shared, replayable RNG. Route all randomness through `Rng` (autoload) with an explicit seed.
  - No wall-clock time (`Time.get_ticks_msec()`) for gameplay decisions — count ticks.
  - Keep rendering/VFX/audio *out* of the sim; they react to sim state, never drive it. This is what keeps future rollback netcode possible.
- **Frame data is data, not code.** Startup/active/recovery, hitboxes, damage, knockback live in `.tres` resources, not in `if` branches. See [Architecture](ARCHITECTURE.md).
- **No magic numbers** in combat. Name them (`const HITSTOP_HEAVY := 12`) or put them in the character/tuning resource.
- Use signals for cross-system events (`took_damage`), direct calls within a system.

## 5. Scenes & nodes

- One responsibility per scene; compose small scenes rather than one giant scene.
- Don't hard-code node paths with fragile strings; use `@onready var x := $Path` or `@export` node references.
- Prefer `@export` for anything a designer/artist should tune in the editor.
- Don't reference a parent's internals from a child; communicate up via signals, down via method calls or exported refs.

## 6. Comments & docs

- Use `##` doc comments on every `class_name`, public method, and `@export` var (they show in the editor).
- Comment the *why*, not the *what*. Explain non-obvious frame-data or determinism decisions inline.
- Match the comment density of surrounding code.

## 7. Errors & safety

- Validate with `assert()` for programmer errors (dev builds); handle expected failures gracefully.
- Guard against null: `if not is_instance_valid(node): return`.
- Never leave `print()` debug spam in merged code — use a `Log` helper or remove it.

## 8. Formatting

- Tabs for indentation (Godot default). LF line endings (enforced by `.editorconfig` / `.gitattributes`).
- Max ~100 columns as a soft guide.
- Run **`gdformat`** (from `gdtoolkit`) and **`gdlint`** before pushing — CI runs both. Install: `pip install "gdtoolkit==4.*"`.

## 9. Testing

- Unit-test pure logic (input parser, frame-data math, damage calc) with **GUT** (Godot Unit Test) under `tests/`.
- Every bug fix adds a regression test where practical.
- Combat/feel is validated by playtest, but the *rules* (frame data, hit detection) get automated tests.

## 10. Review rules

- No direct pushes to `main` (branch protection). Everything via PR.
- At least **one approving review** from the relevant area lead (see `.github/CODEOWNERS`).
- CI must be green (lint + format check + tests).
- PRs stay small and focused; a PR that touches core sim + art + UI at once should be split.
- The author does not merge until review + CI pass. See [Git Workflow](GIT_WORKFLOW.md).
