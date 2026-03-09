# N2N — Learnings

Read this file at the start of every invocation. Append new learnings after issues or discoveries.

## Format
- **[Summary] ([MM-DD])** — What happened. What was learned.

## Learnings (Bugs & Gotchas)

### Tool & Environment

- **Playwright browser session conflicts** — If the browser is already running, Playwright `launchPersistentContext` fails with "Opening in existing browser session." Fix: `rm -rf /tmp/playwright-test-profile` then retry. May need `browser_install` first.

- **Edit tool loses file tracking after context compaction** — After context compaction, the Edit tool refuses edits with "file not read." Workaround: re-read the file immediately before editing. This is a persistent tool limitation, not a one-off.

- **Check which dev server port is active** — When running parallel dev servers, use `lsof -i :[PORT]` to confirm which port is live before browser verification.

### Performance & UX

- **Skeleton swap is the biggest perceived-speed killer** — When data refreshes replace content with skeleton placeholders, the blank gap (even 200ms) feels slow. Fix: keep old data visible at reduced opacity (`opacity-50 pointer-events-none`) with a loading indicator, then swap to new data. Separate `loading` (no data yet — show skeleton) from `isRefreshing` (have stale data — dim it).

- **Client-side navigation is the highest-impact speed fix** — Raw `<a>` tags cause full page reloads. Switching to framework-specific client navigation (Next.js `<Link>`, React Router `<Link>`, etc.) is often the single biggest perceived speed improvement.

- **Postgres `count: "planned"` vs `count: "exact"`** — On large tables (50K+ rows), exact counts force full sequential scans (1-3s). Planned counts use Postgres statistics and return in ~0ms. For paginated UIs where approximate counts are fine, always prefer planned.

- **SWR dedupingInterval batches rapid UI toggles** — Default 50ms means every filter click fires a separate request. Setting 500ms batches rapid toggles into one request with no noticeable delay. Good default for filter-heavy UIs.

- **IntersectionObserver infinite scroll is a clean pattern** — Replacing "Load more" buttons requires only: (1) `useRef` + sentinel div at list bottom, (2) `useEffect` with observer + `rootMargin: "200px"` for pre-fetching, (3) cleanup via `observer.disconnect()`. No data layer changes needed when a `loadMore` function already exists.

### Error Handling

- **SWR/fetch error handlers must catch ALL error types** — Custom `onError` that only checks `instanceof FetchError` silently swallows network-level `TypeError: Failed to fetch`. Always catch broadly: `err instanceof Error ? err.message : String(err)`. Add error handlers to every data hook, not just the primary one.

- **Production error sanitizers mask debugging info** — Error wrappers that sanitize messages for clients also hide root causes from developers. When debugging API 500s, temporarily log the raw error before the sanitizer runs.

- **Transient 500s on cold start — retry once** — First API call after dev server restart can fail (cold-start race). Always retry once before investigating. If it works on retry, it's a cold-start issue.

### Database

- **OFFSET pagination breaks on UPDATE-based backfills** — When a backfill script uses `OFFSET` and updates the column in its `WHERE` filter, updated rows no longer match, shifting subsequent pages and skipping rows. Fix: cursor-based pagination (`WHERE id > $lastId ORDER BY id LIMIT N`). Applies to ANY script that modifies the column it filters on.

- **Partial unique indexes break ORM upserts** — ORMs like Supabase can't target partial unique indexes (e.g., `WHERE is_active = true`) in upsert operations, causing "no unique or exclusion constraint" errors. Fix: deactivate/delete old rows, then insert. Always check if a table uses partial indexes before writing upserts.

- **RPC/stored procedures can hide performance bottlenecks** — After optimizing an API query, if it's still slow, check whether an RPC call is doing expensive work internally (e.g., exact counts). Test each sub-query independently — network waterfalls show you which call is slow.

- **Non-existent columns in SELECT cause silent 500s** — Adding a column name to a SELECT that doesn't exist in the table causes a runtime error, not a build error. Always verify column names against the actual DB schema, not just migration files (migrations may not have been applied).

- **DB triggers on large tables can exceed timeouts** — Triggers that run aggregate queries (e.g., `COUNT(*)`) on large tables can exceed default statement timeouts. Fix: use a direct DB client with explicit timeout settings instead of the ORM client.

- **`null` vs `undefined` coercion between DB and TypeScript** — Database columns return `null` for missing values, but TypeScript optional params expect `undefined`. Use `value || undefined` or `value ?? undefined` at the boundary.

### React & CSS

- **React hooks ordering matters** — Adding `useEffect` above a `useState` it references causes a build failure. Always place effects AFTER all state declarations. Easy to miss when inserting code into existing components.

- **React hooks cannot be called conditionally or in try/catch** — Wrapping hooks in try/catch violates rules of hooks. If a hook might throw (e.g., missing context provider), create a safe wrapper hook that returns null instead of throwing.

- **Z-index stacking context — parent needs explicit context** — An element with `absolute z-[N]` inside a container only escapes sibling overlap if the container itself creates a stacking context (`relative z-[M]` where M > siblings). Reading the DOM tree structure diagnoses this faster than visual reproduction.

- **overflow-hidden clips absolutely positioned children** — Dropdowns/panels with `absolute` positioning inside `overflow-hidden` parents will be clipped regardless of z-index. Fix: render the panel at a higher level in the component tree, use portals, or use fixed positioning.

- **Deduplicate data fetches before adding caching** — Before reaching for SWR/React Query caching, check if multiple hooks independently fetch the same data. Passing pre-fetched data as props can eliminate 50% of network calls with zero new dependencies.

### Process

- **Grep for stragglers after large refactors** — When renaming or removing patterns across many files, always run a broad grep for the old pattern after all planned edits, before building. Builds catch import errors but miss string references, config values, and UI text.

- **Schema-first diagnosis for DB errors** — For any database-related 500, check column existence in the schema first (takes 10 seconds). This is faster than trying to reproduce the error or reading server logs.

- **Test with real data early** — Unit tests pass but production data reveals format mismatches between different data sources (e.g., one API returns `c_suite`, another returns `C-Level`). For any feature that combines data from multiple sources, query real data early.

- **Build after all edits, not after each file** — TypeScript's cross-file type checking catches issues that per-file editing misses. Batch your edits, then build once to catch everything.

- **Migration-to-API wiring gap** — When writing a migration that adds a column, immediately update the consuming API routes, SELECT strings, and type definitions. This gap between "column exists in DB" and "column exposed in API" is a recurring bug pattern.

## Growth Reflections

- **Growth: Schema-first verification** — For seed scripts, migrations, or any DB work: read the target table's CREATE TABLE + related migrations to verify column names, constraints, and triggers before writing code.

- **Growth: CSS stacking bugs are faster to diagnose from code** — Reading the component tree structure (DOM hierarchy, position, z-index, overflow) identifies z-index/stacking issues faster than trying to reproduce them visually in a browser.

- **Growth: Multi-file resume across context compaction** — Re-reading files before editing after context compaction works reliably. Building after all edits catches cross-file issues efficiently.

- **Growth: Pass mode params to ALL related endpoints** — When adding a parameter that changes behavior (e.g., `mode=fast`), check all related endpoints and data hooks for consistency. Missing the param on one of three calls means one is still slow.
