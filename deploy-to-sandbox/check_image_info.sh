#!/bin/bash

# Script to check NSO Container Image Information
# This script validates the NSO container image in the project root directory
# and provides guidance on updating the BASE_IMAGE and NSO_VERSION variables
# in sandbox_env_vars.sh before merging changes to the main branch.
#
# Note: This script always looks for the tar.gz file in the project root directory
# to ensure consistency across all developers and avoid configuration confusion.

set -e

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/sandbox_env_vars.sh"

# Construct the container image filename dynamically
NSO_CONTAINER_IMAGE_FILE="nso-${NSO_VERSION}.container-image-prod.linux.x86_64.tar.gz"

# Always look in the project root directory for this validation script
FULL_IMAGE_PATH="$PROJECT_ROOT/$NSO_CONTAINER_IMAGE_FILE"

echo "=== Checking NSO Container Image Information ==="
echo "Looking for file: $NSO_CONTAINER_IMAGE_FILE"
echo "Search path: $PROJECT_ROOT (project root directory)"

# Check if the container image file exists
if [ -f "$FULL_IMAGE_PATH" ]; then
    echo "Found container image file. Extracting repository tags..."
    echo ""
    
    # Extract repository tags from manifest.json
    if REPO_TAG=$(tar -xOf "$FULL_IMAGE_PATH" manifest.json | jq -r '.[].RepoTags[]' 2>/dev/null); then
        if [ -n "$REPO_TAG" ]; then
            echo "Repository Tag found: $REPO_TAG"
            echo ""
            
            # Split the repository tag into name and version
            REPO_NAME="${REPO_TAG%:*}"
            REPO_VERSION="${REPO_TAG#*:}"
            
            echo "Extracted components:"
            echo "  Repository name: $REPO_NAME"
            echo "  Repository version: $REPO_VERSION"
            echo ""
            echo "Current configuration in sandbox_env_vars.sh:"
            echo "  BASE_IMAGE: $BASE_IMAGE"
            echo "  NSO_VERSION: $NSO_VERSION"
            echo ""
            
            # Check if both components match
            BASE_IMAGE_MATCH=false
            NSO_VERSION_MATCH=false
            
            if [ "$BASE_IMAGE" = "$REPO_NAME" ]; then
                echo "✅ BASE_IMAGE matches the repository name"
                BASE_IMAGE_MATCH=true
            else
                echo "⚠️  BASE_IMAGE does not match the repository name"
                echo "   Expected: BASE_IMAGE=$REPO_NAME"
                echo "   Current:  BASE_IMAGE=$BASE_IMAGE"
            fi
            
            if [ "$NSO_VERSION" = "$REPO_VERSION" ]; then
                echo "✅ NSO_VERSION matches the repository version"
                NSO_VERSION_MATCH=true
            else
                echo "⚠️  NSO_VERSION does not match the repository version"
                echo "   Expected: NSO_VERSION=$REPO_VERSION"
                echo "   Current:  NSO_VERSION=$NSO_VERSION"
            fi
            
            echo ""
            if [ "$BASE_IMAGE_MATCH" = true ] && [ "$NSO_VERSION_MATCH" = true ]; then
                echo "🎉 All variables are correctly configured!"
            else
                echo "📝 Suggested updates for sandbox_env_vars.sh:"
                if [ "$BASE_IMAGE_MATCH" = false ]; then
                    echo "   BASE_IMAGE=$REPO_NAME"
                fi
                if [ "$NSO_VERSION_MATCH" = false ]; then
                    echo "   NSO_VERSION=$REPO_VERSION"
                fi
                echo ""
                echo "   Consider updating these before merging to main branch."
            fi
        else
            echo "❌ Error: No repository tags found in manifest.json"
            exit 1
        fi
    else
        echo "❌ Error: Failed to extract repository tags from manifest.json"
        echo "   Make sure jq is installed and the tar.gz file contains a valid manifest.json"
        echo ""
        echo "   To install jq:"
        echo "   - Ubuntu/Debian: sudo apt-get install jq"
        echo "   - CentOS/RHEL: sudo yum install jq"
        echo "   - macOS: brew install jq"
        exit 1
    fi
else
    echo "❌ Error: Container image file '$NSO_CONTAINER_IMAGE_FILE' not found"
    echo "   Please place the NSO container image file in the project root directory:"
    echo "   $PROJECT_ROOT"
    echo ""
    echo "   Expected filename: $NSO_CONTAINER_IMAGE_FILE"
    echo ""
    echo "   This validation script always looks in the project root directory to ensure"
    echo "   consistency for all developers. Please place the tar.gz file there and run again."
    exit 1
fi

echo "=== Image check completed ==="
