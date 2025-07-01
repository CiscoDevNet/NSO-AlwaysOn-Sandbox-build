#!/bin/bash
# post_cleanup_nso.sh
# Removes all dangling Docker images (untagged) non-interactively

set -e

CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman 2>/dev/null)
if [ -z "$CONTAINER_ENGINE" ]; then
  echo "Neither Docker nor Podman is installed or in PATH" >&2
  exit 1
fi

echo "Cleaning up dangling images..."
$CONTAINER_ENGINE image prune -f

echo "Dangling images removed."
