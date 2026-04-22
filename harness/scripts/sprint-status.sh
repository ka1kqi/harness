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
