# macOS Setup Script

Bootstrap a fresh macOS machine with a practical developer setup using Homebrew.

This script installs or updates a curated set of CLI tools, apps, and shell enhancements, then configures a few quality-of-life defaults for Zsh and Neovim.

## What it sets up

### Core tooling
- Homebrew
- Git
- GitHub CLI (`gh`)
- Neovim
- LazyVim starter config
- `uv`
- `ruff`
- Node.js and npm
- Bun
- Starship
- Zsh Patina

### GUI apps
- Ghostty
- Obsidian
- Docker

### Shell tweaks
- Adds Homebrew to PATH when needed
- Ensures `~/.local/bin` is in PATH
- Adds `alias vim="nvim"` to `~/.zshrc`
- Enables Starship in `~/.zshrc`
- Enables Zsh Patina in `~/.zshrc`

## Behavior

This script is designed to be **idempotent**:

- If a package is missing, it installs it.
- If a package is already installed and outdated, it upgrades it.
- If a package is already up to date, it skips it.
- If a config already exists, it leaves it alone.

That makes it suitable for both first-time setup and repeat runs.

## What the script does

1. Checks for Homebrew and installs it if missing.
2. Updates Homebrew if it is already present.
3. Installs or upgrades CLI packages through Homebrew.
4. Installs or upgrades GUI apps through Homebrew Cask.
5. Clones the LazyVim starter into `~/.config/nvim` if no Neovim config exists yet.
6. Installs `ruff` with `uv tool install ruff` if it is not already installed.
7. Appends shell initialization snippets to `~/.zshrc` and `~/.zprofile` only when missing.
8. Taps and trusts the `michel-kraemer/zsh-patina` Homebrew tap, then installs `zsh-patina`.

## Managed paths and files

The script may modify or create these locations:

- `~/.zprofile`
- `~/.zshrc`
- `~/.config/nvim`

## Requirements

- macOS
- Internet connection
- Permission to install software and modify shell config files

## Usage

Save the script and make it executable:

```bash
chmod +x setup-macos.sh
```

Run it:

```bash
./setup-macos.sh
```

If you prefer:

```bash
bash setup-macos.sh
```

## Notes

### Homebrew path handling
On Apple Silicon Macs, the script initializes Homebrew from:

```bash
/opt/homebrew/bin/brew
```

On Intel Macs, it uses:

```bash
/usr/local/bin/brew
```

### LazyVim setup
The script clones the LazyVim starter repo into:

```bash
~/.config/nvim
```

If that directory already exists, it skips installation to avoid overwriting an existing Neovim configuration.

### Ruff installation
`ruff` is installed using `uv tool install ruff` instead of Homebrew.

### Obsidian CLI
The script ensures `~/.local/bin` is available in PATH because the Obsidian CLI setup depends on it.

## After running

The script finishes by printing a few manual next steps:

- Restart the terminal so PATH, aliases, and shell enhancements reload.
- Run `gh auth login` to authenticate GitHub CLI.
- Open Docker once to complete Docker Desktop setup.
- Open Neovim once so LazyVim can install its plugins.
- In Obsidian, enable the command-line interface in Settings, then follow the prompt to register it.

## Example install list

### CLI
- `git`
- `gh`
- `neovim`
- `uv`
- `node`
- `bun`
- `starship`
- `zsh-patina`

### Apps
- `ghostty`
- `obsidian`
- `docker`

## Safety and caveats

- The script appends to shell config files rather than replacing them.
- It intentionally skips existing Neovim config instead of overwriting it.
- It uses `brew trust` for the `michel-kraemer/zsh-patina` tap.
- Some installs may still require user interaction depending on local system state or app permissions.

## Customization ideas

You can easily extend this script by adding more packages to the Homebrew sections, for example:

- `fzf`
- `ripgrep`
- `bat`
- `tmux`
- `pnpm`

## License

Use, modify, and adapt freely for personal machine setup.
