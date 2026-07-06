# Warrior's Art — Implementation Plan

How we build the game. Pairs with the [Roadmap](ROADMAP.md) (when/who) and [Architecture](ARCHITECTURE.md) (how the code is shaped).

## Guiding strategy

> **Game feel is the hardest thing to get right, and it needs fresh eyes.** Build a vertical slice with ONE character and get it in front of outside players before designing the rest of the roster. Everything below is ordered to reach a *fun, testable* build as early as possible.

Three principles:
1. **Data-driven characters.** A character = animations + a set of resource files (frame data, hitboxes, move lists). Adding a fighter must not require engine changes.
2. **Deterministic core sim.** Keep the fight simulation deterministic and decoupled from rendering, so we *could* add rollback netcode post-v1 without a rewrite.
3. **Vertical before horizontal.** Finish one of everything (one character, one stage, one full round loop) before widening.

---

## Phase 0 — Foundations (Week 1–2)

Goal: repo, tooling, and a project everyone can open and run.

- [x] GitHub repo, `.gitignore`, Git LFS, CI. *(Branch protection unavailable on the free-plan private repo — PR discipline by convention.)*
- [ ] Godot 4.3-stable opens clean on all three machines — **tracked as issue #8** (team action; the only open Phase 0 item).
- [x] Task board: [GitHub Project — Dev Board](https://github.com/users/mkarthick1995/projects/1), linked to the repo with all open issues.
- [x] Research split filed as issues #1–#6 (2 states per dev, per the Roadmap table) using the `character_design` template flow.
- [x] Input/frame-data conventions agreed and documented ([Architecture](ARCHITECTURE.md), [Character Authoring](CHARACTER_AUTHORING.md)).

**Exit criteria:** everyone can clone, open, and run an empty scene; task board live; research assignments made.

## Phase 1 — Vertical Slice: one character, one stage (Week 3–7)

Goal: two identical placeholder fighters on one stage, one full round of readable combat. This validates engine choice and game feel.

Build order (each item is testable on its own):
1. [x] **Fighter state machine** — idle, walk, dash (double-tap), jump, crouch, block, hit-stun, knockdown + wake-up, KO. (`src/core/fighter_state_machine.gd`)
2. [x] **Input system** — buffered inputs, numpad motion parser (QCF, double-QCF), double-tap detection, keyboard 2-player mapping (gamepad mapping TODO). (`src/core/input_buffer.gd`)
3. [x] **Hit/hurtbox system** — data-driven boxes per active frame, polled deterministically; blocking + chip; launcher knockdowns with air-stun held to landing. (`src/core/combat/`)
4. [x] **Moveset** — slice character has 3 ground normals, 1 air normal, QCF special, EX special (meter), double-QCF super with technique cam (`src/characters/bengal_lathi/`). Placeholder colored-box sprites.
5. [x] **Round loop** — health/meter bars, round timer, best-of-3, KO/timeout, rematch. (`src/game/match/`)
6. [x] **Game-feel pass** — hit-stop, hit-flash, screen-shake (trauma model), hit sparks, KO + super slow-mo. Real *tuning* still needs human playtests.
7. [x] **Stage + camera** — parallax dusk river-ghat backdrop (sky/sun/temples/trees layers); camera tracks, zooms, shakes, and punches in.

**Exit gate:** the outside playtest is the one remaining Phase 1 item — **tracked as issue #7** (inherently a human gate).

Also landed early from Phase 2: **training mode** (frozen timer, auto-refill, hitbox/state/input overlay — toggle H), the **meter economy** (EX + super costs), **throws + throw-tech** (completing the strike/block/throw triangle), **gamepad support** (device 0/1 → P1/P2), a **parallax dusk-ghat stage**, and **character #2** — Varanasi Musti Yuddha ("Malla"), built purely from `.tres` data with zero engine changes, which satisfies the Phase 2 exit gate. See [`CHARACTER_AUTHORING.md`](CHARACTER_AUTHORING.md) for how to build the rest of the roster.

Verified by headless tests (`tests/run_tests.gd` unit, `tests/run_sim_smoke.gd` end-to-end) — both run in CI.

**Exit criteria:** an outside player can pick up a controller and have a fun 1v1 with the slice character. **Playtest with fresh eyes before Phase 2.**

## Phase 2 — Systems hardening & content pipeline (Week 8–11)

Goal: make adding characters cheap and the combat model complete.

- [x] Finalize the **character data format** (resource `.tres`): frame data, move list, hitbox timelines, meter costs. Documented in [Character Authoring](CHARACTER_AUTHORING.md).
- [x] **Animation import pipeline** — sprite strips → `SpriteFrames` via `tools/build_sprite_frames.gd`; see [Art Pipeline](ART_PIPELINE.md). Placeholder generator included.
- [x] Full defensive kit: throws + tech, chip, pushback, meter gain/spend, EX specials, super with a **technique cam** (slow-mo + move-name banner + camera punch-in).
- [x] Training mode: hitbox display, frame-data readout (move phase + S/A/R), input display, auto-refill. Our primary dev/debug tool (`T`, then `H`).
- [x] Audio system: SFX bus + hit/block/whiff/throw/KO layers, per-character percussion hooks; see [Audio Pipeline](AUDIO_PIPELINE.md). Placeholder WAVs generated.
- [x] Character authoring guide in `docs/` so all three devs can build fighters in parallel.

**Exit criteria:** a second character built *entirely from data + art*, no core-engine changes required. ✅ **Met** — Varanasi Musti Yuddha ("Malla") is pure `.tres` data.

## Phase 3 — Roster & stages (Week 12–20)

Goal: build out to 6–8 characters and 4–6 stages, in parallel.

- [ ] Divide roster across the three devs (see Roadmap ownership). Each character: concept → moveset → animations → frame-data tuning → balance pass.
- [ ] Region stages with parallax + regional percussion, one per priority character.
- [ ] Continuous internal balance playtesting; keep a shared "balance changelog."
- [ ] Character-complete checklist (see below) enforced per fighter via PR template.

**Exit criteria:** 6–8 characters playable in 1v1, each meeting the character-complete checklist.

## Phase 4 — Modes, UI & polish (Week 21–26)

- [ ] Full front-end: main menu, character select, stage select, options, controls remap.
- [ ] **2v2 Team Battles** (tag mechanic, rival-school framing).
- [ ] Arcade/CPU ladder + basic AI.
- [ ] Options: audio/video, controller config, accessibility (input display, colorblind-safe UI).
- [ ] Pause, rematch, results screens; save/settings persistence.
- [ ] Art/audio polish pass; performance profiling; build pipeline for Windows + Linux.

**Exit criteria:** feature-complete v1 candidate; external playtest round; bug-bash.

## Phase 5 — Stretch / post-v1 (deferred)

- State Tournament Ladder + leaderboards.
- Online play with **rollback netcode** (highest-risk item — deliberately last).
- DLC characters (grappler), extra stages, story/arcade cutscenes.

---

## Character-complete checklist (per fighter)

A character is "done" only when all of these pass in review:
- [ ] Concept doc (name, personality, 3+ specials, technique provenance).
- [ ] All animations: idle, walk f/b, dash f/b, jump, crouch, 3 normals × (stand/crouch/jump), specials, super, hit reactions, block, KO/win.
- [ ] Hit/hurtbox timelines authored for every attack frame.
- [ ] Frame data set (startup/active/recovery/on-block) and balanced against the slice character.
- [ ] Meter costs + EX + one super with technique cam.
- [ ] SFX + regional percussion hook.
- [ ] Passes training-mode hitbox/frame-data review.
- [ ] Playtested in ≥3 matches without a crash or soft-lock.

## Key risks & mitigations

| Risk | Mitigation |
|---|---|
| Game feel is subtle and hard | Vertical slice + outside playtests *early* (Phase 1 exit gate). |
| Scope creep (roster, online) | Scope is locked in Game Design §7; online is Phase 5 only. |
| Merge pain on binary assets | Git LFS + one-artist-per-asset ownership + `.gitattributes` (Phase 0). |
| Character work blocks on engine | Data-driven format is the Phase 2 exit gate before roster build-out. |
| Rollback rewrite later | Deterministic core sim decoupled from rendering *from day one*. |
| Balance chaos with 3 authors | Shared balance changelog + one "balance owner" per patch. |
