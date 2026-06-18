#!/bin/bash

# Test: verify setup-macos.sh runs without errors (dry-run where possible)

set -e
PASS=0
FAIL=0

pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

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

# 6. All brew formulae exist
echo "[6] Brew formulae validity"
BREW_FORMULAE=("git" "gh" "neovim" "uv" "node")
for pkg in "${BREW_FORMULAE[@]}"; do
    if brew info --json=v2 "$pkg" 2>/dev/null | grep -q "\"name\":\"$pkg\""; then
        pass "formula: $pkg"
    else
        # Fallback: check if brew knows about it
        if brew info "$pkg" &>/dev/null; then
            pass "formula: $pkg"
        else
            fail "formula: $pkg not found"
        fi
    fi
done

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

# 12. Run in dry mode (stub brew/curl/git, check exit code)
echo "[12] Dry-run with stubbed commands"
DRYRUN_DIR=$(mktemp -d)
cat > "$DRYRUN_DIR/setup-macos.sh" << 'WRAPPER'
#!/bin/bash
set -e
# Stub external commands
brew() { return 0; }
git() { return 0; }
curl() { return 0; }
command() { return 1; }
eval() { return 0; }
uname() { echo "arm64"; }
uv() { return 0; }
export -f brew git curl command eval uname uv
WRAPPER
# Append original script (skip shebang)
tail -n +2 setup-macos.sh >> "$DRYRUN_DIR/setup-macos.sh"
chmod +x "$DRYRUN_DIR/setup-macos.sh"
if bash "$DRYRUN_DIR/setup-macos.sh" 2>/dev/null; then
    pass "dry-run exits 0"
else
    fail "dry-run exits non-zero"
fi
rm -rf "$DRYRUN_DIR"

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "All good." || echo "Fix failures above."
exit "$FAIL"
