#!/bin/bash
# Ralph Setup Installer
# Installs the ralph-setup slash commands for Claude Code
#
# What it does:
#   1. Checks prerequisites (claude CLI, br, jq, git)
#   2. Symlinks all commands/*.md to ~/.claude/commands/
#
# Supported platforms: macOS, Linux, WSL
# Windows users: Use WSL (Windows Subsystem for Linux)

set -e

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows-git-bash"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS=$(detect_os)

echo "Installing ralph-setup..."
echo "Detected platform: $OS"
echo ""

# Check for unsupported platforms
if [ "$OS" = "windows-git-bash" ]; then
    echo "ERROR: Git Bash on Windows is not fully supported."
    echo ""
    echo "The ralph loop system uses Unix process management (ps, kill)"
    echo "which doesn't work correctly in Git Bash."
    echo ""
    echo "Please use WSL (Windows Subsystem for Linux) instead:"
    echo "  1. Install WSL: https://learn.microsoft.com/en-us/windows/wsl/install"
    echo "  2. Open a WSL terminal"
    echo "  3. Install Claude Code in WSL"
    echo "  4. Clone this repo in WSL and run ./install.sh"
    echo ""
    exit 1
fi

if [ "$OS" = "unknown" ]; then
    echo "WARNING: Unrecognized platform. Proceeding anyway..."
    echo "If you encounter issues, please use macOS, Linux, or WSL."
    echo ""
fi

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify command files exist
if [ ! -d "$SCRIPT_DIR/commands" ]; then
    echo "ERROR: commands/ directory not found."
    echo "Make sure you're running this from the ralph-setup repo directory."
    exit 1
fi

# --- Check Prerequisites ---

echo "Checking prerequisites..."
echo ""

MISSING=0

check_prereq() {
    local cmd="$1"
    local name="$2"
    local install_hint="$3"
    if command -v "$cmd" &>/dev/null; then
        echo "  [OK]   $name"
    else
        echo "  [MISS] $name - $install_hint"
        MISSING=$((MISSING + 1))
    fi
}

check_prereq "claude" "Claude Code CLI" "https://docs.anthropic.com/en/docs/claude-code"
check_prereq "br" "br (beads_rust)" "cargo install beads_rust"
check_prereq "jq" "jq" "brew install jq / apt install jq"
check_prereq "git" "git" "https://git-scm.com/downloads"

echo ""

if [ "$MISSING" -gt 0 ]; then
    echo "WARNING: $MISSING prerequisite(s) missing."
    echo "ralph-setup will be installed but some features won't work until"
    echo "the missing tools are installed."
    echo ""
fi

# --- Install Commands ---

# Create commands directory if needed
mkdir -p ~/.claude/commands

# Install each command file
INSTALLED=0
for cmd_file in "$SCRIPT_DIR"/commands/*.md; do
    if [ ! -f "$cmd_file" ]; then
        continue
    fi

    filename=$(basename "$cmd_file")
    target=~/.claude/commands/"$filename"

    # Handle existing files
    if [ -L "$target" ]; then
        # Existing symlink - update it
        rm "$target"
    elif [ -f "$target" ]; then
        # Regular file - back it up
        echo "  Backing up existing $filename to ${filename}.bak"
        mv "$target" "${target}.bak"
    fi

    ln -s "$cmd_file" "$target"
    echo "  Installed: $filename"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "SUCCESS! Installed $INSTALLED command(s) to ~/.claude/commands/"
echo ""
echo "Commands installed:"
echo "  /ralph-setup           - Full setup wizard (interview, spec, beads, launch)"
echo "  /beads-spec-to-beads   - Convert specs into beads epics/tasks"
echo "  /beads-task-elaboration - Add detailed context to beads tasks"
echo "  /beads-validate-beads  - Validate beads quality before implementation"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or start a new session)"
echo "  2. cd to your project directory"
echo "  3. Run 'claude' and type '/ralph-setup'"
echo ""
echo "The setup wizard will:"
echo "  - Interview you about the task"
echo "  - Create the .ralph/ directory with spec files"
echo "  - Install the stop hook in your project"
echo "  - Give you the command to start the loop"
echo ""
echo "See docs/user-guide.md for more details."
echo "See docs/theory.md for the methodology background."
