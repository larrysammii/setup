# macOS Setup Scripts

Automated setup scripts for fresh macOS installations. Installs development tools, CLI utilities, and GUI applications in the correct dependency order.

## What Gets Installed

### Core Tools
- **Homebrew** - Package manager (foundation for everything else)
- **Git** - Version control
- **GitHub CLI** (`gh`) - GitHub from the command line

### Development Environment
- **Neovim** + **LazyVim** - Modern editor with batteries-included config
- **Vim Alias** - Automatically points the `vim` command to `nvim` for a seamless transition
- **Node.js** + **npm** - JavaScript runtime
- **Bun** - Fast JavaScript runtime and package manager
- **uv** - Fast Python package installer
- **Ruff** - Astral's Python linter/formatter

### Shell Enhancements
- **Starship** - Minimal, ultra-fast, and customizable cross-shell prompt
- **Zsh Patina** - Blazingly fast, sub-millisecond syntax highlighting backed by a Rust daemon

### GUI Applications
- **Ghostty** - Modern, GPU-accelerated terminal emulator
- **Obsidian** - Markdown knowledge base (with CLI support)
- **Docker Desktop** - Container platform

## Prerequisites

- macOS (Intel or Apple Silicon)
- Internet connection
- Admin privileges (for some installations)

## Usage

Code output

File generated successfully: README.md

```bash
# Make executable
chmod +x setup-macos.sh

# Run setup
./setup-macos.sh

The script is fully idempotent and crash-proof. It skips up-to-date packages, upgrades outdated ones, and gracefully bypasses manual installations (e.g., if you already dragged Docker or Obsidian into your /Applications folder, the script won't panic or stop).

Post-Installation

After the script completes:

    Restart terminal - Required for PATH updates, the vim alias, Starship, and Zsh Patina to initialize.

    Authenticate GitHub CLI:
    Bash

    gh auth login

    Open Docker - Launch once to complete system setup.

    Open Neovim - Launch once to let LazyVim install plugins automatically.

    Enable Obsidian CLI:

        Open Obsidian → Settings → General

        Enable "Command line interface"

        Follow the on-screen prompt to register the CLI (requires admin password)

        Restart terminal

Testing

Run the test suite to verify the script configuration without actually installing anything on your machine:
Bash

# Make test executable
chmod +x test-setup.sh

# Run tests
./test-setup.sh

Tests verify:

    Script syntax and error-handling flags (set -e)

    Live package availability against Homebrew's remote formula/cask registries

    Remote repository URL integrity

    Architecture detection logic (Intel vs Apple Silicon)

    100% Isolated Dry-Runs: Uses strict inline mocking to completely isolate the test from your real environment, bypassing macOS environment subshell restrictions to ensure zero live packages leak through.

Architecture Support

Scripts automatically detect your system architecture and map things cleanly:

    Apple Silicon (arm64): /opt/homebrew paths

    Intel (x86_64): /usr/local paths

What the Scripts Don't Do

    Install heavy framework managers (like Oh My Zsh) or custom shell plugins outside of Starship and Patina

    Set up SSH keys or Git config credentials (user.name / user.email)

    Install language-specific version managers (like nvm or pyenv)

    Configure editor settings beyond LazyVim defaults

    Pull Docker containers or images

Customization

Edit setup-macos.sh to:

    Add/remove packages

    Change installation order

    Modify PATH setup

    Add custom configuration steps

License

MIT
