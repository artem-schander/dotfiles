#!/usr/bin/env python3
"""Stop hook: refuse to end a turn whose edits introduced LSP diagnostics.

`php -l` only parses. It is silent on an undefined variable, a call to a method
that does not exist, a wrong argument count - the errors that reach production
as a 500 and that a green test suite happily misses when the branch is
uncovered. This asks the language server the question the editor asks it.

Runs ONCE per turn rather than per edit: an indexed intelephense run costs
~15s, which is fine at the end of a turn and miserable after every Edit.

Scoped twice over, because a checker that cries wolf is one nobody reads:

  * only files THIS TURN edited, read out of the transcript - not the whole
    dirty tree, which on a long-lived branch is a hundred files nobody touched
    today;
  * only diagnostics on lines the working-tree diff actually changed, so a
    file's standing complaints are never a reason to block.

Test files are left out. Intelephense types `$user->fresh()` as
`Model|Collection|null`, so every `actingAs($user->fresh())` reads as a type
error - and a mistyped test fails loudly on its own, which is the whole point
of it. `bin/lsp-check --changed` still covers them on demand.

Escapable: `stop_hook_active` means Claude has already seen this once, so the
gate cannot deadlock. Fail-open by design: no repo, no checker, or any internal
error exits 0.
"""
import json
import os
import re
import subprocess
import sys

TIMEOUT = 170
# The checker sits beside the repo, not always inside it: here git's toplevel
# is api/src while the wrappers live in api/bin, the same "../bin" layout the
# other bin/ scripts use.
CANDIDATES = ("bin/lsp-check", "api/bin/lsp-check", "../bin/lsp-check")
EDITED_FILE = re.compile(r'"file_path"\s*:\s*"([^"]+\.php)"')
TEST_PATH = re.compile(r"(^|/)(tests?|__tests__|spec)/")


def repository_root(start):
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start, capture_output=True, text=True, timeout=10,
        )
        return out.stdout.strip() or None
    except (subprocess.TimeoutExpired, OSError):
        return None


def find_checker(root):
    """The repo's own checker. A repo without one is simply not gated."""
    for candidate in CANDIDATES:
        full = os.path.normpath(os.path.join(root, candidate))
        if os.path.isfile(full) and os.access(full, os.X_OK):
            return full
    return None


def edited_php_files(transcript_path, root):
    """The .php files this turn wrote, straight out of the transcript."""
    if not transcript_path or not os.path.isfile(transcript_path):
        return []

    try:
        size = os.path.getsize(transcript_path)
        with open(transcript_path, "r", errors="ignore") as handle:
            # A turn's own edits are at the end; reading the whole transcript of
            # a long session would re-report files settled hours ago.
            if size > 2_000_000:
                handle.seek(size - 2_000_000)
            text = handle.read()
    except OSError:
        return []

    files = []
    for path in dict.fromkeys(EDITED_FILE.findall(text)):
        if TEST_PATH.search(path) or "/vendor/" in path:
            continue
        # Tool results (a GitLab file read, for example) also carry
        # `file_path` keys with repository-relative paths; commonpath refuses
        # to mix those with the absolute root, so resolve against it first.
        path = os.path.abspath(os.path.join(root, path))
        if os.path.isfile(path) and os.path.commonpath([root, path]) == root:
            files.append(path)

    return files


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    if data.get("stop_hook_active"):
        return 0

    root = repository_root(data.get("cwd") or os.getcwd())
    if not root:
        return 0

    checker = find_checker(root)
    if not checker:
        return 0

    files = edited_php_files(data.get("transcript_path"), root)
    if not files:
        return 0

    try:
        result = subprocess.run(
            [checker, "--new", *files],
            cwd=root, capture_output=True, text=True, timeout=TIMEOUT,
        )
    except (subprocess.TimeoutExpired, OSError):
        return 0

    # 3 is "tooling unavailable" - never a reason to block a turn.
    if result.returncode != 1:
        return 0

    print(
        "The language server reports errors on lines this turn changed:\n\n"
        f"{result.stdout.strip()}\n\n"
        "These are real: an undefined variable or a missing method is a 500 at "
        "runtime, and a passing test suite only means the branch is uncovered.\n"
        "Fix them, or say in one line why the diagnostic is wrong.\n\n"
        "Re-run with: " + os.path.relpath(checker, root) + " --new <file>",
        file=sys.stderr,
    )
    return 2


sys.exit(main())
