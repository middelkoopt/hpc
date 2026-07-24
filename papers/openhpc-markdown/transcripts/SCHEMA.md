# Claude Code Transcript Schema & Junk-Reduction Pipeline

How to turn raw Claude Code session transcripts into (a) per-session stats and (b) a compact,
analysis-ready corpus — using `jq`, no Python. Built for the OpenHPC migration paper but generic.

## Where transcripts live

`~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl` — one JSON object per line. The directory
name is the working directory with `/` → `-`. Subagent/workflow transcripts nest under
`<session>/subagents/…` and `<session>/workflows/…`. **Retention defaults to 30 days**
(`cleanupPeriodDays` in `settings.json`); raise it to preserve history.

## Record types (one per line, keyed by `.type`)

| `.type` | Keep? | What it is |
|---|---|---|
| `user` | **yes** | Either a real user prompt (`.promptSource` set, `.message.content` = text) or a tool-result carrier (`.toolUseResult` set, `.message.content[]` has `tool_result`). |
| `assistant` | **yes** | A model turn. `.message.content[]` = `text` / `thinking` / `tool_use` items. `.message.usage` holds token counts. `.message.model` = model id. |
| `attachment` | no | File/context attachments injected into a prompt. |
| `file-history-snapshot` | no | Full file snapshots for undo — large, pure junk for analysis. |
| `ai-title` | no | Auto-generated session title. |
| `last-prompt` | no | Bookkeeping pointer. |
| `queue-operation` | no | Prompt-queue bookkeeping. |

## Where the numbers are

- **Tokens** → `assistant.message.usage`: `input_tokens`, `output_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens`. **Dedupe by `.requestId`** — streaming can
  emit the same usage under one request across multiple `assistant` lines. `stats.jq` groups by
  `requestId` and takes one usage per request.
- **Tool calls** → `assistant.message.content[] | select(.type=="tool_use") | .name`.
- **Chat messages** → user prompts = `user` with `.promptSource`; assistant text = `content[]` of
  `.type=="text"`.
- **Wall-clock** → `min`/`max` of `.timestamp`.

## The "junk" (what bloats a transcript, in order)

1. **`tool_result` bodies** — file reads, `git`/`grep`/build stdout. The single biggest driver.
2. **`thinking` blocks** — extended reasoning; large, often redacted-empty.
3. **`file-history-snapshot`** records — whole-file copies.
4. **`tool_use` inputs** — occasionally large (e.g. a full file `Write`).

`reduce.jq` keeps every chat message and all tool-call *metadata* (name, result size, is_error, a
300-char preview) while truncating bodies — **~81% smaller** on the sample, losslessly for the
questions this corpus answers (who did what, how many calls, how many tokens).

## Reduced-record schema (output of `reduce.jq`)

```jsonc
// user prompt
{ "t": "<iso>", "role": "user", "text": "<≤4000 chars>" }
// assistant turn
{ "t": "<iso>", "role": "assistant", "model": "claude-…",
  "usage": {"input":N,"output":N,"cache_creation":N,"cache_read":N},
  "items": [ {"k":"text","text":"…"},
             {"k":"thinking","chars":N,"preview":"≤200"},
             {"k":"tool_use","name":"Bash","input":"≤400"} ] }
// tool result
{ "t": "<iso>", "role": "tool_result", "is_error": false,
  "chars": N, "preview": "≤300" }
```

## Usage

```bash
# per-session stats (one object)
jq -s -f stats.jq  SESSION.jsonl

# reduced corpus (array of events)
jq -s -f reduce.jq SESSION.jsonl > sample/SESSION.reduced.json

# batch a directory into one stats array
for f in ~/.claude/projects/<dir>/*.jsonl; do jq -s -f stats.jq "$f"; done | jq -s '.' > stats.json

# aggregate across sessions
jq '{sessions:length,
     tokens:{input:(map(.tokens.input)|add), output:(map(.tokens.output)|add)},
     tool_calls:(map(.tool_calls.total)|add),
     by_tool:(map(.tool_calls.by_name)|add)}' stats.json
```

## If migration transcripts are recovered

Drop the raw `*.jsonl` into `transcripts/raw/`, then run the two commands above. The pipeline is
schema-stable across the record types documented here; only add handling if a new `.type` appears.
