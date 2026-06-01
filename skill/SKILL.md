---
name: harness
description: Run the autonomous Plan -> Sprint -> Evaluate development harness. Use when the user wants to build a feature end-to-end with automated planning, implementation, and quality evaluation.
when_to_use: "When user says 'harness', 'use the harness', 'run the harness', 'build this with the harness', or wants autonomous multi-sprint development with evaluation"
argument-hint: "[feature request]"
allowed-tools: Bash(find *) Bash(mkdir *) Bash(cat *) Bash(git *) Bash(npx *) Bash(npm *) Bash(python *) Bash(curl *) Bash(chmod *)
---

# Claude Code Harness — Autonomous Plan -> Sprint -> Evaluate Loop

You are running the Claude Code Harness. This is an autonomous development workflow that separates generation from evaluation for higher quality output.

## Setup Check

First, verify the harness is installed in this project:

1. Check if `harness/` directory exists (symlink or real directory)
2. Check if `harness.config.yaml` exists
3. If neither exists, run: `bash ~/Documents/GitHub/claude-harness/harness/scripts/setup-project.sh .`
4. If config exists but needs customization, ask the user to review `harness.config.yaml`

## Feature Request

The user's feature request: **$ARGUMENTS**

If no arguments were provided, ask the user what they want to build.

## The Loop

Follow these steps exactly. Do not skip or shortcut any step.

### Step 1: Plan

Spawn a **Planner subagent** (use the Agent tool). Pass it:
- The full contents of `harness/agents/planner.md` as the system prompt
- The user's feature request: `$ARGUMENTS`
- The contents of `harness.config.yaml`
- The project's file tree: `find . -type f -not -path './.git/*' -not -path './node_modules/*' | head -100`
- The project's `CLAUDE.md` (if it exists, excluding the Harness section)

The planner writes `sprints/plan.md`. After it completes, read the plan and show a summary to the user.

### Step 2: Sprint Loop

For each sprint in `sprints/plan.md`:

**a. Generate Contract**
Read the sprint details from `sprints/plan.md`. Fill in `harness/templates/sprint-contract.md` with the sprint's data and config values. Save to `sprints/sprint-N/contract.md`.

**b. Spawn Generator**
Spawn a **Generator subagent** (use the Agent tool). Pass it:
- The full contents of `harness/agents/generator.md` as the system prompt
- The contents of `sprints/sprint-N/contract.md`
- The contents of `harness.config.yaml`
- The project's `CLAUDE.md`
- If this is a retry: the contents of `sprints/sprint-N/evaluation.md`

The generator implements the feature, runs tests, commits, and writes `sprints/sprint-N/self-review.md`.

**c. Spawn Evaluator**
Spawn an **Evaluator subagent** (use the Agent tool). Pass it:
- The full contents of `harness/agents/evaluator.md` as the system prompt
- The contents of `sprints/sprint-N/contract.md`
- The contents of `sprints/sprint-N/self-review.md`
- The contents of `harness.config.yaml`

The evaluator tests the app and writes `sprints/sprint-N/evaluation.md`.

**d. Check Verdict**
Read `sprints/sprint-N/evaluation.md`:
- If **PASS**: Write `PASS` to `sprints/sprint-N/status.md`. Move to next sprint.
- If **FAIL** and iteration count < `max_iterations` from config: Write `FAIL iteration M` to `sprints/sprint-N/status.md`. Go back to step b, passing the evaluation critique.
- If **FAIL** and iteration count >= `max_iterations`: Write `FAIL max_iterations_reached` to `sprints/sprint-N/status.md`. Log to `sprints/summary.md` and move on.

**e. Update Summary**
Append sprint results (name, verdict, score, iteration count) to `sprints/summary.md`.

### Step 3: Complete

After all sprints finish, read `sprints/summary.md` and report the final status to the user.

## Critical Rules

- **Fresh subagent per sprint.** Each generator/evaluator invocation gets clean context — pass only file contents, never conversation history.
- **Never skip evaluation.** Every sprint gets evaluated, even if the generator says it's perfect.
- **The evaluator is skeptical.** Don't soften, filter, or summarize its critique when passing it back to the generator.
- **Always use /frontend-design for UI work.** If a sprint involves frontend code, the generator MUST use the `/frontend-design` skill. The evaluator auto-caps scores for generic aesthetics (Inter font = 3/10, purple gradients = 3/10, unstyled templates = 4/10).
- **State lives on disk.** All sprint state goes in `sprints/`. This is the memory system.
