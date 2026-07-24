# Talk Scraps — "Refactoring OpenHPC docs with Claude"

Raw material for a **10-minute talk** (paper may be longer). The real subject is **using Claude for
refactoring** — how it worked at a high level and what was learned. Not polished; a scrapbook so we
don't have to re-discover these later. Author's own words preserved; lightly ordered, not verbatim.

## The one-line pitch

Converted **15 years of LaTeX + Perl (that parses shell scripts too) + gargantuan Makefiles built
with symlink hell, all files in one directory with random names** → **Markdown + Jinja2 + Python**,
where you can find things and don't have to type `../../../../common/parse_doc.pl` 😉.
**Now people can actually contribute to the docs.**

## Why (the motivation)

- The docs were near-impossible for someone to just go in and make a simple change.
- Goal: **facilitate the community to participate in writing the docs.** Adrian (the other person on
  it) would rather work on the technical stuff.
- Started it in "brain-dead, want-to-do-something-else" time last week (had a cold, coding between
  naps) — first time using Claude on a *larger* project.
- Adrian migrated it to Markdown as a **POC**; this work refactors it to shed 15 years of tech debt.

## What changed (high level)

- Layout/structure completely reworked — hopefully makes more sense, easier to find things and contribute.
- **Re-merged ~95% of the duplicated files**; all recipes now follow the same basic flow.
- New **Jinja2 macros** for installing packages / updating configs on compute nodes across the three
  provisioner models: Warewulf (containers/chroots), Confluent (running nodes), OpenCHAMI (yaml).
- Flatter directory structure. A `build.py`/`mkdoc.py` that generates a recipe from a YAML file
  (**no jinja-cli needed** — the lack of an easy install of that is literally what started the whole
  thing). Manifests generated from the repos. Only **jinja2 + pyyaml** as Python deps.
- Deep tooling refactor, not just content. For the most part the recipes (`.md` and `.sh`) render the same.
- Honest self-assessment: "Claude did a good first pass on the refactoring… it got messy at times, I
  had to clean up after it. Claude did a *horrible* first pass on Confluent." Human time went into
  layout decisions, porting Confluent properly, and building validation tools.

## The LLM-practice takeaways (the heart of the talk)

- Using an LLM effectively **is a skill** — and doesn't look like it's changing any time soon.
- Biggest takeaways:
  - **Good design** up front. (Spent the first couple days on design — that's where all the
    compacting happened. After that it was just refactoring + refinement.)
  - **Good documentation.**
  - **Tools for validation and verification.**
  - **Managing context/attention is critical** — including managing the context-window/compaction
    process and internal-memory/state files.
  - Knowing **when (and when not) to watch the "thinking" process.**
- Process evolution: **from constant compacting → to a `handoff.txt` / handoff-prompt workflow.**
  (See `process-evolution.md` — the hpc-lab handoff/PROCESS pattern, born 2026-05-07.)
- **44 compactions across 5 sessions**, concentrated in the design phase.
- Meta-point for the RCD/research audience: coding with LLMs is a game-changer and **will have impact
  on research** as well.

## Credit / collaboration

- **Adrian Reber** kicked it all off with a POC proving LaTeX→Markdown+Jinja2 was possible, and ported
  Warewulf + Confluent. "This showed the way for Claude to help out a lot — I would not have had the
  time to do it otherwise." Adrian also did a **huge PR review** (see `pr-2366-thread.md`).
- **Mike** — the inspiration ("LaTeX is no more!").
- Adrian, on his own POC (Nov 21, 2025): *"As we talked about going from latex to markdown plus
  jinja2, I let claude run for some time and around 300K tokens later I have a new version of the
  OpenHPC pdf. Still a bit rough around the edges, but generally it seems to be a direction that could
  work."*

## Loose ends / notes for later

- The merged PR does **not** include the **539 files** slated for deletion in an upcoming commit
  (the old LaTeX/Perl tree removal).
- Talk framing note: two phases — **4.x first**, then **3.x backport**. See `../STATS.md` §1 and the
  phase comparison.
