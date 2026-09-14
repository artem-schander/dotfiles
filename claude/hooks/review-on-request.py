#!/usr/bin/env python3
"""UserPromptSubmit hook: when the user asks for a code review, pin down what
that means so it does not depend on Claude remembering.

Emits an instruction on stdout, which Claude Code appends to the context.
Never blocks; any internal error exits 0 silently.
"""
import json
import re
import sys

REVIEW_REQUEST = re.compile(
    r"\b(code[- ]review"
    r"|review\s+(the\s+|my\s+|this\s+|these\s+)?"
    r"(code|changes|change|diff|implementation|work|branch|files?)\b"
    r"|review\s+(this|it)\b"
    r"(?!\s+(doc|docs|documentation|readme|spec|plan|text|article|email|message)))",
    re.IGNORECASE,
)

INSTRUCTION = (
    "The user asked for a code review. Run BOTH passes, in this order, and do "
    "not substitute one for the other:\n"
    "  1. /code-review  — correctness, reuse, efficiency.\n"
    "  2. ponytail-review — over-engineering: what to delete, speculative "
    "abstraction, reinvented stdlib.\n"
    "Report the findings from both together. If a pass returns nothing, say so "
    "explicitly rather than omitting it."
)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if REVIEW_REQUEST.search(data.get("prompt") or ""):
        print(INSTRUCTION)
    return 0


sys.exit(main())
