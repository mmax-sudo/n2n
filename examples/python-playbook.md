# My Python API — Traversal Playbook

Read this at the start of every /n2n invocation. Do NOT re-explore patterns documented here — they are stable.

> This is an example of a filled-in playbook for a Python + FastAPI + SQLAlchemy project.
> Copy `n2n/references/traversal-playbook.md` and replace placeholders with your own values.

---

## Build & Scripts

**Working directory:** `cd "/Users/me/projects/my-api"`

| Command | Purpose |
|---------|---------|
| `python -m pytest` | Run tests — catches logic errors. **Always run.** |
| `mypy src/` | Type checking — catches type errors, missing imports. **Always run.** |
| `uvicorn src.main:app --reload --port 8000` | Dev server on **localhost:8000** |
| `black src/ tests/` | Code formatter |
| `ruff check src/` | Linter |

**Dev auth bypass:** Set `AUTH_DISABLED=true` in `.env`. Uses test user `test@example.com` with tenant ID `test-tenant-001`.

---

## Directory Map

```
my-api/
├── src/
│   ├── main.py                  # FastAPI app + startup
│   ├── api/
│   │   ├── routes/              # API route modules
│   │   │   ├── users.py
│   │   │   ├── projects.py
│   │   │   └── billing.py
│   │   ├── deps.py              # Dependency injection (auth, DB session)
│   │   └── middleware.py        # CORS, rate limiting, tenant injection
│   ├── models/                  # SQLAlchemy ORM models
│   ├── schemas/                 # Pydantic request/response schemas
│   ├── services/                # Business logic layer
│   ├── db/
│   │   ├── session.py           # DB engine + session factory
│   │   └── migrations/          # Alembic migration files
│   │       ├── env.py
│   │       └── versions/
│   └── core/
│       ├── config.py            # Settings via pydantic-settings
│       ├── security.py          # JWT encode/decode, password hashing
│       └── exceptions.py        # Custom exception classes
├── tests/
│   ├── conftest.py              # Fixtures (test DB, test client, auth headers)
│   ├── test_users.py
│   └── test_projects.py
├── alembic.ini
├── pyproject.toml
├── requirements.txt
└── .env.example
```

---

## Auth Flow

1. Request hits `middleware.py` → extracts JWT from `Authorization: Bearer <token>`
2. `deps.py:get_current_user()` dependency decodes JWT, loads user from DB
3. `deps.py:get_tenant_id()` extracts `tenant_id` from the user record
4. Route handlers receive `tenant_id` via dependency injection

**No token → 401. Invalid token → 401. Wrong tenant → 403.**

---

## API/Route Pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from src.api.deps import get_db, get_tenant_id
from src.schemas.users import UserResponse
from src.services.users import UserService

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/", response_model=list[UserResponse])
def list_users(
    tenant_id: str = Depends(get_tenant_id),
    db: Session = Depends(get_db),
):
    service = UserService(db, tenant_id)
    return service.list_all()
```

**Key helpers:**
- `get_db` — SQLAlchemy session (auto-closed after request)
- `get_tenant_id` — tenant ID from authenticated user
- `get_current_user` — full user object with role info

**Standard error codes:** 400 (validation), 401 (unauthorized), 403 (forbidden), 404 (not found), 409 (conflict), 422 (Pydantic validation), 500 (server error)

---

## Page/Component Pattern

N/A — this is a backend-only API. Frontend is a separate React app.

For API-only projects, browser verification targets the separate frontend or uses curl/httpie for API testing.

---

## DB Pattern

- **ORM/Client:** SQLAlchemy 2.0 with async support
- **Required filters:** Every query MUST filter by `tenant_id`
- **Migration tool:** Alembic (`alembic revision --autogenerate -m "description"`, `alembic upgrade head`)
- **Index conventions:** All foreign keys indexed. All `tenant_id` columns have composite indexes with commonly-filtered columns.
- **Special rules:**
  - Soft deletes: use `is_deleted = false` filter, never hard delete user data
  - Timestamps: all tables have `created_at` and `updated_at` (auto-set via SQLAlchemy event)

---

## Key Utility Files

| File | Purpose |
|------|---------|
| `src/api/deps.py` | `get_db()`, `get_tenant_id()`, `get_current_user()` |
| `src/core/config.py` | Environment settings via pydantic-settings |
| `src/core/security.py` | JWT creation/verification, password hashing |
| `src/core/exceptions.py` | Custom exceptions with HTTP status codes |
| `tests/conftest.py` | Test DB, test client, auth header fixtures |

---

## Test Pattern

- **Location:** `tests/test_*.py`
- **Runner:** pytest with `pytest-asyncio` for async tests
- **Mocking:** Test fixtures in `conftest.py` create isolated test DB
- **Run:** `python -m pytest` (all) or `python -m pytest tests/test_users.py -v` (specific)
- **Coverage:** `python -m pytest --cov=src --cov-report=term-missing`

---

## Browser Verification (Playwright CLI)

Not applicable for API-only projects. Use curl/httpie for API verification:

```bash
# Get with auth
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/users/

# Post with body
curl -X POST http://localhost:8000/api/users/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "name": "Test User"}'
```

If there's a separate frontend, use Playwright CLI against its dev server.

---

## Common Failure Patterns

| Symptom | Likely Cause |
|---------|-------------|
| 422 Unprocessable Entity | Pydantic schema mismatch (wrong field name/type) |
| 500 "relation does not exist" | Migration not applied (`alembic upgrade head`) |
| 500 on JOIN query | Missing `tenant_id` filter, returns cross-tenant data |
| Tests pass but API fails | Test fixtures use different schema than production |
| Import error on startup | Circular import between models and schemas |
| Alembic "Target database is not up to date" | Run `alembic upgrade head` first |

---

## Project-Specific Conventions

- All business logic lives in `services/` — routes are thin wrappers
- Use `HTTPException` for expected errors, let unexpected errors propagate to global handler
- Pagination via `limit`/`offset` query params, response includes `total` count

---

## Known Issues File

**Path:** `docs/known-issues.md`
