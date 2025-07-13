# ZK (Zettelkasten) functionality for zsh
# This file contains all zk-related aliases, functions, and environment variables

# Set the default notes directory for zk
export ZK_NOTEBOOK_DIR="$HOME/notebook"

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
