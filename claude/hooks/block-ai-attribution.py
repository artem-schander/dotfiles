#!/usr/bin/env python3
"""PreToolUse hook (Bash): no AI attribution line ever reaches a git repository.

Denies, before it runs, any shell command that
  - mentions git and carries an attribution line (the patterns of
    ~/.dotfiles/git/hooks/claude-attribution.patterns, shared with the
    commit-msg and pre-push git hooks), or
  - runs git with --no-verify, or overrides core.hooksPath, both of which
    would skip those git hooks.

The git hooks catch every commit made on this machine; this hook catches the
attempt in Claude Code itself, including the one way around the git hooks.
Fails closed on a missing pattern file: the commit waits until it is back.
"""
import json
import os
import re
import shlex
import sys

PATTERNS_FILE = os.path.expanduser("~/.dotfiles/git/hooks/claude-attribution.patterns")

GIT = re.compile(r"\bgit\b")


def skips_git_hooks(command):
    """--no-verify or core.hooksPath as an argument, not as words inside a quoted message or
    a heredoc: only the shell words before the first heredoc are looked at."""
    head = command.split("<<", 1)[0]
    try:
        words = shlex.split(head)
    except ValueError:
        words = head.split()
    return any(word == "--no-verify" or word.lower().startswith("core.hookspath") for word in words)


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def attribution_patterns():
    with open(PATTERNS_FILE, encoding="utf-8") as handle:
        lines = [line.strip() for line in handle]
    # The file holds POSIX extended expressions; [[:space:]] is the only class they use.
    return [
        re.compile(line.replace("[[:space:]]", r"\s"), re.IGNORECASE | re.MULTILINE)
        for line in lines
        if line and not line.startswith("#")
    ]


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return

    if payload.get("tool_name") != "Bash":
        return

    command = (payload.get("tool_input") or {}).get("command") or ""
    if not GIT.search(command):
        return

    if skips_git_hooks(command):
        deny(
            "git with --no-verify or a core.hooksPath override is not allowed: it skips the "
            "hooks that keep AI attribution lines out of commits. Run the command without it."
        )

    try:
        patterns = attribution_patterns()
    except OSError:
        deny(f"{PATTERNS_FILE} is missing, so AI attribution lines cannot be checked. Restore it first.")

    for pattern in patterns:
        if pattern.search(command):
            deny(
                "This command would put an AI attribution line (Co-Authored-By: Claude, "
                "Claude-Session, Generated with Claude Code) into git. Commit messages read as "
                "written by the user: remove the line and run it again."
            )


if __name__ == "__main__":
    main()
