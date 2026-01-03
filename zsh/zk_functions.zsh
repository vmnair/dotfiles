# ZK (Zettelkasten) functionality for zsh
# This file contains all zk-related aliases, functions, and environment variables

# Set the default notes directory for zk (use real path, not symlink)
export ZK_NOTEBOOK_DIR="$HOME/Library/CloudStorage/Dropbox/notebook"

# ZK search alias
alias search="zk search "

# ZK help function - displays available zk aliases from config
zkhelp() {
    echo "ZK Aliases:"
    awk '/^\[alias\]$/ { in_alias=1; next } /^\[/ && in_alias { in_alias=0 } in_alias && /=/ {
        split($0, parts, " = ")
        alias_name = parts[1]
        command = parts[2]
        gsub(/^'\''|'\''$/, "", command)
        gsub(/.*--title /, "", command)
        gsub(/\$\{@:-/, "", command)
        gsub(/\}.*/, "", command)
        gsub(/"/, "", command)
        printf "  zk %-12s - %s\n", alias_name, command
    }' "$ZK_NOTEBOOK_DIR/.zk/config.toml" 2>/dev/null || \
    awk '/^\[alias\]$/ { in_alias=1; next } /^\[/ && in_alias { in_alias=0 } in_alias && /=/ {
        split($0, parts, " = ")
        alias_name = parts[1]
        command = parts[2]
        gsub(/^'\''|'\''$/, "", command)
        gsub(/.*--title /, "", command)
        gsub(/\$\{@:-/, "", command)
        gsub(/\}.*/, "", command)
        gsub(/"/, "", command)
        printf "  zk %-12s - %s\n", alias_name, command
    }' ~/.zk/config.toml
}

# Wrapper for zk - shows folder picker when called with no args
# Passes through to real zk binary for all other commands
# Keybindings: Enter = new note, Ctrl-e = edit existing file
zk() {
  # If arguments provided, pass through to real zk binary
  if [[ $# -gt 0 ]]; then
    command zk "$@"
    return
  fi

  # No arguments - show folder picker
  local folder title selection key

  selection=$(find -L "$ZK_NOTEBOOK_DIR" -type d -not -path '*/\.*' 2>/dev/null | \
    sed "s|^$ZK_NOTEBOOK_DIR/||" | \
    grep -v "^$" | \
    sort | \
    fzf --preview "ls -1 $ZK_NOTEBOOK_DIR/{}" \
        --header "Enter: new note | Ctrl-e: edit existing" \
        --expect=ctrl-e)

  # Parse key and folder from selection
  key=$(echo "$selection" | head -1)
  folder=$(echo "$selection" | tail -1)

  [[ -z "$folder" ]] && return 1

  if [[ "$key" == "ctrl-e" ]]; then
    # Edit existing file - show file picker
    local file
    file=$(find -L "$ZK_NOTEBOOK_DIR/$folder" -maxdepth 1 -type f -name "*.md" 2>/dev/null | \
      sed "s|^$ZK_NOTEBOOK_DIR/$folder/||" | \
      sort | \
      fzf --preview "head -20 $ZK_NOTEBOOK_DIR/$folder/{}" \
          --header "Select file to edit")

    [[ -z "$file" ]] && return 1
    ${EDITOR:-nvim} "$ZK_NOTEBOOK_DIR/$folder/$file"
  else
    # Create new note
    echo -n "Title: "
    read title
    [[ -z "$title" ]] && title="Untitled"
    command zk new --no-input "$ZK_NOTEBOOK_DIR/$folder" --title "$title"
  fi
}

# Quick daily journal entry
zkdaily() {
  local title="${1:-Daily Journal}"
  command zk new --no-input "$ZK_NOTEBOOK_DIR/journal" --title "$title"
}
