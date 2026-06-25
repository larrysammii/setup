#!/bin/bash

# macOS Setup Script
# Installs: homebrew, git, gh, neovim+lazyvim, uv, astral, node/npm, bun, starship, ghostty, obsidian, docker
# Idempotent: skip installed, upgrade outdated, install missing

set -e

echo "Starting macOS setup..."

# --- Helper functions ---
# Install formula if missing, upgrade if outdated, skip if up-to-date
brew_ensure() {
  local pkg="$1"
  if brew list --formula 2>/dev/null | grep -q "^${pkg}$"; then
    if brew outdated --formula 2>/dev/null | grep -q "^${pkg}$"; then
      echo "Updating $pkg..."
      brew upgrade "$pkg" || echo "Warning: Failed to upgrade $pkg. Skipping..."
    else
      echo "$pkg already up-to-date, skipping"
    fi
  else
    echo "Installing $pkg..."
    # If install fails (e.g. conflicting binaries), log it and move to the next step
    brew install "$pkg" || echo "Warning: Failed to install $pkg. It may already exist. Skipping..."
  fi
}

# Same for casks
cask_ensure() {
  local pkg="$1"
  if brew list --cask 2>/dev/null | grep -q "^${pkg}$"; then
    if brew outdated --cask 2>/dev/null | grep -q "^${pkg}$"; then
      echo "Updating $pkg..."
      brew upgrade --cask "$pkg" || echo "Warning: Failed to upgrade cask $pkg. Skipping..."
    else
      echo "$pkg already up-to-date, skipping"
    fi
  else
    echo "Installing $pkg..."
    # If cask install fails (e.g. App already in /Applications), log it and move to the next step
    brew install --cask "$pkg" || echo "Notice: $pkg setup bypassed (likely already installed manually)."
  fi
}

# 1. Homebrew (foundation)
echo "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to PATH for Apple Silicon
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed, updating..."
  brew update
fi

# 2. Git
echo "Checking Git..."
brew_ensure git

# 3. GitHub CLI
echo "Checking GitHub CLI..."
brew_ensure gh

# 4. Neovim + Lazyvim
echo "Checking Neovim..."
brew_ensure neovim

echo "Setting up Lazyvim..."
LAZYVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ ! -d "$LAZYVIM_DIR" ]; then
  git clone https://github.com/LazyVim/starter "$LAZYVIM_DIR"
  rm -rf "$LAZYVIM_DIR/.git"
  echo "Lazyvim config installed at $LAZYVIM_DIR"
else
  echo "Neovim config already exists at $LAZYVIM_DIR, skipping"
fi

# 5. Python tools (uv, astral)
echo "Checking uv..."
brew_ensure uv

echo "Checking ruff (astral)..."
if uv tool list 2>/dev/null | grep -q "^ruff "; then
  echo "ruff already installed, skipping"
else
  echo "Installing ruff..."
  uv tool install ruff
fi

# 6. Node.js and npm
echo "Checking Node.js (includes npm)..."
brew_ensure node

# 7. Bun
echo "Checking Bun..."
brew_ensure bun

# 8. Starship prompt
echo "Checking Starship..."
brew_ensure starship

echo "Ensuring Starship initializes in zsh..."
if ! grep -q 'eval "$(starship init zsh)"' ~/.zshrc 2>/dev/null; then
  echo 'eval "$(starship init zsh)"' >>~/.zshrc
fi

# 9. GUI Applications via Homebrew Cask
echo "Checking GUI applications..."
cask_ensure ghostty
cask_ensure obsidian
cask_ensure docker

# 10. Ensure ~/.local/bin in PATH (needed by Obsidian CLI on macOS)
echo "Ensuring ~/.local/bin in PATH..."
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.zprofile
  export PATH="$HOME/.local/bin:$PATH"
fi

# 11. Add vim alias to point to neovim
echo "Ensuring 'vim' alias points to 'nvim' in zsh..."
if ! grep -q 'alias vim="nvim"' ~/.zshrc 2>/dev/null; then
  echo 'alias vim="nvim"' >>~/.zshrc
  echo "Alias added!"
else
  echo "Alias already exists, skipping"
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
