#!/bin/bash
set -euo pipefail

# Interactive tmux project (.proj) file generator
# Creates .proj files in ~/dotfiles/tmux/projects/

PROJECTS_DIR="$HOME/dotfiles/tmux/projects"

echo ""
echo "━━ Tmux Project Generator ━━"
echo ""

# 1. Session name
while true; do
    read -p "Session name (e.g., MyProject): " session_name
    if [[ -z "$session_name" ]]; then
        echo "  Session name cannot be empty."
    elif [[ "$session_name" == *" "* ]]; then
        echo "  Session name cannot contain spaces."
    else
        break
    fi
done

# 2. Working directory
while true; do
    read -p "Working directory (e.g., ~/Projects/myapp): " work_dir
    if [[ -z "$work_dir" ]]; then
        echo "  Working directory cannot be empty."
        continue
    fi
    # Expand ~ for validation
    expanded_dir="${work_dir/#\~/$HOME}"
    if [[ -d "$expanded_dir" ]]; then
        break
    else
        echo "  Directory '$expanded_dir' does not exist."
        read -p "  Create it? [y/N]: " create_dir
        if [[ "$create_dir" =~ ^[Yy]$ ]]; then
            mkdir -p "$expanded_dir" && break
            echo "  Failed to create directory."
        fi
    fi
done

# 3. First window name
read -p "First window name [Neovim]: " win1_name
win1_name="${win1_name:-Neovim}"

# 4. Vim target
read -p "Open vim on (file or directory) [.]: " vim_target
vim_target="${vim_target:-.}"

# 5. AI assistant
echo ""
echo "AI assistant for split pane:"
echo "  1) claude"
echo "  2) opencode"
echo "  3) codex"
echo "  4) none"
read -p "Choose [1]: " ai_choice
case "$ai_choice" in
    2) ai_cmd="opencode" ;;
    3) ai_cmd="codex" ;;
    4) ai_cmd="" ;;
    *) ai_cmd="claude" ;;
esac

# 6. Console window
read -p "Add Console window? [Y/n]: " add_console
add_console="${add_console:-Y}"

# 7. Lazygit window
read -p "Add Lazygit window? [Y/n]: " add_lazygit
add_lazygit="${add_lazygit:-Y}"

# 8. Custom windows
custom_windows=()
echo ""
read -p "Add custom windows? [y/N]: " add_custom
if [[ "$add_custom" =~ ^[Yy]$ ]]; then
    while true; do
        read -p "  Window name (empty to stop): " cw_name
        [[ -z "$cw_name" ]] && break
        read -p "  Command to run in '$cw_name': " cw_cmd
        custom_windows+=("$cw_name|$cw_cmd")
    done
fi

# 9. Output filename
default_filename=$(echo "$session_name" | tr '[:upper:]' '[:lower:]')
read -p "Output filename [${default_filename}.proj]: " output_name
output_name="${output_name:-${default_filename}.proj}"
# Ensure .proj extension
[[ "$output_name" != *.proj ]] && output_name="${output_name}.proj"

output_path="${PROJECTS_DIR}/${output_name}"

# Check if file already exists
if [[ -f "$output_path" ]]; then
    read -p "File '$output_name' already exists. Overwrite? [y/N]: " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# --- Generate the .proj file ---

# Track window index
win_idx=1

# Build the file content
{
    echo '#!/bin/bash'
    echo ''
    echo "# tmux setup for ${session_name}"
    echo ''
    echo ''
    echo "if ! tmux has-session -t \"${session_name}\""
    echo 'then'
    echo ''

    # Window 1: Main editor window
    echo "# ${win1_name}"
    echo "tmux new-session -s \"${session_name}\" -n \"${win1_name}\" -d"
    echo "tmux send-keys -t \"${session_name}\":${win_idx} 'cd \"${work_dir}\"' C-m"
    echo "tmux send-keys -t \"${session_name}\":${win_idx} 'vim \"${vim_target}\"' C-m"

    # AI split pane
    if [[ -n "$ai_cmd" ]]; then
        echo ''
        echo "# Create horizontal split and start ${ai_cmd}"
        echo "tmux split-window -h -t \"${session_name}\":${win_idx}"
        echo "tmux send-keys -t \"${session_name}\":${win_idx}.2 'cd \"${work_dir}\"' C-m"
        echo "tmux send-keys -t \"${session_name}\":${win_idx}.2 '${ai_cmd}' C-m"
    fi

    # Console window
    if [[ "$add_console" =~ ^[Yy]$ ]]; then
        win_idx=$((win_idx + 1))
        echo ''
        echo ''
        echo "# Console Window"
        echo "tmux new-window -n Console -t \"${session_name}\""
        echo "tmux send-keys -t \"${session_name}\":${win_idx} 'cd \"${work_dir}\"' C-m"
        echo "tmux send-keys -t \"${session_name}\":${win_idx} 'clear' C-m"
    fi

    # Lazygit window
    if [[ "$add_lazygit" =~ ^[Yy]$ ]]; then
        win_idx=$((win_idx + 1))
        echo ''
        echo ''
        echo "# Lazygit"
        echo "tmux new-window -n Lazygit -t \"${session_name}\""
        echo "tmux send-keys -t \"${session_name}\":${win_idx} 'cd \"${work_dir}\"' C-m"
        echo "tmux send-keys -t \"${session_name}\":${win_idx} 'lg' C-m"
    fi

    # Custom windows
    for cw in "${custom_windows[@]}"; do
        cw_name="${cw%%|*}"
        cw_cmd="${cw#*|}"
        win_idx=$((win_idx + 1))
        echo ''
        echo ''
        echo "# ${cw_name}"
        echo "tmux new-window -n \"${cw_name}\" -t \"${session_name}\""
        echo "tmux send-keys -t \"${session_name}\":${win_idx} 'cd \"${work_dir}\"' C-m"
        if [[ -n "$cw_cmd" ]]; then
            echo "tmux send-keys -t \"${session_name}\":${win_idx} '${cw_cmd}' C-m"
        fi
    done

    # Select first window and pane
    echo ''
    echo "# Select the ${win1_name} window"
    echo "tmux select-window -t \"${session_name}\":1"
    echo "tmux select-pane -t \"${session_name}\":1.1"
    echo 'fi'
    echo ''

    # Attach/switch logic
    echo '# Attach or switch to session'
    echo 'if [ -n "$TMUX" ]; then'
    echo "    tmux switch-client -t \"${session_name}\""
    echo 'else'
    echo "    tmux attach -t \"${session_name}\""
    echo 'fi'

} > "$output_path"

chmod +x "$output_path"

echo ''
echo "━━ Project file created ━━"
echo "  File: ${output_path}"
echo "  Session: ${session_name}"
echo "  Use 'ss' to launch it"
echo ''
