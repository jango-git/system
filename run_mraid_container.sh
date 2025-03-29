#!/bin/bash

_run_mraid_container() {
  local readonly CONTAINER_USER_DIR="/mnt"
  local readonly VOLTA_INSTALL_URL="https://get.volta.sh"

  # Validate input arguments and check environment requirements
  validate_input() {
    if [[ -z "$1" ]]; then
      echo "Error: MRAID directory must be specified"
      echo "Usage: $0 <mraid_directory> [base_image_name]"
      exit 1
    fi

    if [[ ! -f "package.json" ]]; then
      echo "Error: package.json file not found"
      exit 1
    fi

    local mraid_dir=$(realpath "$1")
    local current_dir=$(pwd)

    if [[ "$current_dir" != "$mraid_dir/"* ]]; then
      echo "Error: Current directory is not inside the MRAID directory"
      exit 1
    fi

    echo "$mraid_dir;${2:-$DEFAULT_BASE_IMAGE}"
  }

  # Generate container arguments based on project configuration
  generate_container_args() {
    local mraid_dir=$1
    local current_dir=$(pwd)

    local node_version=$(grep -oP '"node":\s*"\K[0-9.]+' package.json)
    [[ -z "$node_version" ]] && { echo "Error: Node.js version not specified"; exit 1; }

    local port=$(grep -oP '"port":\s*\K[0-9]+' package.json || grep -oP 'port:\s*\K[0-9]+' webpack.config.js 2>/dev/null)
    [[ -z "$port" ]] && { echo "Error: Port not specified"; exit 1; }

    local relative_path="${current_dir#$mraid_dir/}"
    local container_path="$CONTAINER_USER_DIR/$relative_path"
    local port_mapping="-p $port:$port -p $((port+1)):$((port+1))"

    local container_cmd="cd '$container_path' && \
      [ ! -f ~/.bashrc ] && { \
        echo 'export VOLTA_HOME=\"\$HOME/.volta\"' >> ~/.bashrc && \
        echo 'export PATH=\"\$VOLTA_HOME/bin:\$PATH\"' >> ~/.bashrc; \
      } && \
      [ ! -d ~/.volta ] && curl -fsSL $VOLTA_INSTALL_URL | bash || true && \
      source ~/.bashrc && \
      volta install node@$node_version && \
      { [ ! -d node_modules ] || [ ! -f package-lock.json ]; } && npm install || true && \
      npm run dev"

    echo "$node_version;$port;$port_mapping;$container_path;$container_cmd"
  }

  # Ensure the base container image exists, build if necessary
  ensure_base_image() {
    local image_name=$1

    if ! podman image exists "$image_name"; then
      echo "Creating base image $image_name..."
      podman build -t "$image_name" - <<EOF
FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean
EOF

      if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create base image"
        exit 1
      fi
    fi
  }

  # Run the container with the configured parameters
  run_container() {
    local mraid_dir=$1
    local base_image=$2
    local node_version=$3
    local port_mapping=$4
    local container_path=$5
    local container_cmd=$6

    echo "Starting container:"
    echo "  Node.js: $node_version"
    echo "  Path: $container_path"
    echo "  Port: $port_mapping"

    podman run --rm -it \
      --userns=keep-id \
      --volume "$mraid_dir:$CONTAINER_USER_DIR:Z" \
      --env "HOME=$CONTAINER_USER_DIR" \
      $port_mapping \
      "$base_image" \
      bash -c "$container_cmd"
  }

  local input=$(validate_input "$@")
  IFS=';' read -r mraid_dir base_image <<< "$input"

  local container_args=$(generate_container_args "$mraid_dir")
  IFS=';' read -r node_version port port_mapping container_path container_cmd <<< "$container_args"

  ensure_base_image "$base_image"
  run_container "$mraid_dir" "$base_image" "$node_version" "$port_mapping" "$container_path" "$container_cmd"
}

_run_mraid_container "$@"
unset -f _run_mraid_container
