# Audio Pipeline

How sound gets into the game. Placeholder audio is procedurally generated; real recordings replace the WAVs **with the same names** — nothing else changes.

## Layout

```
assets/audio/sfx/          hit_light, hit_heavy, block, whiff, throw, ko  (.wav)
assets/audio/percussion/   <percussion_id>_loop.wav   e.g. dhak_loop.wav
```

WAVs go through Git LFS automatically. 44.1 kHz mono is fine; stereo works too.

## How it plays

- The `Sfx` autoload (`src/autoload/sfx.gd`) owns two code-created buses — **SFX** (pooled players, slight pitch jitter) and **Music** (percussion loops) — both routed to Master.
- Combat sounds are triggered by the presentation layer (`juice.gd`) from sim signals: hits pick the light/heavy layer by damage, blocked hits use the block sound, every attack start plays a whiff, throws and KOs have their own hits.
- **Percussion hook:** each character's `CharacterData.percussion` id (e.g. `"dhak"`, `"pakhawaj"`) maps to `assets/audio/percussion/<id>_loop.wav`. The match plays P1's character loop (blend/switching is a later polish item). A missing loop is silent, not an error — but CI checks that every roster character's id has a file.

## Placeholders

`python tools/generate_placeholder_audio.py` regenerates all current WAVs (deterministic, seeded). Add new percussion ids there when a new character needs a loop before real recordings exist.

## Real recordings (Phase 3+)

Replace files 1:1. For a new character: record/source the regional instrument (chenda, dhol, pung, thavil, …), export a seamless 2–4 bar loop as `<id>_loop.wav`, set `percussion = "<id>"` in the character's `.tres`. Keep provenance notes in the character-design issue (authenticity is a design pillar).
