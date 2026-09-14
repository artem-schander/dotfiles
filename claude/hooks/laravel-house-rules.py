#!/usr/bin/env python3
"""PostToolUse hook: reject Laravel house-rule violations in the file just written.

These are rules a model reliably forgets: foreign keys assigned or mass-assigned
instead of going through the relation, setRelation() where associate()/save()
already sets it, inline fully-qualified class names, and user-facing literals
built in PHP instead of the line files.

Scope: application code (app/) of a real Laravel project - the nearest ancestor
holding an `artisan` file. Everything else is left alone.

Escape hatches, because a rule without one gets disabled wholesale:
  - `// house-rules: allow` at the end of a line, or on the line above it
  - `house-rules: ignore-file` anywhere in the file (put it in the class docblock)
  - a `.claude-house-rules.json` in the project root:
        {"disable": ["inline_fqcn"], "enable": ["user_facing_literal"]}

Exits 2 with the offending lines so the edit is corrected before work continues.
Fail-open: anything unexpected exits 0 and stays out of the way.
"""
import json
import os
import re
import sys

SKIP_DIRS = (
    "/vendor/", "/node_modules/", "/storage/", "/bootstrap/cache/",
    "/database/migrations/", "/database/seeders/", "/database/factories/",
    "/tests/", "/Tests/",
)

ALLOW_LINE = "house-rules: allow"
IGNORE_FILE = "house-rules: ignore-file"
CONFIG_FILE = ".claude-house-rules.json"

# id -> (pattern, message, on_by_default)
RULES = {
    "fk_assignment": (
        re.compile(r"->\s*[a-z_]+_id\s*=\s*\$\w+->id\b"),
        "foreign key assigned from a model: use $model->relation()->associate($other)",
        True,
    ),
    "fk_mass_assignment": (
        re.compile(r"^\s*'[a-z_]+_id'\s*=>\s*\$\w+->id\b"),
        "foreign key mass-assigned: build the model, then relation()->associate($other)",
        True,
    ),
    "set_relation": (
        re.compile(r"->setRelation\("),
        "setRelation(): associate()/save() already set the loaded relation - remove it",
        True,
    ),
    "inline_fqcn": (
        re.compile(r"(?<![\w\\])\\(?:App|Illuminate)\\[A-Za-z\\]+::"),
        "inline fully-qualified class name: add a use statement",
        True,
    ),
    # Off by default: whether a returned literal is user-facing is project
    # knowledge, and an enum-ish `return 'Draft';` is not a violation.
    "user_facing_literal": (
        re.compile(r"return\s+'[A-ZÄÖÜ][A-Za-zÄÖÜäöüß]+(?:\s+[A-Za-zÄÖÜäöüß]+)*'\s*;"),
        "user-facing literal returned from PHP: put it in lang/ and call __()",
        False,
    ),
}


def laravel_root(path):
    directory = os.path.dirname(os.path.abspath(path))
    while directory != "/":
        if os.path.isfile(os.path.join(directory, "artisan")):
            return directory
        directory = os.path.dirname(directory)
    return None


def active_rules(root):
    enabled = {name for name, (_, _, default) in RULES.items() if default}

    try:
        with open(os.path.join(root, CONFIG_FILE), encoding="utf-8") as handle:
            config = json.load(handle)
    except Exception:
        return enabled

    enabled |= set(config.get("enable") or [])
    enabled -= set(config.get("disable") or [])

    return enabled & set(RULES)


def offences(path, enabled):
    with open(path, encoding="utf-8", errors="replace") as handle:
        lines = handle.read().split("\n")

    if any(IGNORE_FILE in line for line in lines):
        return []

    found = []
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith(("*", "//", "/*", "#")):
            continue
        if ALLOW_LINE in line or (index and ALLOW_LINE in lines[index - 1]):
            continue

        for name in enabled:
            pattern, message, _ = RULES[name]
            if pattern.search(line):
                found.append(f"  {path}:{index + 1}: {message}\n    {stripped[:120]}")

    return found


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    path = (payload.get("tool_input") or {}).get("file_path") or ""
    if not path.endswith(".php") or not os.path.isfile(path):
        return 0

    absolute = os.path.abspath(path)
    if any(part in absolute for part in SKIP_DIRS):
        return 0

    root = laravel_root(absolute)
    if not root or not absolute.startswith(os.path.join(root, "app") + os.sep):
        return 0

    try:
        found = offences(absolute, active_rules(root))
    except Exception:
        return 0

    if not found:
        return 0

    print(
        "House rules - fix these before continuing "
        "(`// house-rules: allow` on a line that is genuinely an exception):\n"
        + "\n".join(found),
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
