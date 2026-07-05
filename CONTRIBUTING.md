# Contributing to Warrior's Art

Welcome. This is a small, closed team — these rules keep our three-person codebase clean and mergeable.

## Before you start
- Read [`docs/ONBOARDING.md`](docs/ONBOARDING.md) and set up your toolchain.
- Skim [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md).

## Workflow (short version)
1. Branch off `main`: `type/short-description` (see Git Workflow).
2. Make focused changes; keep sim, art, and UI concerns in separate PRs where possible.
3. Run `gdformat src/` and `gdlint src/`; ensure tests pass.
4. Use Conventional Commits: `type(scope): summary`.
5. Open a PR, fill the template, attach a gif/screenshot for anything visual.
6. Get one approving review from the area lead (`.github/CODEOWNERS`) and green CI.
7. Squash-merge; delete your branch.

## Non-negotiables
- **No direct pushes to `main`.**
- **All binaries via Git LFS** (`git lfs status` before pushing).
- **Keep the simulation deterministic** — see Coding Standards §4 and Architecture. This is reviewed strictly.
- **Frame data is data, not code** — author moves in `.tres` resources.
- One person owns a given art asset at a time (binaries can't be merged).

## Reporting issues / proposing work
Use the issue templates: **Bug report**, **Feature request**, **Character design**. Link issues to your PR.

Questions? Ping the relevant area lead (see the Roadmap ownership table).
