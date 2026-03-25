# User Guide

Getting started with ralph-setup, from installation through your first autonomous loop.

## Prerequisites

**Required:**
1. **Claude Code CLI** — [Install instructions](https://docs.anthropic.com/en/docs/claude-code)
2. **git** — Version control

**Optional:**
3. **br (beads_rust)** — Only needed with `--beads` flag. Agent-first issue tracker for dual-tracking.
   ```bash
   # Requires Rust toolchain: https://rustup.rs/
   cargo install beads_rust
   ```
   Or see https://github.com/kenwilliford/beads_rust for other install methods.
4. **jq** — JSON processing (used by beads validation scripts)
   ```bash
   # macOS
   brew install jq
   # Ubuntu/Debian
   sudo apt install jq
   ```
5. **External reviewer CLI** (optional, for peer review) — one of:
   - [Codex CLI](https://github.com/openai/codex) — `npm install -g @openai/codex` (requires Node.js 18+)
   - [Gemini CLI](https://github.com/google-gemini/gemini-cli) — `npm install -g @google/gemini-cli@latest` (requires Node.js 18+)
   - Or use Claude CLI as a self-review fallback

## Installation

```bash
git clone https://github.com/kenwilliford/ralph-setup.git
cd ralph-setup
./install.sh
```

This symlinks the `/ralph-setup` slash command (and supporting beads commands) into `~/.claude/commands/`. Keep the cloned repo in place — the commands are symlinked, not copied.

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
- **Peer review** the spec with an external model (optional)
- **Validate everything** before declaring ready
- **Install the stop hook** in your project
- **Give you the launch command**

### 3. Launch the loop

The wizard generates a launch script:

```bash
.ralph/launch.sh
```

Or use the convenience wrapper:

```bash
./path/to/ralph-setup/scripts/ralph
```

### 4. Monitor progress

While the loop runs, you can:
- Watch git commits: `git log --oneline -10`
- Check spec progress: `cat .ralph/spec.md | grep '\[x\]'`

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
Creates `.ralph/prompt.md`, `.ralph/readme.md`, and `.ralph/spec.md` within a strict token budget. Acceptance criteria are written directly into spec steps.

### Phase 4.5: Peer Review (optional)
Runs a multi-round peer review of the spec with an external model (Codex, Gemini, or Claude CLI). The reviewer critically evaluates the spec, Claude responds to findings and revises. Runs autonomously until the reviewer issues GO or hits the round cap (4 rounds). Requires an external CLI (e.g., `codex`, `gemini`) for cross-model review.

### Phase 5: Beads Integration (only with `--beads`)
Creates a beads epic with tasks matching each spec step. Moves acceptance criteria into beads tasks for dual-tracking. Validates everything. Skipped by default.

### Phase 6: Validate
Cross-checks that every edge case is a test item, every step has acceptance criteria, and steps are atomic.

### Phase 7: Spec Review
Shows you the complete spec for approval before proceeding. With `--beads`, also lets you review the beads task structure.

### Phase 8: Ensure Infrastructure
Installs the stop hook, creates utility scripts, verifies prerequisites, and reports readiness.

## How the Loop Works

Each iteration of the loop:

1. **Fresh session**: A new Claude Code process starts with no prior context
2. **Reads prompt.md**: Gets the standing instructions (piped via stdin)
3. **Reads spec**: Finds the first unchecked `[ ]` step
4. **Gets criteria**: Reads acceptance criteria from the spec step (or from `br show TASK-xyz` with `--beads`)
5. **Does the work**: Implements exactly one step
6. **Verifies**: Checks each acceptance criterion with evidence
7. **Updates tracking**: Marks spec checkbox `[x]` (and beads task with `--beads`)
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
| `/ralph-setup` | Full setup wizard — interview, spec, launch |
| `/beads-spec-to-beads` | Convert a spec into beads epic/tasks (used with `--beads`) |
| `/beads-task-elaboration` | Add detailed context to beads tasks (used with `--beads`) |
| `/beads-validate-beads` | Validate beads quality before implementation (used with `--beads`) |

## Tips

### Keep specs small
The spec should stay under ~4000 tokens to preserve context budget. Each step should have specific, testable acceptance criteria. With `--beads`, criteria can live in beads tasks instead, keeping the spec even leaner.

### One step per session
Each loop iteration should do exactly one thing. If a step is too large, the setup wizard breaks it into sub-steps.

### Review after completion
Always review the git log and code changes after a loop completes. False completions are possible — specific acceptance criteria and review steps (`.R`) reduce but don't eliminate them.

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

### "br: command not found" (with `--beads`)
This only affects `--beads` mode. Install beads_rust: `cargo install beads_rust` (requires [Rust toolchain](https://rustup.rs/)).

### Spec and beads out of sync (with `--beads`)
Run `.ralph/verify-beads-sync.sh` to diagnose. Fix by closing missing beads tasks with `br close TASK-xyz`.
