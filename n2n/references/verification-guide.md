# N2N Verification Guide

Detailed procedures for each verification type. Referenced from SKILL.md Phase 3.

---

## Build Check (always required)

```bash
cd [PROJECT_DIR] && [BUILD_CMD]
```

See your traversal playbook for the actual build command and project directory.

Must exit 0. Catches type errors, missing imports, broken references.

If build fails:
1. Read the error output — identify the file and line
2. Fix the root cause (not just the symptom)
3. Re-run build to confirm

---

## Browser Verification via Playwright (UI changes)

Use when: Components, pages, styles, or any visible UI was modified.

**Playwright is a first-class verification method.** Use it for all UI work — not just screenshots.

### Prerequisites

1. Dev server running (see traversal playbook for command and port)
2. Auth bypass enabled (see traversal playbook for dev auth setup)

### Steps

1. **Navigate.** `npx @playwright/cli goto "http://localhost:[PORT]/[page]" -s=[SESSION]` → open the page.
2. **Snapshot.** `npx @playwright/cli snapshot -s=[SESSION]` → verify elements exist in the accessibility tree. This is the primary verification — confirms the DOM rendered correctly.
3. **Screenshot.** `npx @playwright/cli screenshot -s=[SESSION]` → visual confirmation of layout, spacing, colors.
4. **Console check.** `npx @playwright/cli console -s=[SESSION]` → verify no JS errors, no failed fetches, no hydration mismatches. If MCP Playwright tools are available (e.g., `mcp__playwright__browser_console_messages`), those work too.
5. **Network check.** `npx @playwright/cli network -s=[SESSION]` → verify correct API calls fired with expected methods/status codes. MCP alternative: `mcp__playwright__browser_network_requests`.
6. **Interact.** `npx @playwright/cli click <ref> -s=[SESSION]` / `fill <ref> "text"` / `press Enter` → test user interactions (buttons, forms, navigation).
7. **Evaluate.** `npx @playwright/cli eval "expression" -s=[SESSION]` → run JS in page context for deeper checks (state values, DOM queries, fetch calls).

### Available Playwright CLI Commands

Run via `npx @playwright/cli <command> -s=[SESSION]`:

| Command | Purpose |
|---------|---------|
| `goto <url>` | Navigate to a URL |
| `snapshot` | Accessibility tree (primary DOM check) |
| `screenshot` | Visual screenshot |
| `click <ref>` | Click an element by ref from snapshot |
| `fill <ref> "text"` | Type text into an input field |
| `press <key>` | Keyboard input (Enter, Escape, Tab) |
| `eval "expression"` | Run JS in page context |
| `hover <ref>` | Hover over element |
| `select <ref> <value>` | Select dropdown option |
| `close` | Close browser session |

### Common UI Failures

- Component renders but data is missing → check API response via network check
- Style looks wrong → screenshot + check against project style guide (if defined in playbook)
- Console shows hydration error → server/client component mismatch (`"use client"` missing)
- Element not found in snapshot → wrong page, component not mounted, or loading state stuck
- Network request returns 401 → dev auth bypass not enabled

---

## API Endpoint Verification (API changes)

Use when: API routes were added, modified, or their dependencies changed.

### Steps

1. **Construct a realistic request.** Use actual IDs and data shapes from
   the codebase.
2. **Hit the endpoint.**
   ```bash
   curl -X POST http://localhost:[PORT]/api/[route] \
     -H "Content-Type: application/json" \
     -H "Cookie: [session cookie]" \
     -d '{ ... }'
   ```
3. **Verify response.**
   - Status code matches expected (200, 201, 400, etc.)
   - Response shape matches TypeScript/Python types
   - Data is correct (not empty, not stale, not from wrong tenant)
4. **Check error cases** (if validation was changed).
   - Missing required fields → 400
   - Invalid auth → 401/403
   - Not found → 404

### Common API Failures

See your traversal playbook's "Common Failure Patterns" section for
project-specific API error patterns.

---

## Database Migration Verification (DB changes)

Use when: Migration files were created or modified.

### Checklist

1. **Syntax.** Read the migration — verify valid SQL syntax.
2. **Required filters.** Check the traversal playbook's DB Pattern section
   for any required filters on new tables (e.g., tenant_id, is_active).
3. **Indexes.** Filterable columns and foreign keys need indexes.
4. **Row multiplication.** Check for JOINs that could multiply rows
   (one-to-many without proper filtering).
5. **Backwards compatibility.** Will the migration break existing queries?

### Common DB Failures

- Missing required filter column → data isolation violation
- Missing index → slow queries at scale
- Array columns with null elements → `.map()` crashes downstream

---

## Verification Matrix

| Change Type     | Build | Browser | API | DB Check |
|-----------------|-------|---------|-----|----------|
| UI component    | Yes   | Yes     | -   | -        |
| API route       | Yes   | -       | Yes | -        |
| Engine/lib      | Yes   | -       | -   | -        |
| DB migration    | Yes   | -       | -   | Yes      |
| Full-stack      | Yes   | Yes     | Yes | Maybe    |

Select verification types based on this matrix. Multiple types may apply
for a single task.
