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
