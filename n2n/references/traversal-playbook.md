# [PROJECT_NAME] — Traversal Playbook

Read this at the start of every /n2n invocation. Do NOT re-explore patterns documented here — they are stable.

> **First time?** Replace all `[PLACEHOLDERS]` with your project's actual values.
> See `examples/` in the n2n repo for filled-in playbooks (Next.js, Python).

---

## Build & Scripts

**Working directory:** `cd "[PROJECT_DIR]"`

| Command | Purpose |
|---------|---------|
| `[BUILD_CMD]` | Production build — catches type errors, missing imports. **Always run.** |
| `[DEV_CMD]` | Dev server on **localhost:[PORT]** |
| `[TEST_CMD]` | Test runner (e.g., `npm run test`, `pytest`, `cargo test`) |
| `[FORMAT_CMD]` | Code formatter (e.g., `npm run format`, `black .`, `cargo fmt`) |
| `[LINT_CMD]` | Linter (e.g., `npm run lint`, `ruff check`, `clippy`) |

**Dev auth bypass:** [How to skip authentication in development — e.g., env var, test user, mock middleware]

---

## Directory Map

<!-- Paste your project's directory tree. Focus on the directories n2n will
     touch most — source code, tests, configs, migrations. -->

```
[PROJECT_NAME]/
├── [Fill in your project structure]
├── ...
└── ...
```

---

## Auth Flow

<!-- How does a request get authenticated? Middleware? JWT? Session cookie?
     What headers or tokens does the API expect? How does dev bypass work? -->

[Describe your auth flow here]

---

## API/Route Pattern

<!-- Show a typical API route or handler with your project's conventions.
     Include: how to extract auth/user context, error handling pattern,
     response format. This is what n2n will follow when creating new routes. -->

```
[Paste a representative API route/handler here]
```

**Key helpers:**
- [List utility functions n2n should know about — auth extractors, error formatters, validators]

**Standard error codes:** [List the HTTP status codes your project uses and when]

---

## Page/Component Pattern

<!-- Show a typical page or component structure. Include: state management
     approach, data fetching pattern, layout conventions. -->

```
[Paste a representative page/component here]
```

---

## DB Pattern

<!-- Database conventions — what ORM/client? Required filters on every query?
     Migration tool and conventions? Index requirements? -->

- **ORM/Client:** [e.g., Supabase, Prisma, SQLAlchemy, Drizzle]
- **Required filters:** [e.g., "Every query MUST filter by tenant_id"]
- **Migration tool:** [e.g., Prisma migrate, Alembic, raw SQL files]
- **Index conventions:** [e.g., "All foreign keys need indexes"]
- **Special rules:** [e.g., "JOINs on X table must include AND is_active = true"]

---

## Key Utility Files

| File | Purpose |
|------|---------|
| [path] | [purpose] |
| [path] | [purpose] |
| [path] | [purpose] |

---

## Test Pattern

- **Location:** [e.g., `tests/`, `__tests__/`, `src/**/*.test.ts`]
- **Runner:** [e.g., Vitest, Jest, pytest, cargo test]
- **Mocking:** [e.g., "Mock DB before importing tested module"]
- **Run:** [e.g., `npm run test` (single) or `npm run test:watch` (watch)]

---

## Browser Verification (Playwright CLI)

**Dev server must be running.** Default port [PORT].

Typical flow (all commands use `-s=[SESSION_NAME]` for session persistence):
1. `npx @playwright/cli goto "http://localhost:[PORT]/[page]" -s=[SESSION_NAME]` → navigate
2. `npx @playwright/cli snapshot -s=[SESSION_NAME]` → verify elements in accessibility tree
3. `npx @playwright/cli screenshot -s=[SESSION_NAME]` → visual confirmation
4. `npx @playwright/cli console -s=[SESSION_NAME]` → check for JS errors
5. `npx @playwright/cli network -s=[SESSION_NAME]` → verify API calls
6. `npx @playwright/cli click <ref> -s=[SESSION_NAME]` / `fill <ref> "text"` → test interactions

---

## Common Failure Patterns

<!-- Add patterns as you discover them. This table prevents repeat debugging. -->

| Symptom | Likely Cause |
|---------|-------------|
| [e.g., 500 "tenant_id is required"] | [e.g., Missing auth context extraction] |
| [e.g., Hydration error in console] | [e.g., Server/client component mismatch] |
| [e.g., Build fails on import] | [e.g., Wrong path alias] |

---

## Project-Specific Conventions

<!-- This section grows as n2n discovers patterns during runs.
     n2n will automatically append new patterns here. -->

[None yet — n2n will populate this as it learns your codebase]

---

## Known Issues File

**Path:** [ISSUES_FILE_PATH]

<!-- Default: `memory/known-issues.md` in your project root.
     n2n logs every bug it finds here. Read at session start to avoid repeats. -->
