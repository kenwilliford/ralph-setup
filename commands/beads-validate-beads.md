---
name: beads-validate-beads
description: "Validate and optimize beads before implementation - operate in plan space"
argument-hint: [epic:BEADS-XXX | "all" | empty for current plan]
author: Mike Williamson (@mikez93)
---

# Validate Beads

**Scope:** $ARGUMENTS

Before implementing anything, validate the plan. It's far cheaper to fix problems in **plan space** than in code space.

> "It's a lot easier and faster to operate in 'plan space' before we start implementing these things!"

---

## Determine Scope

- `epic:BEADS-XXX` -> Validate specific epic and its children
- `all` -> Validate all open beads
- No argument -> Validate current plan (`br list --status=open`)

---

## Phase 1: Automated Structure Validation

Run these checks programmatically before manual review.

### 1.1 Get the Beads

```bash
# If epic ID provided
EPIC_ID="BEADS-123"
br show $EPIC_ID
br list --parent=$EPIC_ID --json

# If validating all open beads
br list --status=open --json
```

### 1.2 Dependency Validation

```bash
# Visualize the dependency tree
br dep tree $EPIC_ID

# Check for circular dependencies (will error if cycles exist)
br dep cycles

# Find orphaned tasks (tasks without parents that should have them)
br list --status=open --json | jq '[.[] | select(.parent == null and .type == "task")] | length'
```

### 1.3 Structural Completeness

```bash
# Count children under epic
CHILD_COUNT=$(br show $EPIC_ID --json | jq '.children | length')
echo "Epic has $CHILD_COUNT children"

# Verify no empty epics
if [ "$CHILD_COUNT" -eq 0 ]; then
  echo "WARNING: Epic has no children"
fi
```

### Automated Check Results

```markdown
## Structure Validation

| Check | Result | Status |
|-------|--------|--------|
| Epic has children | [count] tasks | pass/fail |
| No circular dependencies | Pass/Fail | pass/fail |
| No orphaned tasks | [count] orphans | pass/warn |
| Dependency tree valid | Pass/Fail | pass/fail |
```

---

## Phase 2: Quality Metrics (Strongly Suggested)

These metrics indicate elaboration quality. They are **guidelines, not strict requirements** - some tasks may legitimately have brief descriptions or single acceptance criteria.

### 2.1 Description Length Check

```bash
# Check description lengths for all tasks
TASKS=$(br list --parent=$EPIC_ID --json | jq -r '.[].id')

echo "Description Length Analysis:"
for TASK in $TASKS; do
  DESC_LEN=$(br show $TASK --json | jq '.description | length')
  TITLE=$(br show $TASK --json | jq -r '.title')

  if [ "$DESC_LEN" -lt 200 ]; then
    echo "WARN $TASK: $TITLE - $DESC_LEN chars (consider elaborating)"
  elif [ "$DESC_LEN" -lt 500 ]; then
    echo "OK   $TASK: $TITLE - $DESC_LEN chars (adequate)"
  else
    echo "OK   $TASK: $TITLE - $DESC_LEN chars (well elaborated)"
  fi
done
```

### 2.2 Acceptance Criteria Check

```bash
# Count acceptance criteria (checkbox items) in descriptions
for TASK in $TASKS; do
  DESC=$(br show $TASK --json | jq -r '.description')
  CRITERIA_COUNT=$(echo "$DESC" | grep -c '\- \[ \]' || echo "0")
  TITLE=$(br show $TASK --json | jq -r '.title')

  if [ "$CRITERIA_COUNT" -lt 1 ]; then
    echo "WARN $TASK: $TITLE - No acceptance criteria found"
  elif [ "$CRITERIA_COUNT" -lt 2 ]; then
    echo "OK   $TASK: $TITLE - $CRITERIA_COUNT criterion (minimal)"
  else
    echo "OK   $TASK: $TITLE - $CRITERIA_COUNT criteria"
  fi
done
```

### Quality Metrics Guidelines

| Metric | Suggested Minimum | Notes |
|--------|-------------------|-------|
| Description length | 200+ chars | Brief tasks may be exceptions |
| Acceptance criteria | 1-2 items | Simple tasks may need only 1 |
| Background section | Present | Explains "why" |
| Approach section | Present | Explains "how" |

**Note**: These are heuristics. A well-scoped simple task with 150 chars and 1 criterion may be perfectly valid. Use judgment.

---

## Phase 3: Manual Review Checklist

For **each bead**, verify:

### Coherence
- [ ] Title is clear and descriptive
- [ ] Description makes sense standalone (no conversation context needed)
- [ ] Scope is appropriate (1-4 hours of focused work)
- [ ] "Done" state is obvious

### Dependencies
- [ ] All dependencies are captured
- [ ] No hidden dependencies missed
- [ ] Dependency order is correct
- [ ] Parallel opportunities identified

### Feasibility
- [ ] Approach is technically sound
- [ ] No hidden complexities
- [ ] Skills/knowledge available to complete
- [ ] Integrates cleanly with existing code

### Value
- [ ] Delivers user value or enables it
- [ ] Not over-engineered
- [ ] Not under-engineered
- [ ] Worth doing now (not premature)

### Completeness
- [ ] Testing is accounted for
- [ ] Documentation needs identified
- [ ] Deployment/migration steps if needed
- [ ] Review task exists at end of epic

---

## Phase 4: Red Flags Detection

Watch for these issues:

| Red Flag | Symptom | Resolution |
|----------|---------|------------|
| **Giant beads** | Estimated >4 hours | Split into smaller tasks |
| **Vague beads** | "Improve X" without specifics | Add concrete criteria |
| **Orphan beads** | No clear goal connection | Link to epic or remove |
| **Circular deps** | A->B->C->A | Restructure dependencies |
| **Missing error handling** | Only happy path | Add failure considerations |
| **Scope creep** | Nice-to-haves mixed in | Separate or defer |
| **Premature optimization** | Optimizing unknowns | Defer until needed |

---

## Phase 5: Beads Viewer Analysis (Optional)

If you have `bv` (beads_viewer) installed, use it for additional AI-powered analysis:

```bash
# Check if bv is available
if command -v bv &>/dev/null; then
  # Get AI-recommended execution order
  bv --robot-plan

  # Get insights and potential issues
  bv --robot-insights
else
  echo "bv not installed - skipping AI analysis (this is optional)"
  echo "Install from: https://github.com/kenwilliford/beads_viewer"
fi
```

Review the analysis for:
- Suggested reordering
- Identified risks
- Missing tasks
- Optimization opportunities

**Note:** `bv` is optional. All critical validation is covered by Phases 1-4.

---

## Phase 6: Revision Actions

If issues found, fix them:

```bash
# Update description or title
br update <id> --title="Clearer title"
br update <id> --description="Better description"
br update <id> --description="$(cat /tmp/revised-desc.md)"

# Change priority
br update <id> --priority=1

# Fix dependencies
br dep add <id> <depends-on>
br dep remove <id> <no-longer-depends-on>

# Split a giant bead
br create --title="Part 1: ..." --type=task --parent=$EPIC_ID
br create --title="Part 2: ..." --type=task --parent=$EPIC_ID
br close <original-id> --reason="Split into smaller tasks"

# Remove unnecessary work
br close <id> --reason="Not needed - simplifying approach"

# Fix orphaned task
br update <orphan-id> --parent=$EPIC_ID
```

---

## Phase 7: Final Verdict

After all checks, provide a clear GO/NO-GO decision.

### Verdict Format

```markdown
## Validation Summary

**Scope**: Epic $EPIC_ID - [Title]
**Tasks validated**: X
**Issues found**: Y
**Issues resolved**: Z

### Automated Checks

| Check | Result |
|-------|--------|
| Children attached | X tasks |
| No circular deps | Pass |
| No orphaned tasks | 0 orphans |
| Dependency tree | Valid |

### Quality Metrics

| Metric | Result | Notes |
|--------|--------|-------|
| Avg description length | 847 chars | Well elaborated |
| Tasks with acceptance criteria | 8/10 | 2 tasks minimal |
| Tasks with approach section | 10/10 | Complete |

### Issues Found & Resolved
1. BEADS-124: Title was vague -> Updated to specific action
2. BEADS-127: Missing dependency on BEADS-125 -> Added
3. BEADS-129: Too large (~8 hours) -> Split into 2 tasks

### Remaining Concerns
- BEADS-126: Technical uncertainty around caching - may need spike
- Timeline may be optimistic if caching proves complex

### Confidence Assessment

| Dimension | Level | Notes |
|-----------|-------|-------|
| Plan coherence | High | Clear structure and dependencies |
| Technical feasibility | Medium | Caching approach uncertain |
| Dependency accuracy | High | Graph verified |
| Completeness | High | All requirements covered |

---

## VERDICT: READY FOR IMPLEMENTATION

**Recommendation**: Plan is ready. Consider spiking the caching approach in BEADS-126 first to reduce risk.

**Start with**: `br ready` -> BEADS-124, BEADS-125 (no blockers)
```

### Verdict Options

**READY FOR IMPLEMENTATION**
- All automated checks pass
- No blocking issues remain
- Confidence is medium or higher across dimensions

**CONDITIONALLY READY**
- Minor issues exist but won't block progress
- Specific tasks flagged for extra attention
- Can proceed with caution

**NOT READY - X issues to fix**
- Blocking issues exist
- List specific issues that must be resolved
- Re-run validation after fixes

---

## Cost of Change Reality Check

| Stage | Cost to Fix |
|-------|-------------|
| Plan space | Minutes |
| Implementation | Hours |
| Code review | Hours-Days |
| Post-merge | Days |
| Production | Days-Weeks |

Every issue caught now saves 10-100x the effort later.

---

## When to Re-Validate

- After significant plan changes
- Before starting a long autonomous execution session
- When requirements change mid-stream
- After `/beads-task-elaboration` updates
- When you feel uncertain about the approach

---

## Integration with Pipeline

This is Step 3 in the beads workflow:

```
1. /beads-spec-to-beads  -> Creates structure (epic, tasks, dependencies)
2. /beads-task-elaboration -> Adds detail (self-documenting context)
3. /beads-validate-beads -> Verifies quality (this command)
4. Implementation        -> Systematic work through the beads
```

After validation passes, start working with `br ready`.
