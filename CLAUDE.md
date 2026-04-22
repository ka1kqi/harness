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
