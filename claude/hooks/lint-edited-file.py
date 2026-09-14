#!/usr/bin/env python3
"""PostToolUse hook: check the file Claude just edited, using whatever tooling
that project already has. Formatters auto-fix silently; real errors exit 2 so
Claude must fix them before continuing.

Fail-open by design: unknown language, missing tool, or any internal error
exits 0 and stays out of the way.
"""
import json
import os
import subprocess
import sys

TIMEOUT = 25
SKIP_DIRS = ("/vendor/", "/node_modules/", "/dist/", "/build/", "/.venv/", "/storage/")


def project_root(path):
    directory = os.path.dirname(os.path.abspath(path))
    while directory != "/":
        if os.path.isdir(os.path.join(directory, ".git")):
            return directory
        directory = os.path.dirname(directory)
    return None


def local_binary(root, *candidates):
    for candidate in candidates:
        full = os.path.join(root, candidate)
        if os.path.isfile(full) and os.access(full, os.X_OK):
            return full
    return None


def run(command, cwd):
    try:
        return subprocess.run(
            command, cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT
        )
    except (subprocess.TimeoutExpired, OSError):
        return None


def which(name):
    from shutil import which as _which

    return _which(name)


def check(path, root):
    """Return an error string to report back, or None when clean."""
    extension = os.path.splitext(path)[1].lower()

    if extension == ".php":
        if which("php"):
            result = run(["php", "-l", path], root)
            if result and result.returncode != 0:
                return (result.stdout + result.stderr).strip()
        pint = local_binary(root, "vendor/bin/pint", "src/vendor/bin/pint")
        if pint:
            run([pint, "--quiet", path], root)
        return None

    if extension in (".js", ".jsx", ".ts", ".tsx", ".vue", ".mjs", ".cjs"):
        eslint = local_binary(root, "node_modules/.bin/eslint")
        if eslint:
            result = run([eslint, "--quiet", path], root)
            if result and result.returncode != 0:
                return (result.stdout + result.stderr).strip()
        prettier = local_binary(root, "node_modules/.bin/prettier")
        if prettier:
            run([prettier, "--write", "--log-level", "silent", path], root)
        return None

    if extension == ".py":
        ruff = local_binary(root, ".venv/bin/ruff") or which("ruff")
        if ruff:
            run([ruff, "format", "--quiet", path], root)
            result = run([ruff, "check", "--quiet", path], root)
            if result and result.returncode != 0:
                return (result.stdout + result.stderr).strip()
            return None
        result = run([sys.executable, "-m", "py_compile", path], root)
        if result and result.returncode != 0:
            return (result.stdout + result.stderr).strip()
        return None

    if extension == ".go" and which("gofmt"):
        run(["gofmt", "-w", path], root)
        return None

    if extension == ".rs" and which("rustfmt"):
        run(["rustfmt", "--edition", "2021", path], root)
        return None

    return None


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    path = (data.get("tool_input") or {}).get("file_path")
    if not path or not os.path.isfile(path):
        return 0
    if any(fragment in path for fragment in SKIP_DIRS):
        return 0

    root = project_root(path)
    if not root:
        return 0

    try:
        error = check(path, root)
    except Exception:
        return 0

    if error:
        relative = os.path.relpath(path, root)
        print(
            f"Lint/syntax errors in {relative} — fix them before continuing:\n\n{error}",
            file=sys.stderr,
        )
        return 2
    return 0


sys.exit(main())
