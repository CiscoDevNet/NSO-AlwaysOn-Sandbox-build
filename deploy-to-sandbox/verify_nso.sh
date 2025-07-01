#!/bin/bash
set -e

# This script runs on the VM to verify NSO containers

echo "=== Loading environment variables ==="
source ./sandbox_env_vars.sh
echo "NSO_VERSION: $NSO_VERSION"
echo "TAG_IMAGE: $TAG_IMAGE"
echo "Expected image: $TAG_IMAGE:$NSO_VERSION"
echo "Expected container count: $EXPECTED_CONTAINER_COUNT"
echo "Container name pattern: $CONTAINER_NAME"

# Detect if docker or podman is available and use the one that is available
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman 2>/dev/null)
if [ -z "$CONTAINER_ENGINE" ]; then
    echo "Error: Neither Docker nor Podman is installed or in PATH"
    exit 1
fi
CONTAINER_ENGINE_NAME=$(basename $CONTAINER_ENGINE)
echo "Using container engine: $CONTAINER_ENGINE_NAME"

# For podman, we may need to adjust the compose command
if [ "$CONTAINER_ENGINE_NAME" = "podman" ]; then
    COMPOSE_CMD="podman-compose"
else
    COMPOSE_CMD="$CONTAINER_ENGINE compose"
fi


echo "Expected image: $TAG_IMAGE:$NSO_VERSION"

echo "=== Waiting for containers to become healthy ==="
echo "Waiting for NSO containers to become healthy (this may take up to 5 minutes)..."
for i in {1..10}; do 
    echo "Check $i/10: Waiting 30 seconds for containers to initialize..."
    sleep 30
    
    UNHEALTHY=$($CONTAINER_ENGINE ps --filter "health=unhealthy" --format "{{.Names}}" | grep -c "$CONTAINER_NAME" || true)
    HEALTHY=$($CONTAINER_ENGINE ps --filter "health=healthy" --format "{{.Names}}" | grep -c "$CONTAINER_NAME" || true)
    STARTING=$($CONTAINER_ENGINE ps --filter "health=starting" --format "{{.Names}}" | grep -c "$CONTAINER_NAME" || true)
    
    echo "Status: $HEALTHY healthy, $STARTING starting, $UNHEALTHY unhealthy"
    
    if [ $HEALTHY -eq $EXPECTED_CONTAINER_COUNT ]; then
        echo "✅ All containers are healthy!"
        break
    fi
    
    if [ $i -eq 10 ] && [ $HEALTHY -ne $EXPECTED_CONTAINER_COUNT ]; then
        echo "⚠️ Warning: Not all containers are healthy after 5 minutes. Proceeding anyway..."
    fi
done

echo "=== Docker Compose Status ==="
$COMPOSE_CMD ps

echo "=== Container Status ==="
$CONTAINER_ENGINE ps --format "table {{.Names}}\t{{.Status}}"

echo "=== Verifying correct NSO version is running ==="
$CONTAINER_ENGINE ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
IMAGE_COUNT=$($CONTAINER_ENGINE ps --format "{{.Image}}" | grep -c "$TAG_IMAGE:$NSO_VERSION" || true)

if [ $IMAGE_COUNT -eq $EXPECTED_CONTAINER_COUNT ]; then
    echo "✅ Verification successful: All $IMAGE_COUNT containers running the correct image: $TAG_IMAGE:$NSO_VERSION"
else
    echo "❌ Verification failed: Expected $EXPECTED_CONTAINER_COUNT containers with image $TAG_IMAGE:$NSO_VERSION but found $IMAGE_COUNT"
    exit 1
fi

echo "=== Verification completed successfully! ===" 