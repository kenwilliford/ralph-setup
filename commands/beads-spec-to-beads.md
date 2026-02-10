---
name: beads-spec-to-beads
description: "Convert specs into Beads epics/tasks with full PRD detail preserved"
argument-hint: [spec-file-path | spec-directory | leave blank to use current context]
---

# Spec-to-Beads Conversion

Convert a spec/PRD into a properly-structured Beads hierarchy with correct parent-child relationships and dependencies.

## Input

$ARGUMENTS

- If no argument: use current conversation context (e.g., an approved spec)
- If a file: create one epic from that spec
- If a directory: create one epic per spec file

---

## The Golden Rule

> **Dependencies and hierarchy must be mapped BEFORE creating any beads.**

Creating beads without a dependency graph leads to orphaned tasks, missing relationships, and broken execution order. Analyze first, create second.

---

## Phase 1: Analyze the Spec (Read-Only)

**Do NOT create any beads yet.** This phase is pure analysis.

### 1.1 Identify Work Phases

Group the spec into sequential phases where later phases depend on earlier ones:

```
Phase 1: Foundation (no dependencies)
  - Database schema, config, project setup

Phase 2: Core Implementation (depends on Phase 1)
  - Main features, business logic, APIs

Phase 3: Integration (depends on Phase 2)
  - Connect components, end-to-end flows

Phase 4: Polish (depends on Phase 3)
  - Error handling, edge cases, UX refinement

Phase 5: Verification (depends on Phase 4)
  - Testing, documentation, review
```

### 1.2 Extract Tasks from Each Phase

For each phase, identify discrete deliverables. Each task should be:
- **Completable in 1-4 hours** of focused work
- **Independently testable** - you can verify it works
- **Clearly scoped** - obvious when it's done

### 1.3 Map the Dependency Graph

Draw the relationships BEFORE creating anything:

```
EPIC: Feature X
│
├── Phase 1: Foundation
│   ├── Task A: Database schema (no deps)
│   └── Task B: Config setup (no deps, parallel with A)
│
├── Phase 2: Core (depends on Phase 1)
│   ├── Task C: User API (depends on A)
│   ├── Task D: Auth logic (depends on A, B)
│   └── Task E: Business rules (depends on A)
│
├── Phase 3: Integration (depends on Phase 2)
│   └── Task F: End-to-end flow (depends on C, D, E)
│
└── Phase 4: Verification (depends on Phase 3)
    └── Task G: Review & Testing (depends on F)
```

### 1.4 Validate the Graph

Before proceeding, verify:
- [ ] No circular dependencies (A->B->C->A)
- [ ] Every task has a clear "done" state
- [ ] Task sizes are roughly equal (1-4 hours each)
- [ ] All spec requirements are covered
- [ ] Nothing is orphaned (every task connects to the epic)

---

## Phase 2: Create the Epic

**Now** you can start creating beads. Always capture the ID.

### 2.1 Create Epic and Capture ID

```bash
# Create the epic and capture its ID
EPIC_ID=$(br create \
  --title="Epic: [Feature Name]" \
  --type=epic \
  --priority=1 \
  --description="$(cat <<'EOF'
## Overview
[One paragraph: what this epic delivers and why]

## Spec Reference
Source: `[path/to/spec.md]`

## Phases
1. **Foundation**: [brief description]
2. **Core**: [brief description]
3. **Integration**: [brief description]
4. **Verification**: [brief description]

## Success Criteria
- [ ] [High-level criterion 1]
- [ ] [High-level criterion 2]
- [ ] All tasks closed, tests passing, reviewed
EOF
)" --silent)

echo "Created epic: $EPIC_ID"
```

**Important flags**:
- `--silent` returns only the ID (best for scripting)
- `--json` returns full object (use `| jq -r '.id'` to extract ID)

---

## Phase 3: Create Tasks Under the Epic

**CRITICAL**: Every task MUST use `--parent=$EPIC_ID`

### 3.1 Foundation Tasks (No Dependencies)

```bash
# Task with no dependencies - foundation work
TASK_A=$(br create \
  --title="Task: [Descriptive Name]" \
  --type=task \
  --priority=2 \
  --parent=$EPIC_ID \
  --description="$(cat <<'EOF'
## Background
[Why this task exists - what spec requirement it addresses]

## Spec Reference
See: `[path/to/spec.md#section]`

## Deliverable
[Concrete output: file, feature, config, etc.]

## Approach
1. [Step one]
2. [Step two]
3. [Step three]

## Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Another criterion]

## Notes
[Any context future self needs: gotchas, links, contacts]
EOF
)" --silent)

echo "Created task A: $TASK_A"
```

### 3.2 Dependent Tasks (Specify Dependencies at Creation)

Use `--deps` to declare dependencies at creation time:

```bash
# Task depending on one other task
TASK_C=$(br create \
  --title="Task: [Name]" \
  --type=task \
  --priority=2 \
  --parent=$EPIC_ID \
  --deps="$TASK_A" \
  --description="..." \
  --silent)

# Task depending on multiple tasks
TASK_F=$(br create \
  --title="Task: [Name]" \
  --type=task \
  --priority=2 \
  --parent=$EPIC_ID \
  --deps="$TASK_C,$TASK_D,$TASK_E" \
  --description="..." \
  --silent)

echo "Created task C: $TASK_C (depends on $TASK_A)"
echo "Created task F: $TASK_F (depends on C, D, E)"
```

### 3.3 Using Body Files for Complex Descriptions

For detailed tasks, use `--body-file`:

```bash
# Write description to temp file
cat > /tmp/task-desc.md << 'EOF'
## Background
This task implements the user authentication flow as specified in the PRD.

## Spec Reference
See: `specs/auth-feature.md#oauth-flow`

## Current State
- Database schema exists (from Task A)
- No auth logic yet

## Deliverable
- `src/auth/oauth.ts` - OAuth provider integration
- `src/auth/session.ts` - Session management
- Unit tests with >80% coverage

## Approach
1. Set up OAuth provider client
2. Implement token exchange flow
3. Create session storage
4. Add refresh token logic
5. Write unit tests

## API Contract
```typescript
interface AuthService {
  login(provider: string): Promise<Session>;
  refresh(token: string): Promise<Session>;
  logout(sessionId: string): Promise<void>;
}
```

## Acceptance Criteria
- [ ] OAuth flow works with Google provider
- [ ] Sessions persist across page refresh
- [ ] Token refresh happens automatically
- [ ] Unit tests pass

## Edge Cases
- Expired refresh token -> redirect to login
- Network failure during auth -> retry with backoff
- Invalid state parameter -> reject and log

## Dependencies
- **Depends on**: Task A (database schema)
- **Blocks**: Task F (end-to-end flow)
EOF

# Create task with body file
TASK_D=$(br create \
  --title="Task: Implement OAuth authentication" \
  --type=task \
  --priority=2 \
  --parent=$EPIC_ID \
  --deps="$TASK_A,$TASK_B" \
  --description="$(cat /tmp/task-desc.md)" \
  --silent)
```

### 3.4 Review & Verification Task (Always Last)

Every epic should end with a verification task:

```bash
TASK_REVIEW=$(br create \
  --title="Task: Review & Verification" \
  --type=task \
  --priority=2 \
  --parent=$EPIC_ID \
  --deps="$TASK_F" \
  --description="$(cat <<'EOF'
## Purpose
Final verification before closing the epic.

## Checklist
- [ ] All tasks in epic are closed
- [ ] Tests pass: `[test command]`
- [ ] Lint passes: `[lint command]`
- [ ] Type check passes: `[type command]`
- [ ] Code review completed
- [ ] Documentation updated if needed

## Spec Compliance
Verify against original spec: `[path/to/spec.md]`

## Close Procedure
1. Run all quality checks
2. Review code changes
3. Address any findings
4. Close this task
5. Close the epic
EOF
)" --silent)

echo "Created review task: $TASK_REVIEW"
```

---

## Phase 4: Validate the Structure

**Do NOT report success until validation passes.**

### 4.1 Verify Epic Has Children

```bash
# Check the epic has children attached
CHILD_COUNT=$(br show $EPIC_ID --json | jq '.children | length')
echo "Epic has $CHILD_COUNT children"

if [ "$CHILD_COUNT" -eq 0 ]; then
  echo "ERROR: Epic has no children! Tasks may be orphaned."
  exit 1
fi
```

### 4.2 Visualize Dependency Tree

```bash
# Show the dependency structure
br dep tree $EPIC_ID
```

Expected output should show a proper hierarchy:
```
Epic: Feature X (abc123)
├── Task: Database schema (def456) [ready]
├── Task: Config setup (ghi789) [ready]
├── Task: User API (jkl012) [blocked by def456]
├── Task: Auth logic (mno345) [blocked by def456, ghi789]
└── Task: Review (pqr678) [blocked by ...]
```

### 4.3 Check for Orphaned Tasks

```bash
# Find any tasks without parents (potential orphans)
br list --status=open --json | jq '[.[] | select(.parent == null and .type == "task")] | .[] | {id, title}'
```

If this returns tasks that should be under the epic, fix them:
```bash
br update <orphan-id> --parent=$EPIC_ID
```

### 4.4 Verify No Circular Dependencies

```bash
# This will error if there are cycles
br dep cycles
```

---

## Phase 5: Report Results

After validation passes, report:

```markdown
## Spec-to-Beads Conversion Complete

**Source**: `[spec file path]`
**Epic**: $EPIC_ID - [Epic Title]
**Tasks Created**: [count]

### Structure

```
$EPIC_ID: Epic: [Name]
├── $TASK_A: [Title] (no deps) ready
├── $TASK_B: [Title] (no deps) ready
├── $TASK_C: [Title] (deps: A) -> blocked
├── $TASK_D: [Title] (deps: A, B) -> blocked
├── $TASK_E: [Title] (deps: A) -> blocked
├── $TASK_F: [Title] (deps: C, D, E) -> blocked
└── $TASK_REVIEW: Review & Verification (deps: F) -> blocked
```

### Dependency Graph
```
[A]──┬──>[C]──┐
     │        ├──>[F]──>[Review]
[B]──┴──>[D]──┤
         [E]──┘
```

### Validation
- [x] Epic has children: [count] tasks
- [x] No orphaned tasks
- [x] No circular dependencies
- [x] Dependency tree valid

### Ready to Work
Start with: `br ready`

Currently unblocked:
- $TASK_A: [Title]
- $TASK_B: [Title]

### Next Steps
1. Run `br ready` to see available work
2. Use `/beads-task-elaboration` on each task to add detailed context
3. Use `/beads-validate-beads` before starting implementation
```

---

## Quick Reference

### Priority Scale
| Priority | Meaning | Use For |
|----------|---------|---------|
| P0 | Critical | Blocking issues, outages |
| P1 | High | Epic-level, important features |
| P2 | Medium | Standard tasks (default) |
| P3 | Low | Nice-to-haves |
| P4 | Backlog | Future consideration |

### Essential Flags
| Flag | Purpose |
|------|---------|
| `--parent=ID` | **Required** for all tasks - links to epic |
| `--deps="ID1,ID2"` | Declare dependencies at creation |
| `--silent` | Return only the ID (for scripting) |
| `--json` | Return full object |
| `--description="$(cat PATH)"` | Read description from file |
| `--type=epic\|task` | Issue type |

### Common Patterns

**Capture ID and create dependent task:**
```bash
TASK_A=$(br create --title="Task A" --parent=$EPIC --silent)
TASK_B=$(br create --title="Task B" --parent=$EPIC --deps="$TASK_A" --silent)
```

**Fix orphaned task:**
```bash
br update <task-id> --parent=$EPIC_ID
```

**Add missing dependency after creation:**
```bash
br dep add <later-task> <earlier-task>
```

---

## Checklist Before Finishing

- [ ] Dependency graph was mapped BEFORE creating beads
- [ ] Every task uses `--parent=$EPIC_ID`
- [ ] Dependencies specified via `--deps` at creation
- [ ] Each task has description with spec reference
- [ ] Review & Verification task is last in chain
- [ ] `br dep tree` shows correct structure
- [ ] No orphaned tasks
- [ ] No circular dependencies
- [ ] Report includes epic ID, task IDs, and dependency graph

---

## Integration with Other Commands

This command produces the **structure**. Use these commands next:

1. **`/beads-task-elaboration`** - Add detailed, self-documenting context to each task
2. **`/beads-validate-beads`** - Verify the plan before implementation
