# Per-session transcript stats. Run:  jq -s -f stats.jq SESSION.jsonl
# Tokens are deduped by requestId (streaming emits repeat usage under one request).
def n0: . // 0;

# unique assistant requests carry the authoritative usage
(map(select(.type=="assistant" and (.requestId != null)))
   | group_by(.requestId) | map(.[0].message.usage)) as $u
| (map(select(.type=="assistant")) | [.[].message.content[]? | select(.type=="tool_use") | .name]) as $tools
| {
  session:      (.[0].sessionId // "unknown"),
  cwd:          (map(.cwd) | map(select(.)) | last),
  git_branch:   (map(.gitBranch) | map(select(.)) | last),
  first_ts:     (map(.timestamp) | map(select(.)) | min),
  last_ts:      (map(.timestamp) | map(select(.)) | max),
  models:       (map(select(.type=="assistant") | .message.model) | map(select(.)) | unique),
  tokens: {
    input:          ($u | map(.input_tokens          | n0) | add | n0),
    output:         ($u | map(.output_tokens         | n0) | add | n0),
    cache_creation: ($u | map(.cache_creation_input_tokens | n0) | add | n0),
    cache_read:     ($u | map(.cache_read_input_tokens     | n0) | add | n0),
    requests:       ($u | length)
  },
  messages: {
    user_prompts:    (map(select(.type=="user" and (.promptSource != null))) | length),
    assistant_turns: (map(select(.type=="assistant")) | length),
    assistant_text:  (map(select(.type=="assistant") | .message.content[]? | select(.type=="text"))     | length),
    thinking_blocks: (map(select(.type=="assistant") | .message.content[]? | select(.type=="thinking")) | length),
    tool_results:    (map(select(.type=="user")      | .message.content? // [] | if type=="array" then .[] else empty end | select(.type=="tool_result")) | length)
  },
  tool_calls: {
    total: ($tools | length),
    by_name: ($tools | group_by(.) | map({(.[0]): length}) | add // {})
  },
  record_types: (map(.type) | group_by(.) | map({(.[0]): length}) | add)
}
