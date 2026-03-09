---
name: n2n
description: >
  This skill should be used when the user says "do X and verify it works",
  "build and test", "implement and verify", "don't come back until it works",
  "/n2n", or wants autonomous task completion with end-to-end self-verification.
  Implements the task, runs adaptive verification (build, browser, API),
  fix-loops bugs, logs to a project issues file, and does not return control
  until verified working or 5 fix attempts are exhausted.
argument-hint: "[task description]"
version: 1.0.0
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion, TodoWrite, WebFetch, WebSearch
---

# N2N — End-to-End Autonomous Executor

Ship verified work. No half-finished code. Build it, test it, fix it, only
then report back.

**The contract:** Accept a task. Do not return control until the task is done
AND verified working. Fix and log any bugs found. Ask about requirements when
genuinely unclear — but do not stall.

**Task:** $ARGUMENTS

---

## Setup (first time only)

Before your first n2n run on a new project, fill in
[references/traversal-playbook.md](references/traversal-playbook.md) with your
project's build commands, directory map, auth flow, DB patterns, and common
failure patterns. This is how n2n learns your codebase without re-exploring it
every run. See the `examples/` directory in the repo for filled-in playbooks
for Next.js and Python projects.

---

## PHASE 1: UNDERSTAND

Goal: Know exactly what "done" looks like before writing code.

1. **Read [learnings.md](learnings.md).** Check for relevant past issues before
   doing anything else. This prevents repeat mistakes.

2. **Parse the task.** Read `$ARGUMENTS`. Identify:
   - What needs to change (files, components, APIs, DB)
   - What "working" looks like (visible UI change, API response, build passing)
   - Which verification methods apply (see Phase 3)

3. **Ask critical questions only.** Use `AskUserQuestion` for:
   - Ambiguous requirements where a wrong guess wastes significant time
   - Missing information not inferable from the codebase
   - Design choices with multiple valid approaches

   Rules:
   - Max 3 questions per round
   - Do NOT ask about things discoverable by reading code
   - Do NOT block on non-critical details — make a reasonable assumption,
     note it, and validate via testing later
   - If the task is clear enough to start, skip questions entirely

4. **Read the traversal playbook.** Consult
   [references/traversal-playbook.md](references/traversal-playbook.md) for
   build commands, directory map, API/page/DB patterns, auth flow, and common
   failure patterns. **Do NOT re-explore patterns documented there.**

5. **Explore only what's new.** Use Agent (Explore) or Grep/Glob for:
   - Task-specific files not covered by the playbook
   - Existing implementations to reuse
   - Related code that might break

6. **Document new patterns.** If during exploration you discover a stable
   codebase pattern NOT already in
   [references/traversal-playbook.md](references/traversal-playbook.md) (e.g.,
   a hook convention, state management pattern, component structure, data flow),
   append it to the playbook before moving on. Future runs should never
   re-explore what you just learned.

7. **Create a TodoWrite plan.** Break the task into trackable steps including
   a final "Verify end-to-end" todo.

---

## PHASE 2: IMPLEMENT

Goal: Write the code. Follow all project conventions.

1. **Work through the todo list.** Mark each task `in_progress` before
   starting and `completed` when done.

2. **Follow project conventions:**
   - Consult traversal playbook for project-specific patterns and style guides
   - Existing patterns — reuse before creating new
   - When in doubt, match the style of surrounding code

3. **Ask progressively.** If a new ambiguity surfaces mid-implementation:
   - Resolvable by reading code? → Read the code.
   - Low-stakes judgment call? → Pick the simpler option.
   - Wrong choice could break the feature? → Ask via `AskUserQuestion`.

4. **Do NOT return control after this phase.** Move directly to Phase 3.

---

## PHASE 3: SELF-VERIFY (adaptive)

Goal: Prove the work is correct. Pick verification methods based on what changed.

Consult [references/verification-guide.md](references/verification-guide.md)
for detailed procedures per verification type.

- **Always:** Run the project's build command (see traversal playbook) — must exit 0
- **UI changes:** Use Playwright CLI (`npx @playwright/cli`) — navigate to the
  dev server, snapshot DOM, take screenshot, check console for errors, interact
  with elements, verify network requests. See verification guide.
- **API changes:** Hit endpoint via curl or browser evaluate fetch, verify
  response shape and status code
- **DB changes:** Check migration syntax, verify required filters per the
  traversal playbook's DB Pattern section, check indexes

Refer to [references/traversal-playbook.md](references/traversal-playbook.md)
for ports, URLs, auth bypass, and common failure patterns.

**All verifications pass → Phase 5.**
**Any verification fails → Phase 4.**

---

## PHASE 4: FIX LOOP

Goal: Fix what broke. Log what was found. Loop until green.

```
attempt = 0
while verification_fails and attempt < 5:
    1. Diagnose the root cause
    2. Fix it
    3. Log the bug to the project's known-issues file (format below)
    4. Re-run failed verification(s)
    5. attempt += 1

if attempt == 5 and still failing:
    Report what is broken, what was tried, ask for help
```

### Bug Log Format

Append to the known-issues file defined in your traversal playbook (default:
`memory/known-issues.md`):

```
- **[Short summary] ([MM-DD])** — [Symptom]. [Root cause]. | Fix: [What changed]. | Files: [list] | Lesson: **[Reusable takeaway in bold.]**
```

Log every bug — even ones fixed in 30 seconds. The log is institutional
memory. Future sessions check it before starting work.

---

## PHASE 5: LEARN + REPORT

Goal: Log learnings, then communicate what happened. Only reached when
verification passes or fix attempts are exhausted.

### Step 1: Write Learnings (MANDATORY)

Before reporting, append to [learnings.md](learnings.md) — even if the run
was smooth. Every run teaches something.

**What to log:**
- Bugs found and their root causes (even trivial ones)
- Unexpected behavior or gotchas discovered
- Patterns that worked well or didn't
- Environment/port/config surprises
- Verification techniques that caught real issues
- Assumptions that turned out wrong

**Format:** `- **[Summary] ([MM-DD])** — What happened. What was learned.`

**If nothing went wrong:** Log what verification confirmed (e.g., "Build +
browser verify passed cleanly for [feature]. No issues.") — this still has
value as a confidence signal.

### Step 1.5: Growth Reflection (MANDATORY)

After logging learnings, reflect with a growth mindset. Ask yourself:

- What took longer than it should have? Why?
- What would I do differently if I ran this exact task again?
- Did I explore something I didn't need to? What signal should have told me
  to skip it?
- Did I find a faster/simpler approach mid-task that I should use from the
  start next time?
- What assumption slowed me down or led me astray?

Log the most actionable reflection in `learnings.md` under the
**Growth Reflections** section with format:
`- **[Growth: Summary] ([MM-DD])** — What happened. What to do differently.`

Also: if you used or discovered any new architectural pattern during this run,
update [references/traversal-playbook.md](references/traversal-playbook.md)
now. The playbook should grow with every run.

### Step 2: Report

```
## N2N Complete

**Task:** [one-line summary]
**Status:** VERIFIED / BLOCKED (after 5 attempts)

### What was done
- [bullet list of changes with file paths]

### Verification results
- Build: PASS / FAIL
- Browser: PASS / FAIL / N/A
- API: PASS / FAIL / N/A
- DB: PASS / FAIL / N/A

### Bugs found and fixed
- [bug summary] → [fix summary]
(or "None")

### Assumptions made
- [any assumptions made instead of asking]
(or "None")
```

---

## RULES

1. **Never return control early.** No "I've made the changes, please test."
   Test it. That is the entire point of this skill.
2. **Progressive questions.** Ask critical ones upfront. Surface others as
   they arise. Never more than 3 at once. Never ask what can be inferred.
3. **Log every bug.** Even trivial ones. Always log to the known-issues file.
4. **Adaptive verification.** Match verification to what changed. Do not
   browser-test a backend fix. Do not skip build on anything.
5. **5-attempt cap.** After 5 fix loops, stop and report. No infinite loops.
6. **Follow conventions.** Traversal playbook conventions, existing patterns.
   Read the known-issues file before starting — past mistakes repeat.
7. **TodoWrite always.** Create todos at start, update throughout. Progress
   should be visible at any point.
8. **No half-measures.** Build passes but UI looks wrong = failure. API
   returns 200 but data is wrong = failure. "Working" means actually working.

---

## Self-Improvement

1. **Read** [learnings.md](learnings.md) at the start of every invocation.
   This is MANDATORY — do it before Phase 1. Past learnings prevent repeat mistakes.
2. **Write** learnings in Phase 5 (see above). Every run, no exceptions.
3. **Eval cycle:** Test prompts are in [evals/evals.json](evals/evals.json). After significant changes, run the eval loop via the Anthropic skill-creator plugin.
