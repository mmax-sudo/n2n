# Eval Patches

Each patch is a JSON file that introduces a specific bug into your codebase for n2n to find and fix.

## Patch Format

```json
{
  "id": "n2n-bugfix-01",
  "description": "Bad import path causes build error",
  "file": "src/app/api/users/route.ts",
  "find": "import { auth } from '@/lib/auth/session'",
  "replace": "import { auth } from '@/lib/auth/sessions'"
}
```

| Field | Description |
|-------|-------------|
| `id` | Unique identifier matching evals.json entry |
| `description` | Human-readable description of the bug |
| `file` | Relative path from project root to the target file |
| `find` | Exact string to find in the file (must be unique) |
| `replace` | Replacement string that introduces the bug |

## Eval Entry Format (evals.json)

```json
{
  "id": "n2n-bugfix-01",
  "name": "Build error — bad import path",
  "prompt": "/n2n The users API won't build. npm run build fails with a module not found error. Fix the build error.",
  "patch": "patches/01-build-bad-import.json",
  "target_file": "src/app/api/users/route.ts",
  "bug_type": "build",
  "verification_methods": ["build"],
  "expectations": [
    "Ran the build command and saw the module not found error",
    "Identified the wrong import path as root cause",
    "Fixed the import path",
    "Ran build successfully after fix",
    "Reported in N2N Complete format"
  ]
}
```

## Recommended Bug Categories

Create at least one eval per category for good coverage:

| Category | Bug Type | What It Tests |
|----------|----------|---------------|
| **Build error** | `build` | Bad import, missing module, type error |
| **API 500** | `api` | Non-existent DB column, wrong query, missing error handling |
| **Hydration error** | `ui` | Missing "use client", server/client mismatch |
| **Data integrity** | `data` | Missing required filter, wrong JOIN, data leak |
| **Validation/regex** | `fullstack` | Broken regex, missing escaping, edge case in validation |

## How to Create a Patch

1. Find a realistic bug pattern in your codebase (or one you've seen before)
2. Identify the exact string that would change to introduce the bug
3. Create the patch JSON with `find` (correct code) and `replace` (buggy code)
4. Add the eval entry to `evals.json`
5. Test: `./run-eval.sh <eval-id>` then `./run-eval.sh --restore`

## Grading

See `grading-rubric.md` for the 6 evaluation criteria and their weights.
