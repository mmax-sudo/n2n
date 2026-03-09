# N2N — End-to-End Autonomous Executor for Claude Code

> Ship verified work. Build it, test it, fix it, only then report back.

N2N is a [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code) that turns Claude into an autonomous executor. Give it a task, and it won't return control until the work is **verified working** — or it's exhausted 5 fix attempts trying.

No more "I've made the changes, please test." N2N tests it.

---

## What It Does

5-phase autonomous workflow:

1. **Understand** — Read past learnings, parse the task, ask only critical questions, read the project playbook, explore task-specific code
2. **Implement** — Write code following your project's conventions
3. **Self-Verify** — Adaptive verification based on what changed:
   - **Always:** Run your build command (must exit 0)
   - **UI changes:** Playwright CLI — navigate, snapshot DOM, screenshot, check console, verify network requests
   - **API changes:** Hit endpoints via curl, verify status codes and response shapes
   - **DB changes:** Check migration syntax, required filters, indexes
4. **Fix Loop** — If verification fails: diagnose root cause, fix it, log the bug, re-verify. Up to 5 attempts.
5. **Learn + Report** — Log what was learned (every run, mandatory), reflect on improvements, then report in a structured format.

**The contract:** N2N does not return control until the task is verified working or it's exhausted 5 fix attempts.

---

## Strengths

- **Self-correcting** — Catches its own mistakes via build + browser + API verification. Doesn't declare victory until it proves the work is correct.
- **Learns from history** — Reads `learnings.md` before every run. Ships with 30+ universal patterns (pagination gotchas, z-index stacking, schema-first debugging). Your project-specific learnings accumulate over time.
- **Adaptive verification** — Picks the right verification method based on what changed. Doesn't browser-test a backend fix. Doesn't skip build on anything.
- **Institutional memory** — Every bug gets logged with root cause + fix + reusable lesson. Future sessions check the log before starting.
- **Playbook-driven** — The traversal playbook eliminates redundant codebase exploration. First run is expensive; subsequent runs are fast because n2n already knows your build commands, directory map, auth flow, and common patterns.
- **Progressive questioning** — Asks only when genuinely blocked. Max 3 questions at a time. Never asks what it can figure out by reading code.

---

## Weaknesses & Caveats

Be honest with yourself about these before adopting:

- **Context window pressure** — Complex tasks on large codebases can hit context limits. The playbook helps by reducing exploration, but doesn't eliminate the issue. Break large tasks into smaller n2n invocations.
- **Playwright CLI dependency** — Browser verification requires `@playwright/cli`. If not installed or dev server not running, UI verification degrades to build-only. Install: `npm install -D @playwright/cli`.
- **Fix loop ceiling** — 5 attempts is usually enough, but cascading bugs (fix A reveals bug B reveals bug C) can exhaust attempts on legitimately complex issues. When this happens, n2n reports what's broken and what was tried.
- **First-run exploration cost** — The first run on a new project spends significant tokens exploring the codebase and filling in the playbook. Subsequent runs are 2-5x cheaper.
- **Per-change verification, not regression** — N2N verifies the thing it just built, not everything else. It catches what it broke, but won't find pre-existing bugs or regressions in unrelated code.
- **Learnings file growth** — Over months, `learnings.md` grows large. Periodic pruning (removing outdated or project-specific entries) is recommended.
- **Edit tool limitation** — After Claude Code's context compaction, the Edit tool loses track of prior file reads. N2N works around this by re-reading files, but it adds a few seconds per edit.

---

## Cost Estimates

Based on real-world usage across 15+ sessions. Costs vary by model and task complexity.

| Task Type | Tokens (approx) | Duration | Est. Cost (Sonnet) | Est. Cost (Opus) |
|-----------|-----------------|----------|--------------------|------------------|
| Simple bug fix | 50-80K | 3-5 min | $0.15-0.25 | $0.75-1.20 |
| UI component | 100-200K | 8-15 min | $0.30-0.60 | $1.50-3.00 |
| API + DB feature | 150-250K | 10-20 min | $0.45-0.75 | $2.25-3.75 |
| Full-stack feature | 200-400K | 15-30 min | $0.60-1.20 | $3.00-6.00 |
| First run (no playbook) | 300-500K | 20-40 min | $0.90-1.50 | $4.50-7.50 |

**Cost reduction over time:** As the playbook fills in and learnings accumulate, each run gets cheaper because n2n spends less time exploring and avoids repeating past mistakes.

---

## Installation

### Option 1: Copy from GitHub

```bash
git clone https://github.com/YOUR_USERNAME/n2n-skill.git
cp -r n2n-skill/n2n ~/.claude/skills/n2n
```

### Option 2: Manual

Download the `n2n/` directory and place it at:
- **Global (all projects):** `~/.claude/skills/n2n/`
- **Project-local:** `.claude/skills/n2n/` in your project root

Claude Code automatically discovers skills in both locations.

---

## Setup (Required)

**Before your first run**, fill in the traversal playbook:

1. Open `~/.claude/skills/n2n/references/traversal-playbook.md`
2. Replace the `[PLACEHOLDERS]` with your project's values:
   - `[PROJECT_DIR]` — absolute path to your project
   - `[BUILD_CMD]` — e.g., `npm run build`, `pytest`, `cargo build`
   - `[DEV_CMD]` — e.g., `npm run dev`, `uvicorn main:app --reload`
   - `[PORT]` — e.g., 3000, 8000, 8080
   - Directory map, auth flow, DB patterns, common failures
3. *(Optional)* Review `learnings.md` — ships with 30+ universal patterns. Add your own over time.
4. *(Optional)* Create project-specific evals in `evals/` (see "Creating Evals" below).

**See `examples/` for filled-in playbooks:**
- [Next.js + Supabase](examples/nextjs-playbook.md)
- [Python + FastAPI](examples/python-playbook.md)

---

## Usage

Just tell Claude Code what to do with the intent that it should verify:

```
/n2n Fix the login page — clicking "Sign In" does nothing
```

```
/n2n Add a dark mode toggle to the settings page and verify it works
```

```
/n2n The /api/users endpoint returns 500 when the email contains a plus sign
```

```
/n2n Build the new billing dashboard page per the design in Figma
```

You can also trigger n2n without the slash command by saying things like:
- "do X and verify it works"
- "build and test this"
- "implement and verify"
- "don't come back until it works"

---

## How Customization Works

N2N adapts to your project through two files:

### Traversal Playbook (primary)

`references/traversal-playbook.md` tells n2n how your project works:
- Build commands, dev server, test runner
- Directory structure and where things live
- Auth flow and how to bypass it in dev
- API route patterns and conventions
- Database patterns and required filters
- Common failure patterns and their fixes

N2N reads this at the start of every run. As it discovers new patterns, it appends them to the playbook's "Project-Specific Conventions" section. **Over time, the playbook becomes a comprehensive map of your codebase**, reducing token usage on every subsequent run.

### Learnings File (secondary)

`learnings.md` accumulates bug patterns and gotchas. Ships with 30+ universal patterns. Your project-specific learnings build up naturally as n2n runs. N2N reads this before every run to avoid repeating past mistakes.

---

## Creating Evals

Evals let you measure how well n2n handles bugs in your specific codebase.

1. Create a JSON patch that introduces a bug (see `evals/patches/README.md`)
2. Add an eval entry to `evals/evals.json`
3. Run: `./evals/run-eval.sh <eval-id>` → applies patch, prints the prompt to paste
4. Paste the prompt into Claude Code → n2n runs autonomously
5. Grade the result using `evals/grading-rubric.md` (6 criteria, 70% pass threshold)
6. Restore: `./evals/run-eval.sh --restore`

---

## What N2N Reports

Every run ends with a structured report:

```
## N2N Complete

**Task:** Added dark mode toggle to settings page
**Status:** VERIFIED

### What was done
- Added DarkModeToggle component (src/components/DarkModeToggle.tsx)
- Wired to localStorage + system preference detection
- Added to settings layout

### Verification results
- Build: PASS
- Browser: PASS (screenshot confirmed toggle renders, theme switches)
- API: N/A
- DB: N/A

### Bugs found and fixed
- Initial render flash — dark mode applied after hydration → moved to useLayoutEffect

### Assumptions made
- Used localStorage (not server-side preference) — simpler, no DB change needed
```

---

## FAQ

**Q: Does n2n work with any language/framework?**
A: Yes. The core workflow is language-agnostic. The traversal playbook is where you configure project-specific commands and patterns. Examples are provided for Next.js and Python, but it works with any project that has a build command.

**Q: What if I don't have Playwright installed?**
A: N2N gracefully degrades. Build verification always runs. Browser verification is skipped if Playwright isn't available. API verification via curl still works. You'll get less coverage on UI changes but everything else functions normally.

**Q: How much does the first run cost?**
A: More than subsequent runs (300-500K tokens on Sonnet) because n2n explores your codebase and fills in the playbook. After that, runs are 2-5x cheaper because the exploration is already done.

**Q: Can I use this with Opus?**
A: Yes, but it costs ~5x more per run. Sonnet is recommended for most tasks. Use Opus for complex architectural work where the quality difference justifies the cost.

**Q: What happens when the fix loop hits 5 attempts?**
A: N2N stops and reports exactly what's broken, what it tried, and where it got stuck. You can then provide guidance and run n2n again.

---

## License

MIT — see [LICENSE](LICENSE).
