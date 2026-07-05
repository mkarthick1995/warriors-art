# Characters

One folder per fighter: `kerala_kalaripayattu/`, `bengal_lathi/`, etc. Each contains
the fighter scene (`.tscn`), its `CharacterData` resource (`.tres`), move `.tres`
files, and references to its `SpriteFrames`. A character is **data + art** — no
engine changes required to add one (see `docs/ARCHITECTURE.md`).

Build the vertical-slice character first (recommended: Bengal/Lathi or Varanasi/Musti Yuddha).
