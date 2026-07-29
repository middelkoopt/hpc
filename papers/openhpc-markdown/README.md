# papers/openhpc-markdown — Migration Ingest (Phase 1)

First-phase **info dump** for the presentation/paper on migrating the OpenHPC installation-recipe
documentation from a **Perl + LaTeX** build system to a **Python + Jinja2 / Markdown** system
(OpenHPC 4.x, then backported to 3.x). This directory collects the raw, reconstructable evidence in
one place; analysis/prose comes in a later phase.

## Status — talk delivered (2026-07-29), paper is next

The **PEARC26 OpenHPC BoF talk shipped** (Minneapolis, 2026-07-29). The **outward-facing joint deck**
(Google Slides `1OfNnrtIcrFJhKRSWiqjMiR7DNsqUKGZ6WidmrJ2n03Q`, "OpenHPC Community BoF — TM1", with
Simmons/Middelkoop/Renfro) was the one presented; **slide 8** is Tim's whole docs+CI/CD segment
(pasted into PowerPoint from that deck). The detailed **scratch/notes deck**
(`1drnnmLBdNaGi7faduPYxJx7FOX8JEEaS05cfW-dNzkU`) was working material, now superseded.

**For a future session (the eventual longer paper):** start from `story/longform.md` (full narrative
draft) + everything in `narrative/`. All figures here are git/PR-verified — reuse them, don't
re-derive. `narrative/ci-cd.md` was the last addition (CI/CD research: OpenHPC's Actions pipeline, the
QEMU-cluster integration test, Tim's placeholder markers `78865bdef`, and his Warewulf CI work in
PRs 95 and 1804). This ingest/talk phase is **done**.

## ⚠️ The transcript gap (know this before using the data)

The migration ran **Feb–May 2026**. The **agent transcripts** we intended to mine (tool calls,
messages, token usage) were **deleted by Claude Code's default 30-day retention** and are not backed
up on this machine (old working dirs `~/source/ohpc` and `~/projects/ohpc-jetstream2` are gone). The
migration is therefore reconstructed from **git history + Claude memory files**, both rich and
complete. The transcript-stats *pipeline* is built and demonstrated against two surviving (unrelated,
July) sessions, ready if off-machine backups are found. Full detail: [STATS.md](STATS.md) § 0.

## Layout

| Path | Contents |
|---|---|
| [STATS.md](STATS.md) | **Start here.** Timeline, authorship, LaTeX→Markdown volume, milestone diffs, build-system transformation, sample transcript stats. |
| `narrative/` | **Talk scraps** — the real subject (using Claude to refactor). `talk-scraps.md` (author's own words), `magnitude-and-timeline.md` (scale + PR ledger), `claude-usage-stats.md` (recovered 34-session usage table), `process-evolution.md` (compacting→handoff learning), `pr-2366-thread.md` (Adrian's review), `links.md`. |
| `git/` | Full `docs/install` (new) and `docs/recipes/install` (old) commit logs per branch (txt); `*-docs-log-since2024.json` (jq-friendly); per-branch author counts. |
| `git/patches/` | Full patches of the 5 migration milestone commits (POC, cutover, LaTeX deletions, 3.x port). |
| `memory/` | The 8 surviving Claude memory files — design decisions, 3.x backport phase log, provisioner debug notes, proxy patterns. Carry `originSessionId` breadcrumbs to the (deleted) sessions. |
| `product/old-latex/` | Old engine: `parse_doc.pl` + `common/*.pl` + a sample `.tex` recipe. |
| `product/new-markdown/` | New engine: `mkdoc.py`, `generate_manifest.py`, `generate_changelog.py`, `wraptext.py`, `Makefile`, `DESIGN.md`, sample template + recipe. |
| `transcripts/stats.jq` · `reduce.jq` | The `jq` pipeline: per-session stats + junk reduction (~81% smaller). |
| `transcripts/SCHEMA.md` | Transcript JSONL schema, where tokens/tool-calls live, what counts as junk, reduced-record schema, usage. |
| `transcripts/stats.json` · `sample/` | Stats + reduced form of the 2 surviving sessions (methodology demo). |

## Key facts (verified from git)

- **4.x**: POC 2026-02-05 (`077f4e19d`, A. Reber) → cutover 2026-02-26 (`3707edeba`) → LaTeX deleted
  2026-04-19 (`cf392c942`). Recipes: **316 `.tex` (17,871 ln) → 151 `.md.j2` (5,341 ln)**.
- **3.x**: port 2026-04-29 (`22182c33f`) → LaTeX deleted 2026-05-17 (`4688732ca`). Recipes:
  **379 `.tex` (29,653 ln) → 160 `.md.j2` (6,072 ln)**.
- Engine: **Perl (~1,190 ln) → Python (~1,460 ln)**; per-recipe Makefiles → `.conf`+`.yaml` config
  inheritance merged with `yq`.

## Reproducing / extending

- Git figures were pulled read-only from `~/projects/hpc/ohpc-3.x` (branch `3.x`) and `ohpc-4.x`
  (branch `xcat-stateless`) — no checkouts performed. Commands are inline in the extraction; re-run
  against updated refs any time.
- Transcript pipeline: see [transcripts/SCHEMA.md](transcripts/SCHEMA.md).

## Open items (for the operator)

1. **Off-machine transcript hunt** — if the Feb–May sessions or the remembered "analysis" exist on
   another machine/drive/cloud, add them to `transcripts/raw/` and re-run the pipeline.
2. **Preserve remaining history** — consider raising `cleanupPeriodDays` so future sessions aren't
   lost, and snapshotting active transcripts.
3. Decide how much LaTeX-era *content* (rendered recipes, not just source) to include for before/after
   comparison in the paper.
