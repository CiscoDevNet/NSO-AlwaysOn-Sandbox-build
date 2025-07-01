#!/bin/bash

# Script to load NSO Container Image into Docker
# This script loads the NSO container image from a tar.gz file and verifies 
# that the loaded image matches the expected BASE_IMAGE and NSO_VERSION
# 
# Search order for the container image file:
# 1. Project root directory
# 2. NSO_CONTAINER_IMAGE_PATH (if set in sandbox_env_vars.sh)
# 3. Home directory (default fallback)
#
# Note: This script handles differences between Docker and Podman image naming:
# - Docker: uses short names (e.g., cisco-nso-prod)
# - Podman: expands to full registry paths (e.g., docker.io/library/cisco-nso-prod)

set -e

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/sandbox_env_vars.sh"

# Construct the container image filename dynamically
NSO_CONTAINER_IMAGE_FILE="nso-${NSO_VERSION}.container-image-prod.linux.x86_64.tar.gz"

# Search for the container image file in order of preference:
# 1. Project root directory (highest priority)
# 2. NSO_CONTAINER_IMAGE_PATH (if set)
# 3. Home directory (fallback)

SEARCH_PATH=""
FULL_IMAGE_PATH=""

# First, check in project root directory
if [ -f "$PROJECT_ROOT/$NSO_CONTAINER_IMAGE_FILE" ]; then
    SEARCH_PATH="$PROJECT_ROOT"
    FULL_IMAGE_PATH="$PROJECT_ROOT/$NSO_CONTAINER_IMAGE_FILE"
# Second, check NSO_CONTAINER_IMAGE_PATH if it's set and different from HOME
elif [ -n "$NSO_CONTAINER_IMAGE_PATH" ] && [ "$NSO_CONTAINER_IMAGE_PATH" != "~" ]; then
    SEARCH_PATH_EXPANDED=$(eval echo "$NSO_CONTAINER_IMAGE_PATH")
    if [ -f "$SEARCH_PATH_EXPANDED/$NSO_CONTAINER_IMAGE_FILE" ]; then
        SEARCH_PATH="$NSO_CONTAINER_IMAGE_PATH"
        FULL_IMAGE_PATH="$SEARCH_PATH_EXPANDED/$NSO_CONTAINER_IMAGE_FILE"
    fi
fi

# Finally, fallback to HOME directory if not found yet
if [ -z "$FULL_IMAGE_PATH" ]; then
    SEARCH_PATH="${NSO_CONTAINER_IMAGE_PATH:-$HOME}"
    SEARCH_PATH_EXPANDED=$(eval echo "$SEARCH_PATH")
    FULL_IMAGE_PATH="$SEARCH_PATH_EXPANDED/$NSO_CONTAINER_IMAGE_FILE"
fi

echo "=== Loading NSO Container Image ==="
echo "Looking for file: $NSO_CONTAINER_IMAGE_FILE"
if [ "$SEARCH_PATH" = "$PROJECT_ROOT" ]; then
    echo "Found in project root: $SEARCH_PATH"
else
    SEARCH_PATH_DISPLAY=$(eval echo "$SEARCH_PATH")
    echo "Search path: $SEARCH_PATH_DISPLAY"
fi
echo ""

# Check if the container image file exists
if [ ! -f "$FULL_IMAGE_PATH" ]; then
    echo "❌ Error: Container image file '$NSO_CONTAINER_IMAGE_FILE' not found"
    echo "   Searched in the following locations:"
    echo "   1. Project root: $PROJECT_ROOT/$NSO_CONTAINER_IMAGE_FILE"
    if [ -n "$NSO_CONTAINER_IMAGE_PATH" ] && [ "$NSO_CONTAINER_IMAGE_PATH" != "~" ]; then
        SEARCH_PATH_EXPANDED=$(eval echo "$NSO_CONTAINER_IMAGE_PATH")
        echo "   2. NSO_CONTAINER_IMAGE_PATH: $SEARCH_PATH_EXPANDED/$NSO_CONTAINER_IMAGE_FILE"
    fi
    HOME_EXPANDED=$(eval echo "$HOME")
    echo "   3. Home directory: $HOME_EXPANDED/$NSO_CONTAINER_IMAGE_FILE"
    echo ""
    echo "   Expected filename pattern: nso-<VERSION>.container-image-prod.linux.x86_64.tar.gz"
    echo "   Current expected filename: $NSO_CONTAINER_IMAGE_FILE"
    echo ""
    echo "   You can:"
    echo "   1. Place the file in the project root directory: $PROJECT_ROOT"
    echo "   2. Update NSO_CONTAINER_IMAGE_PATH in sandbox_env_vars.sh to point to the correct directory"
    echo "   3. Update NSO_VERSION in sandbox_env_vars.sh if using a different version"
    exit 1
fi

echo "✅ Found container image file at: $FULL_IMAGE_PATH"
echo ""

# Detect container engine (docker or podman)
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman 2>/dev/null)
if [ -z "$CONTAINER_ENGINE" ]; then
    echo "❌ Error: Neither Docker nor Podman is installed or in PATH"
    exit 1
fi
CONTAINER_ENGINE_NAME=$(basename "$CONTAINER_ENGINE")

echo "Using container engine: $CONTAINER_ENGINE_NAME"
echo ""

# Load the image
echo "Loading image into $CONTAINER_ENGINE_NAME..."
if ! LOAD_OUTPUT=$("$CONTAINER_ENGINE" load -i "$FULL_IMAGE_PATH" 2>&1); then
    echo "❌ Error: Failed to load image"
    echo "$LOAD_OUTPUT"
    exit 1
fi

echo "✅ Image loaded successfully"
echo "$LOAD_OUTPUT"
echo ""

# Extract the loaded image name from the output
# Docker load output format: "Loaded image: <image_name:tag>"
LOADED_IMAGE=$(echo "$LOAD_OUTPUT" | grep -o "Loaded image: .*" | sed 's/Loaded image: //' || true)

if [ -z "$LOADED_IMAGE" ]; then
    echo "⚠️  Warning: Could not extract loaded image name from output"
    echo "   Attempting to verify using expected image name..."
    EXPECTED_IMAGE_TAG="${BASE_IMAGE}:${NSO_VERSION}"
    
    # Check if the expected image exists (try both Docker and Podman formats)
    if "$CONTAINER_ENGINE" images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${EXPECTED_IMAGE_TAG}$"; then
        LOADED_IMAGE="$EXPECTED_IMAGE_TAG"
        echo "✅ Found expected image: $LOADED_IMAGE"
    elif "$CONTAINER_ENGINE" images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^docker\.io/library/${EXPECTED_IMAGE_TAG}$"; then
        LOADED_IMAGE="docker.io/library/${EXPECTED_IMAGE_TAG}"
        echo "✅ Found expected image: $LOADED_IMAGE"
    else
        echo "❌ Error: Expected image not found in local images"
        echo "   Expected: $EXPECTED_IMAGE_TAG"
        echo "   Or: docker.io/library/$EXPECTED_IMAGE_TAG (Podman format)"
        echo ""
        echo "Available images:"
        "$CONTAINER_ENGINE" images --format "table {{.Repository}}:{{.Tag}}"
        exit 1
    fi
else
    echo "Loaded image: $LOADED_IMAGE"
fi

echo ""

# Parse the loaded image components
LOADED_REPO="${LOADED_IMAGE%:*}"
LOADED_VERSION="${LOADED_IMAGE#*:}"

# Expected values from configuration
EXPECTED_REPO="$BASE_IMAGE"
EXPECTED_VERSION="$NSO_VERSION"

# Normalize repository names for comparison (handle Docker vs Podman differences)
# Podman expands unqualified names to docker.io/library/<name>, Docker keeps them short
normalize_repo_name() {
    local repo="$1"
    # Remove docker.io/library/ prefix if present (Podman format)
    echo "$repo" | sed 's|^docker\.io/library/||'
}

NORMALIZED_LOADED_REPO=$(normalize_repo_name "$LOADED_REPO")
NORMALIZED_EXPECTED_REPO=$(normalize_repo_name "$EXPECTED_REPO")

echo "Verifying image matches configuration..."
echo "Current configuration from sandbox_env_vars.sh:"
echo "  BASE_IMAGE: $EXPECTED_REPO"
echo "  NSO_VERSION: $EXPECTED_VERSION"
echo ""
echo "Loaded image components:"
echo "  Repository: $LOADED_REPO"
echo "  Version: $LOADED_VERSION"
if [ "$LOADED_REPO" != "$NORMALIZED_LOADED_REPO" ]; then
    echo "  Normalized Repository: $NORMALIZED_LOADED_REPO (for comparison)"
fi
echo ""

# Verify repository name matches (using normalized names for Docker/Podman compatibility)
REPO_MATCH=false
VERSION_MATCH=false

if [ "$NORMALIZED_LOADED_REPO" = "$NORMALIZED_EXPECTED_REPO" ]; then
    echo "✅ Repository name matches (expected: $EXPECTED_REPO)"
    REPO_MATCH=true
else
    echo "❌ Repository name mismatch!"
    echo "   Expected: $EXPECTED_REPO"
    echo "   Found:    $LOADED_REPO"
    if [ "$LOADED_REPO" != "$NORMALIZED_LOADED_REPO" ]; then
        echo "   Normalized: $NORMALIZED_LOADED_REPO"
    fi
fi

# Verify version matches
if [ "$LOADED_VERSION" = "$EXPECTED_VERSION" ]; then
    echo "✅ Version matches (expected: $EXPECTED_VERSION)"
    VERSION_MATCH=true
else
    echo "❌ Version mismatch!"
    echo "   Expected: $EXPECTED_VERSION"
    echo "   Found:    $LOADED_VERSION"
fi

echo ""

# Final validation
if [ "$REPO_MATCH" = true ] && [ "$VERSION_MATCH" = true ]; then
    echo "🎉 Success! NSO container image loaded and verified successfully"
    echo "   Image: $LOADED_IMAGE"
    echo "   The loaded image matches your configuration in sandbox_env_vars.sh"
    echo ""
    echo "You can now proceed with building and deploying your NSO sandbox."
    exit 0
else
    echo "❌ Error: Image verification failed!"
    echo ""
    echo "The loaded image does not match your current configuration."
    echo "Please either:"
    echo "1. Update sandbox_env_vars.sh to match the loaded image:"
    if [ "$REPO_MATCH" = false ]; then
        echo "   BASE_IMAGE=$LOADED_REPO"
    fi
    if [ "$VERSION_MATCH" = false ]; then
        echo "   NSO_VERSION=$LOADED_VERSION"
    fi
    echo "2. Or obtain the correct NSO container image file that matches your configuration"
    echo ""
    exit 1
fi
