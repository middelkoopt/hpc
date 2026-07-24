# Links & References

## Pull requests (openhpc/ohpc)

- **#2366 — New Markdown Docs** (the cutover): https://github.com/openhpc/ohpc/pull/2366
  Created 2026-02-20, merged 2026-02-26. +11,549/−158, 208 files, 32 comments, 2 reviews.
  Full thread captured in `pr-2366-thread.md` (raw JSON: `pr-2366-raw.json`).
- **#2505 — Port Markdown to 3.x** (the backport): https://github.com/openhpc/ohpc/pull/2505 (merged 2026-04-29)
- Full merged-PR ledger Feb–Jun 2026 in `magnitude-and-timeline.md`.
- Pending: the **539-file** LaTeX/Perl tree removal (not yet in a merged commit as of the author's note).

## Source trees

- New 4.x markdown system: https://github.com/openhpc/ohpc/tree/4.x/docs/install
- Author's refactor branch (historical): https://github.com/middelkoopt/ohpc/tree/tm-refactor-md
- 3.x backport branch (local): `ohpc-3.x` — worked on `tm-markdown-3.x` / `tm-openeuler-openpbs-3.x`

## Key commits

| Ref | Date | What |
|---|---|---|
| `077f4e19d` (4.x) | 2026-02-05 | Adrian's POC markdown system |
| `3707edeba` (4.x) | 2026-02-26 | LaTeX→MD cutover (= PR #2366) |
| `cf392c942` (4.x) | 2026-04-19 | LaTeX deleted (4.x) |
| `22182c33f` (3.x) | 2026-04-29 | 3.x port |
| `4688732ca` (3.x) | 2026-05-17 | LaTeX deleted (3.x) |

## People

- **Timothy Middelkoop** (@middelkoopt) — the refactor.
- **Adrian Reber** (@adrianreber) — POC that started it; huge PR review; prefers the technical work.
- **Mike** — the inspiration.

## Local artifacts (this repo)

- `../STATS.md` — consolidated stats. `../git/` — logs + patches. `../memory/` — surviving memory files.
- `../product/` — old Perl/LaTeX vs new Python/Jinja2 engines. `../transcripts/` — jq pipeline + sample.
