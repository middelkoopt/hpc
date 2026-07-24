# The end-state: handoff, automated (SessionStart hook)

The final stage of the compacting→handoff arc (see `process-evolution.md` §5). By 2026-06-05 the
handoff ritual was no longer manual — a **SessionStart hook** (`00e587d`) auto-loads context and
*forces* the "pause and ask before investigating" discipline at the top of every session.

## The hook binding (coordinator `.claude/settings.json`)

```json
"SessionStart": [
  { "matcher": "",
    "hooks": [ { "type": "command",
                 "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh\"" } ] } ]
```

## The script (`.claude/hooks/session-start.sh`)

Its own header comment captures the design intent — a deliberately *disposable* binding, with a plan
to generalize:

> Session-start directive — thin binding (Claude Code specific, disposable). Hardcoded routing for
> now; replace with AGENTS.md router when carcc-os matures.

```
[SESSION-START DIRECTIVE — do this before anything else]
Your FIRST action this session, before any tool call or recommendation:
  1. Read handoff-prompt.md — current session state and active work
  2. Read docs/index.md — coordinator doc navigation
  3. Read hpc-lab/CLAUDE.md — infrastructure project context and key docs
  4. Read hpc-lab/docs/index.md — hpc-lab doc navigation
  5. STATE what you read, then ASK: "Do you have new context, logs, or
     observations before I start?" — the user's opening question does NOT
     count as this answer. Do NOT run any tool calls until the user has
     explicitly responded.
```

## Why it matters for the talk

The handoff went from a **file you remember to read** → a **file the system reads for you**, plus an
enforced human-checkpoint that resists the agent's bias to charge ahead. It's the concrete payoff of
the whole process arc: the discipline is no longer dependent on the human (or the model) remembering
it. Note the explicit portability intent ("replace with AGENTS.md router") — the workflow is being
designed to outlive this one project (→ the `carcc-os` framework).
