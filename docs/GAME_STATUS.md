# Warrior's Art — Game Status

The master "what exists right now" document. Updated at each milestone; last updated **2026-07-07** (Phase 4 in progress). For *how* things are built see [Architecture](ARCHITECTURE.md); for *what's next* see [Implementation Plan](IMPLEMENTATION_PLAN.md) and [Roadmap](ROADMAP.md); for history see [CHANGELOG](../CHANGELOG.md).

## At a glance

| | |
|---|---|
| Engine | Godot 4.3-stable (GDScript), GL Compatibility renderer, fixed 60 Hz sim |
| Characters | **8 / 8** (full design-doc roster) — all placeholder art/names |
| Stages | **6** region backdrops, random per match |
| Modes | Versus (2P local), **Arcade** (solo CPU ladder), Training |
| Input | Keyboard ×2 + gamepads ×2 |
| Tests | 239 unit checks + 2 gameplay smoke suites + AI smoke, all in CI |
| Assets | 100% generated/original — see [Asset Licenses](ASSET_LICENSES.md) |
| Milestones | M0 ✅ · M1 build-complete (playtest gate = issue #7) · M2 ✅ · M3 build-complete · M4 in progress |

## The roster (all data-driven `.tres`, no engine code per character)

| # | Fighter (placeholder name) | State / Art | Archetype | Signature |
|---|---|---|---|---|
| 1 | Lathiyal | Bengal / Lathi Khela | Fast rushdown | Whirlwind Lathi launcher; dhak |
| 2 | Malla | Varanasi / Musti Yuddha | Unarmed brawler | Rising Musti (DP); pakhawaj |
| 3 | Silambar | Tamil Nadu / Silambam | Long-range zoner | 125–215px staff pokes, Neetta Thallu lunge; thavil |
| 4 | Gatkabaz | Punjab / Gatka | Sword+shield midrange | **Chakram projectile** (+EX); dhol |
| 5 | Kalari Abhyasi | Kerala / Kalaripayattu | Acrobatic glass cannon | Curved **urumi** whip, huge-reach spin; chenda |
| 6 | Huyen Lallong | Manipur / Thang-Ta | Technical sword/spear | Ta Chongba spear charge; pung |
| 7 | Mardani Veer | Maharashtra / Mardani Khel | Armored bruiser | Tethered **vita** throw (short-range projectile); tasha |
| 8 | Khanda Yoddha | Bihar / Pari-Khanda | Balanced sword-and-board | Pari Prahar shield bash, overhead launcher; dholak |

Every character: 3 ground normals + 1 air normal + special + EX special (250 meter) + super (full meter, technique cam). Deferred to research: Thang-Ta stance switching, Pari-Khanda shield parry (issues #1–#6 hold the real concepts).

## Stages

GhatDusk (Varanasi-style ghats) · TempleDawn (Tamil Nadu gopurams) · BackwaterDusk (Kerala) · WheatFields (Punjab golden hour) · HillVillage (Manipur) · FortRampart (Maharashtra Sahyadri fort). All hand-authored parallax polygon scenes in `scenes/stages/`; picked randomly per match (backdrops are pure presentation — the sim arena is identical).

## Combat systems (all implemented and tested)

- **Movement**: walk, jump, crouch, double-tap dash/backdash
- **Attacks**: data-driven startup/active/recovery, per-frame hitboxes, air attacks, numpad-notation motions (QCF `236`, DP `623`, double-QCF supers) with length-scaled leniency
- **Defense**: hold-back blocking, chip damage, blockstun frame advantage
- **Throws**: L+M input, 8-tick tech window, controller-resolved
- **Knockdowns**: launcher hits hold air-stun until landing → invulnerable knockdown → timed wake-up
- **Meter**: build on hit, EX specials (250), supers (1000) with **technique cam** (slow-mo + move-name banner + camera punch-in)
- **Projectiles**: deterministic, data-authored (`ProjectileData`), central resolution — chakram (full-screen) and vita (tether-limited) prove the range
- **Game feel**: hit-stop, trauma screen-shake, hit sparks, KO slow-mo
- **Audio**: SFX bus (hit light/heavy, block, whiff, throw, KO) + per-character regional percussion loops
- **CPU AI**: input-level brain (emits `InputButtons`, no sim access — determinism preserved), difficulty 1–7 scaling reaction/blocking/specials

## Modes & flow

- **Title** → `Enter` Versus / `A` Arcade / `T` Training; `Esc` in-game = pause + full controls + `Q` quit-to-title
- **Character select**: grid of 8 with live sprite portraits, dual cursors, lock/unlock; arcade variant (P1 only vs CPU ladder)
- **Versus**: best-of-3, 99s rounds, rematch
- **Arcade**: ladder through the other 7 fighters, difficulty ramps 1→7, VICTORY/DEFEAT/CHAMPION flow
- **Training**: frozen timer, auto-refill, hitbox/frame-data/input overlay (`H`)

## Controls

| | P1 | P2 |
|---|---|---|
| Move | WASD | Arrows |
| Light / Medium | **R / T** (legacy J/K) | **I / O** (legacy numpad 1/2) |
| Throw | R+T | I+O |
| Gamepad | pad 1: D-pad/stick + face buttons | pad 2 same |

## Engineering state

- **Pipelines**: character authoring ([guide](CHARACTER_AUTHORING.md)), sprite strips → SpriteFrames ([art](ART_PIPELINE.md)), procedural placeholder generators (sprites + audio, deterministic), audio ([audio](AUDIO_PIPELINE.md))
- **CI on every push/PR**: gdformat + gdlint, 239 unit checks (data contracts for all 8 characters: moves, sprites, percussion, supers, projectiles), 16-step gameplay smoke (walk/hit/block/dash/throw/knockdown/super/projectile/KO/round-reset), AI smoke
- **Determinism**: fixed-tick sim, no wall-clock, seeded RNG only, presentation strictly read-only — rollback netcode remains possible post-v1
- **Tooling**: headless test runners, screenshot capture tool, `C:\Workspace\Godot\` local runtime + desktop shortcut

## Deliberately deferred / on hold

- **2v2 Team Battles** — on hold by decision (2026-07-07) to prioritize art & music
- Online play / rollback netcode — post-v1 by design
- Options menu (volume/remap/fullscreen), Windows/Linux export presets — Phase 4 remainder
- Simultaneous-throw auto-tech; cross-body push collision; multi-hit moves — known TODOs in code

## Current focus: art & music (with copyright discipline)

All assets today are placeholders — original and safe, but not shippable quality. The path to real assets runs through [Asset Licenses](ASSET_LICENSES.md): IP-assignment contracts for commissions, dual-copyright care for music (record/commission the regional percussion), AI-disclosure tracking for stores. Team research issues #1–#6 feed authentic movesets and character identities.

## Links

- Repo: https://github.com/mkarthick1995/warriors-art (private)
- Board: https://github.com/users/mkarthick1995/projects/1
- Open human-gated issues: #1–#6 (research), #7 (M1 playtest gate), #8 (team onboarding)
