---
name: beads-task-elaboration
description: "Elaborate ideas into self-documenting beads with full context for future sessions"
argument-hint: [epic:BEADS-XXX | conversation | file-path | "clipboard"]
---

# Beads Task Elaboration

**Input:** $ARGUMENTS

This command serves two purposes:

1. **Creation Mode**: Transform ideas/plans into a new epic with elaborated tasks
2. **Update Mode**: Elaborate existing tasks under an epic created by `/beads-spec-to-beads`

---

## Determine Mode

**Update Mode** (elaborate existing beads):
- Argument starts with `epic:` -> e.g., `epic:BEADS-123`
- Processes all tasks under that epic systematically

**Creation Mode** (create new epic):
- Argument is `conversation`, file path, or `clipboard`
- No argument -> use current conversation context
- Creates a new epic with fully elaborated tasks

---

## The Goal

Create beads that your **future self** (or another person/agent) can pick up and execute without needing the original conversation context. Every bead should be self-contained with all the information needed to understand and complete it.

---

## Elaboration Process

### 1. Gather the Raw Material

Identify all actionable items from the source:
- Goals and objectives
- Requirements and deliverables
- Problems to solve
- Improvements to make
- Research or discovery needed
- Documentation needs (guides, runbooks, specs, training materials)
- Dependencies on external parties
- Decisions that need to be made

### 2. Elaborate Each Item

For each item, expand it with:

**Background**
- Why does this task exist?
- What problem does it solve?
- What triggered this work?

**Context**
- What's the current state?
- What related systems, people, or processes are involved?
- What assumptions are we making?
- What constraints exist (budget, timeline, resources)?

**Approach**
- How should this be done?
- What's the recommended strategy?
- Are there alternative approaches? Why this one?
- Who needs to be involved?

**Considerations**
- Risks and mitigation strategies
- Dependencies on external parties or decisions
- Resource requirements (time, money, people, tools)
- Potential blockers or unknowns
- What could go wrong?

**Acceptance Criteria**
- What does "done" look like?
- How do we verify success?
- What are the measurable outcomes?

**Goal Connection**
- How does this serve the project's overarching goals?
- What value does this deliver to users?
- Why is this worth doing now?

### 3. Structure into Tasks and Subtasks

Break down into appropriately-sized units:

**Epic** (large, multi-day effort)
- Multiple related features or a major initiative
- Contains multiple tasks

**Task** (hours to a day)
- Completable in a focused session
- Has clear deliverable

**Subtask** (if needed)
- Very granular steps within a task
- Usually not needed if tasks are well-scoped

### 4. Overlay Dependency Structure

For each bead, specify:
- **Depends on**: What must be done first?
- **Blocks**: What does this enable?
- **Parallel candidates**: What can run simultaneously?

---

## Update Mode Workflow

Use this when elaborating existing tasks created by `/beads-spec-to-beads`.

### 1. Get the Epic and Its Tasks

```bash
# Set the epic ID from your argument
EPIC_ID="BEADS-123"  # Replace with actual ID from epic:BEADS-123

# List all tasks under the epic
br list --parent=$EPIC_ID --json | jq '.[] | {id, title, description}'

# Or get a quick overview
br show $EPIC_ID
```

### 2. Review Each Task's Current State

For each task, check what detail already exists:

```bash
br show $TASK_ID --json | jq '{title, description}'
```

### 3. Elaborate Each Task Systematically

For each task under the epic, apply the elaboration template:

```bash
# Write elaborated description to temp file
cat > /tmp/task-elaboration.md << 'EOF'
## Background
[Why this task exists - reference original spec/PRD if applicable]

## Current State
[What exists now, starting point for this work]

## Approach
1. [Step one]
2. [Step two]
3. [Step three]

## Considerations
- Risk: [what could go wrong]
- Dependencies: [external parties, decisions needed]
- Resources: [time, tools needed]

## Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Another criterion]

## Goal Connection
[How this serves the epic's objectives]

## Notes
[Links, contacts, gotchas for future self]
EOF

# Update the task with elaborated description
br update $TASK_ID --description="$(cat /tmp/task-elaboration.md)"
```

### 4. Batch Processing Pattern

Process all tasks under an epic:

```bash
EPIC_ID="BEADS-123"

# Get all task IDs
TASKS=$(br list --parent=$EPIC_ID --json | jq -r '.[].id')

echo "Tasks to elaborate:"
for TASK in $TASKS; do
  TITLE=$(br show $TASK --json | jq -r '.title')
  echo "  - $TASK: $TITLE"
done

# Then elaborate each one using the pattern above
```

### 5. Verify Elaboration Completeness

After elaborating all tasks:

```bash
# Check each task has substantial description
for TASK in $TASKS; do
  DESC_LEN=$(br show $TASK --json | jq '.description | length')
  TITLE=$(br show $TASK --json | jq -r '.title')
  echo "$TASK: $TITLE - $DESC_LEN chars"
done
```

### Update Mode Output

```markdown
## Task Elaboration Complete (Update Mode)

**Epic**: $EPIC_ID - [Epic Title]
**Tasks elaborated**: X

### Elaboration Summary

| Task ID | Title | Before | After | Status |
|---------|-------|--------|-------|--------|
| BEADS-124 | Setup database | 45 chars | 892 chars | Elaborated |
| BEADS-125 | Implement API | 38 chars | 1,204 chars | Elaborated |
| BEADS-126 | Add tests | 22 chars | 567 chars | Elaborated |

### Next Step
Run `/beads-validate-beads epic:$EPIC_ID` to verify readiness for implementation.
```

---

## Creation Mode Workflow

Use this when creating a new epic from ideas, plans, or conversation context.

### Two Concepts: Hierarchy vs Dependencies

- **`--parent`**: Organizational hierarchy - "this task belongs to this epic"
- **`br dep add`**: Execution order - "this task must complete before that task"

A task can belong to an epic (`--parent`) while also depending on tasks from other epics (`br dep add`).

### Creation Workflow

```bash
# 1. Create epic first and capture the ID
br create --title="Epic: [Name]" --type=epic --priority=1 \
  --description="[Full elaborated context goes here]"
# Note the returned ID (e.g., BEADS-042)

# 2. Create tasks under the epic using --parent
br create --title="Task: [Name]" --type=task --priority=2 \
  --parent=BEADS-042 \
  --description="[Self-documenting description]"

# 3. Add execution dependencies between tasks
br dep add <later-task-id> <earlier-task-id>
```

### Example: Marketing Analytics Epic

```bash
# Create the epic
br create --title="Epic: Marketing Analytics Setup" --type=epic --priority=1 \
  --description="Get tracking and analytics dialed in for the website..."
# Returns: BEADS-050

# Create tasks under it
br create --title="Task: Audit current tracking" --type=task --priority=2 \
  --parent=BEADS-050 \
  --description="Review what's currently in place..."
# Returns: BEADS-051

br create --title="Task: Define KPIs and events to track" --type=task --priority=2 \
  --parent=BEADS-050 \
  --description="Work with stakeholders to define..."
# Returns: BEADS-052

br create --title="Task: Implement tracking code" --type=task --priority=2 \
  --parent=BEADS-050 \
  --description="Add the tracking snippets..."
# Returns: BEADS-053

# Add dependencies (implementation depends on KPIs being defined)
br dep add BEADS-053 BEADS-052
br dep add BEADS-052 BEADS-051
```

---

## Self-Documenting Description Template

Each bead description should include:

```markdown
## Background
[Why this exists, what triggered it]

## Current State
[What exists now, what's the problem or opportunity]

## Approach
[How to accomplish this, strategy, reasoning]

## Considerations
- Risk: [what could go wrong]
- Dependencies: [external parties, decisions needed]
- Resources: [time, budget, people, tools needed]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [How we verify success]

## Goal Connection
[How this serves project objectives]

## Dependencies
- Depends on: [list of blocking tasks]
- Blocks: [list of tasks this enables]

## Notes
[Anything else future self needs to know - contacts, links, context]
```

---

## Quality Checks

Before finalizing, verify:

- [ ] **Standalone clarity**: Could someone understand this without the original conversation?
- [ ] **Actionable**: Is it clear what to do?
- [ ] **Right-sized**: Can each task be completed in a focused session?
- [ ] **Dependencies captured**: Is the order clear?
- [ ] **Reasoning included**: Is the "why" documented?
- [ ] **Acceptance defined**: Do we know when it's done?

---

## Output Format

After creating beads, report:

```markdown
## Task Elaboration Summary

**Source**: [Conversation / File / etc.]
**Beads created**: X (Y epics, Z tasks)

### Epic: [Name] (BEADS-XXX)
Purpose: [Brief description]

Tasks:
1. BEADS-XXX: [Title]
   - Depends on: none
   - Blocks: BEADS-YYY

2. BEADS-YYY: [Title]
   - Depends on: BEADS-XXX
   - Blocks: BEADS-ZZZ

[...]

### Dependency Graph
```
BEADS-001 -> BEADS-002 -> BEADS-003
                       \
                         BEADS-004 (parallel)
```

### Recommended Starting Point
Begin with BEADS-XXX: [Title] - it has no dependencies and unblocks the most work.
```

---

## Why Self-Documenting Matters

- **Context loss**: Conversations get compacted, sessions end, memory fades
- **Handoffs**: Another agent (or human) may pick this up
- **Debugging**: When something goes wrong, you need to understand the intent
- **Auditing**: Future review of why decisions were made
- **Resumption**: Picking up work days or weeks later

Invest the time now. Your future self will thank you.
