#!/bin/bash

PARENT_DIR="$HOME/Development/MRAID"
CONTAINER_USER_DIR="/home/ubuntu"
BASE_IMAGE="base-image"
CONTAINER_NAME="mraid-container"
CURRENT_DIR=$(pwd -P)

if [[ "$CURRENT_DIR" == "$PARENT_DIR/"* ]]; then
  FINAL_PATH="${CURRENT_DIR#$PARENT_DIR/}"
  FINAL_PATH="$CONTAINER_USER_DIR/$FINAL_PATH"
else
  FINAL_PATH="$CONTAINER_USER_DIR"
fi

if podman ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
  podman exec -it "$CONTAINER_NAME" bash -c "cd '$FINAL_PATH' && exec bash"
else
  podman run --rm -dit \
    --name "$CONTAINER_NAME" \
    --userns=keep-id \
    --user=$(id -u):$(id -g) \
    --volume "$PARENT_DIR:$CONTAINER_USER_DIR:Z" \
    --env "HOME=$CONTAINER_USER_DIR" \
    -p 3000-3002:3000-3002 \
    -p 4400-4500:4400-4500 \
    "$BASE_IMAGE"
  
  podman exec -it "$CONTAINER_NAME" bash -c "cd '$FINAL_PATH' && exec bash"
fi
