# My SaaS App — Traversal Playbook

Read this at the start of every /n2n invocation. Do NOT re-explore patterns documented here — they are stable.

> This is an example of a filled-in playbook for a Next.js + Supabase + Tailwind project.
> Copy `n2n/references/traversal-playbook.md` and replace placeholders with your own values.

---

## Build & Scripts

**Working directory:** `cd "/Users/me/projects/my-saas-app"`

| Command | Purpose |
|---------|---------|
| `npm run build` | Production build — catches TS errors, missing imports. **Always run.** |
| `npm run dev` | Dev server on **localhost:3000** |
| `npm run test` | Vitest single run |
| `npm run format` | Prettier write |
| `npm run lint` | ESLint |

**Dev auth bypass:** Set `ALLOW_DEV_AUTH_BYPASS=true` + `NODE_ENV=development` in `.env.local`. Uses dummy workspace `00000000-0000-0000-0000-000000000000`.

---

## Directory Map

```
my-saas-app/
├── src/
│   ├── app/
│   │   ├── (auth)/              # login, signup
│   │   ├── (dashboard)/         # authenticated pages + layout
│   │   │   └── [feature]/page.tsx
│   │   ├── (marketing)/         # public pages
│   │   ├── api/                 # API routes (~50 across 20 groups)
│   │   │   └── [feature]/route.ts
│   │   └── components/          # shared UI components
│   ├── engine/                  # business logic (~40 modules)
│   ├── lib/
│   │   ├── api/                 # external API clients
│   │   ├── auth/                # Supabase auth helpers
│   │   ├── config/              # constants, models, pricing
│   │   ├── db/                  # DB helpers (one file per domain)
│   │   ├── utils/               # api-handler, fetch-timeout
│   │   └── validations/         # Zod schemas
│   └── db/
│       ├── schema.sql           # canonical schema
│       └── migrations/          # migration files
├── tests/                       # Vitest suites
├── scripts/                     # utility scripts
├── middleware.ts                # auth + workspace injection
├── next.config.ts
├── tsconfig.json                # strict mode, @/* → src/*
└── vitest.config.ts
```

---

## Auth Flow

1. Request hits `middleware.ts`
2. Middleware checks Supabase session (or dev bypass)
3. Injects headers: `x-workspace-id`, `x-user-id`, `x-user-role`
4. API routes read via `getWorkspaceId(request)` (from `src/lib/utils/api-handler.ts`)

**No session + API route → 401. No session + page → redirect /login.**

---

## API/Route Pattern

```typescript
import { getWorkspaceId } from "@/lib/utils/api-handler";
import { safeErrorMessage } from "@/lib/utils/api-handler";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const workspaceId = getWorkspaceId(request);
  try {
    const result = await businessLogic(workspaceId);
    return NextResponse.json(result);
  } catch (err) {
    console.error("[API /route-name] Error:", err);
    return NextResponse.json({ error: safeErrorMessage(err) }, { status: 500 });
  }
}
```

**Key helpers:**
- `getWorkspaceId(request)` — extract workspace from middleware header
- `safeErrorMessage(err)` — sanitize errors for client
- `NextResponse.json()` — respond with JSON + status

**Standard error codes:** 400 (bad params), 401 (no session), 403 (no workspace), 404 (not found), 429 (rate limited), 500 (server error)

---

## Page/Component Pattern

```typescript
"use client";
import { useState, useEffect } from "react";

export default function FeaturePage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/feature")
      .then((r) => r.json())
      .then(setData)
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="max-w-5xl space-y-8 px-8 pb-12">
      {loading ? <LoadingState /> : <Content data={data} />}
    </div>
  );
}
```

**Layout:** `src/app/(dashboard)/layout.tsx` wraps all authenticated pages with sidebar.

---

## DB Pattern

- **ORM/Client:** Supabase JS client
- **Required filters:** Every query MUST filter by `workspace_id` (except global tables like `suppression_list`)
- **Migration tool:** Raw SQL files in `src/db/migrations/`
- **Index conventions:** Every `workspace_id` column needs an index (standalone or composite)
- **Special rules:** JOINs on `account_intelligence` MUST include `AND ai.is_active = true`

---

## Key Utility Files

| File | Purpose |
|------|---------|
| `src/lib/utils/api-handler.ts` | `getWorkspaceId()`, `safeErrorMessage()` |
| `src/lib/utils/fetch-timeout.ts` | Fetch with timeout wrapper |
| `src/lib/validations/schemas.ts` | Zod validation schemas |
| `src/lib/db/credits.ts` | Credit balance checks |
| `middleware.ts` | Auth + workspace injection |

---

## Test Pattern

- **Location:** `tests/*.test.ts`
- **Runner:** Vitest (`describe` / `it` / `expect`)
- **Mocking:** Mock Supabase before importing tested module
- **Run:** `npm run test` (single) or `npm run test:watch` (watch)

---

## Browser Verification (Playwright CLI)

**Dev server must be running.** Default port 3000 (`npm run dev`).

Typical flow (all commands use `-s=verify` for session persistence):
1. `npx @playwright/cli goto "http://localhost:3000/[page]" -s=verify` → navigate
2. `npx @playwright/cli snapshot -s=verify` → verify elements in accessibility tree
3. `npx @playwright/cli screenshot -s=verify` → visual confirmation
4. `npx @playwright/cli console -s=verify` → check for JS errors
5. `npx @playwright/cli network -s=verify` → verify API calls
6. `npx @playwright/cli click <ref> -s=verify` / `fill <ref> "text"` → test interactions

---

## Common Failure Patterns

| Symptom | Likely Cause |
|---------|-------------|
| 500 "workspace_id is required" | Missing `getWorkspaceId(request)` |
| Returns wrong workspace data | Missing `.eq("workspace_id", workspaceId)` |
| PGRST116 "multiple rows" | Missing `is_active = true` on intelligence join |
| Hydration error in console | Server/client component mismatch |
| Build fails on import | Wrong path alias (use `@/` not relative) |
| 402 on API call | Credit check failing |
| 429 on API call | Rate limit hit |

---

## Project-Specific Conventions

- All UI follows Tailwind utility classes with `rounded-2xl` cards, `font-light`, neutral color palette
- Framer Motion for animations (0.2-0.25s easeOut)
- Error boundaries wrap each dashboard section

---

## Known Issues File

**Path:** `memory/known-issues.md`
