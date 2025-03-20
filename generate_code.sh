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

# Generate 4 groups of characters
group1=$(generate_group)  # Generate the first group
group2=$(generate_group)  # Generate the second group
group3=$(generate_group)  # Generate the third group
group4=$(generate_group)  # Generate the fourth group

# Output the result as 4 groups separated by spaces
echo "$group1 $group2 $group3 $group4"
