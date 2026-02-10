# ralph-setup

Autonomous development loops for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Write a spec, decompose it into tracked tasks, then let Claude work through it step-by-step — each iteration in a fresh context window. Based on [Geoffrey Huntley's ralph loop methodology](https://ghuntley.com/specs).

## How It Works

```
You (interactive)                    Claude (autonomous)
┌──────────────┐                    ┌──────────────────────┐
│ /ralph-setup │                    │    bash while loop    │
│              │                    │                       │
│ 1. Interview │──── spec.md ──────>│ Session 1: Step 1.1  │
│ 2. Write spec│                    │   commit + exit       │
│ 3. Beads     │                    │                       │
│ 4. Validate  │                    │ Session 2: Step 1.2  │
│ 5. Launch    │                    │   commit + exit       │
└──────────────┘                    │                       │
                                    │ Session N: COMPLETE   │
                                    └──────────────────────┘
```

Each loop iteration spawns a **fresh Claude session** — no context compaction, no accumulated confusion. State persists in git commits and spec files.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- [br (beads_rust)](https://github.com/kenwilliford/beads_rust) — `cargo install beads_rust`
- [jq](https://jqlang.github.io/jq/) — `brew install jq` / `apt install jq`
- git

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

The wizard interviews you, writes a spec, creates beads tasks, and gives you the launch command.

## What Gets Installed

The installer symlinks four slash commands into `~/.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/ralph-setup` | Full setup wizard — interview, spec, beads, launch |
| `/beads-spec-to-beads` | Convert a spec into a beads epic with tasks |
| `/beads-task-elaboration` | Add detailed acceptance criteria to tasks |
| `/beads-validate-beads` | Validate plan quality before implementation |

## The Loop

After setup, you get a launch command:

```bash
# Using the convenience script:
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

### Spec as Index, Beads as Detail
The spec is a minimal checklist. Detailed acceptance criteria live in beads tasks, fetched on-demand via `br show TASK-xyz`.

### Dual Tracking
Every step must be marked complete in both the spec (`[x]`) and beads (`br task complete`). A sync check blocks false completion.

### False Complete Prevention
Each step requires evidence — command output, test results, file contents. "It works" is never sufficient.

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

## License

MIT
