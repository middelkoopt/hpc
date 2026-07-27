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

## Stage 1 — Compacting era (Feb 2026)

Design-heavy refactoring. Per the usage stats: **44 compactions across 5 sessions, concentrated in
the design phase.** Context was held in the live window and repeatedly compacted; losing state to
compaction was the pain that drove everything after.

## Stage 1.5 — Durable context = committed `docs/`, and fresh sessions (from ~Feb 23)

The move off pure compacting was **not** a handoff file — it was **committing knowledge to a `docs/`
tree and starting fresh sessions** that read it back. Operator's recollection, evidence-confirmed in
the **hpc-lab** repo:

- The `docs/` reference tree begins **2026-02-23/24** (`openchami-reference.md`, `configuration.md`) —
  the same moment LLM work starts (`5744d3d` "Add LLM code support", 2026-02-24) — and keeps
  accumulating through Mar–Apr (infiniband, chameleoncloud, cloudlab, confluent, proxy).
- The **first CLAUDE.md (Feb 24) did *not* index the docs** — it was project rules only. So early on
  the durable store was the committed `docs/` themselves; a fresh session simply read them.
- On the OpenHPC side the same instinct produced **`DESIGN.md`** — a 738-line pure design-rationale
  doc (recovered commit `a2596ef37`, 2026-02-19), which Adrian leaned on throughout the PR review.
  The ohpc repos **never** had a handoff file.

So the Feb pattern was: **write it into `docs/` (or `DESIGN.md`) → start a fresh session → read it →
continue.** "Docs are the source of truth" in its earliest, *implicit* form — months before the
ritual was named.

**What May 7 actually added (Stage 2) was two things on top of the docs, not a replacement for them:**
a **"## Key Docs" index** in the rewritten CLAUDE.md (a session-entry pointer into `docs/`), and a
`handoff-prompt.md` for the thin *active-state* layer ("what am I doing right now") that a static doc
tree doesn't hold. The docs stayed the source of truth; the handoff was the ephemeral top layer.

**Verified corrections:** `CLAUDE.md` never carried the handoff (zero handoff/session language across
its history); the machine-local `~/.claude/.../memory/MEMORY.md` also held a "## Current State"
(stamps 2026-02-22 → 04-27) but was a secondary/scratch store, later demoted by PROCESS.md.

### DESIGN.md churn signature (the evidence)

Pre-squash authoring (recovered via GitHub force-push tips):

| Date | Change | Note |
|---|---|---|
| Feb 5 | **+421 / −0** | created **day 0** with the POC import |
| Feb 19 | +146 / −79 | the intensive design push — real deletions = rethinking |
| Feb 19 | +58 / −12 | reformat + cleanup |
| Feb 22 | +14 / −0 | Confluent |
| Feb 24 | +25 / −36 | tracks the pandoc→Makefile / venv-removal review changes |
| Feb 24 | +5 / −5 | rename sections→templates |

≈537 lines at cutover. Committed after: Feb 26 squash **+551**, Mar 3 **+181/−0** (proxy/reset
markers), Jul **+17/−11** & **+4/−4** (xcat). **Final 738 lines; only −15 deleted across its whole
committed life.** Signature: **front-loaded → churned during design → append-only after** — the
fingerprint of a durable design artifact, the inverse of handoff-prompt.md's net-zero
churn-every-session.

**What the content proves** (read of the saved DESIGN.md; snapshot at
`product/new-markdown/DESIGN.md.at-cutover-2026-02-26.md`):

- **Goal #1, verbatim, on day 0:** *"Make documentation easier to edit and contribute to."* The
  contribution thesis was the *stated design goal* from Feb 5 — not a retro-narrative.
- **It absorbed debugging findings.** DESIGN.md carries a subsection titled **"Usage rules (learned
  from debugging)"** — macro gotchas (tilde doesn't expand in double-quoted shell; single-quote echo
  for runtime `${var}`; sed regex quoting). So debug knowledge flowed *back into the design doc* —
  textual proof DESIGN.md was **living durable context during debugging**, not just a design-phase
  artifact.
- **The clever core it documents:** one Markdown source → both rendered PDF/HTML *and* an extracted
  runnable `recipe.sh` (HTML-comment markers `ohpc_begin/command/if_set/fi`, invisible in output) —
  the clean-substrate successor to the old `parse_doc.pl` LaTeX-parses-shell trick — plus the
  `compute_*` macro abstraction (Warewulf-chroot / Confluent-nodeshell / OpenCHAMI-yq / xCAT-chroot)
  that is the actual mechanism behind the ~95% de-duplication.

### Debugging phase — the debug-state docs (the pattern's clearest form)

Debugging leaned on durable docs even harder, in two layers:

- **Machine-local debug-state docs** — `confluent-debug.md` ("## STATUS: Cluster fully validated ✓
  (2026-02-22)" + "All Fixes Applied") and `openchami-debug.md` ("## STATUS: SSH + Slurm WORKING
  (2026-02-23) — 3 more template fixes needed"). Each is **STATUS line + fixes-applied + what's-left**
  — a *debug handoff*, months before handoff-prompt.md named the pattern.
- **Committed gotcha/reference docs** in hpc-lab `docs/` — infiniband (Mar 8), chameleoncloud
  (Mar 9), cloudlab (Mar 15), confluent (Mar 18), proxy (Apr 5), then the May 7 batch (openeuler,
  warewulf-bios-dhcp-bug, ipxe-images…) — the distilled, permanent form of hard-won debugging facts.

Across phases the *kind* of durable doc tracks the work: **design → DESIGN.md; debugging →
debug-state + gotcha docs.** The debug docs' STATUS+pending convention is exactly what
handoff-prompt.md later generalized into a per-session ritual.

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

Arc in one line: **compact → machine-local MEMORY.md → committed handoff → level → automate.** The doc refactor was the crucible;
the workflow was the byproduct — and arguably the more transferable result.
