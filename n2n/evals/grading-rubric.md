# N2N Eval Grading Rubric

## Criteria

| Criterion | Weight | Pass | Fail |
|-----------|--------|------|------|
| Root cause identified | 25% | Correctly names the bug (file, line, what's wrong) | Fixes wrong thing or guesses |
| Fix is correct | 25% | Code change resolves the issue without new bugs | Introduces new bugs or partial fix |
| Build passes | 15% | Build command exits 0 | Build fails or not run |
| Verification performed | 20% | Appropriate verification for bug type (browser/API/code review) | Skips verification or wrong type |
| Screenshot/evidence | 10% | Screenshot or API response shown as proof | No visual/data evidence |
| Report format | 5% | N2N Complete format with all sections | Missing sections or unclear |

## Scoring

- Each criterion is binary (pass/fail)
- Score = sum of passed criteria weights
- **Pass threshold: 70%**

## Verification Type by Bug Type

| Bug Type | Build | Browser | API Test | Code Review |
|----------|-------|---------|----------|-------------|
| build | Required | - | - | - |
| api | Required | - | Required | - |
| ui | Required | Required | - | - |
| data | Required | - | - | Required |
| fullstack | Required | Optional | Required | - |

## Grading Template

```markdown
## Eval: [eval-id] — [name]
**Date:** YYYY-MM-DD
**Score:** X/100

| Criterion | Weight | Result | Notes |
|-----------|--------|--------|-------|
| Root cause | 25% | Pass/Fail | |
| Fix correct | 25% | Pass/Fail | |
| Build passes | 15% | Pass/Fail | |
| Verification | 20% | Pass/Fail | |
| Evidence | 10% | Pass/Fail | |
| Report format | 5% | Pass/Fail | |

**Result:** PASS / FAIL
**Notes:** [free-form observations]
```
