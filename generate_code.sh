#!/bin/sh

# Function to generate a random character from a given set
generate_char() {
    local chars="$1"
    # Select a random character from the set
    echo -n "${chars:$((RANDOM % ${#chars})):1}"
}

# Function to generate a group of 4 characters
generate_group() {
    # Define character sets
    local lowercase="abcdefghijklmnopqrstuvwxyz"
    local uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers="0123456789"
    local special="!@#$%^&*()_+-=[]{}|;:,.<>?~"

    # Create a group with one character from each set
    local group=""
    group+=$(generate_char "$lowercase")  # Add a lowercase letter
    group+=$(generate_char "$uppercase")  # Add an uppercase letter
    group+=$(generate_char "$numbers")    # Add a number
    group+=$(generate_char "$special")    # Add a special character

    # Shuffle the characters in the group to randomize their order
    group=$(echo "$group" | fold -w1 | shuf | tr -d '\n')
    echo -n "$group"
}

# Main script logic
main() {
    # Set the default number of groups to generate
    local num_groups=4

    # Check if the user provided a custom number of groups
    if [ $# -gt 0 ]; then
        # Validate that the argument is a positive integer
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            num_groups="$1"
        else
            echo "Error: Argument must be a positive integer."
            exit 1
        fi
    fi

    # Generate the specified number of groups
    local groups=()
    for ((i = 0; i < num_groups; i++)); do
        groups+=("$(generate_group)")
    done

    # Output the groups separated by spaces
    echo "${groups[*]}"
}

# Execute the main function with the provided arguments
main "$@"
