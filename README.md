# ralph-setup

Autonomous development loops for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Write a spec, then let Claude work through it step-by-step — each iteration in a fresh context window. Based on [Geoffrey Huntley's ralph loop methodology](https://ghuntley.com/ralph/).

## How It Works

```
You (interactive)                    Claude (autonomous)
┌──────────────┐                    ┌───────────────────────┐
│ /ralph-setup │                    │    bash while loop    │
│              │                    │                       │
│ 1. Interview │──── spec.md ──────>│ Session 1: Step 1.1   │
│ 2. Write spec│                    │   commit + exit       │
│ 3. Review    │                    │                       │
│ 4. Launch    │                    │ Session 2: Step 1.2   │
│              │                    │   commit + exit       │
└──────────────┘                    │                       │
                                    │ Session N: COMPLETE   │
                                    └───────────────────────┘
```

Each loop iteration spawns a **fresh Claude session** — no context compaction, no accumulated confusion. State persists in git commits and spec files.

## Prerequisites

**Required:**
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- git

**Optional:**
- [br (beads_rust)](https://github.com/kenwilliford/beads_rust) — only needed with `--beads` flag. Requires [Rust toolchain](https://rustup.rs/) to install: `cargo install beads_rust`
- [jq](https://jqlang.github.io/jq/) — used by validation scripts. `brew install jq` / `apt install jq`
- Reviewer CLI for optional peer review: [Codex](https://github.com/openai/codex) (`npm install -g @openai/codex`) or [Gemini](https://github.com/google-gemini/gemini-cli) (`npm install -g @google/gemini-cli@latest`)

## Quick Start

```bash
# Install the slash commands
git clone https://github.com/kenwilliford/ralph-setup.git
cd ralph-setup
./install.sh

# Go to your project and run the setup wizard
cd ~/your-project
claude
# Type: /ralph-setup
```

The wizard interviews you about your task, writes a spec with acceptance criteria, optionally runs peer review, and gives you a launch command.

**Important:** Keep the cloned repo in place after install. The slash commands are symlinked, not copied — deleting or moving the repo will break them.

## What Gets Installed

The installer symlinks slash commands into `~/.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/ralph-setup` | Full setup wizard — interview, spec, launch |
| `/beads-spec-to-beads` | Convert a spec into a beads epic with tasks (used with `--beads`) |
| `/beads-task-elaboration` | Add detailed acceptance criteria to tasks (used with `--beads`) |
| `/beads-validate-beads` | Validate plan quality before implementation (used with `--beads`) |

## The `--beads` Flag

By default, ralph-setup keeps things simple: acceptance criteria live directly in spec.md, and no external tools are required beyond Claude Code and git.

Pass `--beads` to enable dual-tracking with [beads](https://github.com/kenwilliford/beads_rust), an agent-first issue tracker. With beads enabled:
- Detailed acceptance criteria live in beads tasks (fetched via `br show`)
- Each step must be marked complete in both the spec and beads
- A sync check at completion prevents false-complete scenarios

This is useful for complex multi-phase tasks where you want a second verification layer. For most tasks, the default mode works well.

## The Loop

After setup, you get a launch script:

```bash
# Using the generated launch script:
.ralph/launch.sh

# Or the convenience wrapper:
./path/to/ralph-setup/scripts/ralph

# Or directly:
cd /your/project && RALPH_LOOP=1 bash -c \
  'while [ ! -f .ralph/COMPLETE ] && [ ! -f .ralph/WAITING ]; do
    cat .ralph/prompt.md | claude --dangerously-skip-permissions
    sleep 2
  done'
```

The loop stops when:
- `.ralph/COMPLETE` — all spec steps done
- `.ralph/WAITING` — human verification needed
- `Ctrl+C` — manual stop

## Key Concepts

### Context Parsimony
Core context (prompt + readme + spec) stays under ~5000 tokens. That's 2.5% of the 200K window, leaving 97.5% for actual work.

### Evidence-Based Completion
Each step requires evidence — command output, test results, file contents. "It works" is never sufficient. Review steps (`.R`) at the end of each phase catch bugs before they compound.

### False Complete Prevention
Acceptance criteria must be specific and mechanically verifiable. Vague criteria like "verify it works" get flagged during setup and replaced with concrete checks.

## Updating

```bash
cd path/to/ralph-setup && git pull
```

Symlinks auto-update — no reinstall needed.

## Uninstalling

```bash
# Remove the symlinks
rm ~/.claude/commands/ralph-setup.md
rm ~/.claude/commands/beads-spec-to-beads.md
rm ~/.claude/commands/beads-task-elaboration.md
rm ~/.claude/commands/beads-validate-beads.md

# Optionally remove the cloned repo
rm -rf path/to/ralph-setup
```

## Project Structure

```
ralph-setup/
├── commands/              # Claude Code slash commands
│   ├── ralph-setup.md     # Main setup wizard
│   ├── beads-spec-to-beads.md
│   ├── beads-task-elaboration.md
│   └── beads-validate-beads.md
├── templates/             # Files installed to .ralph/ in target projects
│   ├── prompt.md          # Worker prompt template
│   ├── spec.md            # Spec template
│   ├── readme.md          # Lookup table template
│   ├── check-context.sh   # Context monitor
│   └── stop-hook.sh       # Stop hook template
├── references/
│   └── peer-review/       # Peer review templates
│       ├── REVIEW_TEMPLATE.md
│       ├── RESPONSE_TEMPLATE.md
│       └── CODEX_INSTRUCTIONS.md
├── scripts/
│   ├── ralph              # Loop runner wrapper
│   ├── validate-ac.sh     # Acceptance criteria validator
│   └── health-check.sh    # Prerequisites checker
├── hooks/                 # Claude Code hook configuration
├── docs/
│   ├── architecture.md    # How ralph works
│   ├── user-guide.md      # Getting started
│   └── theory.md          # Methodology background
├── install.sh             # Installer
├── CLAUDE.md              # Project instructions
├── LICENSE                # MIT
└── README.md              # This file
```

## Documentation

- **[User Guide](docs/user-guide.md)** — Step-by-step setup and usage
- **[Architecture](docs/architecture.md)** — How the system works internally
- **[Theory](docs/theory.md)** — The methodology and why fresh context matters

## Security

Ralph loops run with `--dangerously-skip-permissions`. This gives Claude full access to your user account. Mitigations:

1. The spec constrains scope
2. Git tracks every change
3. Review the git log after completion
4. For sensitive environments, run in a VM or container

See [docs/theory.md](docs/theory.md) for isolation strategies.

## Attribution

This implementation is inspired by [Geoffrey Huntley's ralph loop methodology](https://ghuntley.com/specs). The core ideas — fresh context per iteration, parsimonious specs, external bash loops — come from his talks and demonstrations.

The beads integration commands (`/beads-spec-to-beads`, `/beads-task-elaboration`, `/beads-validate-beads`) were contributed by [Mike Williamson (@mikez93)](https://github.com/mikez93).

## License

MIT
