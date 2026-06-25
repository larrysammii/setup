#!/bin/bash

# Test: verify setup-macos.sh runs without errors (completely isolated dry-run)

set -e
PASS=0
FAIL=0

pass() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}
fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

echo "=== setup-macos.sh test suite ==="
echo ""

# 1. Syntax check
echo "[1] Syntax validation"
if bash -n setup-macos.sh 2>/dev/null; then
  pass "bash -n passes"
else
  fail "bash -n fails"
fi

# 2. Shebang present
echo "[2] Shebang"
if head -1 setup-macos.sh | grep -q "^#!/bin/bash"; then
  pass "shebang present"
else
  fail "missing shebang"
fi

# 3. set -e present (fail-fast)
echo "[3] Error handling"
if grep -q "^set -e" setup-macos.sh; then
  pass "set -e present"
else
  fail "missing set -e"
fi

# 4. Homebrew install URL valid
echo "[4] Homebrew install URL"
if curl -sfI "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" >/dev/null 2>&1; then
  pass "homebrew install URL reachable"
else
  fail "homebrew install URL unreachable"
fi

# 5. Lazyvim starter repo exists
echo "[5] Lazyvim repo"
if git ls-remote --exit-code "https://github.com/LazyVim/starter" HEAD >/dev/null 2>&1; then
  pass "lazyvim/starter repo exists"
else
  fail "lazyvim/starter repo missing"
fi

# 6. All brew formulae exist (Read-only System Check)
echo "[6] Brew formulae validity"
BREW_FORMULAE=("git" "gh" "neovim" "uv" "node")
for pkg in "${BREW_FORMULAE[@]}"; do
  if brew info --json=v2 "$pkg" 2>/dev/null | grep -q "\"name\":\"$pkg\""; then
    pass "formula: $pkg"
  else
    if brew info "$pkg" &>/dev/null; then
      pass "formula: $pkg"
    else
      fail "formula: $pkg not found"
    fi
  fi
done

# 6b. Verify Zsh Patina remote repository exists without tapping locally
if git ls-remote --exit-code "https://github.com/michel-kraemer/zsh-patina" HEAD >/dev/null 2>&1; then
  pass "formula repository: michel-kraemer/zsh-patina exists"
else
  fail "formula repository: michel-kraemer/zsh-patina unreachable"
fi

# 7. Brew casks exist
echo "[7] Brew casks validity"
BREW_CASKS=("ghostty" "obsidian" "docker")
for cask in "${BREW_CASKS[@]}"; do
  if brew info --cask "$cask" &>/dev/null; then
    pass "cask: $cask"
  else
    fail "cask: $cask not found"
  fi
done

# 8. Bun formula exists
echo "[8] Bun formula"
if brew info bun &>/dev/null; then
  pass "bun formula valid"
else
  fail "bun formula not found"
fi

# 9. PATH logic: ~/.local/bin added correctly
echo "[9] PATH setup logic"
if grep -q '\.local/bin' setup-macos.sh && grep -q 'export PATH' setup-macos.sh; then
  pass "~/.local/bin PATH logic present"
else
  fail "~/.local/bin PATH logic missing"
fi

# 10. Script is executable
echo "[10] File permissions"
if [ -x setup-macos.sh ]; then
  pass "script is executable"
else
  fail "script not executable"
fi

# 11. No hardcoded paths that break on Apple Silicon vs Intel
echo "[11] Architecture awareness"
if grep -q 'uname -m' setup-macos.sh && grep -q 'arm64' setup-macos.sh; then
  pass "handles arm64 vs intel"
else
  fail "missing arch detection"
fi

# 12. Helper functions exist for idempotent install/upgrade/skip
echo "[12] Idempotent helper functions"
if grep -q 'brew_ensure()' setup-macos.sh && grep -q 'cask_ensure()' setup-macos.sh; then
  pass "brew_ensure and cask_ensure helpers defined"
else
  fail "missing idempotent helper functions"
fi

# 13. No bare 'brew install' outside helpers (all go through helpers)
echo "[13] All installs use helpers"
BARE_INSTALLS=$(grep -n 'brew install' setup-macos.sh | grep -v '"$pkg"' | grep -v 'brew_ensure\|cask_ensure' | wc -l | tr -d ' ')
if [ "$BARE_INSTALLS" -eq 0 ]; then
  pass "no bare brew install outside helpers"
else
  fail "found $BARE_INSTALLS bare brew install calls outside helpers"
fi

# 14. Ruff has skip-if-installed logic
echo "[14] Ruff idempotent install"
if grep -q 'uv tool list' setup-macos.sh && grep -q 'ruff' setup-macos.sh; then
  pass "ruff checks existing install before installing"
else
  fail "ruff missing skip-if-installed check"
fi

# 15. Helpers include upgrade + outdated check
echo "[15] Helpers check for updates"
if grep -q 'brew outdated' setup-macos.sh && grep -q 'brew upgrade' setup-macos.sh; then
  pass "helpers include upgrade and outdated check"
else
  fail "helpers missing upgrade/outdated logic"
fi

# 16. Dry-run: nothing installed -> all get installed
echo "[16] Dry-run (nothing installed) exits 0"
DRYRUN_DIR=$(mktemp -d)
INSTALL_LOG="$DRYRUN_DIR/install.log"
UPGRADE_LOG="$DRYRUN_DIR/upgrade.log"
touch "$INSTALL_LOG" "$UPGRADE_LOG"

cat >"$DRYRUN_DIR/setup-macos.sh" <<EOF
#!/bin/bash
set -e

# Inline Mock Environment
brew() {
    case "\$1" in
        list) return 1 ;;
        outdated) return 1 ;;
        install) echo "\$*" >> "$INSTALL_LOG"; return 0 ;;
        upgrade) echo "\$*" >> "$UPGRADE_LOG"; return 0 ;;
        tap|trust|update) return 0 ;;
        --prefix) echo "/opt/homebrew"; return 0 ;;
        *) return 0 ;;
    esac
}
git() { return 0; }
curl() { return 0; }
command() { return 1; }
uname() { echo "arm64"; }
uv() {
    if [ "\$1" = "tool" ] && [ "\$2" = "list" ]; then echo ""; return 0; fi
    return 0
}
EOF

tail -n +2 setup-macos.sh >>"$DRYRUN_DIR/setup-macos.sh"
chmod +x "$DRYRUN_DIR/setup-macos.sh"

if bash "$DRYRUN_DIR/setup-macos.sh" >/dev/null 2>&1; then
  pass "dry-run exits 0"
else
  fail "dry-run exits non-zero"
fi

# Check that all formulae were tracked in mock log
EXPECTED_FORMULAE=("git" "gh" "neovim" "uv" "node" "bun" "zsh-patina")
for pkg in "${EXPECTED_FORMULAE[@]}"; do
  if grep -q "$pkg" "$DRYRUN_DIR/install.log" 2>/dev/null; then
    pass "mock tracker: $pkg install simulation verified"
  else
    fail "mock tracker: $pkg install simulation missed"
  fi
done
rm -rf "$DRYRUN_DIR"

# 17. Dry-run: all installed, all up-to-date -> skip everything
echo "[17] Dry-run (all installed, up-to-date) skips"
DRYRUN_DIR=$(mktemp -d)
INSTALL_LOG="$DRYRUN_DIR/install.log"
UPGRADE_LOG="$DRYRUN_DIR/upgrade.log"
touch "$INSTALL_LOG" "$UPGRADE_LOG"

INSTALLED_PKGS="git\ngh\nneovim\nuv\nnode\nbun\nstarship\nzsh-patina"
INSTALLED_CASKS="ghostty\nobsidian\ndocker"

cat >"$DRYRUN_DIR/setup-macos.sh" <<EOF
#!/bin/bash
set -e

brew() {
    case "\$1" in
        list)
            if [ "\$2" = "--formula" ]; then
                echo -e "$INSTALLED_PKGS"
            elif [ "\$2" = "--cask" ]; then
                echo -e "$INSTALLED_CASKS"
            fi
            return 0 ;;
        outdated) return 1 ;;
        install) echo "\$*" >> "$INSTALL_LOG"; return 0 ;;
        upgrade) echo "\$*" >> "$UPGRADE_LOG"; return 0 ;;
        tap|trust|update) return 0 ;;
        --prefix) echo "/opt/homebrew"; return 0 ;;
        *) return 0 ;;
    esac
}
git() { return 0; }
curl() { return 0; }
command() { if [ "\$2" = "brew" ]; then return 0; fi; return 1; }
uname() { echo "arm64"; }
uv() {
    if [ "\$1" = "tool" ] && [ "\$2" = "list" ]; then echo "ruff 0.4.0"; return 0; fi
    return 0
}
EOF

tail -n +2 setup-macos.sh >>"$DRYRUN_DIR/setup-macos.sh"
chmod +x "$DRYRUN_DIR/setup-macos.sh"

if bash "$DRYRUN_DIR/setup-macos.sh" >/dev/null 2>&1; then
  pass "dry-run (all installed) exits 0"
else
  fail "dry-run (all installed) exits non-zero"
fi

INSTALL_COUNT=$(wc -l <"$DRYRUN_DIR/install.log" | tr -d ' ')
UPGRADE_COUNT=$(wc -l <"$DRYRUN_DIR/upgrade.log" | tr -d ' ')
if [ "$INSTALL_COUNT" -eq 0 ] && [ "$UPGRADE_COUNT" -eq 0 ]; then
  pass "nothing altered when all dependencies are up-to-date"
else
  fail "leak caught: expected 0 actions, triggered $INSTALL_COUNT installs + $UPGRADE_COUNT upgrades"
fi
rm -rf "$DRYRUN_DIR"

# 18. Dry-run: all installed, some outdated -> upgrade only outdated
echo "[18] Dry-run (outdated pkg) upgrades selectively"
DRYRUN_DIR=$(mktemp -d)
INSTALL_LOG="$DRYRUN_DIR/install.log"
UPGRADE_LOG="$DRYRUN_DIR/upgrade.log"
touch "$INSTALL_LOG" "$UPGRADE_LOG"

INSTALLED_PKGS="git\ngh\nneovim\nuv\nnode\nbun\nstarship\nzsh-patina"
INSTALLED_CASKS="ghostty\nobsidian\ndocker"
OUTDATED_FORMULAE="node"
OUTDATED_CASKS="docker"

cat >"$DRYRUN_DIR/setup-macos.sh" <<EOF
#!/bin/bash
set -e

brew() {
    case "\$1" in
        list)
            if [ "\$2" = "--formula" ]; then
                echo -e "$INSTALLED_PKGS"
            elif [ "\$2" = "--cask" ]; then
                echo -e "$INSTALLED_CASKS"
            fi
            return 0 ;;
        outdated)
            if [ "\$2" = "--formula" ]; then
                echo -e "$OUTDATED_FORMULAE"
            elif [ "\$2" = "--cask" ]; then
                echo -e "$OUTDATED_CASKS"
            fi
            return 0 ;;
        install) echo "\$*" >> "$INSTALL_LOG"; return 0 ;;
        upgrade) echo "\$*" >> "$UPGRADE_LOG"; return 0 ;;
        tap|trust|update) return 0 ;;
        --prefix) echo "/opt/homebrew"; return 0 ;;
        *) return 0 ;;
    esac
}
git() { return 0; }
curl() { return 0; }
command() { if [ "\$2" = "brew" ]; then return 0; fi; return 1; }
uname() { echo "arm64"; }
uv() {
    if [ "\$1" = "tool" ] && [ "\$2" = "list" ]; then echo "ruff 0.4.0"; return 0; fi
    return 0
}
EOF

tail -n +2 setup-macos.sh >>"$DRYRUN_DIR/setup-macos.sh"
chmod +x "$DRYRUN_DIR/setup-macos.sh"

if bash "$DRYRUN_DIR/setup-macos.sh" >/dev/null 2>&1; then
  pass "dry-run (selective outdated) exits 0"
else
  fail "dry-run (selective outdated) exits non-zero"
fi

if grep -q "node" "$DRYRUN_DIR/upgrade.log" 2>/dev/null; then
  pass "node correctly caught for targeted upgrade"
else
  fail "node missed upgrade target"
fi

if grep -q "docker" "$DRYRUN_DIR/upgrade.log" 2>/dev/null; then
  pass "docker cask correctly caught for targeted upgrade"
else
  fail "docker cask missed upgrade target"
fi

if grep -q "^git" "$DRYRUN_DIR/upgrade.log" 2>/dev/null || grep -q " git" "$DRYRUN_DIR/upgrade.log" 2>/dev/null; then
  fail "unnecessary system upgrade leaked to git"
else
  pass "git skipped safely"
fi

INSTALL_COUNT=$(wc -l <"$DRYRUN_DIR/install.log" | tr -d ' ')
if [ "$INSTALL_COUNT" -eq 0 ]; then
  pass "zero installations attempted during an update check"
else
  fail "leaked installs caught: $(cat "$DRYRUN_DIR/install.log")"
fi
rm -rf "$DRYRUN_DIR"

# 19. Vim alias check
echo "[19] Vim alias configuration"
if grep -q 'alias vim="nvim"' setup-macos.sh; then
  pass "vim alias check logic present"
else
  fail "missing vim alias logic"
fi

# 20. Zsh Patina custom configurations
echo "[20] Zsh Patina custom configurations"
if grep -q 'brew tap michel-kraemer/zsh-patina' setup-macos.sh && grep -q 'brew trust michel-kraemer/zsh-patina' setup-macos.sh; then
  pass "zsh-patina tap & trust logic verified"
else
  fail "missing tap or trust operations for zsh-patina"
fi

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "All good." || echo "Fix failures above."
exit "$FAIL"
