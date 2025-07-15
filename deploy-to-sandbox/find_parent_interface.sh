#!/bin/bash
# Script to find the interface name for a given IP and update .env with PARENT_INTERFACE

set -e

# Color and emoji definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

EMOJI_FIND='🔍'
EMOJI_OK='✅'
EMOJI_ERROR='❌'
EMOJI_FILE='📄'
EMOJI_UPDATE='✏️'
EMOJI_ADD='➕'
EMOJI_DONE='🏁'

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
source "$PROJECT_ROOT/sandbox_env_vars.sh"

# IP to search for
TARGET_IP="${SANDBOX_IP}"

if [ -z "$TARGET_IP" ]; then
    echo -e "${RED}${EMOJI_ERROR} [ERROR] No IP specified to search for. Please set in sandbox_env_vars.sh.${NC}"
    exit 1
fi

# Find interface name
echo -e "${BLUE}${EMOJI_FIND} [INFO] Searching for interface with IP $TARGET_IP ...${NC}"
INTERFACE=$(ip -o addr show | awk -v ip="$TARGET_IP" '$0 ~ ip {print $2}' | head -n1)

if [ -z "$INTERFACE" ]; then
    echo -e "${RED}${EMOJI_ERROR} [ERROR] No interface found with IP $TARGET_IP.${NC}"
    exit 1
else
    echo -e "${GREEN}${EMOJI_OK} [INFO] Interface found: $INTERFACE${NC}"
fi

ENV_FILE="$PROJECT_ROOT/.env"

# Ensure .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}${EMOJI_FILE} [INFO] .env file not found. Creating new .env file.${NC}"
    touch "$ENV_FILE"
fi

# Add PARENT_INTERFACE to .env with newlines before and after
TMP_ENV=$(mktemp)

# Add newline before
echo >> "$TMP_ENV"

# Add or update PARENT_INTERFACE
if grep -q '^PARENT_INTERFACE=' "$ENV_FILE"; then
    # Update existing
    echo -e "${YELLOW}${EMOJI_UPDATE} [INFO] Updating PARENT_INTERFACE in .env file.${NC}"
    sed "s|^PARENT_INTERFACE=.*$|PARENT_INTERFACE=$INTERFACE|" "$ENV_FILE" >> "$TMP_ENV"
else
    # Copy existing and append
    echo -e "${YELLOW}${EMOJI_ADD} [INFO] Adding PARENT_INTERFACE to .env file.${NC}"
    cat "$ENV_FILE" >> "$TMP_ENV"
    echo "PARENT_INTERFACE=$INTERFACE" >> "$TMP_ENV"
fi

# Add newline after
echo >> "$TMP_ENV"

mv -f "$TMP_ENV" "$ENV_FILE"

echo -e "${GREEN}${EMOJI_DONE} [INFO] PARENT_INTERFACE set to '$INTERFACE' in .env file.${NC}"
