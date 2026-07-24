# OpenHPC LaTeX → Markdown Migration — Collected Stats

> **Scope:** first-phase info dump for the presentation/paper on migrating the OpenHPC
> installation-recipe docs from a Perl+LaTeX build system to a Python+Jinja2/Markdown system.
> All figures below are **reconstructed from git and Claude memory files** — see the provenance
> caveat first.

## 0. Data provenance & the transcript gap (read first)

The migration ran **Feb–May 2026**. The intended primary data source — the Claude Code **agent
transcripts** (tool calls, chat messages, token usage) — is **not recoverable on this machine**:

- Claude Code retention is at the default **30 days** (`cleanupPeriodDays` unset); today is 2026-07-24.
- The work happened under paths that no longer exist: `~/source/ohpc`, `~/projects/ohpc-jetstream2`
  (both deleted). Their `~/.claude/projects/` transcript dirs retain only `memory/*.md`, not `*.jsonl`.
- No Time Machine / backup / off-tree archive of those transcripts was found.
- The two surviving transcripts under `~/projects/hpc` are **July warewulf work**, not the migration.

**Consequence:** per-session detail from the raw transcripts cannot be re-derived. **However, the
aggregate usage analysis survives** — a Claude-generated summary produced while the transcripts still
existed (34 sessions, 818 prompts, 5,297 tool calls, ~16,000 messages, 9.75 h active, 44 compactions;
full table in `narrative/claude-usage-stats.md`). Plus **git history** (commits, diffs, authorship,
timeline), **8 Claude memory files**, and the **PR review threads**. The transcript-stats pipeline
(`transcripts/stats.jq`, `reduce.jq`) is built and demonstrated against the surviving July sessions,
so it is ready if off-machine transcript backups surface.

*If you locate the migration transcripts, drop them in `transcripts/raw/` and re-run the pipeline
(see `transcripts/SCHEMA.md`).*

## 1. Timeline

| Date | Branch | Commit | Milestone |
|---|---|---|---|
| 2026-02-05 | 4.x | `077f4e19d` | POC Markdown/Jinja2 doc system (Adrian Reber — leveraged pre-work) |
| 2026-02-26 | 4.x | `3707edeba` | **Cutover**: replace LaTeX recipes with Markdown/Jinja2 system (T. Middelkoop) |
| 2026-04-12 | 4.x | `ecc5d8314` | Remove poc-markdown proof of concept |
| 2026-04-19 | 4.x | `cf392c942` | **LaTeX deleted** in 4.x |
| 2026-04-29 | 3.x | `22182c33f` | **3.x port**: installation guide LaTeX → Markdown/Jinja2 (T. Middelkoop) |
| 2026-05-17 | 3.x | `4688732ca` | **LaTeX deleted** in 3.x |

- **4.x migration window:** 2026-02-05 → 2026-04-19 (~10 weeks).
- **3.x backport window:** 2026-04-29 → 2026-05-17 (~3 weeks; benefited from the 4.x system being done).

## 2. Authorship (docs/install, the new system)

| Author | 4.x `docs/install` | 3.x `docs/install` |
|---|---|---|
| Timothy Middelkoop | 14 | 9 |
| Adrian Reber | 11 | 7 |
| Vinícius Ferrão | 3 | — |
| Mike Renfro | 1 | 1 |
| Miguel Dias Costa | 1 | — |

Note: `docs/install` commit counts understate Adrian's role — the POC (`077f4e19d`) and most of the
build engine landed as squashed/rebased imports. Across all of `docs/` since 2024-07: **Adrian Reber** 75 (4.x) / 42 (3.x); **T. Middelkoop** 39 / 24.
Adrian authored the POC and build engine; Tim drove the cutover, the 3.x backport, and provisioner
recipes (Confluent/OpenCHAMI/Warewulf). Full per-commit data: `git/*-docs-log-since2024.json`.

## 3. Volume: LaTeX → Markdown

| | 4.x (before → after) | 3.x (before → after) |
|---|---|---|
| Recipe source files | 316 `.tex` → 151 `.md.j2` | 379 `.tex` → 160 `.md.j2` |
| Recipe source lines | 17,871 `.tex` → 5,341 `.md.j2` | 29,653 `.tex` → 6,072 `.md.j2` |
| Build engine | 5 `.pl` / 1,196 lines → 4 `.py` / 1,461 lines | 5 `.pl` / 1,184 → 4 `.py` / 1,485 |

The headline: **Jinja2 templating + config inheritance collapsed the per-combination LaTeX
duplication** (one `.tex` tree per distro × arch × provisioner × scheduler) into ~half the files and
roughly a third of the source lines, with build logic moving from Perl to Python.

## 4. Migration milestone diff magnitudes

| Branch | Milestone | Commit | Files | +ins | −del |
|---|---|---|---|---|---|
| 4.x | POC system | `077f4e19d` | 123 | 5,466 | 0 |
| 4.x | LaTeX→MD cutover | `3707edeba` | 208 | 11,549 | 158 |
| 4.x | delete LaTeX | `cf392c942` | 382 | 1 | 27,855 |
| 3.x | LaTeX→MD port | `22182c33f` | 256 | 16,930 | 93 |
| 3.x | delete LaTeX | `4688732ca` | 494 | 0 | 41,233 |

Full patches in `git/patches/`.

## 5. Build-system transformation

| | Old (LaTeX era) | New (Markdown era) |
|---|---|---|
| Source format | LaTeX (`.tex`) | Markdown + Jinja2 (`.md.j2`) |
| Engine | Perl (`parse_doc.pl` 361 ln + `common/*.pl`) | Python (`mkdoc.py` 469 ln + helpers) |
| Recipe extraction | Perl regex over LaTeX comments | HTML-comment markers (`<!-- ohpc_begin -->` …) parsed in Python |
| Config | per-recipe Makefiles | `.conf`+`.yaml` merged via `yq`, config inheritance base→distro→arch→provisioner→scheduler |
| Output | PDF (latex) | PDF (pandoc+xelatex), HTML (pandoc, self-contained), Markdown, `recipe.sh` |
| Orchestration | Make | Make (external tools) + pure-Python `mkdoc.py` |

Artifacts side by side in `product/old-latex/` vs `product/new-markdown/`. Design rationale in
`product/new-markdown/DESIGN.md` and `memory/MEMORY.md`.

## 6. Transcript sample (methodology demo — NOT the migration)

Two surviving July 2026 sessions under `~/projects/hpc`, processed by the jq pipeline to prove it out.
Per-session detail in `transcripts/stats.json`; reduced transcripts in `transcripts/sample/`.

| Session | Date | Topic | Tool calls | User prompts | Output tok | Cache-read tok |
|---|---|---|---|---|---|---|
| `22baa9c5…` | 2026-07-09 | warewulf IB interface PR | 8 | 8 | 14,545 | 509,463 |
| `cf4d7f62…` | 2026-07-24 | this ingest session | (live) | (live) | (live) | (live) |

Junk reduction achieved by `reduce.jq`: **~81%** size drop (156 KB → 30 KB on `22baa9c5`), keeping all
chat text + tool-call metadata + per-turn tokens, truncating tool-result bodies and thinking blocks.
