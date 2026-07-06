# Character Authoring Guide

How to add a fighter to Warrior's Art **without touching engine code**. A character is a folder of data + (eventually) art. If you find yourself editing `src/core/`, stop — that's an engine gap; file an issue instead.

Reference examples: [`src/characters/bengal_lathi/`](../src/characters/bengal_lathi/bengal_lathi.tres) (fast rushdown, QCF special) and [`src/characters/varanasi_musti/`](../src/characters/varanasi_musti/varanasi_musti.tres) (slow tanky brawler, DP special).

## 1. Files

```
src/characters/<state>_<art>/          e.g. punjab_gatka/
└── <state>_<art>.tres                 the CharacterData resource
```

Create the `.tres` in the Godot editor: right-click the folder → *New Resource…* → `CharacterData`. Fill the fields in the Inspector (this avoids hand-writing the file format).

## 2. CharacterData fields

| Field | Meaning | Typical range |
|---|---|---|
| `display_name` / `state_region` / `martial_art` | Identity (shown in UI later) | — |
| `walk_speed` | px/second | 170 (tank) – 240 (rushdown) |
| `dash_speed` | px/second during dash | ~2× walk |
| `jump_velocity` | negative = up | -880 … -980 |
| `gravity` | px/s² | ~2400 |
| `max_health` | — | 900 (glass) – 1100 (tank) |
| `weight` | scales knockback *taken* (higher = moves less). Never scales damage. | 0.9 – 1.15 |
| `moves` | Array of MoveData (see below) | 5–8 at v1 |
| `super_move` | One MoveData with `technique_cam = true` and `meter_cost = 1000` | exactly 1 |
| `percussion` | Regional instrument id (audio hook, Phase 2+) | e.g. "dhol" |

## 3. MoveData — one attack

**`input` notation** — numpad motion digits + one button letter (`L`/`M`/`H`), button always last:

| Input | Meaning |
|---|---|
| `"L"` | standing light |
| `"2L"` | crouching light (down held) |
| `"236L"` | quarter-circle-forward + light |
| `"623M"` | dragon-punch motion + medium |
| `"236236L"` | double-QCF (super) |

Numpad directions are **facing-relative**: 6 is always toward the opponent. Motion leniency scales automatically with input length.

- `air = true` → usable **only** airborne (and ground moves only grounded). The same button can have a ground and an air move.
- **Timing (60 Hz ticks):** `startup` (before hitting) / `active` (can hit) / `recovery` (after). Fast jabs: 3–5 startup. Heavies: 8–12. Supers punishable on block: big recovery.
- `on_block` — frame advantage on block (negative = you're punishable). Informational for now; used by balance review.
- `meter_gain` on hit; `meter_cost` gates and spends meter (EX ≈ 250, super = 1000).
- `technique_cam = true` (supers only) triggers the slow-mo cam.
- `hitbox_frames` — see below.

## 4. FrameData — the hitboxes

One `FrameData` per active tick (if the move has more active ticks than frames, the **last frame repeats**). Each frame:

- `hitbox_rect` — `Rect2(x, y, w, h)` in **fighter-local space**: origin at the feet, +x toward the opponent (auto-flipped), −y up. The body is 60 wide × 160 tall, so chest height ≈ y −130…−100. A jab poking 110 px out: `Rect2(25, -125, 85, 24)`.
- `damage`, `hitstun` (victim stun ticks), `hitstop` (both freeze — 4–6 light, 8–14 heavy/super).
- `knockback` — px/s impulse, `(x, y)`: +x away from attacker, −y launches upward.
- `knockdown = true` → victim falls into a knockdown (air-stun holds until they land). Use on launchers, sweeps, supers.

A hit connects **once per swing** — multi-frame moves grow/move the box across frames but can't multi-hit yet.

## 5. What you get for free (don't build these)

Blocking + chip, throws + techs, dashes, meter bar, knockdown/wake-up, hit-stop, screen shake, hit sparks, super slow-mo, round loop, training overlay. All system-level.

## 6. Test your character

1. **Wire it in:** set your `.tres` as `data` on P1 or P2 in `scenes/Match.tscn` (or just swap it temporarily).
2. **Training mode:** title screen → `T`, then `H` for hitbox display. Check every move's reach, whiff recovery, and that specials come out with their motion.
3. **Add to the test suite:** append your `.tres` path to the `paths` array in `tests/run_tests.gd` (`_test_character_resource_loads`) — CI then guards your data.
4. Run headless before pushing: `godot --headless --path . -s res://tests/run_tests.gd`.

## 7. Authenticity checklist (per the design pillars)

- Every special/super is named after and based on a **real technique** of the state's martial art — note the provenance in your character-design issue.
- Original name and design only — no film/actor/game references (see Game Design §8).
- One clear archetype (zoner / rushdown / grappler / brawler…) and a silhouette-friendly weapon stance.
