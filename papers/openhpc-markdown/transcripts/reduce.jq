# Junk-reduced transcript. Run:  jq -s -f reduce.jq SESSION.jsonl > reduced.json
# Keeps: user prompts, assistant text, tool-call metadata, tool-result previews, per-turn tokens.
# Drops: file-history-snapshot, attachment, ai-title, last-prompt, queue-operation.
# Truncates: thinking blocks, tool_use inputs, and tool_result bodies (the size driver).
def clip(n): if type=="string" and (length>n) then (.[:n] + "…[+\(length-n)]") else . end;
def txt: if type=="array" then (map(select(.type=="text").text) | join("\n")) else (.|tostring) end;

[ .[]
  | select(.type=="user" or .type=="assistant")
  | if .type=="user" and (.promptSource != null) then
      { t:.timestamp, role:"user", text:(.message.content | txt | clip(4000)) }
    elif .type=="user" then
      # tool_result carrier
      .timestamp as $ts
      | ( .message.content? // [] | if type=="array" then .[] else empty end
        | select(.type=="tool_result")
        | { t:$ts, role:"tool_result", is_error:(.is_error//false),
            chars:(.content|txt|length), preview:(.content|txt|clip(300)) } )
    else
      { t:.timestamp, role:"assistant", model:.message.model,
        usage:(.message.usage | {input:.input_tokens, output:.output_tokens,
               cache_creation:.cache_creation_input_tokens, cache_read:.cache_read_input_tokens}),
        items:[ .message.content[]?
                | if .type=="text"     then {k:"text", text:(.text|clip(4000))}
                  elif .type=="thinking" then {k:"thinking", chars:(.thinking|length), preview:(.thinking|clip(200))}
                  elif .type=="tool_use" then {k:"tool_use", name:.name, input:(.input|tostring|clip(400))}
                  else empty end ] }
    end
]
