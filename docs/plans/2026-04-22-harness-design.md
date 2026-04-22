# Claude Code Harness Design

**Date:** 2026-04-22
**Status:** Approved
**Approach:** Lean Harness (Claude Code native)

## Problem

Long-running Claude Code development sessions across multiple full-stack projects suffer from:
1. **Context loss/drift** — Claude forgets decisions after context compaction
2. **Quality degradation** — later features get sloppy, broken, or generic
3. **No structured workflow** — manual direction at every step

## Solution

A 3-agent harness inspired by [Anthropic's harness design article](https://www.anthropic.com/engineering/harness-design-long-running-apps) that separates work generation from evaluation, uses context resets over compaction, and runs an autonomous sprint loop.

## Architecture

### Project Structure

```
claude-harness/
├── CLAUDE.md                    # Master harness instructions (template)
├── harness/
│   ├── agents/
│   │   ├── planner.md           # Planner agent system prompt
│   │   ├── generator.md         # Generator agent system prompt
│   │   └── evaluator.md         # Evaluator agent system prompt
│   ├── hooks/
│   │   ├── pre-sprint.sh        # Generates sprint contract before work
│   │   └── post-sprint.sh       # Triggers evaluator after sprint
│   ├── scripts/
│   │   ├── evaluate.sh          # Playwright + tests runner
│   │   ├── setup-project.sh     # Symlinks harness into target project
│   │   └── sprint-status.sh     # Shows current sprint state
│   └── templates/
│       ├── sprint-contract.md   # Template for sprint success criteria
│       └── evaluation-report.md # Template for evaluator output
├── docs/plans/
└── README.md
```

### Three Agents

**Planner** — Expands a brief prompt (1-4 sentences) into a structured plan (`sprints/plan.md`) with features broken into sprints, each with acceptance criteria. Describes WHAT, not HOW. Runs as a Claude Code subagent.

**Generator** — Implements one feature per sprint. Writes code, runs tests, commits, writes self-review. Works in focused sprints, not marathon sessions. Runs as a Claude Code subagent with fresh context per sprint.

**Evaluator** — Tests the running application like a real user using Playwright (frontend) and test runners (backend). Grades against 4 criteria:
1. **Design Quality** — visual coherence, colors, typography, layout
2. **Originality** — deliberate creative choices vs template defaults
3. **Craft** — technical execution, hierarchy, spacing, contrast
4. **Functionality** — does it actually work as specified?

Tuned toward skepticism — easier to make an evaluator critical than a generator self-critical. Runs as a Claude Code subagent.

### Sprint Contract

Before each sprint, a contract is generated defining specific, measurable success criteria. This prevents the evaluator from moving goalposts and gives the generator clear targets. Stored in `sprints/sprint-N/contract.md`.

### Context Management

Key insight from the article: **context resets beat compaction.**

- Each sprint uses a **fresh subagent** (clean context window)
- Subagents receive only: sprint contract, relevant file paths, project conventions
- State persists via **files on disk**, not in-context memory
- No accumulated conversation history degrading quality

### Sprint Loop

```
1. PLAN: Planner reads prompt -> writes sprints/plan.md
2. For each sprint:
   a. CONTRACT: Generate sprints/sprint-N/contract.md
   b. GENERATE: Fresh generator subagent implements the feature
   c. COMMIT: Generator commits and writes self-review
   d. EVALUATE: Fresh evaluator subagent tests + critiques
   e. If FAIL: Generator gets critique, iterates (up to max_iterations)
   f. If PASS: Move to next sprint
3. DONE: All sprints complete
```

### State Files

```
sprints/
├── plan.md                      # Full plan from planner
├── sprint-1/
│   ├── contract.md              # What "done" looks like
│   ├── self-review.md           # Generator's assessment
│   ├── evaluation.md            # Evaluator's critique
│   └── status.md                # pass/fail/iteration-count
├── sprint-2/
│   └── ...
└── summary.md                   # Running summary of completed work
```

### Per-Project Configuration

`harness.config.yaml` at project root:

```yaml
stack:
  frontend: react
  backend: fastapi
  test_runner: vitest

evaluator:
  playwright: true
  api_tests: true
  max_iterations: 5
  pass_threshold: 7

dev_server:
  start_cmd: "npm run dev"
  port: 3000
  health_check: "http://localhost:3000"
```

### Setup

`setup-project.sh /path/to/your-app`:
1. Symlinks `harness/` into the target project
2. Merges harness CLAUDE.md instructions with existing CLAUDE.md
3. Creates `sprints/` directory for state tracking

## Key Principles

- Separate generation from evaluation (GAN-inspired)
- Context resets over compaction
- Concrete, measurable grading criteria
- Sprint contracts prevent goalpost-moving
- Files on disk as memory, not in-context state
- Fresh subagent per sprint for quality consistency
