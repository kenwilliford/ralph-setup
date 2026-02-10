# ralph-setup

Structured spec-writing and autonomous loop system for Claude Code.

## Purpose

This repository contains the `/ralph-setup` slash command and supporting tools for running autonomous development loops with Claude Code. It implements the "ralph loop" methodology: interview, spec, beads decomposition, then hands-off execution.

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `commands/` | Claude Code slash commands (.md skill files) |
| `templates/` | Template files installed to `.ralph/` in target projects |
| `scripts/` | Loop runner, validation scripts, health check |
| `hooks/` | Claude Code hook for stop-after-task behavior |
| `docs/` | Architecture, user guide, methodology theory |
| `examples/` | Example specs and workflows |

## CRITICAL: Incremental Spec Updates

When working in a ralph-loop (indicated by `RALPH_LOOP=1` or a spec.md file):

**AFTER COMPLETING EACH STEP:**
1. Immediately update spec.md to mark the checkbox `[x]`
2. Do NOT batch checkbox updates
3. Do NOT wait until the end to mark steps complete
4. Each step should be: implement -> verify -> mark checkbox -> commit

## Beads Integration

**Beads hold the detail, spec.md is just an index.** This keeps core context under 5K tokens.

**BEFORE working on any step:**
1. Find the task ID from spec (format: `[TASK-xyz]`)
2. Run `br show TASK-xyz` to get acceptance criteria
3. Read and understand the criteria BEFORE implementing

**AFTER completing each spec step:**
1. Verify ALL acceptance criteria from `br show` output
2. Mark spec checkbox: `[ ]` -> `[x]`
3. Add evidence to spec's progress log
4. Mark beads task complete: `br task complete <TASK_ID>`

## False Complete Prevention

**NEVER mark a step complete without verification:**
- "It seems to work" -> NOT ACCEPTABLE
- "Tests pass" (without showing which tests) -> NOT ACCEPTABLE

**ALWAYS provide evidence:**
- Show command output (e.g., test results)
- Show file contents
- Show verification results

**When in doubt, WAITING not COMPLETE.**
