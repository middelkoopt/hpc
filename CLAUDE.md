# hpc — Workspace Coordinator

Personal workspace for HPC infrastructure, OpenHPC development, and Warewulf contribution.
All active repos live as independent git checkouts inside this directory.

## Sub-Repos

| Directory | Purpose | Upstream |
|---|---|---|
| `hpc-lab/` | Infrastructure test-rig: OpenHPC recipe validation on qemu/Jetstream2/CHI@TACC | github.com/middelkoopt/hpc-lab |
| `ohpc-3.x/` | OpenHPC 3.x — docs, components, recipe development | github.com/openhpc/ohpc (3.x branch) |
| `ohpc-4.x/` | OpenHPC 4.x — primary active upstream contribution | github.com/openhpc/ohpc (main) |
| `warewulf/` | Warewulf provisioner — upstream contribution | github.com/warewulf/warewulf |
| `warewulf-node-images/` | Warewulf node image definitions | github.com/warewulf/warewulf-node-images |

Each sub-repo has its own `.git/` and independent remotes. The coordinator `.gitignore`
excludes them so `git status` here only shows coordinator files.

## Key Rules

Never commit directly to upstream tracking branches in `ohpc-3.x/`, `ohpc-4.x/`,
`warewulf/`, or `warewulf-node-images/` without going through the upstream review process.
Work on personal branches and submit PRs.

Never run `git checkout` in a sub-repo without explicit confirmation — it changes branch/HEAD
state that persists across sessions. To read a file at a tag or commit, use
`git show <ref>:<path>` (e.g. `git show v4.7.0:warewulf.spec.in`).

## Context by Mode

**Infrastructure / recipe testing** → work inside `hpc-lab/`; read `hpc-lab/CLAUDE.md`
and `hpc-lab/PROCESS.md` for full context. Resume with `hpc-lab/handoff-prompt.md`.

**OpenHPC docs / design** → active work in `ohpc-3.x/docs/install/` (3.x branch).
`ohpc-4.x/docs/install/` is the 4.x counterpart. Key design doc: `DESIGN.md` in whichever
branch is active. The markdown doc system uses `mkdoc.py` + Makefile.

**Warewulf contribution** → work inside `warewulf/` and `warewulf-node-images/`.
User is an active Warewulf developer; the `middelkoopt` remote is the personal fork.

## Key Docs

- `docs/workspace-design.md` — why this structure exists, the coordinator pattern
- `docs/ohpc-docs-system.md` — mkdoc.py architecture, build commands, key patterns, conventions
- `docs/ohpc-3x-status.md` — 3.x branch status, recipe matrix, key decisions
- `hpc-lab/CLAUDE.md` — full infrastructure project context
- `hpc-lab/docs/` — infrastructure reference docs (proxy, warewulf bugs, cloud setup, etc.)
- `ohpc-3.x/docs/install/DESIGN.md` — OpenHPC markdown docs system design (active branch)
- `ohpc-4.x/docs/install/DESIGN.md` — same system, 4.x branch

## RPM Spec Authoring Rules

**Never place `## OHPC:` comments inside a `make ... \` continuation block.**
Bash treats `#` after whitespace as a comment, silently terminating the joined line — all
arguments after the comment are dropped and `make` never sees them. Place OHPC comments on
their own line immediately before the `make` invocation.

## Pending

- Docs placement and content migration strategy between `ohpc-3.x` and `ohpc-4.x`
