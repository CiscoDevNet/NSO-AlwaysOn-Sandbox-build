#!/bin/bash

# TACACS Environment Validation Script
# This script validates that all required TACACS environment variables are properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "TACACS Environment Validation"
echo -e "==============================================${NC}"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}ERROR: .env file not found in project root${NC}"
    echo -e "${YELLOW}Please create a .env file with required TACACS variables${NC}"
    exit 1
fi

echo -e "${GREEN}✓ .env file found${NC}"

# Source the .env file
source .env

# Validation flags
validation_passed=true

# Check required variables
echo ""
echo "Checking required environment variables..."

if [ -z "$TACACS_SERVER_HOST" ]; then
    echo -e "${RED}✗ TACACS_SERVER_HOST is not set${NC}"
    validation_passed=false
else
    echo -e "${GREEN}✓ TACACS_SERVER_HOST: $TACACS_SERVER_HOST${NC}"
fi

if [ -z "$TACACS_SERVER_SECRET" ]; then
    echo -e "${RED}✗ TACACS_SERVER_SECRET is not set${NC}"
    validation_passed=false
else
    echo -e "${GREEN}✓ TACACS_SERVER_SECRET: [REDACTED]${NC}"
fi

# Check optional variables
echo ""
echo "Checking optional environment variables..."

if [ -z "$TACACS_SERVER_PORT" ]; then
    echo -e "${YELLOW}⚠ TACACS_SERVER_PORT not set (will default to 49)${NC}"
else
    echo -e "${GREEN}✓ TACACS_SERVER_PORT: $TACACS_SERVER_PORT${NC}"
fi

# Check if template XML exists
echo ""
echo "Checking template configuration..."

if [ ! -f "config/phase0/cisco-nso-tacacs-auth.xml" ]; then
    echo -e "${RED}✗ TACACS template XML not found${NC}"
    validation_passed=false
else
    echo -e "${GREEN}✓ TACACS template XML found${NC}"
fi

# Check if inject script exists and is executable
if [ ! -f "scripts/inject_tacacs_env.sh" ]; then
    echo -e "${RED}✗ TACACS injection script not found${NC}"
    validation_passed=false
elif [ ! -x "scripts/inject_tacacs_env.sh" ]; then
    echo -e "${YELLOW}⚠ TACACS injection script not executable${NC}"
    chmod +x scripts/inject_tacacs_env.sh
    echo -e "${GREEN}✓ Made injection script executable${NC}"
else
    echo -e "${GREEN}✓ TACACS injection script ready${NC}"
fi

echo ""
echo -e "${BLUE}=============================================="

if [ "$validation_passed" = true ]; then
    echo -e "${GREEN}✓ All TACACS requirements validated successfully!${NC}"
    echo -e "${GREEN}✓ Ready to build with TACACS authentication${NC}"
    exit 0
else
    echo -e "${RED}✗ TACACS validation failed${NC}"
    echo -e "${YELLOW}Please fix the issues above before building${NC}"
    exit 1
fi
