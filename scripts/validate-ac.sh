#!/bin/bash
# Validate that all beads tasks have acceptance criteria
# This is a HARD GATE - must pass before proceeding with ralph loop
#
# Usage: .ralph/validate-ac.sh
# Exit codes:
#   0 = All tasks have acceptance criteria
#   1 = One or more tasks missing acceptance criteria
#   2 = Configuration error (no epic ID, br not found, etc.)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "=== Acceptance Criteria Validation Gate ==="
echo ""

# Check for br command
if ! command -v br &> /dev/null; then
    echo -e "${RED}ERROR: 'br' command not found. Install beads_rust first.${NC}"
    exit 2
fi

# Get epic ID from beads-state.txt
if [[ ! -f .ralph/beads-state.txt ]]; then
    echo -e "${RED}ERROR: .ralph/beads-state.txt not found.${NC}"
    echo "Run /beads-spec-to-beads first to create the epic."
    exit 2
fi

EPIC_ID=$(grep "Epic ID:" .ralph/beads-state.txt | awk '{print $3}')
if [[ -z "$EPIC_ID" ]]; then
    echo -e "${RED}ERROR: Could not find Epic ID in beads-state.txt${NC}"
    exit 2
fi

echo "Epic ID: $EPIC_ID"
echo ""

# Get all tasks under the epic
TASKS=$(br list --type task --parent "$EPIC_ID" --json 2>/dev/null | jq -r '.[].id' || echo "")

if [[ -z "$TASKS" ]]; then
    echo -e "${YELLOW}WARNING: No tasks found under epic $EPIC_ID${NC}"
    echo "This might be OK if tasks haven't been created yet."
    exit 0
fi

TASK_COUNT=$(echo "$TASKS" | wc -l)
echo "Checking $TASK_COUNT tasks..."
echo ""

MISSING_COUNT=0
MISSING_TASKS=""

for TASK_ID in $TASKS; do
    # Get acceptance criteria for this task
    AC=$(br show "$TASK_ID" --json 2>/dev/null | jq -r '.acceptance_criteria // empty' || echo "")
    TITLE=$(br show "$TASK_ID" --json 2>/dev/null | jq -r '.title // "unknown"' || echo "unknown")

    # Check if AC is empty or just whitespace
    AC_TRIMMED=$(echo "$AC" | tr -d '[:space:]')

    if [[ -z "$AC_TRIMMED" ]]; then
        echo -e "${RED}MISSING AC:${NC} $TASK_ID - $TITLE"
        MISSING_COUNT=$((MISSING_COUNT + 1))
        MISSING_TASKS="$MISSING_TASKS\n  $TASK_ID: $TITLE"
    else
        # Check if AC has actual criteria (not just placeholder text)
        AC_LINES=$(echo "$AC" | grep -c '\- \[ \]' || echo "0")
        if [[ "$AC_LINES" -eq 0 ]]; then
            # No checkbox items, check for any substantive content
            AC_LEN=${#AC_TRIMMED}
            if [[ "$AC_LEN" -lt 20 ]]; then
                echo -e "${YELLOW}WEAK AC:${NC} $TASK_ID - $TITLE (only $AC_LEN chars, no checkboxes)"
            else
                echo -e "${GREEN}OK:${NC} $TASK_ID - $TITLE ($AC_LEN chars)"
            fi
        else
            echo -e "${GREEN}OK:${NC} $TASK_ID - $TITLE ($AC_LINES criteria)"
        fi
    fi
done

echo ""
echo "=== Summary ==="

if [[ "$MISSING_COUNT" -gt 0 ]]; then
    echo -e "${RED}FAILED: $MISSING_COUNT tasks missing acceptance criteria${NC}"
    echo ""
    echo "Tasks needing AC:$MISSING_TASKS"
    echo ""
    echo "To fix, run for each missing task:"
    echo '  br update <TASK_ID> --acceptance-criteria "- [ ] Criterion 1\n- [ ] Criterion 2"'
    echo ""
    echo "Or re-run /beads-task-elaboration to add AC to all tasks."
    exit 1
else
    echo -e "${GREEN}PASSED: All $TASK_COUNT tasks have acceptance criteria${NC}"
    exit 0
fi
