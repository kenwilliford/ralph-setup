# User Guide

Getting started with ralph-setup, from installation through your first autonomous loop.

## Prerequisites

1. **Claude Code CLI** — [Install instructions](https://docs.anthropic.com/en/docs/claude-code)
2. **br (beads_rust)** — Task tracking for specs
   ```bash
   cargo install beads_rust
   ```
   Or see https://github.com/kenwilliford/beads_rust for other install methods.
3. **jq** — JSON processing (used by validation scripts)
   ```bash
   # macOS
   brew install jq
   # Ubuntu/Debian
   sudo apt install jq
   # Arch
   sudo pacman -S jq
   ```
4. **git** — Version control

## Installation

```bash
git clone https://github.com/kenwilliford/ralph-setup.git
cd ralph-setup
./install.sh
```

This installs the `/ralph-setup` slash command (and supporting commands) into `~/.claude/commands/`.

## Your First Ralph Loop

### 1. Navigate to your project

```bash
cd ~/your-project
```

Ralph works in any git repository. The `.ralph/` directory it creates is project-local.

### 2. Start the setup wizard

```bash
claude
# Then type: /ralph-setup
```

The wizard will:
- **Interview you** about what you want to build or fix
- **Write a spec** with numbered steps and acceptance criteria
- **Create beads tasks** for progress tracking
- **Validate everything** before declaring ready
- **Install the stop hook** in your project
- **Give you the launch command**

### 3. Launch the loop

The wizard will output a command like:

```bash
cd /path/to/project && RALPH_LOOP=1 bash -c 'while [ ! -f .ralph/COMPLETE ] && [ ! -f .ralph/WAITING ]; do cat .ralph/prompt.md | claude --dangerously-skip-permissions; sleep 2; done'
```

Or use the convenience wrapper:

```bash
./path/to/ralph-setup/scripts/ralph
```

### 4. Monitor progress

While the loop runs, you can:
- Watch git commits: `git log --oneline -10`
- Check spec progress: `cat .ralph/spec.md | grep '\[x\]'`
- Check beads: `br list --type task --parent $EPIC_ID`

### 5. Review when done

When the loop creates `.ralph/COMPLETE`:
- Review the git log: `git log --oneline`
- Check the final report: `cat .ralph/final-report.txt`
- Review the code changes
- Merge the branch if satisfied

## Setup Wizard Phases

The `/ralph-setup` command walks through these phases:

### Phase 1: Archive & Resume
Checks for existing `.ralph/` state. Offers to resume or start fresh.

### Phase 2: Interview
Asks about your goal, success criteria, scope, edge cases, and research needs. Supports structured (multiple-choice) or conversational mode.

### Phase 3: Research (conditional)
If your task needs investigation, explores the codebase first.

### Phase 4: Write Spec
Creates `.ralph/prompt.md`, `.ralph/readme.md`, and `.ralph/spec.md` within a strict token budget.

### Phase 5: Beads Integration
Creates a beads epic with tasks matching each spec step. Adds detailed acceptance criteria. Validates everything.

### Phase 6: Validate
Cross-checks that every edge case is a test item, every step has acceptance criteria, and steps are atomic.

### Phase 7: Spec Review
Shows you the complete spec and beads structure for approval before proceeding.

### Phase 8: Ensure Infrastructure
Installs the stop hook, creates utility scripts, verifies prerequisites, and reports readiness.

## How the Loop Works

Each iteration of the loop:

1. **Fresh session**: A new Claude Code process starts with no prior context
2. **Reads prompt.md**: Gets the standing instructions (piped via stdin)
3. **Reads spec**: Finds the first unchecked `[ ]` step
4. **Gets criteria**: Runs `br show TASK-xyz` for detailed acceptance criteria
5. **Does the work**: Implements exactly one step
6. **Verifies**: Checks each acceptance criterion with evidence
7. **Updates tracking**: Marks spec checkbox `[x]` and beads task complete
8. **Commits and exits**: One commit, one push, then the stop hook kills the session
9. **Loop restarts**: Back to step 1 with fresh context

## Stop Conditions

| Condition | File | What Happens |
|-----------|------|-------------|
| All done | `.ralph/COMPLETE` | Loop exits cleanly |
| Human needed | `.ralph/WAITING` | Loop pauses, read file for instructions |
| Manual stop | Ctrl+C | Loop stops immediately |
| Context limit | (auto) | Session checkpoints and exits, loop restarts |

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/ralph-setup` | Full setup wizard — interview, spec, beads, launch |
| `/beads-spec-to-beads` | Convert a spec into beads epic/tasks |
| `/beads-task-elaboration` | Add detailed context to beads tasks |
| `/beads-validate-beads` | Validate beads quality before implementation |

## Tips

### Keep specs small
The spec should be an index, not a novel. Detailed acceptance criteria belong in beads tasks, fetched on-demand via `br show`.

### One step per session
Each loop iteration should do exactly one thing. If a step is too large, the setup wizard breaks it into sub-steps.

### Review after completion
Always review the git log and code changes after a loop completes. False completions are possible — the dual tracking (spec + beads) reduces but doesn't eliminate them.

### Use branches
The setup wizard creates a dedicated branch for each loop. Review and merge after completion.

### Context monitoring
Sessions check context usage and checkpoint before hitting the 80% auto-compact threshold. If you notice sessions getting truncated, the spec may be too large.

## Troubleshooting

### Loop runs but nothing happens
- Check that `.ralph/prompt.md` exists
- Verify `claude` CLI is in your PATH
- Run `scripts/health-check.sh` from your project directory

### Session doesn't exit after completing a step
- Check that the stop hook is installed: `cat .claude/settings.json`
- Verify the hook script is executable: `ls -la .claude/hooks/exit-after-task.sh`

### "br: command not found"
Install beads_rust: `cargo install beads_rust`

### Spec and beads out of sync
Run `.ralph/verify-beads-sync.sh` to diagnose. Fix by marking missing beads tasks complete with `br task complete TASK-xyz`.
