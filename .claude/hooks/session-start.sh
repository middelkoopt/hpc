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
  3. If the handoff involves hpc-lab or infrastructure work:
     also read hpc-lab/CLAUDE.md
  4. STATE what you read, then ASK for new context before opening
     more files, grepping, or making any recommendations.
EOF
