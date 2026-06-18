#!/bin/bash

# macOS Setup Script
# Installs: homebrew, git, gh, neovim+lazyvim, uv, astral, node/npm, bun, ghostty, obsidian, docker

set -e

echo "Starting macOS setup..."

# 1. Homebrew (foundation)
echo "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed"
fi

# 2. Git
echo "Installing Git..."
brew install git

# 3. GitHub CLI
echo "Installing GitHub CLI..."
brew install gh

# 4. Neovim + Lazyvim
echo "Installing Neovim..."
brew install neovim

echo "Setting up Lazyvim..."
LAZYVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ ! -d "$LAZYVIM_DIR" ]; then
    git clone https://github.com/LazyVim/starter "$LAZYVIM_DIR"
    rm -rf "$LAZYVIM_DIR/.git"
    echo "Lazyvim config installed at $LAZYVIM_DIR"
else
    echo "Neovim config already exists at $LAZYVIM_DIR"
fi

# 5. Python tools (uv, astral)
echo "Installing uv..."
brew install uv

echo "Installing ruff (astral)..."
uv tool install ruff

# 6. Node.js and npm
echo "Installing Node.js (includes npm)..."
brew install node

# 7. Bun
echo "Installing Bun..."
brew install bun

# 8. GUI Applications via Homebrew Cask
echo "Installing GUI applications..."
brew install --cask ghostty
brew install --cask obsidian
brew install --cask docker

# 9. Ensure ~/.local/bin in PATH (needed by Obsidian CLI on macOS)
echo "Ensuring ~/.local/bin in PATH..."
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "- Restart terminal for PATH changes"
echo "- Run 'gh auth login' to authenticate GitHub CLI"
echo "- Open Docker app to complete setup"
echo "- Open Neovim once to let Lazyvim install plugins"
echo "- Obsidian CLI: open Obsidian -> Settings -> General -> enable 'Command line interface'"
echo "  Then follow on-screen prompt to register CLI (needs admin). Restart terminal."
