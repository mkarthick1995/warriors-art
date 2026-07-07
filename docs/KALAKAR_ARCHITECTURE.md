# Kalakar — Asset Forge Architecture (Design Proposal)

*Kalakar ("artist"): a tool that turns one hand-drawn character sheet into the hundreds of game-ready animation assets a fighter needs.* Status: **v0.1 MVP built** (2026-07-07) at `C:\Workspace\kalakar` (own project, per team decision) — template, full pipeline (ingest→segment→render→export), `bengal_lathi` pose set, synthetic end-to-end test passing. Next: first real hand-drawn sheet.

## 1. Purpose & product shape

**Input:** a photo/scan of a character drawn on paper (on a printed template).
**Output:** everything a Warrior's Art character needs — 13+ animation strips in our `anim@FRAMESxFPS.png` convention, a built `SpriteFrames` resource, portraits for the select screen, and an asset-ledger row — plus engine-agnostic exports later.

Shape: an **internal pipeline tool first** (CLI + preview window), used by our team; potential standalone product later. Resist GUI-app scope until the pipeline proves itself — the value is in the pipeline, not the window chrome.

## 2. The core idea: parts + rig + pose library (not per-frame drawing, not AI imagination)

One drawing cannot become 300 frames by redrawing; it becomes 300 frames by **decomposition and puppetry**:

```
photo of drawing ──► clean parts ──► rigged puppet ──► posed per frame ──► rendered strips
                     (segmentation)   (skeleton+pivots)  (pose library)      (exporter)
```

Validated approach (cf. Meta's open-source *Animated Drawings*). Our advantage: the **pose library already exists** — `tools/generate_placeholder_sprites.py` defines 13 animations of per-frame joint poses per archetype, already tuned against real gameplay (reach distances match hitbox data). Kalakar re-targets those poses from stick limbs to drawn parts.

## 3. Pipeline stages (each a module with a file-based I/O contract)

| # | Stage | In → Out | How |
|---|---|---|---|
| 1 | **Ingest** | photo (jpg/png) → normalized image | deskew via template registration marks, white-balance, contrast, denoise (OpenCV) |
| 2 | **Segment** | normalized image → part images (head, torso, upper/lower arms ×2, hands, upper/lower legs ×2, weapon…) | **template-guided**: the artist draws inside a printed parts-sheet template with fiducial corner marks, so each part's location is known — deterministic, no ML needed. Manual box-editor as fallback. |
| 3 | **Clean** | part images → crisp transparent-background parts | thresholding + despeckle + optional vector trace (potrace) for infinite-resolution linework; flat-color fill from a palette file |
| 4 | **Rig** | parts + skeleton spec → `rig.json` | pivots/joints per part, z-order, attachment points (weapon in hand), scale normalization to our 128×192 frame space |
| 5 | **Pose** | `rig.json` + pose library → per-frame part transforms | the existing pose sets (idle/walk/attacks/hit/knockdown…), extended with per-archetype parameters (staff length → weapon part length, etc.) |
| 6 | **Render** | posed frames → `anim@NxF.png` strips | compose parts per frame (rotate/translate around pivots), rasterize at target resolution; optional outline/rim-light pass for the cinematic look |
| 7 | **Export** | strips → engine assets | reuse `tools/build_sprite_frames.gd` for SpriteFrames; select-screen portrait; auto-append `docs/ASSET_LICENSES.md` row ("hand-drawn by X, processed by Kalakar") |
| 8 | **Preview/QA** | assets → human eyes | a Godot scene that hot-loads the character into training mode — the game itself is the previewer |

Every stage reads/writes files in a character workspace dir → stages are independently testable, resumable, and re-runnable (change the drawing, re-run from stage 1; tweak a pivot, re-run from 5).

## 4. Data contracts

```
workspace/<character>/
├── input/photo.jpg              # the drawing
├── parts/*.png                  # stage 2–3 output (transparent, cleaned)
├── rig.json                     # skeleton: parts, pivots, z-order, attachments
├── palette.json                 # flat-fill colors chosen by the artist
├── poses/ (shared library)      # animation definitions (from the game repo)
└── out/anim@NxF.png + frames.tres + portrait.png + ledger_row.md
```

`rig.json` sketch: `{ "parts": [{ "name": "upper_arm_front", "image": "parts/upper_arm_front.png", "pivot": [12, 8], "parent": "torso", "attach_at": [40, 22], "z": 3 }], "weapon_length": 116 }`

## 5. Tech stack (recommendation)

- **Pipeline core: Python** (OpenCV, Pillow, potrace binding) — matches our existing generator code, easy for the whole team, trivially CI-tested with sample drawings.
- **Preview/QA + final export: Godot** — the game is the ground truth for how assets read; `build_sprite_frames.gd` already exists.
- **No ML/AI in the core path** (keeps it deterministic + ledger-clean). An *optional* stylization stage (AI shading of drawn parts) can slot between stages 3–4 later, clearly flagged for Steam disclosure.
- Repo: start under `tools/kalakar/` in this repo (shares conventions, pose library, and CI); extract to its own repo if it matures toward a product.

## 6. Build plan

- **MVP (prove it end-to-end):** printed template sheet (PDF) → one hand-drawn Lathiyal parts sheet → segmentation + cleanup → rig with fixed skeleton → render `idle` + `walk` + `jab` using the existing pose data → into the game next to the stick figures. *The demo: your drawing, walking around in a real match.*
- **v0.2:** all 13 animations; weapon attachment variants (staff lengths, shield); palette tooling; portrait export; ledger automation.
- **v0.3:** manual pivot/box editor (small Godot tool scene); smear-frame and squash options for the cinematic pass; per-character pose overrides.
- **Later/maybe:** standalone GUI, non-Warrior's-Art export targets (generic sprite sheets, Spine JSON), optional AI stylization module.

## 7. Risks & honest limits

| Risk | Reality check |
|---|---|
| Puppet look vs hand-drawn feel | Cutout animation reads "animated cartoon," not "key-framed anime." Mitigations: more parts (forearm/hand split), rotation smears, secondary motion. If the team wants true frame-by-frame anime, that's human-artist territory — Kalakar still saves them 80% by generating pose-accurate underlays to draw over. |
| Photo quality variance | Template with corner marks + a "retake photo" QA gate in stage 1 solves most of it. |
| One front-facing drawing = one view | Fighting games live in profile — the template asks for a **side-view** drawing, matching gameplay. |
| Scope creep into "app" | The pipeline is the product. CLI + game-as-previewer until v0.3. |

## 8. Decisions needed

1. Go/no-go on the **parts-sheet template** approach (artist draws parts separately — this is what makes it deterministic).
2. Tool lives in `tools/kalakar/` (recommended) vs new repo.
3. MVP target character (recommend Lathiyal).
