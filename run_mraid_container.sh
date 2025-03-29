#!/bin/bash

# =============================================
# Configuration section
# =============================================
readonly CONTAINER_USER_DIR="/mnt"
readonly VOLTA_INSTALL_URL="https://get.volta.sh"

# =============================================
# Function definitions
# =============================================

# Initialize and validate environment
init_environment() {
    readonly CURRENT_DIR=$(pwd -P)

    # Set MRAID_DIRECTORY from first argument
    if [[ -z "$1" ]]; then
        error_exit "MRAID_DIRECTORY argument is required." \
                  "Usage: $0 <mraid_directory> [base_image_name]"
    fi
    readonly MRAID_DIRECTORY=$(realpath "$1")

    # Set BASE_IMAGE from second argument or use default
    readonly BASE_IMAGE=${2:-"base-image-mraid"}

    if [[ ! -f "$CURRENT_DIR/package.json" ]]; then
        error_exit "This is not an MRAID project: package.json not found."
    fi

    if [[ "$CURRENT_DIR" != "$MRAID_DIRECTORY/"* ]]; then
        error_exit "This is not an MRAID project: current directory is not inside the MRAID directory."
    fi
}

# Build base container image if needed
ensure_base_image() {
    if ! podman image exists "$BASE_IMAGE"; then
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
            error_exit "Failed to build base image '$BASE_IMAGE'"
        fi

        echo "Base image '$BASE_IMAGE' successfully built."
    fi
}

# Extract configuration from package.json or webpack.config.js
get_project_config() {
    local package_json="$CURRENT_DIR/package.json"
    local webpack_config="$CURRENT_DIR/webpack.config.js"

    # Get Node.js version
    readonly NODE_VERSION=$(grep -oP '"node":\s*"\K[0-9]+\.[0-9]+\.[0-9]+' "$package_json" 2>/dev/null)
    if [[ -z "$NODE_VERSION" ]]; then
        error_exit "Node.js version not specified in package.json" \
                  "Please add \"node\": \"x.y.z\" to your package.json"
    fi

    # Get port number (try package.json first, then webpack.config.js)
    readonly PORT=$(grep -oP '"port":\s*\K[0-9]+' "$package_json" 2>/dev/null ||
                    grep -oP 'port:\s*\K[0-9]+' "$webpack_config" 2>/dev/null)
    if [[ -z "$PORT" ]]; then
        error_exit "No 'port' field found in package.json or webpack.config.js."
    fi

    readonly NEXT_PORT=$((PORT + 1))
    readonly PORT_MAPPING="-p $PORT:$PORT -p $NEXT_PORT:$NEXT_PORT"

    # Calculate container path
    readonly RELATIVE_PATH="${CURRENT_DIR#$MRAID_DIRECTORY/}"
    readonly FINAL_PATH="$CONTAINER_USER_DIR/$RELATIVE_PATH"
}

# Prepare the command to run inside container
prepare_container_command() {
    local cmd_parts=(
        "cd '$FINAL_PATH'"
        "[ ! -f ~/.bashrc ] && echo 'export VOLTA_HOME=\"\$HOME/.volta\"' >> ~/.bashrc && echo 'export PATH=\"\$VOLTA_HOME/bin:\$PATH\"' >> ~/.bashrc"
        "[ ! -d ~/.volta ] && curl -fsSL $VOLTA_INSTALL_URL | bash || true"
        "source ~/.bashrc"
        "volta install node@'$NODE_VERSION'"
        "[ ! -d node_modules ] || [ ! -f package-lock.json ] && npm install || true"
        "npm run dev"
    )

    CONTAINER_CMD=$(printf "%s && " "${cmd_parts[@]}")
    CONTAINER_CMD="${CONTAINER_CMD% && }"

    readonly CONTAINER_CMD
}

# Run the container with prepared configuration
run_container() {
    echo "Starting container with Node.js $NODE_VERSION..."
    echo "Project path in container: $FINAL_PATH"
    echo "Port mapping: $PORT_MAPPING"

    podman run --rm -it \
        --userns=keep-id \
        --user=$(id -u):$(id -g) \
        --volume "$MRAID_DIRECTORY:$CONTAINER_USER_DIR:Z" \
        --env "HOME=$CONTAINER_USER_DIR" \
        $PORT_MAPPING \
        "$BASE_IMAGE" \
        bash -c "$CONTAINER_CMD"
}

# Display error message and exit
error_exit() {
    for msg in "$@"; do
        echo "Error: $msg" >&2
    done
    exit 1
}

# =============================================
# Main script execution
# =============================================
main() {
    init_environment "$@"
    ensure_base_image
    get_project_config
    prepare_container_command
    run_container
}

main "$@"
