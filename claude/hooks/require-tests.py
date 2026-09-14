#!/usr/bin/env python3
"""Stop hook: refuse to end a turn that changed source code without either
touching a test or running the test suite.

Escapable: after blocking once, `stop_hook_active` is set on the next Stop, so
Claude gets through by adding a test, running the suite, or stating why neither
applies. It can never deadlock.

Fail-open by design: not a git repo, no changes, or any internal error exits 0.
"""
import json
import os
import re
import subprocess
import sys

CODE_EXTENSIONS = {
    ".php", ".js", ".jsx", ".ts", ".tsx", ".vue", ".mjs", ".cjs",
    ".py", ".go", ".rs", ".rb", ".java", ".kt", ".cs", ".swift",
    ".ex", ".exs", ".scala", ".c", ".cc", ".cpp", ".h", ".hpp",
}

IGNORED_PATH_FRAGMENTS = (
    "vendor/", "node_modules/", "dist/", "build/", ".venv/",
    "storage/", "migrations/", ".claude/",
)

TEST_PATH = re.compile(
    r"(^|/)(tests?|__tests__|spec)/"
    r"|[Tt]est\.[a-z]+$"
    r"|_test\.[a-z]+$"
    r"|\.(test|spec)\.[a-z]+$"
    r"|(^|/)test_[^/]+\.py$"
)

TEST_COMMAND = re.compile(
    r"\b("
    r"phpunit|artisan test|bin/test|pest"
    r"|(npm|yarn|pnpm) (run )?test|jest|vitest"
    r"|pytest|python -m unittest"
    r"|go test|cargo test|rspec|mix test|dotnet test|gradle test|mvn test"
    r")\b"
)


def git(args, cwd):
    result = subprocess.run(
        ["git"] + args, cwd=cwd, capture_output=True, text=True, timeout=15
    )
    return result.stdout if result.returncode == 0 else None


def changed_files(root):
    output = git(["status", "--porcelain", "--untracked-files=all"], root)
    if not output:
        return []
    files = []
    for line in output.splitlines():
        name = line[3:].strip()
        if " -> " in name:
            name = name.split(" -> ")[-1]
        files.append(name.strip('"'))
    return files


def is_relevant(path):
    if any(fragment in path for fragment in IGNORED_PATH_FRAGMENTS):
        return False
    return os.path.splitext(path)[1].lower() in CODE_EXTENSIONS


def tests_were_run(transcript_path):
    if not transcript_path or not os.path.isfile(transcript_path):
        return False
    try:
        size = os.path.getsize(transcript_path)
        with open(transcript_path, "r", errors="ignore") as handle:
            if size > 2_000_000:
                handle.seek(size - 2_000_000)
            return bool(TEST_COMMAND.search(handle.read()))
    except OSError:
        return False


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    if data.get("stop_hook_active"):
        return 0

    cwd = data.get("cwd") or os.getcwd()
    root = git(["rev-parse", "--show-toplevel"], cwd)
    if not root:
        return 0
    root = root.strip()

    files = [f for f in changed_files(root) if is_relevant(f)]
    if not files:
        return 0

    source = [f for f in files if not TEST_PATH.search(f)]
    tests = [f for f in files if TEST_PATH.search(f)]

    if not source or tests:
        return 0
    if tests_were_run(data.get("transcript_path")):
        return 0

    listing = "\n".join(f"  - {f}" for f in source[:12])
    if len(source) > 12:
        listing += f"\n  ... and {len(source) - 12} more"

    print(
        "Source changed, but no test was touched and no test suite was run.\n\n"
        f"{listing}\n\n"
        "Before finishing, do one of:\n"
        "  1. Add or update a test covering this change, or\n"
        "  2. Run the relevant tests and report the result, or\n"
        "  3. State in one line why this change needs no test "
        "(docs, config, pure rename, generated file).\n\n"
        "Then stop again — this gate will not block a second time.",
        file=sys.stderr,
    )
    return 2


sys.exit(main())
