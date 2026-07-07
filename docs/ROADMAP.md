# Warrior's Art — Roadmap

Timeline is expressed in **relative weeks** (from project start) plus indicative milestones. A three-person team, part-time-friendly. Adjust dates in the task board; keep this file as the high-level map.

## Milestones

| Milestone | Target | Definition of done | Status (2026-07-07) |
|---|---|---|---|
| **M0 — Foundations** | Week 2 | Repo + tooling live; everyone can run the project; research assigned. | ✅ (team clone check = issue #8) |
| **M1 — Vertical Slice** | Week 7 | One character, one stage, one fun round loop; **passed an outside playtest**. | Build ✅; playtest gate = issue #7 |
| **M2 — Content Pipeline** | Week 11 | Second character built from data + art only; training mode; audio system. | ✅ |
| **M3 — Roster Alpha** | Week 20 | 6–8 characters + 4–6 stages playable in 1v1. | Build ✅ (8 chars, 6 stages, placeholder assets) |
| **M4 — Feature-Complete v1** | Week 26 | Full front-end, 2v2, arcade ladder, polish; v1 release candidate. | In progress (select ✅, arcade ✅, pause ✅; 2v2 on hold; **focus: art & music**) |
| **M5 — Post-v1 (stretch)** | TBD | Tournament ladder, online/rollback, DLC grappler. | — |

```
Wk  1   2   3   4   5   6   7   8   9  10  11  12 ...        20        26
    |---M0--|------ M1: Vertical Slice ------|-- M2 --|--- M3: Roster ---|-- M4 --|
    setup   state machine / input / combat   pipeline   6-8 chars/stages   modes+polish
                         ^ PLAYTEST GATE                          ^ balance    ^ RC
```

## Ownership (three-person team)

Adjust names in `.github/CODEOWNERS`. Each person leads one area **and** owns a slice of the roster so character work parallelizes.

| Role | Primary area | Suggested roster ownership |
|---|---|---|
| **Dev A — Systems/Engine lead** | Core sim, state machine, input, combat, netcode readiness, CI | 2–3 characters |
| **Dev B — Gameplay/Content lead** | Character data format, moveset design, balance, training mode, modes | 2–3 characters |
| **Dev C — Art/Audio/UX lead** | Animation pipeline, VFX, stages, audio, front-end UI | 2–3 characters |

> All three own gameplay feel. The area lead is the *decision-maker + reviewer* for that area, not the only contributor.

## Research assignments (Phase 0)

Each dev deep-dives **2 states**: confirm techniques, gather reference video, draft a one-page character concept (name, personality, 3 special moves) via the `character_design` issue template.

| Dev | States (edit to taste) |
|---|---|
| A | Kerala (Kalaripayattu), Manipur (Thang-Ta) |
| B | Punjab (Gatka), Tamil Nadu (Silambam) |
| C | Bengal (Lathi Khela), Varanasi (Musti Yuddha) |

(Bihar / Maharashtra held as the 7th–8th picks; assign when the first six are scoped.)

## Cadence

- **Weekly sync** — demo latest build, review board, unblock.
- **Playtest often** — internal every week from M1; outside players at the M1 gate and before M4.
- **Balance changelog** — every character/frame-data change noted; one "balance owner" per patch.

## Scope guardrails (say no to these until their phase)

- Online / rollback netcode → **Phase 5 only.**
- Story mode / cutscenes beyond technique cams → post-v1.
- Roster beyond 8 → post-v1 DLC.
- New engine features when a data-driven solution exists → avoid.
