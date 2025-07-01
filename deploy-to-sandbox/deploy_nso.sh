#!/bin/bash
set -e

# This script runs on the VM to deploy the NSO container

echo "=== Loading environment variables ==="
source ./sandbox_env_vars.sh
echo "NSO_VERSION: $NSO_VERSION"
echo "TAG_IMAGE: $TAG_IMAGE"
echo "Expected image: $TAG_IMAGE:$NSO_VERSION"
EXPECTED_TAG="$TAG_IMAGE:$NSO_VERSION"

# Detect if docker or podman is available
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman 2>/dev/null)
if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Error: Neither Docker nor Podman is installed or in PATH on remote host"
    exit 1
fi
CONTAINER_ENGINE_NAME=$(basename $CONTAINER_ENGINE)
echo "Using container engine: $CONTAINER_ENGINE_NAME"

if [ "$CONTAINER_ENGINE_NAME" = "podman" ]; then
    COMPOSE_CMD="podman-compose"
else
    COMPOSE_CMD="$CONTAINER_ENGINE compose"
fi

echo "=== Verifying image availability ==="
if ! $CONTAINER_ENGINE image inspect "$EXPECTED_TAG" >/dev/null 2>&1; then
    echo "⚠️ Error: Image $EXPECTED_TAG is not available locally on the remote host."
    echo "Please make sure the image is properly loaded before deploying."
    exit 1
fi
echo "✅ Image $EXPECTED_TAG is available for deployment."

echo "Deploying NSO version: $NSO_VERSION"

echo "=== Stopping any running NSO container ==="
$COMPOSE_CMD  --profile prod down

# Make sure .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️ Warning: .env file not found."
    echo "Creating .env file as a fallback..."
    touch .env
fi

# Ensure .env ends with a newline to avoid concatenation issues
tail -c1 .env | read -r _ || echo >> .env

# Append missing variables from sandbox_env_vars.sh to .env
while IFS= read -r line; do
    # Skip comments and export lines
    if [[ "$line" =~ ^# ]] || [[ "$line" =~ ^export ]] || [[ -z "$line" ]]; then
        continue
    fi
    var_name="${line%%=*}"
    # Remove possible whitespace
    var_name="${var_name// /}"
    # Check if variable is already in .env
    if ! grep -q "^$var_name=" .env; then
        echo "$line" >> .env
        echo "Added missing variable: $var_name to .env"
    fi
done < sandbox_env_vars.sh

echo "=== Starting the NSO container  ==="
$COMPOSE_CMD --profile prod up -d

echo "=== NSO container  started ==="