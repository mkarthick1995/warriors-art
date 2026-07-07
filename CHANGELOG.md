# Changelog

Development history by milestone. Current status lives in [docs/GAME_STATUS.md](docs/GAME_STATUS.md).

## 2026-07-07 — Phase 4 begins + playtest fixes

- **Arcade mode**: solo ladder vs CPU through the other 7 fighters, difficulty 1–7 (reaction time, blocking, meter usage), VICTORY/DEFEAT/CHAMPION flow. `FighterAI` is an input-level brain — emits `InputButtons` through the normal pipeline, deterministic and replay-safe. AI smoke test added to CI. (`fb2a0db`)
- **Character select screen**: grid of all 8 fighters with live sprite portraits, dual cursors, lock/unlock, arcade variant; title simplified to Versus/Arcade/Training. (`4491163`)
- **Playtest feedback round 1** (first outside-ish playtest): Musti's missing sprites added; Esc pause menu with full controls + quit-to-title (`2ef6694`); P1 fighter selection (`11c7def`); no-numpad keyboard layout — R/T and I/O attack keys (`bbcb03b`); numpad-digit picker fix (`a780438`).
- **Asset provenance ledger** for store-launch copyright discipline. (`133262d`)

## 2026-07-06 → 07 — Phase 3: full roster & stages

- **8/8 characters** (all pure `.tres` data, zero engine changes per character):
  Lathi Khela rushdown & Musti Yuddha brawler (slice era), Silambam zoner (`73b02ff`), Gatka with chakram (`b0abae9`), Kalaripayattu urumi + Thang-Ta sword/spear (`d0a26a0`), Mardani Khel bruiser + Pari-Khanda all-rounder (`2ab50fc`).
- **Deterministic projectile system** (`ProjectileData` + fixed-tick `Projectile`), proving both full-screen (chakram) and tether-limited (vita) ranged attacks. (`b0abae9`, closed #9)
- **6 parallax stages** with random per-match selection.
- Title-screen fighter pickers (superseded by the select screen in Phase 4).

## 2026-07-06 — Phases 0–2 closed

- **Audio system**: SFX bus + hit/block/whiff/throw/KO layers, per-character regional percussion loops (procedurally generated placeholders); technique cam completed (banner + camera punch-in); training-mode frame-data readout; Phase 0 closed on GitHub (labels, milestones M0–M5, research issues #1–#6, playtest gate #7, project board). (`7218b01`)
- **Art pipeline**: sprite-strip convention → headless SpriteFrames builder; procedural placeholder sprite generator; animated fighter visual with colored-box fallback; CI LFS fix. (`168e34a`, `ea521b5`)
- **Combat completion**: throws + throw-tech, gamepad support (2 pads), first parallax stage, second character. (`4751bd7`)
- **Full kit + training mode**: dash/backdash, knockdowns with air-stun hold, air attacks, meter economy (EX + supers with technique-cam slow-mo), screen-shake/hit-sparks/KO slow-mo, training mode with hitbox overlay. (`0c06905`)

## 2026-07-05 — Foundations & vertical slice

- **Vertical slice**: deterministic 60 Hz sim (state machine, ring-buffer inputs with numpad motion parser, polled hit/hurtboxes), round loop (best-of-3, timer, KO), HUD, tracking camera, first character from data, headless test runners (unit + gameplay smoke) wired into CI. (`0f4d94d`)
- **Code review pass** on the scaffold: seeded-RNG bug, unconnected hitbox signal, missing stun exit, knockback math, real key bindings, GL Compatibility renderer. (`00619c0`)
- **Project scaffold**: Godot 4 project, docs suite (design/plan/roadmap/architecture/standards/workflow/onboarding), CI (gdformat/gdlint), Git LFS, PR/issue templates, private GitHub repo. (`af3715d`)
