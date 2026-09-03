#!/bin/bash
# Claude Code SessionStart hook: print the project's handoff file so it lands in context at startup.
# Looks for docs/handoff.md in the current directory. Missing file -> silent exit, never blocks startup.
# Plain stdout of a SessionStart hook is added to Claude's context, so no jq/JSON needed.
f="docs/handoff.md"
[ -f "$f" ] || exit 0
printf '=== handoff: %s (read before starting work) ===\n' "$(pwd)/$f"
tr -d '\r' < "$f"
printf '\n=== handoff end ===\n'
