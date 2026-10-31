#!/bin/sh
# usage: digest.sh SESSION.jsonl  -> compact text digest
jq -r '
def cut: tostring | .[0:300];
select(.type=="message") | .message as $m |
if $m.role=="user" then "USER: " + ([$m.content[]? | select(.type=="text") | .text] | join(" ") | cut)
elif $m.role=="assistant" then
  ($m.content[]? |
    if .type=="toolCall" then "CALL " + .name + " " + (.arguments | cut)
    elif .type=="text" then "ASSIST: " + (.text | cut) else empty end)
elif $m.role=="toolResult" and $m.isError==true then "ERROR " + $m.toolName + ": " + ([$m.content[]? | .text?] | join(" ") | cut)
else empty end' "$1"
