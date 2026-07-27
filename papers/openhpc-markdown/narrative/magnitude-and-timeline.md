# Magnitude & Timeline — what was accomplished

Stats to convey the scale of the work for the talk. All git/GitHub-verified (2026-07-24).

## Headline numbers

| | |
|---|---|
| Source converted | **LaTeX + Perl + Makefiles → Markdown + Jinja2 + Python** |
| Recipe source (4.x) | **316 `.tex` files → 136 `.md.j2` templates** at cutover (151 today, +xCAT); 17,871 → 5,341 ln |
| Recipe source (3.x) | 379 `.tex` files (29,653 ln) → **160 `.md.j2` (6,072 ln)** |
| De-duplication | 316 real `.tex` (284 distinct — near-duplicate variants, some stale/older) collapsed into 136 shared templates via macros + config inheritance |
| Build engine | 5 Perl scripts (~1,190 ln) → 4 Python (~1,460 ln), `mkdoc.py` core |
| Python deps | reduced to **jinja2 + pyyaml only** (no jinja-cli) |
| Working recipes | **44 total** (16 in 4.x + 28 in 3.x) |
| Merged PRs (Feb–Jun 2026) | **24** |
| LaTeX tree deleted | 4.x −27,855 ln, 3.x −41,233 ln (**539 files** in the pending removal) |
| Claude effort | 34 sessions · 5,297 tool calls · **9.75 h active** · 44 compactions (see `claude-usage-stats.md`) |

## Timeline (merged PRs — the accomplishment ledger)

Migration proper is **~3 weeks of design+cutover (Feb)**, then **~3 months of hardening, new targets,
and the 3.x backport**.

| Date | PR | What |
|---|---|---|
| 2026-02-05 | #2352/#2353/#2355 | Warewulf v4.6.5 upgrade + Markdown docs (pre-migration groundwork) |
| **2026-02-20→26** | **#2366** | **New Markdown Docs — the cutover** (+11,549/−158, 208 files, 32 comments, Adrian's big review) |
| 2026-02-27 | #2371 | Report line number by section (tooling: validation) |
| 2026-03-03 | #2380 | Proxy + node-reset placeholder markers |
| 2026-03-06 | #2391 | nfs-server package install |
| 2026-03-08 | #2396 | Test infrastructure updates |
| 2026-03-19 | #2416 | **Confluent aarch64** support |
| 2026-03-20 | #2418 | **OpenCHAMI aarch64** support |
| 2026-03-23 | #2421 | Default to dnf over yum |
| 2026-03-25 | #2433 | **openEuler** support fixes |
| 2026-04-26 | #2482 | Upgrade OpenCHAMI |
| **2026-04-29** | **#2505** | **Port Markdown to 3.x** (the backport begins) |
| 2026-04-30 | #2512 | Confluent → latest Rocky 9 |
| 2026-05-01 | #2513/#2519 | OpenCHAMI 3.x fixes; single-node OpenPBS |
| 2026-05-08 | #2557 | openEuler Warewulf3 + SP4/COPR |
| 2026-05-11 | #2561/#2562 | **OpenPBS** fixes; **Leap15** fixes |
| 2026-05-14 | #2572 | Warewulf3 VNFS assembly |
| 2026-05-19→23 | #2586/#2592 | Warewulf 4.7.0 |
| 2026-06-08 | #2597 | Backport Confluent/OpenCHAMI/openEuler fixes 3.x→4.x |

(Commit-level detail: `../git/*-docs-log-since2024.json`. LaTeX deletions: 4.x `cf392c942` 2026-04-19,
3.x `4688732ca` 2026-05-17.)

## Targets / matrix (the breadth of "new targets")

**4.x — 16 recipes.** Distros: rocky10, almalinux10, openeuler24.03. Arch: x86_64, aarch64.
Provisioners: warewulf, confluent, openchami, **xcat_stateless** (new). Scheduler: slurm.

**3.x — 28 recipes.** Distros: rocky9, almalinux9, **leap15**, **openeuler22.03**. Arch: x86_64,
aarch64. Provisioners: warewulf (v4), **warewulf3** (new), confluent, openchami. Schedulers: slurm,
**openpbs** (new).

The 3.x backport was **7 phases**: verbatim copy → EL9 core (12 recipes) → OpenPBS+Warewulf3 (20) →
Leap15 (24) → RPM spec → openEuler warewulf3 (28) + manifests (see `../memory/project_3x_backport.md`).

## Reorganization / refactor (the "shape" change)

- Flat, findable layout replaced **symlink hell + one directory of randomly-named files**.
- `../../../../common/parse_doc.pl` → a single `mkdoc.py` driven by a per-recipe YAML.
- Config inheritance base → distro → arch → provisioner → scheduler (no per-recipe Makefiles).
- New Jinja2 macros abstract the three provisioner models (Warewulf chroots / Confluent live nodes /
  OpenCHAMI yaml) behind one recipe flow.
- Outputs from one source: Markdown, PDF (pandoc+xelatex), self-contained HTML, and `recipe.sh`.
