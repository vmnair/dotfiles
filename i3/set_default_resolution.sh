#!/bin/bash

  # Check if the script exists
  if [[ -f "$HOME/.screenlayout/default.sh" ]]; then
    "$HOME/.screenlayout/default.sh"
  else
    echo "The script $HOME/.screenlayout/default.sh does not exist."
  fi
