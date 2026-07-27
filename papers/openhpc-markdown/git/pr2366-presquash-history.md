# Recovered: pre-squash commit history of PR #2366

PR #2366 was **squash-merged** on 2026-02-26 into a single commit (`3707edeba` on the branch;
`3d5fb9ed5` as GitHub records it), so the step-by-step history is not on any branch. It was also
**gc'd locally** (reflog only reaches 2026-05-08; no matching dangling objects) and the fork branch
`tm-refactor-md` was **deleted** after merge.

**Recovered anyway** from GitHub's retained force-push records: the PR timeline
(`repos/openhpc/ohpc/issues/2366/timeline`) still lists 9 `head_ref_force_pushed` events, each with the
branch tip SHA *before* that push. Those commit objects are still served by the GitHub API
(`repos/openhpc/ohpc/commits/<sha>`) even though `git fetch <sha>` is refused. Walking each tip's
first-parent ancestry and unioning gives the history below. (Recovered 2026-07-27.)

## The logical step-by-step (~10 commits)

Deduplicated by content — this is the actual sequence of the 4.x refactor:

| # | Date | Step |
|---|---|---|
| 1 | 2026-02-05 | **Refactor poc-markdown and tex recipes into docs/install** (the import — build on Adrian's POC) |
| 2 | 2026-02-19 | Reorganization and refactor chapters |
| 3 | 2026-02-19 | Reformat text and cleanup **DESIGN.md** |
| 4 | 2026-02-19 | Rework **script validation** code |
| 5 | 2026-02-21→22 | **Confluent** updates, formatting, and build fixes |
| 6 | 2026-02-23 | **OpenCHAMI** fixes |
| 7 | 2026-02-24 | **Move pandoc into Makefile and remove .venv** ← direct response to Adrian's review |
| 8 | 2026-02-24 | **Refactor chapters: out of recipes into main.md.j2** ← the de-duplication |
| 9 | 2026-02-24 | **Rename sections to templates** ← matches the PR-thread comment |
| 10 | 2026-02-24 | Various fixes from testing |

Branch base: `d978eadd8` (rejoins known 4.x history).

## The churn (why it was squashed)

The same ~10 logical commits appear under **37 distinct SHAs** across the 9 force-pushes — each step
was rebased/reworded 3–4 times during the Feb 19–26 review. This is precisely the "30 or so large-ish
commits… way too much churn to follow" Tim described in the PR thread, and the reason Adrian said
"Now squash it."

| Logical commit | # of SHA variants (rebases) |
|---|---|
| Refactor poc-markdown and tex recipes into docs/install | 4 |
| Reorganization and refactor chapters | 4 |
| Reformat text and cleanup DESIGN.md | 5 |
| Rework script validation code | 5 |
| Confluent updates/fixes, formatting, and build fixes | 6 |
| OpenCHAMI fixes | 3 |
| Move pandoc into Makefile and remove .venv | 2 |
| Refactor chapters: out of recipes into main.md.j2 | 2 |
| Rename sections to templates | 2 |
| Various fixes from testing | 3 |

## What this shows (for the talk)

The recovered order *is* the method: **structure first** (import → reorganize chapters → DESIGN.md →
validation, Feb 5–19), **then provisioner-by-provisioner** (Confluent Feb 21–22, OpenCHAMI Feb 23),
**then review-driven simplification** (pandoc→Makefile, drop the venv, de-duplicate chapters, rename
sections, Feb 24). Design → breadth → simplify. The squash hid this; it's worth showing.

## Provenance / re-recovery

Force-push "before" SHAs (from the PR timeline): `7ec6c8e22 cfd2d9138 ad4d1805c 8f58d552b ae19af338
d932436d2 6788b6633 81fcf2fdc 83a7e01df`. Each is fetchable only via the API by SHA. These objects may
be gc'd by GitHub eventually — if per-commit **diffs** are wanted for the paper, pull them soon via
`gh api repos/openhpc/ohpc/commits/<sha>`.
