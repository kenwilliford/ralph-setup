# Examples

Example specs and workflows demonstrating ralph-setup patterns.

## Example: Simple Bug Fix Spec

```markdown
# Spec: Fix login timeout

**Branch:** `ralph-fix-login-timeout`

## Goal

Users report being logged out after 5 minutes of inactivity. The session
timeout should be 30 minutes, matching the cookie expiry.

## Done When

- [ ] Session stays alive for 25+ minutes of inactivity
- [ ] Session expires after 35 minutes of inactivity
- [ ] Existing active sessions are not disrupted by the fix
- [ ] All auth tests pass

## Implementation Plan

### Phase 1: Investigate
- [ ] **1.1** Find where session timeout is configured
- [ ] **1.2** Identify the mismatch between cookie and session TTL
- [ ] **1.R** Review: root cause documented in notes

### Phase 2: Fix
- [ ] **2.1** Update session timeout to 30 minutes
- [ ] **2.2** Add regression test for timeout value
- [ ] **2.R** Review: all auth tests pass

### Phase 3: Finalize
- [ ] **3.1** All tests pass
- [ ] **3.2** Log "COMPLETE" in Progress Log
- [ ] **3.3** Create `.ralph/COMPLETE` file

## Progress Log

| Session | Item | Result |
|---------|------|--------|
| 1 | | |

## Stuck Flags

| Item | Tried | Failed Because | Try Next |
|------|-------|----------------|----------|
| | | | |
```

## Example: Feature Spec

```markdown
# Spec: Add CSV export

**Branch:** `ralph-csv-export`

## Goal

Add a "Download CSV" button to the dashboard that exports the current
filtered view as a CSV file.

## Done When

- [ ] Button appears in dashboard toolbar
- [ ] CSV contains all visible columns
- [ ] Filters are applied (only visible rows exported)
- [ ] File downloads with correct name: `export-YYYY-MM-DD.csv`
- [ ] Works with 10,000+ rows without browser hang

## Implementation Plan

### Phase 1: Backend
- [ ] **1.1** Add GET /api/export/csv endpoint
- [ ] **1.2** Implement CSV serialization with current filters
- [ ] **1.3** Add streaming for large datasets
- [ ] **1.R** Review: endpoint returns valid CSV for test data

### Phase 2: Frontend
- [ ] **2.1** Add download button to toolbar
- [ ] **2.2** Wire button to API endpoint with current filters
- [ ] **2.3** Show loading state during download
- [ ] **2.R** Review: button works end-to-end

### Phase 3: Edge Cases
- [ ] **3.1** Handle empty result set (show message, don't download)
- [ ] **3.2** Handle special characters in data (proper escaping)
- [ ] **3.R** Review: edge cases handled

### Phase 4: Finalize
- [ ] **4.1** All tests pass
- [ ] **4.2** Log "COMPLETE" in Progress Log
- [ ] **4.3** Create `.ralph/COMPLETE` file

## Progress Log

| Session | Item | Result |
|---------|------|--------|
| 1 | | |

## Stuck Flags

| Item | Tried | Failed Because | Try Next |
|------|-------|----------------|----------|
| | | | |
```

## Tips for Writing Good Specs

1. **Be specific in "Done When"** — exact scenarios, not vague goals
2. **Keep steps atomic** — one thing per checkbox, completable in one session
3. **End every phase with a review step** (`.R`)
4. **Put detailed criteria in beads** — spec is an index, beads hold detail
5. **Include edge cases as explicit steps** — not assumptions
