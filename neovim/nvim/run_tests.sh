#!/bin/bash
# Portable test runner for readwise.nvim development
# Usage: ./run_tests.sh [options]
# Options:
#   watch    - Run tests automatically when files change
#   verbose  - Show detailed output including debug messages
#   help     - Show this help message

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if we're in the right directory
check_environment() {
    if [ ! -d "tests" ]; then
        print_color $RED "Error: tests/ directory not found"
        print_color $YELLOW "Run this script from the directory containing tests/"
        print_color $BLUE "Expected structure:"
        print_color $BLUE "  tests/"
        print_color $BLUE "  ├── minimal_init.lua"
        print_color $BLUE "  └── readwise_spec.lua"
        exit 1
    fi
    
    if [ ! -f "tests/minimal_init.lua" ]; then
        print_color $RED "Error: tests/minimal_init.lua not found"
        exit 1
    fi
    
    if [ ! -f "tests/readwise_spec.lua" ]; then
        print_color $RED "Error: tests/readwise_spec.lua not found"
        exit 1
    fi
}

# Run the test suite
run_tests() {
    local verbose=${1:-false}
    
    print_color $BLUE "Running Readwise tests from $(pwd)..."
    print_color $BLUE "Using runtime path: $(pwd)"
    
    if [ "$verbose" = true ]; then
        # Verbose mode - show all output
        nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "quit"
    else
        # Clean mode - filter output to show only test results
        nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "quit" 2>&1 | \
        grep -E "(Success|Failed|Errors|Testing:|✓|✗|\[32m|\[31m|should|describe)" || \
        {
            print_color $RED "Test run failed or no output captured"
            print_color $YELLOW "Try running with 'verbose' option for full output"
            return 1
        }
    fi
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        print_color $GREEN "✓ All tests completed"
    else
        print_color $RED "✗ Tests failed with exit code $exit_code"
        return $exit_code
    fi
}

# Watch mode - run tests when files change
watch_tests() {
    print_color $BLUE "Watching for changes... (Press Ctrl+C to stop)"
    print_color $YELLOW "Monitoring: lua/vinod/readwise.lua, tests/"
    
    if command -v fswatch >/dev/null 2>&1; then
        # Use fswatch if available (install with: brew install fswatch)
        fswatch -o lua/vinod/readwise.lua tests/ | while read num; do
            clear
            print_color $YELLOW "File changed, running tests..."
            echo "----------------------------------------"
            run_tests false
            echo "----------------------------------------"
            print_color $BLUE "Waiting for changes..."
        done
    elif command -v inotifywait >/dev/null 2>&1; then
        # Linux alternative
        while inotifywait -r -e modify lua/vinod/readwise.lua tests/ >/dev/null 2>&1; do
            clear
            print_color $YELLOW "File changed, running tests..."
            echo "----------------------------------------"
            run_tests false
            echo "----------------------------------------"
            print_color $BLUE "Waiting for changes..."
        done
    else
        print_color $RED "Watch mode requires fswatch (macOS) or inotifywait (Linux)"
        print_color $YELLOW "Install with:"
        print_color $BLUE "  macOS: brew install fswatch"
        print_color $BLUE "  Linux: apt-get install inotify-tools"
        print_color $YELLOW "Running tests once instead..."
        run_tests false
    fi
}

# Show help
show_help() {
    print_color $BLUE "Readwise Test Runner"
    echo
    print_color $YELLOW "Usage:"
    echo "  ./run_tests.sh              # Run tests once (clean output)"
    echo "  ./run_tests.sh verbose      # Run tests with full output"
    echo "  ./run_tests.sh watch        # Run tests when files change"
    echo "  ./run_tests.sh help         # Show this help"
    echo
    print_color $YELLOW "Requirements:"
    echo "  - Neovim with plenary.nvim plugin"
    echo "  - tests/minimal_init.lua"
    echo "  - tests/readwise_spec.lua"
    echo
    print_color $YELLOW "Optional (for watch mode):"
    echo "  - fswatch (macOS): brew install fswatch"
    echo "  - inotify-tools (Linux): apt-get install inotify-tools"
}

# Main script logic
main() {
    case "${1:-}" in
        "help"|"-h"|"--help")
            show_help
            ;;
        "watch"|"-w"|"--watch")
            check_environment
            watch_tests
            ;;
        "verbose"|"-v"|"--verbose")
            check_environment
            run_tests true
            ;;
        "")
            check_environment
            run_tests false
            ;;
        *)
            print_color $RED "Unknown option: $1"
            print_color $YELLOW "Use './run_tests.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
