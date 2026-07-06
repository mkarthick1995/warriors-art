# Art Pipeline — Sprites to SpriteFrames

How character animation art gets into the game. Works today with the generated placeholder silhouettes; real art replaces the PNGs with the **same names and layout** and reruns one command.

## 1. The convention

```
assets/sprites/<character>/<anim>@<frames>x<fps>.png
e.g.  assets/sprites/bengal_lathi/jab@4x20.png   (4 frames, 20 fps)
```

- **Horizontal strip**: frames left→right, each frame **128×192 px**.
- **Feet on the baseline** at y=188, body centered around x≈56–64, **facing right** (the game flips for left).
- The fighter's collision body is 60×160 world px; keep the character roughly within that, letting weapons/effects overshoot.
- PNGs go through **Git LFS** automatically (`.gitattributes`).

### Animation names the game looks for

| Name | Used for | Loops |
|---|---|---|
| `idle`, `walk`, `crouch`, `jump` | movement states | yes |
| `hit` | hitstun / blockstun / thrown | no |
| `knockdown` | knockdown + KO | no |
| *`MoveData.animation_name`* | each attack (e.g. `jab`, `whirlwind`) | no |

Missing animations fall back to `idle` — ship a character with just `idle` + `walk` and add the rest incrementally. A character with **no** sprites at all renders as the colored placeholder box.

## 2. Build step

After adding/changing PNGs, from the repo root:

```bash
godot --headless --path . --import
godot --headless --path . -s res://tools/build_sprite_frames.gd
```

This writes `src/characters/<character>/<character>_frames.tres`. Then reference it from the character's `CharacterData` (`sprite_frames` field) — one-time setup per character.

**Commit the PNGs and the generated `_frames.tres` together.**

## 3. Placeholder generator (until real art lands)

`python tools/generate_placeholder_sprites.py` regenerates the stick-silhouette strips for characters defined in that script. Add a pose set there if you want animated placeholders for a new character before art exists.

## 4. Aseprite / real art notes (Phase 3)

- Export horizontal strip PNG per animation tag: *File → Export Sprite Sheet → Horizontal strip*, then rename to the `anim@NxF.png` convention.
- Target the design's 12–16 frames for key attacks (see Game Design §6); the pipeline doesn't care about frame counts.
- Per-frame hitboxes are authored in the move's `FrameData` against the sprite poses — use training mode (`T`, then `H`) to align boxes to art.
- If a character needs a bigger canvas (large weapons), bump `FRAME_W/FRAME_H` in `tools/build_sprite_frames.gd` — but keep it uniform per character.
