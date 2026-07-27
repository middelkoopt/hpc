# Milestone timeline (slide)

All dates git/PR-verified. Two clocks worth separating: **calendar span** (~7 months) vs **active
effort** (~9.75 hours across 34 sessions).

## Major milestones

| When | Milestone | Duration |
|---|---|---|
| **Nov 2025** | Adrian's POC proves LaTeX → Markdown+Jinja2 is viable ("~300K tokens later… a direction that could work") | the spark |
| **Feb 5, 2026** | 4.x refactor branch starts — POC + LaTeX imported into `docs/install` | day 0 |
| **Feb 19–24** | Intensive refactor: design + DESIGN.md + validation → Confluent → OpenCHAMI → review-driven simplify | **~6 days** |
| **Feb 20–26** | PR #2366 review & **cutover merge** (Adrian's "too big to review" → simplify → merge) | **6-day review** |
| **Feb 26 → Apr 19** | 4.x hardening (aarch64, openEuler, dnf, OpenCHAMI) → **LaTeX deleted** | **~8 weeks** |
| **Apr 29 → May 17** | **3.x backport** — 7 phases, 12 → 28 recipes → **LaTeX deleted** | **~3 weeks** |
| **May 7 → Jun 5** | Process matured *(parallel)*: compacting → handoff → auto-loaded on session start | ~4 weeks |
| **Feb → Jun 8** | 24 PRs merged end-to-end | ~4 months |

## Span vs effort (the headline contrast)

- **Migration proper:** Feb 5 → May 17 ≈ **14 weeks** across both branches.
- **Whole arc:** Nov 2025 (POC) → Jun 2026 (backports done) ≈ **7 months**.
- **Active effort:** **34 sessions · ~9.75 hours · 44 compactions** (Claude Code's own accounting).

## Compact visual (for the slide)

```
 Nov'25      Feb'26 ─────────────────►         Apr'26        May'26        Jun'26
  POC         ▉ 6-day build + 6-day review       4.x LaTeX     3.x backport   24 PRs
  proof       └ PR #2366 cutover (merged 2/26)    deleted       (7 phases)     merged
                                                   (4/19)        12→28 recipes  (6/8)
              ├───────────── migration proper: ~14 weeks ─────────────┤
  └──────────────────────── whole arc: ~7 months ───────────────────────────┘
        active effort across it all: ~9.75 h · 34 sessions · 44 compactions
```
