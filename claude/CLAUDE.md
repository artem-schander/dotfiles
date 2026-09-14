## CRITICAL - Commits and Pushes

**NEVER create git commits or push unless the user explicitly asks.**
- Do NOT run `git commit` unless asked
- Do NOT run `git push` unless asked
- Do NOT offer to commit
- Do NOT ask "want me to commit?"
- When explicitly asked to commit and/or push, do it

---

## CRITICAL - Never Start Servers or Bind Ports

**NEVER start a dev server, preview server, or built app — on ANY port — unless explicitly asked.**
- No `yarn dev` / `npm run dev` / `nuxt dev` / `serve` / `artisan serve` / `docker compose up` on your own initiative
- No production builds of an app whose dev server is running (`yarn build` writes into the same `.nuxt`/`dist` and breaks it)
- The user runs these processes in their own terminal multiplexer. A server you start is invisible to them, survives for days, occupies the port their restart then silently skips, and answers requests with stale state — poisoning every measurement taken against it
- Need the app running to verify something? ASK. Do not start it "just to check"
- Never kill or restart a process you did not start without explicit permission either
- If you already started one: say so immediately and plainly, do not rationalise it away
- This rule is NON-NEGOTIABLE

---

## CRITICAL - Test Integrity Rule

**There is NO such thing as "pre-existing errors" or "pre-existing failing tests".**
- Before starting any new feature, ALL tests MUST be passing
- If tests fail, they are YOUR responsibility to fix - no exceptions
- Never blame failing tests on "pre-existing issues"
- If you encounter failing tests, fix them BEFORE proceeding
- This rule is NON-NEGOTIABLE

---

## CRITICAL - Data Flow Tracing Rule

**When data is not arriving where expected, TRACE THE DATA - do not guess or theorize.**
- Before writing ANY fix, trace the actual data flow from source to destination
- Identify EVERY file and function the data passes through
- Show this path to the user before touching any code
- Do NOT invent theories (e.g., "Vue reactivity caching", "computed property issues")
- If the user says "the request doesn't have the fields" - immediately look at what builds the request (API layer), not the component
- This rule is NON-NEGOTIABLE

---

## CRITICAL - No Changes Based on Guesses

**NEVER make code changes based on assumptions about framework/library behavior.**
- Before proposing a fix, VERIFY the root cause by checking official docs, reading framework source code, or writing a test script
- If you catch yourself saying "I think", "maybe", "wait, is that actually true?" — STOP and verify before proceeding
- Never scale a fix across multiple repos/files until the fix is confirmed working on ONE first
- When debugging framework behavior, READ the actual source code or TEST it — do NOT guess
- This rule is NON-NEGOTIABLE

---

- test driven development
- remember to always use `use statements` instead inline full namepaces. Example: instead of `\Sti3bas\ScoutArray\Facades\Search::assertNotSynced($article)`, write `use Sti3bas\ScoutArray\Facades\Search;` then `Search::assertNotSynced($article)`
- NEVER use vertical alignment in array assignments or variable declarations
- NEVER use acronyms or abbreviated/unclear names for variables, methods, classes, etc. Always use full, descriptive, understandable names (e.g., `$customerGroup` not `$cg`, `$difference` not `$diff`)
- In Laravel projects, **always prefer `Arr` and `Str` helpers** over PHP native array/string functions (e.g., `Arr::has()` not `array_key_exists()`, `Arr::first()` not `array_shift()`, `Str::contains()` not `str_contains()`, `collect()->diff()` not `array_diff()`, etc.)
