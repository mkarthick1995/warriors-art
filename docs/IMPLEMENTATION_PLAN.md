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

- [x] GitHub repo, `.gitignore`, Git LFS, branch protection, CI. *(this scaffold)*
- [ ] Godot 4.x project opens clean on all three machines (document the exact version in `docs/ONBOARDING.md`).
- [ ] Task board (GitHub Projects / Trello / Notion) with columns: Backlog → Ready → In Progress → Review → Done.
- [ ] Research split: each person deep-dives 2 states — confirm techniques, gather reference video, draft a one-page character concept (name, personality, 3 special moves). Use the `character_design` issue template.
- [ ] Agree the input/frame-data conventions in [Architecture](ARCHITECTURE.md).

**Exit criteria:** everyone can clone, open, and run an empty scene; task board live; research assignments made.

## Phase 1 — Vertical Slice: one character, one stage (Week 3–7)

Goal: two identical placeholder fighters on one stage, one full round of readable combat. This validates engine choice and game feel.

Build order (each item is testable on its own):
1. **Fighter state machine** — idle, walk, dash, jump, crouch, block, hit-stun, KO. (`src/core/fighter_state_machine.gd`)
2. **Input system** — buffered inputs, motion-input parser (QCF etc.), local 2-player device mapping. (`src/core/input_buffer.gd`)
3. **Hit/hurtbox system** — data-driven boxes per animation frame; collision → damage/knockback. (`src/core/combat/`)
4. **Two normals + one special** for the slice character (per the ideation "Next Steps"). Placeholder sprites are fine.
5. **Round loop** — health bars, round timer, best-of-3, win/KO, rematch. (`src/game/match/`)
6. **Game-feel pass** — hit-stop, hit-stun frames, screen-shake, one impact particle. This is where "fun" is won or lost.
7. **One parallax stage** with a floor and camera that tracks both fighters.

**Exit criteria:** an outside player can pick up a controller and have a fun 1v1 with the slice character. **Playtest with fresh eyes before Phase 2.**

## Phase 2 — Systems hardening & content pipeline (Week 8–11)

Goal: make adding characters cheap and the combat model complete.

- [ ] Finalize the **character data format** (resource `.tres`): frame data, move list, hitbox timelines, meter costs. Document it so an artist/designer can add moves without a programmer.
- [ ] **Animation import pipeline** — Aseprite/PSD → sprite sheets → Godot `SpriteFrames`, with a naming convention and an import checklist.
- [ ] Full defensive kit: throws + tech, chip, pushback, meter gain/spend, EX specials, one super with a **technique cam**.
- [ ] Training mode (hitbox display, frame-data overlay, input display) — this is also our primary dev/debug tool.
- [ ] Audio system: per-character percussion hooks, SFX bus, hit-sound layers.
- [ ] Character authoring guide in `docs/` so all three devs can build fighters in parallel.

**Exit criteria:** a second character built *entirely from data + art*, no core-engine changes required.

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
