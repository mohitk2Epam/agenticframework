#!/bin/bash
# SF AI Dev Framework - Install Script
# Copies .claude/ directory into target SFDX project

set -e

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

if [ ! -f "$TARGET_DIR/sfdx-project.json" ]; then
    echo "Warning: No sfdx-project.json found in '$TARGET_DIR'."
    echo "Are you sure this is an SFDX project? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$TARGET_DIR/.claude" ]; then
    echo "Warning: .claude/ already exists in '$TARGET_DIR'."
    echo "This will merge framework files into existing .claude/ directory."
    echo "Existing files will NOT be overwritten. Continue? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
fi

# Copy framework content
cp -rn "$SCRIPT_DIR/.claude/skills" "$TARGET_DIR/.claude/" 2>/dev/null || true
cp -rn "$SCRIPT_DIR/.claude/agents" "$TARGET_DIR/.claude/" 2>/dev/null || true
cp -rn "$SCRIPT_DIR/.claude/workflows" "$TARGET_DIR/.claude/" 2>/dev/null || true
mkdir -p "$TARGET_DIR/.claude/context"

# Copy CLAUDE.md only if it doesn't exist
if [ ! -f "$TARGET_DIR/.claude/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/.claude/CLAUDE.md" "$TARGET_DIR/.claude/CLAUDE.md"
    echo "Created .claude/CLAUDE.md"
else
    echo "Skipped .claude/CLAUDE.md (already exists)"
fi

# Copy skills-registry.json only if it doesn't exist
if [ ! -f "$TARGET_DIR/.claude/skills-registry.json" ]; then
    cp "$SCRIPT_DIR/.claude/skills-registry.json" "$TARGET_DIR/.claude/skills-registry.json"
    echo "Created .claude/skills-registry.json"
else
    echo "Skipped .claude/skills-registry.json (already exists)"
fi

echo ""
echo "SF AI Dev Framework installed to: $TARGET_DIR/.claude/"
echo ""
echo "Next steps:"
echo "  1. Run AIInitFramework to populate .claude/context/"
echo "  2. Open project in Claude Code (CLAUDE.md loads automatically)"
echo "  3. For Cursor: copy .claude/CLAUDE.md content to .cursorrules"
