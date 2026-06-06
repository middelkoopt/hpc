# Claude Code Settings — Project Reference

Permission patterns and settings notes specific to this workspace.

---

## autoMemoryEnabled

`autoMemoryEnabled: false` in `.claude/settings.json` disables the auto-memory system entirely
for this project — Claude will not load, create, or update `~/.claude/projects/.../memory/`
files. Verified with two fresh sessions (2026-06-05): MEMORY.md is not injected into context
when the setting is false.

Persistent knowledge lives in `docs/` (git) and `handoff-prompt.md` per `PROCESS.md`. The
`memory/` directory and its `MEMORY.md` index are kept but inert.

---

## Settings File Locations

| File | Scope | Git |
| ---- | ----- | --- |
| `~/.claude/settings.json` | Global (all projects) | no |
| `.claude/settings.json` | Project (this dir) | yes — team-shared |
| `.claude/settings.local.json` | Project (this dir) | no — personal overrides |

Settings load in order: user → project → local (later wins).

The project file lives at `hpc/.claude/settings.json`.

---

## Permission Rule Syntax

```json
{
  "permissions": {
    "allow": [
      "Bash(ssh ssh://cloud@localhost:8022 *)",
      "Bash(git log *)",
      "WebFetch(*)"
    ]
  }
}
```

- `Bash(<pattern>)` — glob-match against the full command string
- `**` matches any suffix including `/` — use this for commands that may contain paths
- `*` does NOT match `/`; avoid it when the command or its arguments may contain slashes
- **Pattern must match the exact command string** — flag order matters

---

## SSH/SCP Pattern Gotcha — ssh:// URI Form

This project's scripts use the URI form for qemu head node connections:

```bash
ssh ssh://cloud@localhost:8022 <command>
scp file scp://cloud@localhost:8022/path
```

This is the project standard (per `hpc-lab/CLAUDE.md`) — used in `test-recipe-run.sh`,
`ohpc-run.sh`, `wait.sh`, `warewulf-run.sh`. **Do not switch to `-p 8022 cloud@localhost`.**

**Critical:** the permission pattern must NOT include flags before the URI if the scripts
don't use them. The original broken pattern was:

```text
"Bash(ssh -o StrictHostKeyChecking=no ssh://cloud@localhost:8022 *)"
```

The scripts call `ssh ssh://...` with no `-o` flag, so this pattern never matched.
Correct patterns (currently in `.claude/settings.json`):

```json
"Bash(ssh ssh://cloud@localhost:8022 **)",
"Bash(scp ** scp://cloud@localhost:8022**)"
```

**Use `**` not `*` when the pattern contains `://`** — the glob engine splits on `/`, so `*`
fails to match across the URI. `**` matches everything including slashes. Verified 2026-06-05.

---

## Editing settings.json with jq (preferred for permission changes)

jq/yq are installed (`jq 1.8.1`, `yq v4 mikefarah`). For permission array edits, jq is
strictly better than Read+Edit: no context consumed, no need to read the file first.

**Add a permission entry:**

```bash
jq '.permissions.allow += ["Bash(new pattern)"]' .claude/settings.json \
  > /tmp/settings.json && mv /tmp/settings.json .claude/settings.json
```

**Remove a permission entry:**

```bash
jq '.permissions.allow -= ["Bash(old pattern)"]' .claude/settings.json \
  > /tmp/settings.json && mv /tmp/settings.json .claude/settings.json
```

**Verify current allow list:**

```bash
jq '.permissions.allow[]' .claude/settings.json
```

yq supports in-place with `-i` but defaults to YAML output — add `-o=json` to keep JSON:

```bash
yq -i -o=json '.permissions.allow += ["Bash(new pattern)"]' .claude/settings.json
```

**When to use Read+Edit instead:** when the change is structural (adding a new top-level
key, hooks config) where getting the jq expression wrong could silently corrupt the file.
For simple array append/remove, jq is reliable and saves the context.

---

## update-config Skill — Use Reluctantly

Invoking `/update-config` loads the **full Claude Code settings JSON schema** — thousands of
lines. It will consume significant context for the entire session.

**Rule:** For adding or fixing permission allow-rules, use jq (see above) or edit
`.claude/settings.json` directly with the Edit tool. Only invoke the skill when you need
hook event names, hook type syntax, or other schema details not covered here.

---

## Hook Events (quick reference)

For the rare cases where hooks are needed:

| Event | When it fires |
| ----- | ------------- |
| `PreToolUse` | Before any tool call; can block |
| `PostToolUse` | After successful tool call |
| `Stop` | When Claude finishes a turn |
| `UserPromptSubmit` | When user submits a message |
| `SessionStart` | On session start |

Hook structure:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "your-command-here" }]
    }]
  }
}
```

The hook receives JSON on stdin with `tool_name`, `tool_input`, `tool_response` fields.
Use `jq -r '.tool_input.file_path'` to extract values.
