#!/bin/bash

# Configuration
CONTAINER_USER_DIR="/home/ubuntu"  # User directory inside the container
BASE_IMAGE="base-image-mraid"      # Base image for the container
CURRENT_DIR=$(pwd -P)              # Current directory (absolute path)

# Function to build the base image if it doesn't exist
build_base_image() {
    echo "Base image '$BASE_IMAGE' not found. Building it now..."
    podman build -t "$BASE_IMAGE" - <<EOF
FROM ubuntu:latest

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
EOF

    if [ $? -ne 0 ]; then
        echo "Error: Failed to build base image '$BASE_IMAGE'"
        exit 1
    fi
    echo "Base image '$BASE_IMAGE' successfully built."
}

# Check if the base image exists
if ! podman image exists "$BASE_IMAGE"; then
    build_base_image
fi

# Check if MRAID_DIRECTORY is set
if [[ -z "$MRAID_DIRECTORY" ]]; then
  echo "Error: MRAID_DIRECTORY environment variable is not set."
  echo "Please define MRAID_DIRECTORY in your .bashrc or shell configuration."
  exit 1
fi

# Check if package.json exists
if [[ ! -f "$CURRENT_DIR/package.json" ]]; then
  echo "This is not an MRAID project: package.json not found."
  exit 1
fi

# Check if the current directory is inside the MRAID directory
if [[ "$CURRENT_DIR" != "$MRAID_DIRECTORY/"* ]]; then
  echo "This is not an MRAID project: current directory is not inside the MRAID directory."
  exit 1
fi

# Extract the port from package.json
PORT=$(grep -oP '"port":\s*\K[0-9]+' "$CURRENT_DIR/package.json" 2>/dev/null)

# If the port is found, map it and the next port
if [[ -n "$PORT" ]]; then
  NEXT_PORT=$((PORT + 1))
  PORT_MAPPING="-p $PORT:$PORT -p $NEXT_PORT:$NEXT_PORT"
else
  echo "No 'port' field found in package.json."
  exit 1
fi

# Extract the Node.js version from package.json
NODE_VERSION=$(grep -oP '"node":\s*"\K[0-9]+\.[0-9]+\.[0-9]+' "$CURRENT_DIR/package.json" 2>/dev/null)

# Calculate the final path inside the container
RELATIVE_PATH="${CURRENT_DIR#$MRAID_DIRECTORY/}"  # Remove MRAID directory prefix
FINAL_PATH="$CONTAINER_USER_DIR/$RELATIVE_PATH"   # Full path inside the container

# Prepare the command to run inside the container
if [[ -n "$NODE_VERSION" ]]; then
  CMD="cd '$FINAL_PATH' && source ~/.bashrc && volta install node@'$NODE_VERSION' && { [[ ! -d node_modules || ! -f package-lock.json ]] && npm install || true; } && npm run dev"
else
  CMD="cd '$FINAL_PATH' && exec bash"
fi

# Run a temporary container without a name
podman run --rm -it \
  --userns=keep-id \
  --user=$(id -u):$(id -g) \
  --volume "$MRAID_DIRECTORY:$CONTAINER_USER_DIR:Z" \
  --env "HOME=$CONTAINER_USER_DIR" \
  $PORT_MAPPING \
  "$BASE_IMAGE" \
  bash -c "$CMD"
