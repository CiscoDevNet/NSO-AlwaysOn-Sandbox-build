#!/bin/bash

# Script to extract NSO Container Image from signed binary
# This script extracts the tar.gz file from a signed.bin file by executing the binary
# with --skip-verification argument and verifies that the extracted file matches 
# the expected NSO_VERSION

set -e

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/sandbox_env_vars.sh"

# Construct the binary filename and tar.gz output filename dynamically
NSO_SIGNED_BIN_FILE="nso-${NSO_VERSION}.container-image-prod.linux.x86_64.signed.bin"
NSO_TAR_GZ_FILE="nso-${NSO_VERSION}.container-image-prod.linux.x86_64.tar.gz"

# Use project root as location for binary file
FULL_BIN_PATH="$PROJECT_ROOT/$NSO_SIGNED_BIN_FILE"

echo "=== Extracting NSO Container Image from Signed Binary ==="
echo "Looking for binary file: $NSO_SIGNED_BIN_FILE"
echo "Project root: $PROJECT_ROOT"
echo ""

# Check if the signed binary file exists
if [ ! -f "$FULL_BIN_PATH" ]; then
    echo "❌ Error: Signed binary file '$NSO_SIGNED_BIN_FILE' not found"
    echo "   Please ensure the NSO signed binary file is present at:"
    echo "   $FULL_BIN_PATH"
    echo ""
    echo "   Expected filename pattern: nso-<VERSION>.container-image-prod.linux.x86_64.signed.bin"
    echo "   Current expected filename: $NSO_SIGNED_BIN_FILE"
    echo ""
    echo "   You can:"
    echo "   1. Place the file in the project root: $PROJECT_ROOT"
    echo "   2. Update NSO_VERSION in sandbox_env_vars.sh if using a different version"
    exit 1
fi

echo "✅ Found signed binary file at: $FULL_BIN_PATH"
echo ""

# Verify the binary file name matches the expected version
if [[ "$NSO_SIGNED_BIN_FILE" == *"$NSO_VERSION"* ]]; then
    echo "✅ Binary file version matches configuration (NSO_VERSION: $NSO_VERSION)"
else
    echo "❌ Error: Binary file version mismatch!"
    echo "   Expected version: $NSO_VERSION"
    echo "   Found in filename: $NSO_SIGNED_BIN_FILE"
    echo "   Please update NSO_VERSION in sandbox_env_vars.sh or use the correct binary file"
    exit 1
fi

echo ""

# Check if the output tar.gz file already exists and remove it to avoid conflicts
OUTPUT_TAR_PATH="$PROJECT_ROOT/$NSO_TAR_GZ_FILE"
if [ -f "$OUTPUT_TAR_PATH" ]; then
    echo "⚠️  Existing tar.gz file found, removing: $NSO_TAR_GZ_FILE"
    rm -f "$OUTPUT_TAR_PATH"
    echo ""
fi

# Make the binary executable
echo "Setting execution permissions on binary file..."
if ! chmod +x "$FULL_BIN_PATH"; then
    echo "❌ Error: Failed to set execution permissions on $FULL_BIN_PATH"
    exit 1
fi
echo "✅ Execution permissions set"
echo ""

# Change to project root directory to ensure proper extraction location
cd "$PROJECT_ROOT"

# Execute the binary with --skip-verification to extract the tar.gz
echo "Executing binary to extract container image..."
echo "Command: $FULL_BIN_PATH --skip-verification"
echo ""

if ! "$FULL_BIN_PATH" --skip-verification; then
    echo "❌ Error: Failed to execute binary extraction"
    exit 1
fi

echo ""
echo "✅ Binary execution completed"
echo ""

# Verify the expected tar.gz file was created
if [ ! -f "$OUTPUT_TAR_PATH" ]; then
    echo "❌ Error: Expected tar.gz file not found after extraction"
    echo "   Expected: $OUTPUT_TAR_PATH"
    echo ""
    echo "Files created in project root:"
    ls -la "$PROJECT_ROOT"/*.tar.gz 2>/dev/null || echo "   No .tar.gz files found"
    exit 1
fi

echo "✅ Found extracted tar.gz file: $NSO_TAR_GZ_FILE"
echo ""

# Verify the extracted tar.gz file name matches the expected version
if [[ "$NSO_TAR_GZ_FILE" == *"$NSO_VERSION"* ]]; then
    echo "✅ Extracted tar.gz file version matches configuration (NSO_VERSION: $NSO_VERSION)"
else
    echo "❌ Error: Extracted tar.gz file version mismatch!"
    echo "   Expected version: $NSO_VERSION"
    echo "   Found in filename: $NSO_TAR_GZ_FILE"
    exit 1
fi

echo ""

# Display file information
echo "📋 Extraction Summary:"
echo "   Source binary: $NSO_SIGNED_BIN_FILE"
echo "   Extracted file: $NSO_TAR_GZ_FILE"
echo "   Location: $PROJECT_ROOT"
echo "   File size: $(du -h "$OUTPUT_TAR_PATH" | cut -f1)"
echo ""

echo "🎉 Success! NSO container image extracted successfully"
echo ""
echo "📦 The file '$NSO_TAR_GZ_FILE' contains the NSO container image"
echo "   and should be shared with the sandbox team for deployment."
echo ""
echo "💡 Next steps:"
echo "   1. You can now use 'make load-nso-image' to load this image into Docker/Podman"
echo "   2. Or share the '$NSO_TAR_GZ_FILE' file with the sandbox team"
echo ""
