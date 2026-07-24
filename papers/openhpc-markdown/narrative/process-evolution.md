# Process Evolution — compacting → handoff (what the hpc-lab git log reveals)

The talk's central process lesson, reconstructed from the **`hpc-lab` git history** (the test-rig,
359 commits, all Tim, 2024-02 → 2026-06) and the **coordinator** repo (`~/projects/hpc`, 22 commits,
2026-05 → 2026-06). The dates line up with the doc migration and tell a clean five-stage arc.

## The ignition point

- **2026-02-24** `hpc-lab 5744d3d "Add LLM code support"` — first explicit LLM involvement, two days
  before the 4.x Markdown cutover PR #2366 merged (2026-02-26). LLM-assisted work and the doc
  migration start together.
- Commit cadence then spikes in exactly the LLM-coding weeks: **W09 (13), W10 (9), W11 (23)** in
  March, **W18 (15), W19 (29)** in May — the "coding with Claude between naps" bursts.

## Stage 1 — Compacting era (Feb–Apr 2026)

Design-heavy refactoring. Per the usage stats: **44 compactions across 5 sessions, concentrated in
the design phase.** Context was held in the live window and repeatedly compacted; losing state to
compaction was the pain that drove everything after.

## Stage 2 — Handoff invented (2026-05-07, a single day)

Four commits in `hpc-lab`, one afternoon:

- `72ff884` Docs overhaul, **CLAUDE.md rewrite**
- `d193c44` **Add PROCESS.md and handoff-prompt.md session management files** ← the birth
- `d36e4e0` **Clean up handoff-prompt.md for session close** ← first deliberate session-close ritual
- `5d17161` … **session process improvements**

`PROCESS.md` codified the load-bearing rule: *"docs/ is the source of truth. Machine-local memory
(MEMORY.md) is only pointers + active state. Loss of the machine = loss of MEMORY.md; acceptable if
you commit regularly."* The handoff file even lists its own creation as a completed to-do.

## Stage 3 — Coordinator + memory migration (2026-05-08)

The single project became a multi-repo workspace, and machine-local memory moved into git:

- `hpc-lab 03474e4` **Rename project to hpc-lab**; `3749ec0` **End of session reflection updates**
- coordinator `16dcf68` Build base coordination structure → `9fb9aa2` **First coordinator session:
  migrate ohpc memory, fix stale docs**. The coordinator was born (2026-05-07/08) exactly as the doc
  migration finished (3.x LaTeX deleted 2026-05-17).

## Stage 4 — Maturation: slim the handoff, level the knowledge (2026-06-01)

- coordinator `26bd797` **"slim handoff-prompt; move durable reference to CLAUDE.md and docs/"** —
  handoff-prompt.md cut **−55/+17 lines** in one commit. The realization: handoff = *present state
  only*; durable knowledge belongs in CLAUDE.md / docs/, each fact at its most-specific home.

## Stage 5 — Automation: the handoff becomes a system (2026-06-05)

A six-commit burst turns discipline into tooling:

- `de870da` **`autoMemoryEnabled: false`** + deleted 5 stale memory files ("content was redundant with
  always-loaded CLAUDE.md/docs/") — a decisive move *away* from opaque auto-memory toward
  git-committed, right-leveled, always-loaded docs.
- `00e587d` **add SessionStart hook for automatic context loading**; `516c6bf` always load
  hpc-lab/CLAUDE.md; `9fa28ba` add docs/index.md to session-start reads; `ec08c48` update
  session-start docs. Plus doc `index.md` files as navigation.

The end state (visible in this very session): a SessionStart hook auto-reads the handoff + doc indexes
and forces a "pause and ask for new context before investigating" step — the handoff ritual, automated.

## Churn vs append-only (what co-changed in the window)

The 2026-05-07 handoff birth was not isolated — it rode a **docs consolidation push** the same day
(`72ff884`): CLAUDE.md rewritten (+78) and **7 new `docs/` files created at once** (confluent-upstream,
ipxe-images, openeuler, recipe-testing, warewulf-ansible-vars, warewulf-bios-dhcp-bug,
warewulf-image-tests). So "docs/ is source of truth" was *enacted*, not just declared.

Lifetime churn of the session-management files (`+added / −deleted / final lines`):

| File | Commits | +added | −deleted | Final | Character |
|---|---|---|---|---|---|
| `handoff-prompt.md` | 5 | 135 | 135 | **0** | **fully churned, then deleted** — ephemeral by design |
| `CLAUDE.md` | 10 | 155 | 41 | 114 | **moderately churned** — periodically rewritten as rules matured |
| `PROCESS.md` | 5 | 132 | 8 | 124 | **near append-only** — written once (117 ln), stable after |

(`Developer.md` is Tim's personal scratch file — excluded from process analysis.)

The key delta: at the coordinator move (`37a6319` "Cleanup repo after move") the sub-repo's
`handoff-prompt.md` was **deleted entirely** (−115) — the handoff role migrated *up* to the coordinator
repo. That's why hpc-lab's handoff shows net-0 lines today: it churned every session, then graduated.

**Answer to "append-only or churned":** both, by design — and the system routes volatility to the
right file. Ephemeral now-state (`handoff`) is rewritten wholesale each session; rules (`CLAUDE.md`)
churn slowly; reference (`PROCESS.md`, `docs/*`) is largely append-only; scratch (`Developer.md`)
churns constantly. The same volatility-leveling the docs migration applied to *content* got applied to
*process files*.

## The through-line (deferred — planning phase)

The migration didn't just convert docs; it **forced a personal methodology into existence**. Each
process artifact is a scar from a specific pain:

1. **Compaction lost context** → the **handoff file** (explicit, committed state).
2. **Machine-local memory was fragile / redundant** → **"docs/ is source of truth"** + auto-memory
   OFF. (This project's own transcript loss is the same lesson: the committed `MEMORY.md` files
   survived; the un-committed transcripts didn't.)
3. **Reload cost at every session start** → the **SessionStart hook**.
4. **Knowledge dumped in the nearest file rotted** → **level each fact** (handoff = now, CLAUDE.md =
   rules, docs/ = reference).

Arc in one line: **compact → handoff → commit → level → automate.** The doc refactor was the crucible;
the workflow was the byproduct — and arguably the more transferable result.
