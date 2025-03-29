#!/bin/bash

_generate_code() {
  # Generate a single random character from the provided character set
  generate_char() {
    local chars="$1"
    echo -n "${chars:$((RANDOM % ${#chars})):1}"
  }

  # Generate a shuffled group containing one character from each character class
  generate_group() {
    local lowercase="abcdefghijklmnopqrstuvwxyz"
    local uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers="0123456789"
    local special="!@#$%^&*()_+-=[]{}|;:,.<>?~"

    local group=""
    group+=$(generate_char "$lowercase")
    group+=$(generate_char "$uppercase")
    group+=$(generate_char "$numbers")
    group+=$(generate_char "$special")

    # Shuffle the characters in the group
    group=$(echo "$group" | fold -w1 | shuf | tr -d '\n')
    echo -n "$group"
  }

  # Default number of groups to generate
  local num_groups=4

  # Process command line argument if provided
  if [ $# -gt 0 ]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      num_groups="$1"
    else
      echo "Error: Argument must be a positive integer."
      exit 1
    fi
  fi

  # Generate the specified number of character groups
  local groups=()
  for ((i = 0; i < num_groups; i++)); do
    groups+=("$(generate_group)")
  done

  # Output all generated groups
  echo "${groups[*]}"
}

_generate_code "$@"
unset -f _generate_code
