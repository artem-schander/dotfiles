## CRITICAL - Commits and Pushes

**NEVER create git commits or push unless the user explicitly asks.**
- Do NOT run `git commit` unless asked
- Do NOT run `git push` unless asked
- Do NOT offer to commit
- Do NOT ask "want me to commit?"
- When explicitly asked to commit and/or push, do it
- NEVER mention Claude, AI or yourself in a commit message: no `Co-Authored-By: Claude`, no `Claude-Session:` link, no "Generated with Claude Code" line. The message reads as written by the user

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

---

## CRITICAL - Design Principles (SOLID, KISS, DRY, DDD, Layered Architecture)

**Every change in every project and language follows these principles. They are NOT optional and NOT "for later".**

**Apply them as far as reasonable, never to the point of over-engineering.** Keep things simple when they do not need to be complex: a principle that adds classes, layers or indirection without a real gain in readability, testability or change safety is not applied. Simple and correct beats "textbook".

**SOLID:**
- **S**ingle Responsibility: one class/module/function does ONE thing and has ONE reason to change. A class that persists, validates and formats is three classes
- **O**pen/Closed: extend behaviour by adding (a new class, strategy, handler, plugin), not by editing a growing `if`/`switch` in an existing one
- **L**iskov Substitution: a subtype/implementation must be usable wherever its parent/interface is, without surprises (no "not implemented" throws, no narrowed preconditions, no widened side effects)
- **I**nterface Segregation: small, focused interfaces. No client is forced to depend on methods it does not use
- **D**ependency Inversion: depend on abstractions, not concretions. Business logic never constructs its own infrastructure (a mailer, an HTTP client, a database handle); it receives it via constructor injection / a container / a parameter

**KISS:**
- The simplest solution that correctly solves the problem wins. Boring over clever
- No speculative abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes (YAGNI)
- If the explanation is longer than the code, the code is wrong

**DRY:**
- Every piece of knowledge lives in ONE place. Before writing anything, search for an existing helper, utility, module, component or pattern and reuse or extend it
- Duplicated knowledge (a rule, a mapping, a validation, a query) is a bug waiting to diverge. Extract on the SECOND occurrence, not the fifth
- DRY is about knowledge, not text: two similar-looking blocks that change for different reasons stay separate

**DDD (Domain-Driven Design):**
- Use the domain's ubiquitous language in code: names of classes, methods, fields, events and API types are the words the business uses, not technical synonyms
- Respect bounded contexts: a concept belongs to ONE context/module. Do not reach into another context's internals; talk to it through its public interface (services, events, API)
- Rich domain models: business rules live with the domain object (invariants, state transitions, derived values), not scattered across controllers, handlers and jobs
- Aggregates guard their invariants: mutate a child only through its aggregate root; never let two entry points enforce the same rule differently
- Cross-context side effects (indexing, notifications, denormalization, sync) go through domain events, never through inline calls into another context

**Layered Architecture:**
- Layers, top to bottom: **Presentation** (HTTP/API handlers, CLI commands, UI components) -> **Application** (use cases, services, orchestration, background jobs) -> **Domain** (entities, value objects, domain rules, events, policies) -> **Infrastructure** (database, queues, mail, external APIs, file storage)
- Dependencies point DOWN only. The domain never knows about the API layer; a service never knows about an HTTP request; a background job never parses raw request input
- Presentation layer is thin: validate input, call ONE application service/use case, format the response. No business logic in handlers, controllers or UI components
- Infrastructure is swappable: the domain and application layers talk to it through interfaces so a mailer, search engine or payment gateway can be replaced without touching business logic
- Frontends mirror this: view components render and emit; a store/API layer talks to the backend; business rules are not computed in templates

**Self-check before calling a change done:** name the layer each new file belongs to, name the ONE responsibility of each new class, and name the existing code you reused instead of duplicating. If you cannot, the change is not done.
