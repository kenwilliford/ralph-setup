#!/bin/bash
# Check current session's context utilization
# Returns: percentage of 200K context window used
#
# USAGE: .ralph/check-context.sh
# EXIT CODES:
#   0 - Context usage OK (<60%)
#   1 - Error (no session file found)
#   2 - Context elevated (60-79%) - consider checkpointing
#   3 - Context critical (>=80%) - checkpoint immediately, auto-compact imminent
#
# INSTALLATION:
# 1. Copy to .ralph/check-context.sh
# 2. chmod +x .ralph/check-context.sh

# Auto-detect project session directory from current working directory
# Claude stores sessions in ~/.claude/projects/<sanitized-path>
PROJECT_PATH=$(pwd | sed 's|/|-|g; s|^-||')
SESSION_DIR=~/.claude/projects/$PROJECT_PATH

# Find most recently modified session file
LATEST=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
    echo "error: no session file found"
    echo "Check SESSION_DIR path: $SESSION_DIR"
    exit 1
fi

# Sum up cache_read_input_tokens from last entry (most accurate current state)
TOKENS=$(tail -20 "$LATEST" | grep -o '"cache_read_input_tokens":[0-9]*' | tail -1 | grep -o '[0-9]*')

if [ -z "$TOKENS" ]; then
    echo "error: no token count found"
    exit 1
fi

# Context window is 200K
WINDOW=200000
PERCENT=$((TOKENS * 100 / WINDOW))

echo "${PERCENT}% context used (${TOKENS}/${WINDOW} tokens)"

# Exit codes:
# - 0: OK, plenty of room (<60%)
# - 2: Warning, approaching limit (60-79%) - consider checkpointing
# - 3: Critical (>=80%) - checkpoint immediately, auto-compact imminent
if [ "$PERCENT" -ge 80 ]; then
    exit 3  # Critical: auto-compact triggers at 80%
elif [ "$PERCENT" -ge 60 ]; then
    exit 2  # Warning: should checkpoint soon
fi
