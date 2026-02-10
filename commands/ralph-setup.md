---
name: ralph-setup
description: "Set up for a ralph loop - archive prior work, interview, write spec, validate, confirm readiness"
---

# Ralph Loop Setup

You are setting up for an autonomous ralph loop. Follow this cycle exactly.

## Context Awareness

**Monitor context throughout setup.** Run periodically:
```bash
.ralph/check-context.sh 2>/dev/null || echo "Context check unavailable"
```

- At **60%+ context**: Warn user, mention checkpoint option
- At **70%+ context**: **Checkpoint immediately** - auto-compact triggers at 80%

Claude Code auto-compacts at 80% which loses conversation history. Complete checkpoint before then.

**Checkpoint mechanism:** Save state to `.ralph/setup-state.json`:
```json
{
  "phase": "interview",
  "step": 3,
  "interview_mode": "conversational",
  "answers": {
    "goal": "...",
    "reproduction_steps": "...",
    "success_criteria": ["..."],
    "scope": "...",
    "edge_cases": ["..."]
  },
  "research_notes": "..."
}
```

On `/clear` and restart, check for this file and offer to resume.

---

## Phase 1: ARCHIVE & RESUME

Check for existing `.ralph/` directory:
- If `.ralph/setup-state.json` exists: ask "Resume setup from [phase]?" or "Start fresh?"
- If `.ralph/COMPLETE` exists: offer to archive to `.ralph/archive/YYYY-MM-DD-<name>/`
- If `.ralph/` exists without COMPLETE or state: ask if continuing prior work or starting fresh
- If none: proceed to interview

---

## Phase 2: INTERVIEW

### 2.0 Interview Mode

Ask using AskUserQuestion:

"How would you like to conduct the interview?"

Options:
- **Structured** - Multiple-choice questions, quick and focused
- **Conversational** - Open discussion, I'll ask follow-ups naturally

Save choice to setup-state.json.

### 2.1-2.5 Interview Questions

**If Structured mode:** Use AskUserQuestion for each, one at a time.

**If Conversational mode:** Ask these as natural questions, follow up as needed, summarize answers before moving on.

1. **What's the goal?** What should be different when this loop completes?

2. **What's broken?** If fixing a bug: what EXACT steps reproduce it?
   - Get specific: zoom level, click sequence, wait duration, expected vs actual

3. **Success criteria:** What specific scenarios must work to call this done?
   - Turn each into a testable checklist item

4. **Scope:** Narrow fix or broader work? What's explicitly OUT of scope?

5. **Edge cases:** What tricky conditions should be explicitly tested?
   - These become spec items, not assumptions

6. **Research needs:** Does this require investigation before coding?
   - Bug fixes often need investigation to find root cause
   - New features in unfamiliar areas need exploration
   - Simple changes to well-understood code may not need research
   - Options: None / Light exploration / Deep investigation

7. **Documentation:** Will this work require doc updates?
   - Check project's CLAUDE.md for documentation requirements
   - New APIs, changed behavior, new features typically need docs
   - Bug fixes usually don't

**After each answer:** Update setup-state.json with the answer.

**After all questions:** Summarize what you heard and confirm accuracy.

---

## Phase 3: RESEARCH (Conditional)

**Skip this phase if interview answer was "None" for research needs.**

If research is needed:
1. Use Task tool with Explore agent for codebase exploration
2. Document findings in setup-state.json under "research_notes"
3. Summarize findings for user
4. Ask if more research needed or ready to proceed

**Check context after research** - research can consume significant context.

---

## Phase 4: WRITE SPEC

Create these files. **Token budget: 5000 tokens total** for core context.

Budget allocation:
- prompt.md: ~450 tokens (fixed overhead, includes beads workflow)
- readme.md: ~550 tokens (index overhead)
- **spec.md: ~4000 tokens available** (5000 - 450 - 550)

**Key insight:** Acceptance criteria live in beads tasks, NOT in spec.md. This keeps spec minimal while still having rigorous verification criteria available on-demand via `br show`.

**`.ralph/prompt.md`** (~500 tokens):
```markdown
# FIRST: Check stop conditions - exit immediately if present
if [ -f .ralph/WAITING ]; then cat .ralph/WAITING; exit 0; fi
if [ -f .ralph/COMPLETE ]; then echo "Already complete"; exit 0; fi

# Record start time if not already set
if [ ! -f .ralph/started.txt ]; then date -Iseconds > .ralph/started.txt; fi

study .ralph/readme.md
study .ralph/spec.md

═══════════════════════════════════════════════════════════════════
  DO EXACTLY ONE STEP, THEN COMMIT AND EXIT. NOT TWO. NOT THREE.
  The outer loop will restart you for the next step.
═══════════════════════════════════════════════════════════════════

Pick the FIRST incomplete step. Do that ONE step. Then commit, push, and EXIT.

If ALL spec checkboxes complete:
  1. VERIFY BEADS SYNC FIRST (REQUIRED - DO NOT SKIP):
     Run: .ralph/verify-beads-sync.sh
     If FAILED: Fix sync before proceeding (mark beads tasks complete)
  2. Only after sync passes:
     date -Iseconds > .ralph/completed.txt
     .ralph/report.sh > .ralph/final-report.txt
  3. CLOSE THE EPIC (keeps .beads clean for future loops):
     EPIC_ID=$(grep "Epic ID:" .ralph/beads-state.txt | awk '{print $3}')
     br close $EPIC_ID --reason "Ralph loop complete"
  4. Create .ralph/COMPLETE, commit, push, exit.

═══════════════════════════════════════════════════════════════════
MANDATORY WORKFLOW FOR EACH STEP (ALL steps required, no skipping):
═══════════════════════════════════════════════════════════════════
  1. FIND TASK ID: Look for [TASK-xyz] in spec step (REQUIRED)
  2. FETCH CRITERIA: Run `br show TASK-xyz` (REQUIRED - do NOT skip!)
     └─ This gives you acceptance criteria. Read them carefully.
  3. DO THE WORK: Implement the step
  4. VERIFY: Check EACH acceptance criterion from br show output
     └─ Show specific evidence (command output, file contents)
  5. MARK SPEC: Change [ ] → [x] in spec.md
  6. MARK BEADS: Run `br task complete TASK-xyz` (REQUIRED - do NOT skip!)
     └─ If you skip this, sync check will FAIL at completion
  7. LOG EVIDENCE: Add to progress log in spec.md
  8. COMMIT AND EXIT: `git add -A && git commit`, `git push`, then EXIT.
     └─ Do NOT start the next step. The outer loop restarts you.

⚠️  BEADS COMPLETION IS MANDATORY - NOT OPTIONAL  ⚠️
The final sync check WILL FAIL if you mark spec checkboxes without
running `br task complete`. You MUST do both for every step.

FALSE COMPLETE PREVENTION:
  - ALWAYS run `br show` BEFORE starting work - criteria live there
  - NEVER mark done without verifying EACH criterion
  - Show specific evidence (command output, not "it works")
  - If manual verification needed, create WAITING file instead

EVIDENCE FORMAT (for progress log - pick applicable types):
  - File created: `ls -la path/file` output
  - Compiles: `tsc --noEmit` success
  - Test passes: actual test output showing pass
  - Grep finds: `grep -n 'pattern' file` showing match
  - Export exists: `grep 'export' file | head -3`

REVIEW STEPS (.R): Trigger autonomous code review:
  - Re-read implementation code with fresh eyes
  - Look for bugs, edge cases, security issues
  - Verify tests actually test the right things
  - Check implementation matches spec INTENT not just syntax

COMMITS: Exactly one commit per session, then push and EXIT immediately.
Format: "<step>: <what changed>"
Do NOT start another step after committing.

CONTEXT: At ≥60%, checkpoint, commit, push, and EXIT.
```

**`.ralph/readme.md`** (~600 tokens):
- Lookup table pointing to reference docs
- "When to read" triggers for each doc
- Branch name for this loop

**`.ralph/spec.md`** (use remaining budget, target <4000 tokens):
- Phases with numbered items (1.1, 1.2, 1.R for review)
- Progress Log table: session | item | result (1 line each!)
- Stuck Flags table: item | tried | failed because | try next
- "Done When" section with EXACT test scenarios from interview

**CRITICAL: Spec is Index, Beads Hold Detail**

Spec.md stays MINIMAL to preserve context budget. Detailed acceptance criteria live in beads tasks.

**Spec Step Pattern (REQUIRED format - ~80 chars each):**
```markdown
- [ ] **N.X** Action description [TASK-xyz]
  - Evidence: (filled in after completion)
```

**⚠️ The `[TASK-xyz]` inline reference is MANDATORY ⚠️**

Every spec step MUST have a bracketed task ID. This is NOT optional because:
1. Workers need the ID to run `br show TASK-xyz` for acceptance criteria
2. Workers need the ID to run `br task complete TASK-xyz` after completion
3. The sync verification script checks that all beads tasks are complete
4. Without IDs, the Phase 12 workflow gap WILL recur

The `[TASK-xyz]` reference tells the session to run `br show TASK-xyz` to get:
- Background and context
- Detailed acceptance criteria
- Verification commands

**After beads-spec-to-beads runs, UPDATE spec.md to add the task IDs inline.**
This is done in Phase 5.1 - do not skip this step.

**Where Information Lives:**
| What | Where | When Read |
|------|-------|-----------|
| Step list (index) | spec.md | Every session (in context) |
| Acceptance criteria | beads task | On-demand via `br show` |
| Completion evidence | spec.md progress log | After step done |

**MANDATORY Review Steps (X.R):**

**Every implementation phase MUST end with a `.R` review step.** This is non-negotiable.

Review steps trigger autonomous code review looking for:
- Logic errors and bugs
- Missing edge cases
- Security issues
- Integration problems
- Code that doesn't match the spec intent

```markdown
## Phase 2: Implement Feature
- [ ] **2.1** Create the component [TASK-abc]
- [ ] **2.2** Add validation logic [TASK-def]
- [ ] **2.3** Wire to existing system [TASK-ghi]
- [ ] **2.R** Review: code review + verify tests pass [TASK-jkl]  ← MANDATORY
```

The beads task for X.R steps should include:
```markdown
## Acceptance Criteria
- [ ] All Phase X implementation steps are marked complete
- [ ] Code compiles without errors: `tsc --noEmit`
- [ ] Tests pass: `npm test` (or project-specific command)
- [ ] No obvious bugs found during code review
- [ ] Implementation matches spec intent (not just "runs without error")
```

**Good vs Bad Acceptance Criteria (in beads, not spec):**

BAD (vague):
- "It works"
- "Tests pass"

GOOD (in beads task description):
- "`npm test -- --grep 'validation'` shows 5/5 passing"
- "File `src/utils/validate.ts` exports `validateInput()` function"

### Spec Structure Guidelines

**Branch:** Always create a dedicated branch. Name format: `<issue-number>-<short-description>` or `ralph-<feature-name>`. Include branch name in readme.md.

**Commit organization:** Group spec phases into logical commits:
- Phase boundaries are natural commit points
- Each commit should be self-contained and buildable
- Commit messages should reference the spec step (e.g., "1.2: Add validation logic")
- Format: `<phase>.<step>: <what and why>` (e.g., "2.1: Implement tile cache - reduces redundant fetches")

**Documentation phase:** If interview identified doc requirements, add a dedicated phase:
```markdown
## Phase N: Documentation
- [ ] **N.1** Update [specific doc] with [specific content]
- [ ] **N.2** Add examples for new API
- [ ] **N.R** Review: docs match implementation
```
Place doc phase after implementation but before final review.

---

## Phase 5: BEADS INTEGRATION

Create beads tasks from the spec for reliable progress tracking and false-complete prevention.

### 5.1 Convert Spec to Beads and Add Task IDs

Run `/beads-spec-to-beads .ralph/spec.md`:

```bash
# This skill will:
# 1. Create an epic for the ralph-loop task
# 2. Create tasks matching each spec step
# 3. Map dependencies between phases
# 4. Add acceptance criteria from spec

# Record the epic ID for subsequent steps
EPIC_ID=$(br list --type epic --limit 1 --json | jq -r '.[0].id')
echo "Epic ID: $EPIC_ID" >> .ralph/beads-state.txt
```

**CRITICAL: Add Task IDs to Spec Steps (DO NOT SKIP)**

After beads tasks are created, UPDATE spec.md to add inline task IDs:

```bash
# Get mapping of step descriptions to task IDs
br list --type task --parent $EPIC_ID --format "%(id) %(title)"
```

Then edit spec.md to add `[TASK-xyz]` to each step:

Before: `- [ ] **2.1** Implement user validation`
After:  `- [ ] **2.1** Implement user validation [TASK-abc123]`

**This step is MANDATORY.** Without inline task IDs:
- Workers won't know which task to `br show` for criteria
- Workers won't know which task to `br task complete`
- The sync check at completion will fail
- You will repeat the Phase 12 workflow gap

Evidence:
- Epic created
- `br dep tree $EPIC_ID` shows matching structure
- EVERY spec step has inline `[TASK-xyz]` reference

### 5.2 Elaborate Task Context (THIS IS WHERE ACCEPTANCE CRITERIA LIVE)

Run `/beads-task-elaboration epic:$EPIC_ID`:

This is **CRITICAL** - beads tasks become the source of truth for acceptance criteria.

Each task gets:
- **Background**: Why this task exists
- **Current State**: Starting point
- **Approach**: How to accomplish
- **Acceptance Criteria**: Specific, testable checkboxes (the detail that would bloat spec.md)
- **Verification Commands**: Exact commands to prove completion

**Sessions will run `br show $TASK_ID` to fetch these criteria before working on each step.**

Evidence: `br show $TASK_ID` shows full elaboration with testable acceptance criteria.

### 5.3 Validate Acceptance Criteria Exist (AUTOMATED GATE)

**This is a hard gate.** Run `.ralph/validate-ac.sh` to verify AC exists for all tasks:

```bash
.ralph/validate-ac.sh
```

This script checks that EVERY task has non-empty acceptance criteria. If ANY task is missing AC, the script fails and you MUST fix it before proceeding.

**If validation fails:**
1. Run `br show <TASK_ID>` on failing tasks
2. Add acceptance criteria via `br update <TASK_ID> --acceptance-criteria "..."`
3. Re-run validation until it passes

**Evidence:** `validate-ac.sh` exits with status 0.

### 5.4 Validate Beads Quality

Run `/beads-validate-beads epic:$EPIC_ID`:

Checks:
- Description quality (200+ chars each)
- Acceptance criteria present (verified by 5.3)
- No red flags (giant/vague beads, orphans, circular deps)

**ONLY proceed if verdict is GO or CONDITIONALLY READY.**

If NOT READY: fix issues with `br update` before proceeding.

Evidence: Validation passed with GO status.

### 5.R Review: Beads Ready

Confirm:
- [ ] Epic created with ID in `.ralph/beads-state.txt`
- [ ] All tasks have explicit acceptance criteria
- [ ] `/beads-validate-beads` returned GO verdict
- [ ] Task count matches spec step count
- [ ] **EVERY spec step has inline `[TASK-xyz]` reference** (verify with grep):
  ```bash
  # Count steps without task IDs (should be 0)
  grep -E '^\- \[ \] \*\*[0-9]+\.' .ralph/spec.md | grep -v '\[TASK-' | wc -l
  ```
  If count > 0, add missing task IDs before proceeding.

---

## Phase 6: VALIDATE

Before declaring ready, verify:
1. Each edge case from interview is an explicit numbered test item
2. Acceptance criteria can be mechanically verified
3. The EXACT reproduction steps are a test item, not assumed covered
4. Steps are atomic (one thing per session)
5. **Each spec step has corresponding beads task with acceptance criteria**

---

## Phase 7: SPEC REVIEW

Present the spec and beads to the user for review using AskUserQuestion:

"I've written the spec and created beads tasks. Would you like to review before we proceed?"

Options:
- **Ready to run** - Proceed to infrastructure check and launch
- **Review spec** - Show me the spec files for review
- **Review beads** - Show me the beads structure (`br dep tree $EPIC_ID`)
- **Iterate** - I have changes to make

If "Review spec": Display contents of prompt.md, readme.md, and spec.md, then ask again.

If "Review beads": Run `br dep tree $EPIC_ID` and show task acceptance criteria, then ask again.

If "Iterate": Ask what changes are needed, make them, re-run beads validation, and return to this step.

Only proceed to Phase 8 when user selects "Ready to run".

---

## Phase 8: ENSURE INFRASTRUCTURE

### 8.1 Stop Hook (idempotent)

Check if ralph stop hook exists in `.claude/settings.json`. If missing, add it.

```bash
# Check for existing ralph hook
grep -q "exit-after-task" .claude/settings.json 2>/dev/null && echo "Hook exists" || echo "Hook missing"
```

If missing, read `.claude/settings.json` (or create if none), and ensure it has:
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/exit-after-task.sh"
      }]
    }]
  }
}
```

Merge with existing settings - don't overwrite permissions or other hooks.

Then create `.claude/hooks/exit-after-task.sh` if missing:
```bash
#!/bin/bash
# Ralph Loop stop hook - conditional on RALPH_LOOP=1
if [[ "$RALPH_LOOP" != "1" ]]; then exit 0; fi

# --- Token logging ---
if [[ -f .ralph/started.txt ]]; then
    # Find session directory (adjust path pattern as needed for your project)
    SESSION_DIR=$(find ~/.claude/projects -maxdepth 1 -type d -name "*$(basename $(pwd))*" 2>/dev/null | head -1)
    if [[ -n "$SESSION_DIR" ]]; then
        LATEST=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)
        if [[ -n "$LATEST" ]]; then
            TOKENS=$(tail -50 "$LATEST" | grep -o '"input_tokens":[0-9]*\|"output_tokens":[0-9]*' | tail -2)
            INPUT=$(echo "$TOKENS" | grep input | grep -o '[0-9]*')
            OUTPUT=$(echo "$TOKENS" | grep output | grep -o '[0-9]*')
            echo "$(date -Iseconds) input:${INPUT:-0} output:${OUTPUT:-0}" >> .ralph/tokens.log
        fi
    fi
fi
# --- End token logging ---

PID=$$
while [ "$PID" != "1" ]; do
  PARENT=$(ps -o ppid= -p "$PID" 2>/dev/null | tr -d ' ')
  CMD=$(ps -o comm= -p "$PARENT" 2>/dev/null)
  if [[ "$CMD" == "claude" ]]; then
    sleep 0.5; kill -INT "$PARENT" 2>/dev/null; exit 0
  fi
  PID="$PARENT"
done
exit 1
```
Make it executable: `chmod +x .claude/hooks/exit-after-task.sh`

### 8.2 Context Monitor

Create `.ralph/check-context.sh` if missing:
```bash
#!/bin/bash
# Check current session's context utilization
# Returns: percentage of 200K context window used

# Find session directory (adjust path pattern as needed)
SESSION_DIR=$(find ~/.claude/projects -maxdepth 1 -type d -name "*$(basename $(pwd))*" 2>/dev/null | head -1)

if [ -z "$SESSION_DIR" ]; then
    echo "error: no session directory found"
    exit 1
fi

LATEST=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
    echo "error: no session file found"
    exit 1
fi

TOKENS=$(tail -20 "$LATEST" | grep -o '"cache_read_input_tokens":[0-9]*' | tail -1 | grep -o '[0-9]*')

if [ -z "$TOKENS" ]; then
    echo "error: no token count found"
    exit 1
fi

WINDOW=200000
PERCENT=$((TOKENS * 100 / WINDOW))

echo "${PERCENT}% context used (${TOKENS}/${WINDOW} tokens)"

# Exit with non-zero if approaching limit (>60% - auto-compact at 80%, exit well before)
if [ "$PERCENT" -gt 60 ]; then
    exit 2  # Signal: checkpoint and exit soon
fi
```
Make it executable: `chmod +x .ralph/check-context.sh`

### 8.3 Acceptance Criteria Validation Script (HARD GATE)

Create `.ralph/validate-ac.sh` - this ensures all tasks have acceptance criteria:
```bash
#!/bin/bash
# Validate all beads tasks have acceptance criteria - HARD GATE
set -e

if ! command -v br &> /dev/null; then
    echo "ERROR: 'br' command not found"
    exit 2
fi

if [[ ! -f .ralph/beads-state.txt ]]; then
    echo "ERROR: .ralph/beads-state.txt not found"
    exit 2
fi

EPIC_ID=$(grep "Epic ID:" .ralph/beads-state.txt | awk '{print $3}')
TASKS=$(br list --type task --parent "$EPIC_ID" --json | jq -r '.[].id')
MISSING=0

for TASK_ID in $TASKS; do
    AC=$(br show "$TASK_ID" --json | jq -r '.acceptance_criteria // empty')
    AC_TRIMMED=$(echo "$AC" | tr -d '[:space:]')
    TITLE=$(br show "$TASK_ID" --json | jq -r '.title')

    if [[ -z "$AC_TRIMMED" ]]; then
        echo "MISSING AC: $TASK_ID - $TITLE"
        MISSING=$((MISSING + 1))
    fi
done

if [[ "$MISSING" -gt 0 ]]; then
    echo ""
    echo "FAILED: $MISSING tasks missing acceptance criteria"
    echo "Fix with: br update <TASK_ID> --acceptance-criteria \"...\""
    exit 1
fi

echo "PASSED: All tasks have acceptance criteria"
exit 0
```
Make it executable: `chmod +x .ralph/validate-ac.sh`

### 8.4 Beads Sync Verification Script (CRITICAL)

Create `.ralph/verify-beads-sync.sh` - this enforces beads completion:
```bash
#!/bin/bash
# Verify spec.md checkboxes match beads task completion
# MUST pass before creating COMPLETE file

set -e

# Get epic ID
if [[ ! -f .ralph/beads-state.txt ]]; then
    echo "ERROR: No beads-state.txt found. Run beads integration first."
    exit 1
fi

EPIC_ID=$(grep "Epic ID:" .ralph/beads-state.txt | awk '{print $3}')
if [[ -z "$EPIC_ID" ]]; then
    echo "ERROR: Could not find Epic ID in beads-state.txt"
    exit 1
fi

# Count completed spec checkboxes
SPEC_DONE=$(grep -c '^\- \[x\]' .ralph/spec.md 2>/dev/null || echo 0)
SPEC_TOTAL=$(grep -c '^\- \[' .ralph/spec.md 2>/dev/null || echo 0)

# Count completed beads tasks
BEADS_DONE=$(br list --type task --parent "$EPIC_ID" --status done 2>/dev/null | wc -l || echo 0)
BEADS_TOTAL=$(br list --type task --parent "$EPIC_ID" 2>/dev/null | wc -l || echo 0)

echo "=== Beads/Spec Sync Check ==="
echo "Spec checkboxes: $SPEC_DONE / $SPEC_TOTAL complete"
echo "Beads tasks:     $BEADS_DONE / $BEADS_TOTAL complete"
echo ""

# Check if spec is complete
if [[ "$SPEC_DONE" -lt "$SPEC_TOTAL" ]]; then
    echo "INCOMPLETE: Spec has unchecked boxes"
    exit 1
fi

# Check if beads is complete
if [[ "$BEADS_DONE" -lt "$BEADS_TOTAL" ]]; then
    echo ""
    echo "  SYNC FAILURE: Spec complete but beads tasks NOT marked!"
    echo ""
    echo "You marked $SPEC_DONE spec checkboxes but only $BEADS_DONE beads tasks."
    echo ""
    echo "This means you skipped 'br task complete <TASK_ID>' for some steps."
    echo ""
    echo "FIX: Find incomplete tasks and mark them:"
    echo "  br list --type task --parent $EPIC_ID --status pending"
    echo ""
    echo "Then for each: br task complete <TASK_ID>"
    echo ""
    exit 1
fi

# Check counts match (warn if different)
if [[ "$SPEC_TOTAL" -ne "$BEADS_TOTAL" ]]; then
    echo "WARNING: Task counts differ (spec: $SPEC_TOTAL, beads: $BEADS_TOTAL)"
    echo "This may be OK if some beads tasks don't map 1:1 to spec steps."
fi

echo "SYNC OK: All spec checkboxes and beads tasks are complete"
exit 0
```
Make it executable: `chmod +x .ralph/verify-beads-sync.sh`

### 8.5 Report Generator

Create `.ralph/report.sh`:
```bash
#!/bin/bash
# Generate final report for ralph loop

if [[ ! -f .ralph/started.txt ]]; then
    echo "error: no started.txt found"
    exit 1
fi

START=$(cat .ralph/started.txt)
END=$(cat .ralph/completed.txt 2>/dev/null || date -Iseconds)

START_SEC=$(date -d "$START" +%s)
END_SEC=$(date -d "$END" +%s)
ELAPSED=$((END_SEC - START_SEC))
HOURS=$((ELAPSED / 3600))
MINS=$(((ELAPSED % 3600) / 60))

echo "=== Ralph Loop Report ==="
echo "Started:  $START"
echo "Ended:    $END"
echo "Elapsed:  ${HOURS}h ${MINS}m"
echo ""

if [[ -f .ralph/tokens.log ]]; then
    TOTAL_INPUT=$(awk -F'input:' '{sum += $2} END {print int(sum)}' .ralph/tokens.log)
    TOTAL_OUTPUT=$(awk -F'output:' '{split($2,a," "); sum += a[1]} END {print int(sum)}' .ralph/tokens.log)
    STEPS=$(wc -l < .ralph/tokens.log)
    echo "Steps:    $STEPS"
    echo "Tokens:   $TOTAL_INPUT input + $TOTAL_OUTPUT output = $((TOTAL_INPUT + TOTAL_OUTPUT)) total"
else
    echo "Tokens:   (no tokens.log found)"
fi

echo ""
if [[ -f .ralph/context-exits.log ]]; then
    EXIT_COUNT=$(wc -l < .ralph/context-exits.log)
    echo "Context exits: $EXIT_COUNT"
    echo "  Affected steps:"
    awk -F'step:' '{split($2,a," "); print "    - " a[1]}' .ralph/context-exits.log
else
    echo "Context exits: 0"
fi
```
Make it executable: `chmod +x .ralph/report.sh`

### 8.6 Report Readiness

Calculate token budget (using chars/4 heuristic):
```bash
# Get byte counts
prompt_bytes=$(wc -c < .ralph/prompt.md)
readme_bytes=$(wc -c < .ralph/readme.md)
spec_bytes=$(wc -c < .ralph/spec.md)
total_bytes=$((prompt_bytes + readme_bytes + spec_bytes))
total_tokens=$((total_bytes / 4))
echo "Core context: ~${total_tokens} / 5000 tokens"
```

Confirm:
- [ ] Stop hook registered in settings.json
- [ ] Hook script exists and is executable
- [ ] .ralph/prompt.md exists
- [ ] .ralph/spec.md exists
- [ ] .ralph/validate-ac.sh exists and is executable
- [ ] .ralph/verify-beads-sync.sh exists and is executable
- [ ] All spec steps have inline `[TASK-xyz]` references
- [ ] **validate-ac.sh passes** (all tasks have acceptance criteria)
- [ ] **Core context ≤ 5000 tokens**

Report: "Ready for ralph" with token budget and launch command:

```
**Core context budget:**
- prompt.md: ~X tokens
- readme.md: ~Y tokens
- spec.md: ~Z tokens
- **Total: ~N / 5000 tokens** (over or under)

**Branch:** <branch-name> (from readme.md)

**Launch from:** <absolute-path-to-project-root>
```

**CRITICAL: The launch command MUST check for BOTH stop files**

Provide the complete launch command with `cd`:
```bash
cd /absolute/path/to/project && RALPH_LOOP=1 bash -c 'while [ ! -f .ralph/COMPLETE ] && [ ! -f .ralph/WAITING ]; do cat .ralph/prompt.md | claude --dangerously-skip-permissions; sleep 2; done'
```

**The `&& [ ! -f .ralph/WAITING ]` part is REQUIRED.** Without it, the loop will continue running infinitely when a WAITING file is created.

**Stop conditions:**
- `.ralph/COMPLETE` - All work done
- `.ralph/WAITING` - Human verification required (loop pauses, read file for instructions)

**Pre-launch checklist:**
- [ ] On the correct branch (create if needed: `git checkout -b <branch-name>`)
- [ ] Working directory clean (`git status`)
- [ ] Tests pass before starting

If over budget, offer to trim spec before proceeding.

### 8.7 Cleanup

Delete `.ralph/setup-state.json` - no longer needed once loop is ready.

---

## Critical Principles

**False COMPLETEs are real.** Loops can mark done while bugs persist. Mitigate:
- Every bug reproduction step becomes an explicit test item
- "Verify it works" is not enough - specify EXACT steps
- Human review after loop completion is mandatory
- **Beads acceptance criteria provide second verification layer**
- **Spec checkbox AND beads task must BOTH be marked complete**

**Verification Guardrails:**
1. **Dual tracking**: Spec.md checkboxes AND beads tasks must stay synchronized
2. **Acceptance criteria**: Every step must have testable, specific criteria
3. **Evidence required**: "It works" is never sufficient - show command output, file contents, test results
4. **Red flag detection**: Define what FALSE completion looks like for each step
5. **Review phases**: Every phase ends with aggregated verification

**When in doubt, WAITING not COMPLETE.** If any acceptance criterion cannot be mechanically verified:
- Create `.ralph/WAITING` file explaining what human verification is needed
- Do NOT mark the step complete
- Do NOT create COMPLETE file

**Context parsimony.** Core context <5K tokens. Sessions read index, pull detail as needed.

**One question at a time.** Don't overwhelm during interview.

**Save state often.** Update setup-state.json after each phase so /clear doesn't lose progress.

---

## Commit Discipline

Agents must follow strict commit rules to avoid pathological behavior (e.g., 30 duplicate commits).

### When to Commit
- After completing a numbered spec step (e.g., "7.1: Implement feature X")
- After creating WAITING file (exactly once, then exit)
- After creating COMPLETE file (exactly once, then exit)
- One commit per session maximum - batch related changes

### When NOT to Commit
- If WAITING file exists - exit immediately, no commits
- If COMPLETE file exists - exit immediately, no commits
- If your commit message would be identical to the last commit
- While polling or in any kind of loop
- For exploratory/research work with no code changes

### Commit Message Format
```
<step>: <what changed>

<optional details>
```

Example: `2.3: Add validation for user input - prevents XSS in comment field`

---

## Exit Conditions (CRITICAL)

**Check these FIRST, before any work:**

```bash
# At session start, BEFORE reading spec or doing any work:
if [ -f .ralph/WAITING ]; then
    echo "WAITING file exists - human action required"
    cat .ralph/WAITING
    # EXIT IMMEDIATELY - DO NOT COMMIT, DO NOT LOOP
    exit 0
fi

if [ -f .ralph/COMPLETE ]; then
    echo "Loop already complete"
    # EXIT IMMEDIATELY - DO NOT COMMIT
    exit 0
fi
```

**The loop script already checks for these files.** But if an agent finds itself running when WAITING/COMPLETE exists:
1. Do NOT make any commits
2. Do NOT do any work
3. Report what you see
4. Exit immediately

**Creating WAITING:** When you create a WAITING file (blocked on human action):
1. Write the WAITING file with clear instructions
2. Commit once: `WAITING: <reason>`
3. Push
4. Exit immediately - the loop will stop

**Never loop on WAITING.** If you detect you've already created WAITING, exit without committing.
