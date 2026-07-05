# Summary

<!-- What does this PR do and why? Link the issue: Closes #___ -->

## Type
- [ ] feat  - [ ] fix  - [ ] art  - [ ] audio  - [ ] docs  - [ ] refactor  - [ ] test  - [ ] chore

## Changes
<!-- Bullet the key changes. -->

## Testing
<!-- How did you verify this? Steps, playtest notes. -->

## Visuals
<!-- For anything visible, attach a screenshot or gif. Required for art/UI/VFX. -->

## Checklist
- [ ] Branch is focused (sim / art / UI not mixed unless trivial).
- [ ] `gdformat src/` and `gdlint src/` pass locally.
- [ ] Tests pass (or N/A).
- [ ] No stray `print()` / debug scenes committed.
- [ ] New binaries are Git LFS-tracked (`git lfs status`).
- [ ] Sim changes preserve determinism (no wall-clock, no unseeded RNG — see Coding Standards §4).
- [ ] Frame data / tuning is in `.tres` resources, not hard-coded.
- [ ] Docs updated if behaviour or design changed.
