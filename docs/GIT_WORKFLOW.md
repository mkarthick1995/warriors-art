# Warrior's Art — Git Workflow

A lightweight trunk-based workflow tuned for a three-person team and a Godot project with large binary art/audio assets.

## Branching model

- **`main`** is always releasable and protected. No direct pushes.
- Work happens on **short-lived feature branches** off `main`.
- Branch naming: `type/short-description`
  - `feat/kerala-urumi-special`
  - `fix/hitbox-double-trigger`
  - `art/varanasi-stage-parallax`
  - `chore/ci-gdlint`
  - `docs/character-authoring-guide`

Keep branches short-lived (days, not weeks) to avoid painful merges — especially with binary assets that can't be auto-merged.

## Commits

- **Conventional Commits**: `type(scope): summary`
  - `feat(kerala): add urumi whip special`
  - `fix(combat): stop hurtbox surviving one frame after KO`
  - `art(stage): add Punjab wheat-field parallax layers`
  - Types: `feat`, `fix`, `art`, `audio`, `docs`, `refactor`, `test`, `chore`, `perf`.
- Present tense, imperative, ≤72-char summary. Body explains *why* when non-obvious.
- Commit logically; don't dump unrelated changes in one commit.

## Pull requests

1. Push your branch, open a PR into `main`.
2. Fill in the PR template (what/why, testing, screenshots or a gif for anything visual).
3. CI must pass (lint, format check, tests).
4. Get **one approval** from the area lead (`CODEOWNERS` auto-requests them).
5. Squash-merge (keeps `main` history clean). Delete the branch after merge.
6. Keep PRs small and single-purpose.

## Git LFS (mandatory)

Binary assets **must** go through Git LFS or the repo will bloat and merges will break. This is configured in [`.gitattributes`](../.gitattributes).

- Install once per machine: `git lfs install`
- Tracked by default: `*.png *.jpg *.jpeg *.aseprite *.ase *.psd *.wav *.mp3 *.ogg *.ttf *.otf *.mp4 *.webm *.docx`
- To track a new binary type: `git lfs track "*.ext"`, commit the updated `.gitattributes`.
- Verify before pushing large files: `git lfs status`.

### Avoiding binary merge conflicts
Binary assets can't be merged. To avoid conflicts:
- **One owner per asset.** Don't have two people editing the same sprite sheet on parallel branches.
- Coordinate art tasks so files don't overlap; keep art PRs small and land them quickly.
- Never commit Godot's `.godot/` import cache (it's git-ignored) — regenerate locally.

## Branch protection (configure on GitHub once)

On `main`, enable:
- Require a pull request before merging (≥1 approval).
- Require status checks to pass (CI).
- Require branches to be up to date before merging.
- Require conversation resolution.
- (Recommended) Require linear history / squash-only.

## Day-to-day

```bash
git checkout main && git pull                 # start fresh
git checkout -b feat/kerala-urumi-special     # branch
# ...work...
git add -p && git commit -m "feat(kerala): add urumi whip special"
git push -u origin feat/kerala-urumi-special  # open PR from the link
```

## Releases

- Tag v1 candidates as `v1.0.0-rc.N`, final as `v1.0.0` (SemVer).
- Export presets for Windows + Linux live in the Godot project; document build steps in `ONBOARDING.md` before M4.
