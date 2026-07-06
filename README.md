# Warrior's Art

> A cinematic 2D fighting game where every character is an original fighter built on a real Indian state's martial-arts tradition. Play 1v1 or 2v2 as rival training schools. The competitive hook is regional pride — whose state's style wins.

**Engine:** Godot 4.x (GDScript) · **Platform (v1):** PC (Windows / Linux) · **Multiplayer (v1):** Local only

---

## What this is

Warrior's Art is a 2D fighter in the Street Fighter / Guilty Gear lineage. The entire cast is drawn from India — each fighter embodies one state's traditional martial art, with movesets, stances, and weapons based on the real discipline. Because every character is an **original design** grounded in public-domain martial traditions (not any film, actor, or existing game character), the IP is fully ownable, trademarkable, and franchise-ready.

## The v1 roster (6–8 characters)

| State | Martial Art | Signature Weapon | Archetype |
|---|---|---|---|
| Kerala | Kalaripayattu | Urumi (whip-sword), dagger | Fluid acrobatic all-rounder |
| Tamil Nadu | Silambam | Bamboo staff, deer horns | Long-range zoner |
| Punjab | Gatka | Sword + shield, chakram | Aggressive dual-wielder |
| Manipur | Thang-Ta | Sword + spear | Technical stance-dancer |
| Maharashtra | Mardani Khel | Patta, vita (whip-lance) | Armored bruiser with reach |
| Bengal | Lathi Khela | Lathi (bamboo stick) | High-speed rushdown |
| Bihar | Pari-Khanda | Sword and shield | Balanced sword-and-board |
| Varanasi | Musti Yuddha | Unarmed | Pure brawler / clinch pressure |

> Stretch grappler slot: a pan-India Pehlwani / Malla-yuddha wrestler ("big grappler") as a later addition.

See [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) for the full design brief.

## Project documentation

| Doc | Purpose |
|---|---|
| [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) | How we build it — phases, systems, vertical slice |
| [Roadmap](docs/ROADMAP.md) | Milestones, timeline, ownership |
| [Game Design](docs/GAME_DESIGN.md) | Roster, mechanics, modes, art & audio direction |
| [Architecture](docs/ARCHITECTURE.md) | Code structure, core systems, data model |
| [Character Authoring](docs/CHARACTER_AUTHORING.md) | Build a fighter from data — no engine code |
| [Art Pipeline](docs/ART_PIPELINE.md) | Sprite-strip convention → SpriteFrames build |
| [Audio Pipeline](docs/AUDIO_PIPELINE.md) | SFX layers + regional percussion hooks |
| [Coding Standards](docs/CODING_STANDARDS.md) | GDScript style, naming, review rules |
| [Git Workflow](docs/GIT_WORKFLOW.md) | Branching, commits, PRs, LFS |
| [Onboarding](docs/ONBOARDING.md) | New-contributor setup (start here) |

## Quick start

1. Install **Godot 4.3-stable (standard, GDScript build)** — https://godotengine.org/download
2. Install **Git** and **Git LFS**: `git lfs install`
3. Clone: `git clone https://github.com/mkarthick1995/warriors-art.git`
4. Open `project.godot` in Godot and press F5 — Enter starts a local 1v1 (Lathiyal vs Malla), T starts training mode (H toggles the hitbox overlay).
   **P1:** WASD move, J/K light/medium, J+K throw, double-tap dash, motion specials (QCF+J, QCF·QCF+J super on full meter) · **P2:** arrows + numpad 1/2 (numpad 1+2 throw).
   **Gamepads:** controller 1 → P1, controller 2 → P2 (D-pad/stick + bottom/left face buttons; bottom+left together = throw).
5. Read [`docs/ONBOARDING.md`](docs/ONBOARDING.md).

Headless tests: `godot --headless --path . -s res://tests/run_tests.gd` (unit) and `-s res://tests/run_sim_smoke.gd` (end-to-end). CI runs both plus `gdformat`/`gdlint`.

## Team

Three-person team. Ownership and area leads are tracked in [`.github/CODEOWNERS`](.github/CODEOWNERS) and the [Roadmap](docs/ROADMAP.md).

## License

Proprietary — All Rights Reserved. See [`LICENSE`](LICENSE). This is intentionally closed-source to protect the IP.
