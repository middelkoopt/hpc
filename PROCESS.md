# Process

How this workspace is used across sessions. Read when resuming after a gap or starting
a cross-project task.

---

## Session Start

Just open the project — the SessionStart hook reads `handoff-prompt.md`, `docs/index.md`,
`hpc-lab/CLAUDE.md`, and `hpc-lab/docs/index.md` automatically, then pauses and asks for
new context before doing anything.

No "continue with handoff-prompt.md" needed. If the hook doesn't fire, say something
task-oriented and it will follow the session-start directive.

---

## Three Working Modes

### Mode A — OpenHPC docs/design

Primary workspace: `ohpc-4.x/docs/install/` (or `ohpc-3.x/docs/install/` for 3.x work).

- Key entry point: `DESIGN.md` in the install dir
- Build: `make` in `ohpc-4.x/docs/install/` (requires `yq`, Python deps in `.venv`)
- All design decisions → commit to the upstream repo on a personal branch, then PR
- Design notes that can't go upstream yet → `docs/` in this coordinator

### Mode B — Infrastructure / recipe testing

Primary workspace: `hpc-lab/`

- Full context: read `hpc-lab/CLAUDE.md` and `hpc-lab/PROCESS.md`
- Resume state: `hpc-lab/handoff-prompt.md`
- Rule: only fix the one `tests/` script matching the current run

### Mode C — Warewulf contribution

Primary workspace: `warewulf/` (and `warewulf-node-images/` as needed).

- Personal fork remote: `middelkoopt`
- Upstream remote: `warewulf`
- Work on personal branches; open PRs upstream

---

## Session Wrap

1. Update `handoff-prompt.md` in this coordinator (cross-cutting state)
2. Update `hpc-lab/handoff-prompt.md` if infrastructure work was done
3. Commit new/updated `docs/` files before closing
4. Commit any coordinator file changes (`CLAUDE.md`, `PROCESS.md`, `handoff-prompt.md`)

---

## Knowledge Structure

```
CLAUDE.md           — always in context; sub-repo index, key rules, mode guide
PROCESS.md          — this file; read once when resuming
handoff-prompt.md   — cross-cutting session state; updated each session
docs/               — design docs, cross-project notes, things that can't go upstream yet
hpc-lab/CLAUDE.md   — full infrastructure project context (always loaded in Mode B)
```

The rule: `docs/` is the source of truth. Machine-local memory (`~/.claude/.../MEMORY.md`)
holds only active session state and pointers. Commit regularly.
