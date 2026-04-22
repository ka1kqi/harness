# Claude Code Harness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a lean, reusable Claude Code harness that runs an autonomous Plan -> Sprint -> Evaluate loop across multiple full-stack projects.

**Architecture:** Three agent prompts (planner, generator, evaluator) orchestrated by a master CLAUDE.md. State tracked as markdown files on disk. Shell scripts handle setup, evaluation tooling, and sprint lifecycle. Per-project config via YAML.

**Tech Stack:** Shell scripts (bash), YAML config, Playwright (evaluator), Claude Code subagents

---

### Task 1: Scaffold Project Structure

**Files:**
- Create: `harness/agents/.gitkeep`
- Create: `harness/hooks/.gitkeep`
- Create: `harness/scripts/.gitkeep`
- Create: `harness/templates/.gitkeep`

**Step 1: Create directory structure**

```bash
mkdir -p harness/{agents,hooks,scripts,templates}
```

**Step 2: Add .gitkeep files**

```bash
touch harness/agents/.gitkeep harness/hooks/.gitkeep harness/scripts/.gitkeep harness/templates/.gitkeep
```

**Step 3: Commit**

```bash
git add harness/
git commit -m "chore: scaffold harness directory structure"
```

---

### Task 2: Write Planner Agent Prompt

**Files:**
- Create: `harness/agents/planner.md`

**Step 1: Write the planner agent prompt**

Write `harness/agents/planner.md` with the following content:

```markdown
# Planner Agent

You are the Planner in a Plan -> Sprint -> Evaluate development harness.

## Your Role

Turn a brief user prompt (1-4 sentences) into a structured development plan.

## Input

You will receive:
1. The user's feature request (brief prompt)
2. The project's `harness.config.yaml` (tech stack info)
3. The project's existing file structure (via ls/tree)
4. Any existing `CLAUDE.md` conventions

## Output

Write `sprints/plan.md` with this exact structure:

```
# Development Plan

## Goal
[One sentence restating what we're building]

## Tech Decisions
[2-3 sentences on approach, respecting existing project conventions]

## Sprints

### Sprint 1: [Feature Name]
**Description:** [What this sprint delivers]
**Acceptance Criteria:**
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
**Files Likely Touched:** [list of paths]

### Sprint 2: [Feature Name]
...
```

## Rules

1. **Describe WHAT, not HOW.** Don't write pseudocode or specify implementation details.
2. **One feature per sprint.** Each sprint should be completable in one focused session.
3. **Acceptance criteria must be testable.** "Looks good" is not a criterion. "Login form validates email format and shows inline error" is.
4. **Respect existing conventions.** Read the project's CLAUDE.md and match its patterns.
5. **Order sprints by dependency.** Backend before frontend. Data model before UI.
6. **Keep it to 3-7 sprints.** If more are needed, the feature request is too broad — ask the user to narrow scope.
```

**Step 2: Review the file reads correctly**

```bash
cat harness/agents/planner.md | head -5
```
Expected: Shows the header lines of the planner prompt.

**Step 3: Commit**

```bash
git add harness/agents/planner.md
git commit -m "feat: add planner agent prompt"
```

---

### Task 3: Write Generator Agent Prompt

**Files:**
- Create: `harness/agents/generator.md`

**Step 1: Write the generator agent prompt**

Write `harness/agents/generator.md`:

```markdown
# Generator Agent

You are the Generator in a Plan -> Sprint -> Evaluate development harness.

## Your Role

Implement one sprint at a time. Write code, run tests, commit, and self-review.

## Input

You will receive:
1. The sprint contract (`sprints/sprint-N/contract.md`) — your success criteria
2. The project's `harness.config.yaml` — tech stack info
3. The project's `CLAUDE.md` — coding conventions
4. If this is a retry: the evaluator's critique (`sprints/sprint-N/evaluation.md`)

## Process

1. **Read the contract.** Understand exactly what "done" means.
2. **If retrying:** Read the evaluator's critique carefully. Address every point.
3. **Implement the feature.** Write production code following project conventions.
4. **Write/update tests.** Every acceptance criterion should have a corresponding test.
5. **Run all tests.** Ensure nothing is broken — both new and existing tests pass.
6. **Git commit.** Use conventional commit messages (`feat:`, `fix:`, etc.).
7. **Write self-review.** Output to `sprints/sprint-N/self-review.md`.

## Self-Review Format

Write `sprints/sprint-N/self-review.md`:

```
# Sprint N Self-Review

## What I Built
[2-3 sentences]

## Contract Checklist
- [x/] [Criterion from contract] — [brief note on how it's met]
- [x/] [Criterion from contract] — [brief note]

## Tests Added/Modified
- `path/to/test` — tests [what]

## Known Gaps
[Anything I'm unsure about or couldn't fully verify]

## Files Changed
- `path/to/file` — [what changed]
```

## Rules

1. **One sprint only.** Don't look ahead or work on future sprints.
2. **Follow the contract.** It defines "done" — don't add unrequested features.
3. **Run tests before committing.** Never commit broken code.
4. **Be honest in self-review.** If something isn't fully working, say so in Known Gaps.
5. **Don't modify tests to make them pass.** Fix the implementation instead.
6. **Respect existing code.** Don't refactor things outside your sprint scope.
```

**Step 2: Commit**

```bash
git add harness/agents/generator.md
git commit -m "feat: add generator agent prompt"
```

---

### Task 4: Write Evaluator Agent Prompt

**Files:**
- Create: `harness/agents/evaluator.md`

**Step 1: Write the evaluator agent prompt**

Write `harness/agents/evaluator.md`:

```markdown
# Evaluator Agent

You are the Evaluator in a Plan -> Sprint -> Evaluate development harness. You are tuned toward skepticism. Your job is to catch what the generator missed.

## Your Role

Test the running application like a real user. Grade against concrete criteria. Write actionable critique.

## Input

You will receive:
1. The sprint contract (`sprints/sprint-N/contract.md`) — what was promised
2. The generator's self-review (`sprints/sprint-N/self-review.md`) — what they claim
3. The project's `harness.config.yaml` — tech stack and eval settings
4. Access to the running application (dev server) and test tools

## Evaluation Process

1. **Read the contract and self-review.** Know what was promised vs. claimed.
2. **Run existing tests.** Check nothing is broken.
3. **Run Playwright tests** (if `evaluator.playwright: true` in config):
   - Navigate to relevant pages
   - Test all user flows from the contract
   - Check responsive behavior
   - Capture screenshots of key states
4. **Run API tests** (if `evaluator.api_tests: true` in config):
   - Hit all endpoints related to the sprint
   - Test edge cases (empty input, invalid data, auth boundaries)
5. **Grade on 4 criteria** (each scored 1-10):

### Grading Criteria

**Design Quality (1-10):** Coherence across colors, typography, layout, and imagery. Does the UI feel like a unified product or a collection of disconnected components?

**Originality (1-10):** Evidence of deliberate creative choices. Does this look like every other template app, or does it have a distinct identity? Watch for: default shadcn/tailwind patterns used without customization, generic placeholder text, stock layouts.

**Craft (1-10):** Technical execution of visual details. Hierarchy, spacing, contrast, alignment, responsiveness. Are interactive elements discoverable? Do animations serve a purpose?

**Functionality (1-10):** Does it work as specified in the contract? Test every acceptance criterion. This is pass/fail per criterion, then averaged.

**Overall Score** = average of all 4 criteria.

## Output

Write `sprints/sprint-N/evaluation.md`:

```
# Sprint N Evaluation

## Contract Compliance
- [PASS/FAIL] [Criterion] — [evidence]
- [PASS/FAIL] [Criterion] — [evidence]

## Scores
| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | X/10 | [specifics] |
| Originality | X/10 | [specifics] |
| Craft | X/10 | [specifics] |
| Functionality | X/10 | [specifics] |
| **Overall** | **X/10** | |

## Critical Issues
[Things that MUST be fixed before this sprint can pass]

## Suggestions
[Nice-to-haves that aren't blockers]

## Verdict: PASS / FAIL
[If overall >= pass_threshold from config: PASS. Otherwise: FAIL.]
```

## Rules

1. **Be skeptical.** Assume things are broken until proven otherwise.
2. **Test, don't assume.** Actually run the app, click buttons, submit forms.
3. **Grade against the contract.** Don't introduce new requirements mid-evaluation.
4. **Be specific in critique.** "The button doesn't work" is bad. "The 'Submit' button on /login returns a 422 because the email field sends null when empty" is good.
5. **Functionality is non-negotiable.** If core features don't work, it's a FAIL regardless of how pretty it looks.
6. **Don't be nice.** Your job is to catch problems, not validate feelings.
```

**Step 2: Commit**

```bash
git add harness/agents/evaluator.md
git commit -m "feat: add evaluator agent prompt"
```

---

### Task 5: Write Sprint Templates

**Files:**
- Create: `harness/templates/sprint-contract.md`
- Create: `harness/templates/evaluation-report.md`

**Step 1: Write sprint contract template**

Write `harness/templates/sprint-contract.md`:

```markdown
# Sprint {{N}} Contract

## Feature
{{feature_name}}

## Description
{{description_from_plan}}

## Acceptance Criteria
{{acceptance_criteria_from_plan}}

## Technical Constraints
- Stack: {{stack_from_config}}
- Must pass all existing tests
- Must follow project CLAUDE.md conventions

## Evaluation Criteria
- Pass threshold: {{pass_threshold}}/10
- Playwright testing: {{playwright_enabled}}
- API testing: {{api_tests_enabled}}

## Max Iterations
{{max_iterations}}
```

**Step 2: Write evaluation report template**

Write `harness/templates/evaluation-report.md`:

```markdown
# Sprint {{N}} Evaluation

## Contract Compliance
{{compliance_checklist}}

## Scores
| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | /10 | |
| Originality | /10 | |
| Craft | /10 | |
| Functionality | /10 | |
| **Overall** | **/10** | |

## Critical Issues
{{critical_issues}}

## Suggestions
{{suggestions}}

## Verdict: {{PASS_OR_FAIL}}
```

**Step 3: Commit**

```bash
git add harness/templates/
git commit -m "feat: add sprint contract and evaluation templates"
```

---

### Task 6: Write the Master CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

**Step 1: Write CLAUDE.md**

This is the orchestrator — it tells Claude Code how to run the full harness loop. Write `CLAUDE.md`:

```markdown
# Claude Code Harness

This project is a development harness that runs an autonomous Plan -> Sprint -> Evaluate loop.

## How to Use

When given a feature request for a project that has this harness installed:

1. **Invoke the Planner.** Spawn a subagent with the prompt from `harness/agents/planner.md`. Pass it:
   - The user's feature request
   - The project's `harness.config.yaml`
   - The project's file tree (`find . -type f | head -100`)
   - The project's `CLAUDE.md` (if it exists)
   The planner writes `sprints/plan.md`.

2. **Run the Sprint Loop.** For each sprint in `sprints/plan.md`:

   a. **Generate Contract.** Read the sprint from `sprints/plan.md`, fill in `harness/templates/sprint-contract.md`, save to `sprints/sprint-N/contract.md`.

   b. **Spawn Generator.** Spawn a subagent with the prompt from `harness/agents/generator.md`. Pass it:
      - `sprints/sprint-N/contract.md`
      - `harness.config.yaml`
      - The project's `CLAUDE.md`
      - If retrying: `sprints/sprint-N/evaluation.md` (the evaluator's critique)
   The generator implements the feature, runs tests, commits, and writes `sprints/sprint-N/self-review.md`.

   c. **Spawn Evaluator.** Spawn a subagent with the prompt from `harness/agents/evaluator.md`. Pass it:
      - `sprints/sprint-N/contract.md`
      - `sprints/sprint-N/self-review.md`
      - `harness.config.yaml`
   The evaluator tests the running app and writes `sprints/sprint-N/evaluation.md`.

   d. **Check Verdict.**
      - Read `sprints/sprint-N/evaluation.md`.
      - If PASS: Write `PASS` to `sprints/sprint-N/status.md`. Move to next sprint.
      - If FAIL and iterations < max_iterations: Write `FAIL iteration M` to status. Go back to step b with the critique.
      - If FAIL and iterations >= max_iterations: Write `FAIL max_iterations_reached` to status. Log to `sprints/summary.md` and move to next sprint.

   e. **Update Summary.** Append sprint results to `sprints/summary.md`.

3. **Complete.** After all sprints, report final status from `sprints/summary.md`.

## Important

- **Each subagent gets fresh context.** Don't pass conversation history — only files.
- **The evaluator is skeptical by design.** Don't soften its output.
- **State lives on disk.** All sprint state is in the `sprints/` directory.
- **Don't skip evaluation.** Every sprint gets evaluated, even if the generator is confident.

## Project Setup

To install this harness in a project, run:
```
bash harness/scripts/setup-project.sh /path/to/project
```
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add master CLAUDE.md orchestrator"
```

---

### Task 7: Write harness.config.yaml Default

**Files:**
- Create: `harness/templates/harness.config.yaml`

**Step 1: Write default config**

Write `harness/templates/harness.config.yaml`:

```yaml
# Claude Code Harness Configuration
# Copy this to your project root and customize.

stack:
  frontend: react          # react | next | vue | svelte | none
  backend: fastapi         # fastapi | express | django | rails | none
  test_runner: vitest      # vitest | jest | pytest | go test

evaluator:
  playwright: true         # Enable Playwright browser testing
  api_tests: true          # Enable API endpoint testing
  max_iterations: 5        # Max retries per sprint before moving on
  pass_threshold: 7        # Score (out of 10) required to pass

dev_server:
  start_cmd: "npm run dev" # Command to start the dev server
  port: 3000               # Dev server port
  health_check: "http://localhost:3000"  # URL to verify server is up
```

**Step 2: Commit**

```bash
git add harness/templates/harness.config.yaml
git commit -m "feat: add default harness config template"
```

---

### Task 8: Write setup-project.sh

**Files:**
- Create: `harness/scripts/setup-project.sh`

**Step 1: Write the setup script**

Write `harness/scripts/setup-project.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Setup Claude Code Harness in a target project
# Usage: ./setup-project.sh /path/to/project

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:?Usage: setup-project.sh /path/to/project}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR does not exist"
  exit 1
fi

echo "Setting up harness in: $TARGET_DIR"

# 1. Symlink harness directory
if [ -L "$TARGET_DIR/harness" ] || [ -d "$TARGET_DIR/harness" ]; then
  echo "Warning: harness/ already exists in target. Skipping symlink."
else
  ln -s "$HARNESS_DIR" "$TARGET_DIR/harness"
  echo "Symlinked harness/ -> $HARNESS_DIR"
fi

# 2. Create sprints directory
mkdir -p "$TARGET_DIR/sprints"
echo "Created sprints/ directory"

# 3. Copy default config if none exists
if [ ! -f "$TARGET_DIR/harness.config.yaml" ]; then
  cp "$HARNESS_DIR/templates/harness.config.yaml" "$TARGET_DIR/harness.config.yaml"
  echo "Copied default harness.config.yaml (edit this for your project)"
else
  echo "harness.config.yaml already exists. Skipping."
fi

# 4. Append harness instructions to CLAUDE.md
HARNESS_SECTION="
## Harness

This project uses the Claude Code Harness for autonomous development.
When given a feature request, follow the harness workflow in \`harness/CLAUDE.md\`.
Agent prompts are in \`harness/agents/\`. Sprint state is in \`sprints/\`.
Configuration is in \`harness.config.yaml\`.
"

if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  if grep -q "## Harness" "$TARGET_DIR/CLAUDE.md"; then
    echo "CLAUDE.md already has Harness section. Skipping."
  else
    echo "$HARNESS_SECTION" >> "$TARGET_DIR/CLAUDE.md"
    echo "Appended harness section to existing CLAUDE.md"
  fi
else
  echo "# Project CLAUDE.md$HARNESS_SECTION" > "$TARGET_DIR/CLAUDE.md"
  echo "Created CLAUDE.md with harness section"
fi

# 5. Add sprints/ to .gitignore if not present
if [ -f "$TARGET_DIR/.gitignore" ]; then
  if ! grep -q "sprints/" "$TARGET_DIR/.gitignore"; then
    echo "sprints/" >> "$TARGET_DIR/.gitignore"
    echo "Added sprints/ to .gitignore"
  fi
else
  echo "sprints/" > "$TARGET_DIR/.gitignore"
  echo "Created .gitignore with sprints/"
fi

echo ""
echo "Harness setup complete!"
echo "Next steps:"
echo "  1. Edit harness.config.yaml for your project's stack"
echo "  2. Start Claude Code in your project"
echo "  3. Give it a feature request — the harness will take over"
```

**Step 2: Make executable**

```bash
chmod +x harness/scripts/setup-project.sh
```

**Step 3: Test it does nothing harmful on a dry run**

```bash
bash -n harness/scripts/setup-project.sh
```
Expected: No output (syntax check passes).

**Step 4: Commit**

```bash
git add harness/scripts/setup-project.sh
git commit -m "feat: add setup-project.sh for installing harness into projects"
```

---

### Task 9: Write evaluate.sh

**Files:**
- Create: `harness/scripts/evaluate.sh`

**Step 1: Write the evaluation runner script**

Write `harness/scripts/evaluate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run evaluation tools for a sprint
# Usage: ./evaluate.sh /path/to/project [sprint-number]
# This script starts the dev server, runs tests, and collects results.

PROJECT_DIR="${1:?Usage: evaluate.sh /path/to/project [sprint-number]}"
SPRINT_NUM="${2:-1}"

if [ ! -f "$PROJECT_DIR/harness.config.yaml" ]; then
  echo "Error: No harness.config.yaml found in $PROJECT_DIR"
  exit 1
fi

# Parse config (simple grep-based — no yq dependency)
get_config() {
  grep "^  $1:" "$PROJECT_DIR/harness.config.yaml" | sed 's/.*: *//' | tr -d '"' | tr -d "'"
}

START_CMD=$(get_config "start_cmd")
PORT=$(get_config "port")
HEALTH_CHECK=$(get_config "health_check")
PLAYWRIGHT_ENABLED=$(get_config "playwright")
API_TESTS_ENABLED=$(get_config "api_tests")
TEST_RUNNER=$(get_config "test_runner")

SPRINT_DIR="$PROJECT_DIR/sprints/sprint-$SPRINT_NUM"
RESULTS_FILE="$SPRINT_DIR/test-results.txt"
mkdir -p "$SPRINT_DIR"

echo "=== Harness Evaluator ==="
echo "Project: $PROJECT_DIR"
echo "Sprint: $SPRINT_NUM"
echo ""

# 1. Run test suite
echo "--- Running tests ($TEST_RUNNER) ---"
cd "$PROJECT_DIR"
case "$TEST_RUNNER" in
  vitest)  npx vitest run --reporter=verbose 2>&1 | tee "$RESULTS_FILE" || true ;;
  jest)    npx jest --verbose 2>&1 | tee "$RESULTS_FILE" || true ;;
  pytest)  python -m pytest -v 2>&1 | tee "$RESULTS_FILE" || true ;;
  *)       echo "Unknown test runner: $TEST_RUNNER" | tee "$RESULTS_FILE" ;;
esac
echo ""

# 2. Start dev server if needed for Playwright
if [ "$PLAYWRIGHT_ENABLED" = "true" ]; then
  echo "--- Starting dev server ---"
  eval "$START_CMD" &
  SERVER_PID=$!

  # Wait for server to be ready
  for i in $(seq 1 30); do
    if curl -s "$HEALTH_CHECK" > /dev/null 2>&1; then
      echo "Server ready on port $PORT"
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "Error: Server failed to start within 30s"
      kill $SERVER_PID 2>/dev/null || true
      exit 1
    fi
    sleep 1
  done

  echo "--- Running Playwright tests ---"
  npx playwright test --reporter=list 2>&1 | tee -a "$RESULTS_FILE" || true

  # Stop server
  kill $SERVER_PID 2>/dev/null || true
  echo ""
fi

echo "--- Results saved to $RESULTS_FILE ---"
echo "Evaluation runner complete. The evaluator agent will read these results."
```

**Step 2: Make executable**

```bash
chmod +x harness/scripts/evaluate.sh
```

**Step 3: Syntax check**

```bash
bash -n harness/scripts/evaluate.sh
```
Expected: No output.

**Step 4: Commit**

```bash
git add harness/scripts/evaluate.sh
git commit -m "feat: add evaluate.sh for running tests and Playwright"
```

---

### Task 10: Write sprint-status.sh

**Files:**
- Create: `harness/scripts/sprint-status.sh`

**Step 1: Write the sprint status script**

Write `harness/scripts/sprint-status.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Show current sprint status
# Usage: ./sprint-status.sh /path/to/project

PROJECT_DIR="${1:?Usage: sprint-status.sh /path/to/project}"
SPRINTS_DIR="$PROJECT_DIR/sprints"

if [ ! -d "$SPRINTS_DIR" ]; then
  echo "No sprints/ directory found. Run setup-project.sh first."
  exit 1
fi

echo "=== Sprint Status ==="
echo ""

if [ -f "$SPRINTS_DIR/plan.md" ]; then
  echo "Plan: EXISTS"
  grep "^### Sprint" "$SPRINTS_DIR/plan.md" 2>/dev/null || echo "  (no sprints found in plan)"
else
  echo "Plan: NOT CREATED"
fi

echo ""

for sprint_dir in "$SPRINTS_DIR"/sprint-*/; do
  [ -d "$sprint_dir" ] || continue
  sprint_name=$(basename "$sprint_dir")
  status="PENDING"
  if [ -f "$sprint_dir/status.md" ]; then
    status=$(cat "$sprint_dir/status.md")
  fi
  echo "$sprint_name: $status"
done

echo ""
if [ -f "$SPRINTS_DIR/summary.md" ]; then
  echo "--- Summary ---"
  cat "$SPRINTS_DIR/summary.md"
fi
```

**Step 2: Make executable and syntax check**

```bash
chmod +x harness/scripts/sprint-status.sh
bash -n harness/scripts/sprint-status.sh
```

**Step 3: Commit**

```bash
git add harness/scripts/sprint-status.sh
git commit -m "feat: add sprint-status.sh for checking sprint progress"
```

---

### Task 11: Clean Up and Final Commit

**Files:**
- Remove: `harness/agents/.gitkeep`, `harness/hooks/.gitkeep`, `harness/scripts/.gitkeep`, `harness/templates/.gitkeep`

**Step 1: Remove .gitkeep files (no longer needed)**

```bash
rm -f harness/agents/.gitkeep harness/hooks/.gitkeep harness/scripts/.gitkeep harness/templates/.gitkeep
```

**Step 2: Verify final structure**

```bash
find . -not -path './.git/*' -not -path './.git' | sort
```

Expected output should match the design doc structure.

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove scaffolding .gitkeep files"
```

---

### Task 12: Smoke Test with a Real Project

**Step 1: Run setup on one of your existing projects**

```bash
bash harness/scripts/setup-project.sh /Users/kaikaidu/Documents/GitHub/cronicl-frontend
```

Expected: Symlink created, sprints/ dir created, config copied, CLAUDE.md updated.

**Step 2: Verify the setup**

```bash
ls -la /Users/kaikaidu/Documents/GitHub/cronicl-frontend/harness
ls /Users/kaikaidu/Documents/GitHub/cronicl-frontend/sprints/
cat /Users/kaikaidu/Documents/GitHub/cronicl-frontend/harness.config.yaml
grep "Harness" /Users/kaikaidu/Documents/GitHub/cronicl-frontend/CLAUDE.md
```

**Step 3: Clean up the smoke test** (don't actually commit to the target project)

```bash
rm /Users/kaikaidu/Documents/GitHub/cronicl-frontend/harness
rm -rf /Users/kaikaidu/Documents/GitHub/cronicl-frontend/sprints
rm /Users/kaikaidu/Documents/GitHub/cronicl-frontend/harness.config.yaml
# Manually remove the Harness section from CLAUDE.md if needed
```
