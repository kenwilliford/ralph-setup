#!/usr/bin/env bash
#
# health-check.sh - Verify ralph-loop prerequisites are installed and configured
#
# Exit 0 if all checks pass, non-zero if any fail.

set -euo pipefail

FAILED=0

# Report function for pass/fail output
# Usage: report "name" "description" (exit_code)
# If exit_code is 0, prints PASS; otherwise prints FAIL and sets FAILED=1
report() {
    local name="$1"
    local desc="$2"
    local code="${3:-0}"

    if [[ "$code" -eq 0 ]]; then
        echo "[PASS] ${name}: ${desc}"
    else
        echo "[FAIL] ${name}: ${desc}"
        FAILED=1
    fi
}

# --- Core Tools Checks ---

# Check for br (beads_rust)
if command -v br &>/dev/null; then
    report "br" "installed"
else
    report "br" "not found" 1
fi

# Check for git
if command -v git &>/dev/null; then
    report "git" "installed"
else
    report "git" "not found" 1
fi

# Check for claude CLI
if command -v claude &>/dev/null; then
    report "claude" "installed"
else
    report "claude" "not found" 1
fi

# Check for jq
if command -v jq &>/dev/null; then
    report "jq" "installed"
else
    report "jq" "not found" 1
fi

# --- Hook Configuration Checks ---

# Check for .claude/settings.json
if [[ -f ".claude/settings.json" ]]; then
    report "settings" ".claude/settings.json exists"
else
    report "settings" ".claude/settings.json not found" 1
fi

# Check for Stop hook registration in settings
if [[ -f ".claude/settings.json" ]]; then
    if jq -e '.hooks.Stop' .claude/settings.json &>/dev/null; then
        # Check if it references exit-after-task.sh
        if jq -e '.hooks.Stop | .. | .command? | select(. != null) | contains("exit-after-task")' .claude/settings.json &>/dev/null; then
            report "stop-hook" "registered with exit-after-task.sh"
        else
            report "stop-hook" "registered but missing exit-after-task.sh" 1
        fi
    else
        report "stop-hook" "not registered in settings" 1
    fi
else
    report "stop-hook" "cannot check (settings.json missing)" 1
fi

# Check for hook script existence and executability
HOOK_SCRIPT=".claude/hooks/exit-after-task.sh"
if [[ -f "$HOOK_SCRIPT" ]]; then
    if [[ -x "$HOOK_SCRIPT" ]]; then
        report "hook-script" "exit-after-task.sh exists and is executable"
    else
        report "hook-script" "exit-after-task.sh exists but not executable" 1
    fi
else
    report "hook-script" "exit-after-task.sh not found" 1
fi

# --- Project Structure Checks ---

# Check for .ralph/ directory
if [[ -d ".ralph" ]]; then
    report "ralph-dir" ".ralph/ directory exists"
else
    report "ralph-dir" ".ralph/ directory not found" 1
fi

# Check for git repository
if git rev-parse --is-inside-work-tree &>/dev/null; then
    report "git-repo" "inside git repository"
else
    report "git-repo" "not inside git repository" 1
fi

# Exit with appropriate code
exit "$FAILED"
