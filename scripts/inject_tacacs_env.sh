#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SOURCE_XML="/tmp/config/phase0/cisco-nso-tacacs-auth.xml"
TARGET_XML="/tmp/config/phase0/cisco-nso-tacacs-auth-runtime.xml"

echo "=============================================="
echo "TACACS Configuration Environment Injection"
echo "=============================================="

# Check if required environment variables are set
if [ -z "$TACACS_SERVER_HOST" ]; then
    echo -e "${RED}ERROR: TACACS_SERVER_HOST environment variable is not set${NC}"
    echo -e "${YELLOW}Please ensure TACACS_SERVER_HOST is defined in your .env file${NC}"
    exit 1
fi

if [ -z "$TACACS_SERVER_SECRET" ]; then
    echo -e "${RED}ERROR: TACACS_SERVER_SECRET environment variable is not set${NC}"
    echo -e "${YELLOW}Please ensure TACACS_SERVER_SECRET is defined in your .env file${NC}"
    exit 1
fi

# Optional: Check if TACACS_SERVER_PORT is set, use default if not
if [ -z "$TACACS_SERVER_PORT" ]; then
    echo -e "${YELLOW}WARNING: TACACS_SERVER_PORT not set, using default port 49${NC}"
    TACACS_SERVER_PORT=49
fi

echo "Injecting TACACS environment variables into XML configuration..."
echo "  Host: $TACACS_SERVER_HOST"
echo "  Port: $TACACS_SERVER_PORT"
echo "  Secret: [REDACTED]"

# Create the runtime XML file with environment variables replaced
sed -e "s/\${TACACS_SERVER_HOST}/$TACACS_SERVER_HOST/g" \
    -e "s/\${TACACS_SERVER_PORT}/$TACACS_SERVER_PORT/g" \
    -e "s/\${TACACS_SERVER_SECRET}/$TACACS_SERVER_SECRET/g" \
    "$SOURCE_XML" > "$TARGET_XML"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ TACACS configuration successfully created at $TARGET_XML${NC}"
else
    echo -e "${RED}✗ Failed to create TACACS configuration${NC}"
    exit 1
fi

echo "=============================================="
