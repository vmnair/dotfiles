#!/usr/bin/env bash
# Run todo-manager tests
# Usage: ./tests/run_tests.sh [specific_file.lua]
# Run from: dev-plugins/todo-manager.nvim/

set -euo pipefail

SCRIPT_DIR="$(builtin cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

builtin cd "$PROJECT_DIR"

exit_code=0

if [ $# -gt 0 ]; then
    # Run specific file
    echo "Running: $1"
    nvim --headless -l "$1" || exit_code=1
else
    # Run all *_spec.lua files
    for spec in tests/*_spec.lua; do
        echo "Running: $spec"
        nvim --headless -l "$spec" || exit_code=1
        echo ""
    done
fi

exit $exit_code
