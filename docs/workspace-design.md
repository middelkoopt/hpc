# Workspace Design

## The Problem

HPC work spans multiple repos — infrastructure testing (`hpc-lab`), OpenHPC upstream
(`ohpc-3.x`, `ohpc-4.x`), and Warewulf (`warewulf`, `warewulf-node-images`). Claude Code
context doesn't survive session switches. Switching directories means starting cold, losing
the thread of cross-project work.

A secondary constraint: upstream repos (`ohpc-*`, `warewulf`) can't carry AI tooling files
(CLAUDE.md, PROCESS.md) without going through upstream review. So that context has to live
somewhere else.

## The Solution: Coordinator + Co-located Repos

`~/projects/hpc/` is a lightweight git repo that owns the cross-project context layer:

- `CLAUDE.md` — always loaded; tells Claude what each sub-repo is and how they relate
- `PROCESS.md` — session workflow; how to resume, how to hand off
- `handoff-prompt.md` — current session state; the single file that resumes any session
- `docs/` — design notes, cross-project decisions, anything that can't go upstream yet

The upstream repos live as independent git checkouts inside the coordinator directory.
Each has its own `.git/` and its own remotes. The coordinator's `.gitignore` excludes them,
so `git status` here only shows coordinator files. There are no git submodules — the repos
are just directories.

## Why Not Submodules

Git submodules pin a specific commit and create a tracking relationship. For repos where
the user is an active contributor (not a consumer), this adds friction without benefit.
The repos are co-located for Claude Code context, not for build dependency management.

## VSCode Multi-Root Workspace

`hpc.code-workspace` defines all six roots. VSCode gives each sub-repo its own Source
Control panel with independent commit/push/branch operations. Opening the workspace file
is the correct way to start a cross-project session in VSCode.

## The Coordinator Pattern

This pattern is transferable. Any project where:
- work spans multiple repos
- at least one repo can't carry AI tooling files
- continuity across sessions matters

...benefits from a thin coordinator repo with `CLAUDE.md` + `PROCESS.md` + `handoff-prompt.md`
+ `docs/`. The coordinator itself is cheap to create and maintain.

## Repo Origins

- `hpc-lab` — split from `ohpc-jetstream2/tm-dev` (May 2026); `ohpc-jetstream2` retained
  on GitHub as historical reference (main branch only)
- `ohpc-3.x` — OpenHPC 3.x; primary work was latex→markdown documentation port
- `ohpc-4.x` — OpenHPC 4.x; primary active upstream contribution target
- `warewulf` — user is an active Warewulf developer/contributor
- `warewulf-node-images` — Warewulf node image definitions, companion to warewulf
