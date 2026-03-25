# Ralph Architecture

How the ralph loop system works, from concept to implementation.

## Core Concept

Ralph is an **external bash loop** that spawns fresh Claude Code sessions to work through a specification one step at a time. Each iteration:

1. Pipes a `prompt.md` file into a fresh `claude` session
2. The session reads the spec, picks the first incomplete step, does it
3. The session commits, pushes, and exits
4. The loop restarts with a fresh context window

```
┌─────────────────────────────────────────────────────────┐
│                     bash while loop                      │
│                                                          │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────┐   │
│   │  Session 1   │   │  Session 2   │   │ Session N │   │
│   │  Step 1.1    │──>│  Step 1.2    │──>│ COMPLETE  │   │
│   │  commit+exit │   │  commit+exit │   │ exit      │   │
│   └──────────────┘   └──────────────┘   └──────────┘   │
│                                                          │
│   State persists in: git, .ralph/spec.md                 │
└─────────────────────────────────────────────────────────┘
```

## Why Fresh Context?

> "Context windows are arrays...you got to think of context windows as arrays because they are."
> — Geoffrey Huntley

Claude Code auto-compacts conversation history at ~80% context usage. This compaction is lossy — the model decides what to summarize, introducing drift. By starting fresh each iteration:

- **No compaction drift**: Every session starts with the same deterministic context
- **Maximum working space**: Core context is ~5K tokens, leaving 195K for actual work
- **No accumulated confusion**: Previous session's debugging tangents don't pollute the next one
- **Clean failure recovery**: If a session goes wrong, the next one starts clean

## System Components

### 1. The Prompt (`prompt.md`)

The prompt is piped into each Claude session via stdin. It's the "deterministic malloc" — the same instructions every time. It tells the session to:

- Read the spec and readme
- Pick the first incomplete step
- Do that ONE step
- Commit and exit

The `/ralph-setup` command generates this prompt tailored to your project.

### 2. The Spec (`.ralph/spec.md`)

A minimal index of work to be done. Each step is a checkbox with acceptance criteria:

```markdown
- [ ] **1.1** Create database schema
  - AC: migration file exists at db/migrations/
  - AC: schema matches ERD from spec
- [ ] **1.2** Add validation logic
  - AC: rejects invalid input with 400 status
  - AC: unit tests pass
- [ ] **1.R** Review: tests pass, no bugs
  - AC: `npm test` exits 0
  - AC: no obvious bugs in code review
```

The spec stays under ~4000 tokens to preserve context budget.

**With `--beads`:** Spec steps use a minimal format with task ID references instead of inline acceptance criteria:
```markdown
- [ ] **1.1** Create database schema [TASK-abc]
- [ ] **1.2** Add validation logic [TASK-def]
- [ ] **1.R** Review: tests pass, no bugs [TASK-ghi]
```
Detailed criteria live in beads tasks, fetched on-demand via `br show TASK-xyz`.

### 3. The Readme (`.ralph/readme.md`)

A lookup table that points to reference docs. It "teases the latent space" — giving Claude enough context to know what docs exist without loading them all into context.

### 4. Beads Tasks (optional, with `--beads`)

When using the `--beads` flag, each spec step maps to a [beads](https://github.com/kenwilliford/beads_rust) task containing:
- Background and context
- Detailed acceptance criteria
- Verification commands

Sessions run `br show TASK-xyz` on-demand to get criteria for the current step. This keeps the spec small while maintaining rigorous verification. See the `--beads` section below for the full verification architecture.

### 5. The Stop Hook

A Claude Code hook that fires on the `Stop` event. When `RALPH_LOOP=1` is set, it walks up the process tree and sends `SIGINT` to the parent Claude process, ending the session so the bash loop can restart it.

```
bash loop → claude → [does work] → Stop hook fires → kills claude → bash loop restarts
```

The hook is **dual-mode**: it does nothing during normal interactive use. Only activates when the `RALPH_LOOP=1` environment variable is set.

### 6. Stop Files

Two sentinel files control the loop:

| File | Meaning | Created When |
|------|---------|-------------|
| `.ralph/COMPLETE` | All work done | All spec checkboxes checked |
| `.ralph/WAITING` | Human needed | Can't mechanically verify something |

The bash loop checks for both files each iteration.

## Token Budget

The core context (files read every session) must stay under ~5000 tokens:

| Component | Budget | Purpose |
|-----------|--------|---------|
| `prompt.md` | ~500 tokens | Standing instructions |
| `readme.md` | ~550 tokens | Lookup table |
| `spec.md` | ~3950 tokens | Work index |
| **Total** | **~5000 tokens** | **2.5% of 200K window** |

This leaves 97.5% of the context window for actual work — reading code, reasoning, writing implementations.

## Verification Architecture

### Default Mode

Each step requires:
1. Read acceptance criteria from spec step
2. Verify each criterion with evidence (command output, file contents, test results)
3. Mark spec checkbox `[x]`
4. Log evidence in progress log

### With `--beads`: Dual Tracking

When beads is enabled, ralph adds a second verification layer:

```
spec.md checkboxes  ←→  beads task status
       ↓                       ↓
  [x] Step 1.1          br close TASK-abc
       ↓                       ↓
  verify-beads-sync.sh checks both match
```

Every step requires:
1. `br show TASK-xyz` before starting (get acceptance criteria)
2. Verify each criterion with evidence
3. Mark spec checkbox `[x]`
4. Close beads task: `br close TASK-xyz`
5. Log evidence in progress log

The sync verification script (`verify-beads-sync.sh`) blocks completion until both systems agree.

## Data Flow

```
/ralph-setup (interactive)
      │
      ├── Interview user
      ├── Write spec.md, readme.md, prompt.md
      ├── Peer review spec (optional)
      │     ├── Spawn subagent for multi-round review
      │     ├── External reviewer (codex/gemini) ↔ Claude iterate
      │     ├── Produces .ralph/reviews/ audit trail
      │     └── Revised spec replaces spec.md
      ├── [--beads only] Create beads epic + tasks
      ├── [--beads only] Elaborate tasks with acceptance criteria
      ├── [--beads only] Validate beads quality
      └── Install stop hook + launch script
              │
              v
        ralph loop (autonomous)
              │
              ├── Session reads prompt.md
              ├── Reads spec.md → finds first [ ] step
              ├── Gets acceptance criteria (from spec, or br show with --beads)
              ├── Does the work
              ├── Verifies criteria with evidence
              ├── Marks spec [x] (+ br close with --beads)
              ├── Commits + pushes
              └── Exits → loop restarts
                      │
                      v
              .ralph/COMPLETE or .ralph/WAITING
```

## Security Model

Ralph loops run with `--dangerously-skip-permissions`, giving Claude full access to your system. Mitigations:

1. **Scope limitation**: The spec constrains what work gets done
2. **Git tracking**: Every change is committed, creating an audit trail
3. **Human review**: Review the git log after loop completion
4. **Stop conditions**: WAITING file pauses for human verification
5. **Isolation (recommended)**: Run in a VM, container, or dedicated user account

See the [theory doc](theory.md) for a deeper discussion of isolation strategies.
