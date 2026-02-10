#!/bin/bash
# Stop hook for Ralph Loop - exits only THIS Claude session
# Walks up process tree to find the specific Claude that spawned this hook
# Safe with multiple Claude instances running simultaneously
#
# DUAL-MODE: Only activates when RALPH_LOOP=1 is set
# - Normal interactive use: hook does nothing
# - Loop mode: RALPH_LOOP=1 claude ... (kills after each turn)

# Only kill Claude if we're in loop mode
if [[ "$RALPH_LOOP" != "1" ]]; then
  exit 0
fi

# Walk up the process tree to find "claude"
PID=$$
while [ "$PID" != "1" ]; do
  PARENT=$(ps -o ppid= -p "$PID" 2>/dev/null | tr -d ' ')
  CMD=$(ps -o comm= -p "$PARENT" 2>/dev/null)
  if [[ "$CMD" == "claude" ]]; then
    sleep 0.5
    kill -INT "$PARENT" 2>/dev/null
    exit 0
  fi
  PID="$PARENT"
done

echo "Could not find parent Claude process" >&2
exit 1
