# Warrior's Art — Onboarding

Start here. Goal: from zero to running the project and making your first PR.

## 1. Install tools

| Tool | Version | Notes |
|---|---|---|
| **Godot** | **4.3-stable (standard / GDScript build, NOT .NET)** | Pinned — CI runs 4.3.0. Everyone uses the same version; mismatches rewrite scene files and cause noisy diffs. |
| **Git** | latest | |
| **Git LFS** | latest | Run `git lfs install` once after installing. |
| **Python** | 3.10+ | For the linters below. |
| **gdtoolkit** | 4.x | `pip install "gdtoolkit==4.*"` → gives `gdformat` + `gdlint`. If they aren't on your PATH (common on Windows), use `python -m gdtoolkit.formatter` / `python -m gdtoolkit.linter` instead. |

> Decide and record the exact Godot version at M0. Mismatched Godot versions can rewrite `.tscn`/`.godot` files and cause noisy diffs.

## 2. Clone and open

```bash
git lfs install
git clone https://github.com/mkarthick1995/warriors-art.git
cd warriors-art
git lfs pull
```
Open `project.godot` in Godot. Let it import (this generates the local, git-ignored `.godot/` cache).

## 3. Read these, in order

1. [Game Design](GAME_DESIGN.md) — what we're building.
2. [Architecture](ARCHITECTURE.md) — how the code is shaped (esp. the layering + determinism rules).
3. [Coding Standards](CODING_STANDARDS.md) — how we write GDScript.
4. [Git Workflow](GIT_WORKFLOW.md) — branches, commits, PRs, LFS.
5. [Implementation Plan](IMPLEMENTATION_PLAN.md) + [Roadmap](ROADMAP.md) — what's next and who owns what.

## 4. Your first contribution

1. `git checkout -b docs/your-name-onboarding-notes`
2. Add yourself to `.github/CODEOWNERS` and the Roadmap ownership table.
3. Run the linters: `gdformat src/ && gdlint src/`.
4. Commit (Conventional Commits), push, open a PR, get it reviewed. This proves your whole toolchain + workflow works.

## 5. Local dev checklist before every push

- [ ] `gdformat src/` — no reformatting left to do.
- [ ] `gdlint src/` — clean.
- [ ] Tests pass: `godot --headless --path . -s res://tests/run_tests.gd` and `-s res://tests/run_sim_smoke.gd` (both exit 0).
- [ ] `git lfs status` — any new binaries are LFS-tracked, not committed raw.
- [ ] No stray `print()` / debug scenes committed.

## 6. Task board

Tasks live on the shared board (GitHub Projects / Trello / Notion — link here once created). Columns: **Backlog → Ready → In Progress → Review → Done**. Move your card and link the PR.

## 7. Getting help

- Systems/engine questions → Dev A. Gameplay/data → Dev B. Art/audio/UX → Dev C. (See Roadmap ownership.)
- Weekly sync: demo your branch, raise blockers.
