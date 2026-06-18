# macOS Setup Scripts

Automated setup scripts for fresh macOS installations. Installs development tools, CLI utilities, and GUI applications in the correct dependency order.

## What Gets Installed

### Core Tools
- **Homebrew** - Package manager (foundation for everything else)
- **Git** - Version control
- **GitHub CLI** (`gh`) - GitHub from the command line

### Development Environment
- **Neovim** + **LazyVim** - Modern editor with batteries-included config
- **Node.js** + **npm** - JavaScript runtime
- **Bun** - Fast JavaScript runtime and package manager
- **uv** - Fast Python package installer
- **Ruff** - Astral's Python linter/formatter

### GUI Applications
- **Ghostty** - Modern terminal emulator
- **Obsidian** - Markdown knowledge base (with CLI support)
- **Docker** - Container platform

## Prerequisites

- macOS (Intel or Apple Silicon)
- Internet connection
- Admin privileges (for some installations)

## Usage

```bash
# Make executable
chmod +x setup-macos.sh

# Run setup
./setup-macos.sh
```

The script is idempotent — safe to run multiple times. Already-installed packages are skipped.

## Post-Installation

After the script completes:

1. **Restart terminal** - PATH changes require a new shell session
2. **Authenticate GitHub CLI**:
   ```bash
   gh auth login
   ```
3. **Open Docker** - Launch once to complete setup
4. **Open Neovim** - Launch once to let LazyVim install plugins
5. **Enable Obsidian CLI**:
   - Open Obsidian → Settings → General
   - Enable "Command line interface"
   - Follow on-screen prompt to register CLI (requires admin password)
   - Restart terminal

## Testing

Run the test suite to verify the script without installing anything:

```bash
# Make test executable
chmod +x test-setup.sh

# Run tests
./test-setup.sh
```

Tests verify:
- Script syntax
- Package availability (formulae and casks)
- Repository URLs
- Architecture detection (Intel vs Apple Silicon)
- Dry-run execution with stubbed commands

## Architecture Support

Scripts automatically detect and handle:
- **Apple Silicon** (arm64): `/opt/homebrew` paths
- **Intel** (x86_64): `/usr/local` paths

## What the Scripts Don't Do

- Configure shell themes (Oh My Zsh, Starship, etc.)
- Set up SSH keys
- Install language-specific tools beyond Node/Python
- Configure editor settings beyond LazyVim defaults
- Set up Docker containers or images

## Customization

Edit `setup-macos.sh` to:
- Add/remove packages
- Change installation order
- Modify PATH setup
- Add custom configuration steps

## License

MIT
