#!/usr/bin/env bash
# Session-start directive — thin binding (Claude Code specific, disposable).
# Hardcoded routing for now; replace with AGENTS.md router when carcc-os matures.
# Tradeoff: hpc-lab/CLAUDE.md is always pulled for hpc-lab sessions (context cost
# accepted); fix properly when the full routing layer lands.
cat <<'EOF'
[SESSION-START DIRECTIVE — do this before anything else]
Your FIRST action this session, before any tool call or recommendation:
  1. Read handoff-prompt.md — current session state and active work
  2. Read docs/index.md — coordinator doc navigation
  3. Read hpc-lab/CLAUDE.md — infrastructure project context and key docs
  4. STATE what you read, then ASK: "Do you have new context, logs, or
     observations before I start?" — the user's opening question does NOT
     count as this answer. Do NOT run any tool calls (Bash, git, grep,
     find) until the user has explicitly responded to this question.
EOF
