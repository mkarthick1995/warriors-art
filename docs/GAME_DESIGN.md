# Warrior's Art — Game Design Brief

This is the design source of truth, distilled from the original ideation doc (archived at [`docs/Warriors_Art_Ideation.docx`](Warriors_Art_Ideation.docx)). Update this file when design decisions change; never let the two drift silently.

## 1. Pitch

A cinematic 2D fighting game. Every character is an original fighter built on a real Indian state's martial-arts tradition. 1v1 core, 2v2 as rival training schools. Competitive hook: **regional pride — whose state's style wins.** All characters are original ⇒ legally clean and fully ownable.

## 2. Design pillars

1. **Authentic, not derivative** — movesets, stances, and weapons come from the *real* martial art. Every ultimate is a named, technique-accurate move.
2. **Cinematic on a 2D budget** — perceived quality comes from animation density + presentation (impact FX, hit-stop, screen-shake, technique cams), not expensive hand-drawn art.
3. **Readable, fair fundamentals** — a solid fighting-game core (footsies, spacing, meter, anti-airs) before roster breadth.
4. **Regional identity** — each fighter has a distinct silhouette, stage, and percussion instrument.

## 3. Roster (v1: 6–8 finished characters)

| State | Art | Signature Weapon | Archetype / Role |
|---|---|---|---|
| Kerala | Kalaripayattu | Urumi (flexible whip-sword), dagger | Fluid acrobatic all-rounder; urumi = high-risk long-range whip |
| Tamil Nadu | Silambam | Bamboo staff, deer horns | Long-range zoner; spinning staff pokes, stance-switch counters |
| Punjab | Gatka | Sword + shield (farri), chakram | Aggressive dual-wielder; heavy sword strings, shield-block→counter |
| Manipur | Thang-Ta | Sword (thang) + spear (ta) | Technical stance-dancer; sword/spear switching rewards reads |
| Maharashtra | Mardani Khel | Patta (gauntlet-sword), vita (whip-lance) | Armored bruiser; parry-glove + whip-range special |
| Bengal | Lathi Khela | Lathi (long bamboo stick) | Scrappy high-speed rushdown; fast multi-hit, low commitment |
| Bihar | Pari-Khanda | Sword and shield | Balanced sword-and-board; shield parry→riposte |
| Varanasi | Musti Yuddha | Unarmed (strikes + grappling) | Pure brawler; close-range clinch pressure |

**Stretch:** pan-India Pehlwani / Malla-yuddha wrestler — the "big grappler" — as post-launch DLC.

**Vertical-slice character:** ship ONE character fully before designing the rest. Recommended first pick: **Bengal / Lathi Khela** (rushdown, simplest weapon, fewest stance systems) OR **Varanasi / Musti Yuddha** (unarmed — no weapon-reach edge cases). See Implementation Plan §Vertical Slice.

## 4. Core mechanics

- **Rounds:** best of 3. Health bars + special meter.
- **Movement:** walk, dash, back-dash, jump (short/full-hop), crouch.
- **Attacks:** light / medium / heavy normals × standing/crouching/jumping; command normals; specials (motion inputs); one super/ultimate per character.
- **Defense:** block (stand/crouch), pushblock (stretch), throw + throw-tech, one archetype-defining parry/counter per relevant character.
- **Meter:** builds on hit/block/whiff-recovery; spent on EX specials and the ultimate.
- **Game-feel systems:** hit-stop, hit-stun/block-stun frames, screen-shake, chip damage, juggle/gravity scaling.

Frame data is **data-driven** (resource files), never hard-coded — see [Architecture](ARCHITECTURE.md).

## 5. Game modes

1. **1v1 (core)** — polish first. Best of 3, health, meter.
2. **2v2 Team Battles (secondary)** — tag-team between rival training schools; natural regional pairings (e.g. South-India duo vs North-India duo).
3. **State Tournament Ladder (stretch)** — pick a state, climb regional leaderboards; the true state-pride loop.
4. Supporting: Local Versus, Training mode, Arcade/CPU ladder.

**Scope guard:** local multiplayer only for v1. Online play — especially rollback netcode — is the single biggest complexity risk in fighting games and is **deferred past v1**. (The core sim is written deterministically now so rollback stays *possible* later — see Architecture.)

## 6. Cinematic 2D direction

- **High-frame-count sprites** — 12–16 frames per key attack (Streets of Rage 4 / Skullgirls density), not low-frame retro.
- **Impact FX** — rim-lighting, dust + ground-impact particles, screen-shake, hit-stop on heavy hits. Cheap to add, large perceived-quality gain.
- **Region stages (4–6)** — real-location backdrops with parallax: Kerala backwaters, Punjab wheat fields at golden hour, Varanasi ghats at dusk, a Manipur hill village.
- **Technique cams** — each ultimate is a named, technique-accurate move shown in a brief slow-motion camera cut. Cinematic without full-cutscene cost.
- **Regional audio** — real percussion per fighter: chenda (Kerala), dhol (Punjab), pung (Manipur), thavil (Tamil Nadu).

## 7. Scope — medium project (v1 targets)

| Area | v1 target |
|---|---|
| Roster | 6–8 original characters; 1–2 DLC later |
| Modes | 1v1 fully polished; 2v2 secondary |
| Stages | 4–6 region-themed backdrops with parallax |
| Multiplayer | Local only; online/rollback deferred |
| Art | 2D, high-frame-count animation (not hand-drawn) |
| Audio | Regional percussion per character |
| Engine | **Godot 4.x** (chosen — see Architecture §Engine) |

## 8. Legal / IP

All characters, names, and stages are original. No film, actor, or existing game character may be referenced in final assets. Keep a short provenance note per character (which real, public-domain technique inspired each move) in the character design doc, so authenticity claims are defensible and the IP stays clean and trademarkable.
