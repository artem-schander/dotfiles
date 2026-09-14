#!/usr/bin/env bash
# Link the shared Claude Code config into ~/.claude and merge shared settings
# into the machine-local settings.json.
#
# ~/.claude/settings.json is NOT symlinked: Claude Code rewrites it, and its
# autoMode block holds machine- and employer-specific context that must never
# reach a public repository. The shared keys are merged in instead, and the
# local-only keys listed in LOCAL_ONLY_KEYS are preserved.

DOTCLAUDE="$HOME/.dotfiles/claude"
TARGET="$HOME/.claude"
LOCAL_ONLY_KEYS='["autoMode"]'

GREEN="${GREEN:-$(tput setaf 2 2>/dev/null)}"
YELLOW="${YELLOW:-$(tput setaf 3 2>/dev/null)}"
NORMAL="${NORMAL:-$(tput sgr0 2>/dev/null)}"

echo -e "\n\n${GREEN}Setting up Claude Code"
echo -e "==============================${NORMAL}"

mkdir -p "$TARGET/hooks"

linkInto () {
    local source_path="$1" target_path="$2"
    if [ -L "$target_path" ]; then
        [ "$(readlink "$target_path")" = "$source_path" ] && return 0
        rm "$target_path"
    elif [ -e "$target_path" ]; then
        echo "  ~${target_path#$HOME} exists, backing up to ~${target_path#$HOME}.bak"
        mv -f "$target_path" "$target_path.bak"
    fi
    ln -s "$source_path" "$target_path"
    echo "  linked ~${target_path#$HOME}"
}

linkInto "$DOTCLAUDE/CLAUDE.md" "$TARGET/CLAUDE.md"
linkInto "$DOTCLAUDE/statusline-command.sh" "$TARGET/statusline-command.sh"
for hook in "$DOTCLAUDE"/hooks/*; do
    [ -e "$hook" ] || continue
    chmod +x "$hook"
    linkInto "$hook" "$TARGET/hooks/$(basename "$hook")"
done

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${YELLOW}  python3 not found — settings.json not merged, hooks will not run${NORMAL}"
    return 0 2>/dev/null || exit 0
fi

python3 - "$DOTCLAUDE/settings.json" "$TARGET/settings.json" "$LOCAL_ONLY_KEYS" <<'PYEOF'
import json
import os
import shutil
import sys

shared_path, local_path, local_only = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])

with open(shared_path) as handle:
    merged = json.load(handle)

if os.path.exists(local_path):
    shutil.copy2(local_path, local_path + ".bak")
    try:
        with open(local_path) as handle:
            existing = json.load(handle)
    except ValueError:
        existing = {}
    for key in local_only:
        if key in existing:
            merged[key] = existing[key]

with open(local_path, "w") as handle:
    json.dump(merged, handle, indent=2)

kept = [k for k in local_only if k in merged]
print(f"  merged settings.json (kept local: {', '.join(kept) or 'nothing'})")
PYEOF
