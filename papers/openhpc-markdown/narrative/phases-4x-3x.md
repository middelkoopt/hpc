# High-level phase view: 4.x vs 3.x

Data-organized scrap (not a synthesis — planning phase). Two branches, two very different modes of
work. Verified from git + `../memory/project_3x_backport.md`.

## 4.x — greenfield refactor (born from Adrian's POC)

| Phase | When | Evidence | What happened |
|---|---|---|---|
| POC (pre-work) | 2026-02-05 | `077f4e19d` (Adrian), 123 files +5,466 | Proof it's possible; Warewulf + Confluent ported to Markdown/Jinja2 |
| Design + tooling | Feb | (design-heavy; 44 compactions here) | Built `mkdoc.py` (killed the jinja-cli dependency), new dir structure, provisioner macros |
| **Cutover** | 2026-02-20→26 | **PR #2366 / `3707edeba`**, 208 files +11,549/−158 | All recipes ported, ~95% duplication merged, new layout; old LaTeX left in place; merged after Adrian's 32-comment review |
| Hardening | Mar–Apr | #2416 Confluent aarch64, #2418 OpenCHAMI aarch64, #2421 dnf, #2433 openEuler, #2482 OpenCHAMI upgrade | Breadth + real-cluster testing on Jetstream2 |
| LaTeX removal | 2026-04-19 | `cf392c942`, −27,855 | Old Perl/LaTeX tree deleted |

**4.x targets (16 recipes):** rocky10, almalinux10, openeuler24.03 × {x86_64, aarch64} ×
{warewulf, confluent, openchami} + xcat_stateless; **slurm only**.

## 3.x — disciplined phased backport (7 phases)

| Phase | Evidence | Recipes |
|---|---|---|
| Start / port | 2026-04-29 `22182c33f` / PR #2505, 256 files +16,930/−93 | — |
| P1 verbatim copy of 4.x `docs/install` | project log | — |
| P2 EL9 core adaptation | build-clean | 12 |
| P3+4 OpenPBS + Warewulf3 | (paired only in 3.x) | 20 |
| P5 Leap 15 | new distro | 24 |
| P6 RPM spec (LaTeX deps removed, yq/jinja2 added) | docs.spec | 24 |
| P7 openEuler warewulf3 | | 28 |
| LaTeX removal | 2026-05-17 `4688732ca`, −41,233 | 28 |

**3.x targets (28 recipes):** rocky9, almalinux9, leap15, openeuler22.03 × {x86_64, aarch64} ×
{warewulf(v4), **warewulf3**, confluent, openchami} × {slurm, **openpbs**}.

## The contrast (facts, take deferred)

| Axis | 4.x | 3.x |
|---|---|---|
| Mode | Greenfield refactor from POC | Backport of a finished system |
| Era / stack | EL10, modern provisioners | EL9 + **legacy** (warewulf3, openpbs, leap15) |
| Recipes | 16 (slurm only) | 28 (adds openpbs; broader matrix) |
| Process | Design-heavy, exploratory, "messy first passes," heavy compaction | Phased, incremental commits, per-phase review |
| Enabled by | — | The 4.x system (copy-verbatim-then-adapt) **and** the handoff workflow, which was born 2026-05-07, *mid-backport* |
| LaTeX removed | −27,855 lines | −41,233 lines |

Two orderings worth noting for the talk: (a) 4.x **built** the system, 3.x **scaled** it to the older
+ wider support matrix; (b) the process discipline (handoff, phases) appears in the *3.x* record, not
the 4.x record — the methodology matured on the second pass.
