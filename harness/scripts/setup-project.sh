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
