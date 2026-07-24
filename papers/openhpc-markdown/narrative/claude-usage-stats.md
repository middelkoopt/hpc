# Claude Code Usage Stats (recovered)

**This is the "some analysis" that was done earlier** — a Claude-generated summary of its own use
across the refactoring project. It was produced while the raw transcripts still existed; those
transcripts have since been deleted by 30-day retention (see `../STATS.md` §0), so **this table is now
the authoritative record** and cannot be re-derived from local data. Treat the figures as
Claude-reported, not independently re-verified.

## The numbers

| Metric | Value |
|---|---|
| Sessions | 34 |
| Real user prompts | 818 |
| Assistant messages | 9,953 |
| Tool calls | 5,297 |
| Total messages (all roles) | ~16,000 |
| API: token generation | 166 min (2.8 hrs) |
| API: time-to-first-token | 104 min (1.7 hrs) |
| Local: tool execution | 315 min (5.3 hrs) |
| Total active time | 585 min (9.75 hrs) |
| Compactions | 44 across 5 sessions (concentrated in the design phase) |

## Reading them for the talk

- **~16,000 messages / 5,297 tool calls / 818 prompts** over **34 sessions** → a sense of the
  human-in-the-loop cadence: roughly one user prompt per ~6.5 tool calls.
- **9.75 h active** but spread over ~a few weeks of part-time work ("between naps, with a cold").
- **Local tool execution (5.3 h) > API generation (2.8 h)** — most wall-clock was the agent running
  builds/tests/greps, not the model thinking. A useful point about where refactoring time actually goes.
- **44 compactions, mostly in the design phase** — motivates the move to an explicit handoff workflow
  (see `process-evolution.md`).

## Provenance note

Adrian's parallel POC data point (Nov 21, 2025): *"~300K tokens later I have a new version of the
OpenHPC pdf."* Useful as an independent second anecdote on token cost of an LLM doc conversion.
