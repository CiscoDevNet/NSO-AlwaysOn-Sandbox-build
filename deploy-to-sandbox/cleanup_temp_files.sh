#!/bin/bash

# =============================================================================
# NSO Project Cleanup Script
# =============================================================================
# This script removes temporary files that were extracted from the NSO signed
# binary but are no longer needed after the workflow is complete.
#
# IMPORTANT: This script preserves *.signed.bin files which contain all the
# other files and should not be deleted.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the project root directory (one level up from deploy-to-sandbox)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_status "Starting cleanup of temporary NSO files..."
print_status "Project root: $PROJECT_ROOT"

# Change to project root directory
cd "$PROJECT_ROOT"

# Define patterns for files to remove (excluding *.signed.bin)
CLEANUP_PATTERNS=(
    "nso*.tar.gz"
    "ncs*.tar.gz"
    "*.tar.gz.signature"
    "README.signature"
    "tailf.cer"
    "cisco_x509_verify_release.py3"
)

# Counter for removed files
removed_count=0
total_size=0

print_status "Scanning for temporary files to remove..."

# Function to safely remove files matching a pattern
cleanup_pattern() {
    local pattern="$1"
    local files_found=false
    
    # Use find to locate files matching the pattern
    while IFS= read -r -d '' file; do
        files_found=true
        # Skip if it's a .signed.bin file
        if [[ "$file" == *.signed.bin ]]; then
            print_warning "Skipping protected file: $(basename "$file")"
            continue
        fi
        
        # Get file size for reporting
        if [[ -f "$file" ]]; then
            file_size=$(stat -f%z "$file" 2>/dev/null || echo "0")
            total_size=$((total_size + file_size))
            
            print_status "Removing: $(basename "$file") ($(numfmt --to=iec "$file_size" 2>/dev/null || echo "$file_size bytes"))"
            rm -f "$file"
            removed_count=$((removed_count + 1))
        fi
    done < <(find . -maxdepth 1 -name "$pattern" -type f -print0 2>/dev/null)
    
    return 0
}

# Process each cleanup pattern
for pattern in "${CLEANUP_PATTERNS[@]}"; do
    print_status "Processing pattern: $pattern"
    cleanup_pattern "$pattern"
done

# Format total size for display
if command -v numfmt >/dev/null 2>&1; then
    formatted_size=$(numfmt --to=iec "$total_size")
else
    formatted_size="$total_size bytes"
fi

# Summary
echo
print_success "Cleanup completed!"
print_success "Files removed: $removed_count"
print_success "Total space freed: $formatted_size"

# List remaining NSO-related files for verification
echo
print_status "Remaining NSO files in project root:"
find . -maxdepth 1 \( -name "nso*" -o -name "ncs*" \) -type f -exec ls -lh {} \; | while read -r line; do
    filename=$(echo "$line" | awk '{print $NF}')
    if [[ "$filename" == *.signed.bin ]]; then
        echo -e "  ${GREEN}✓ PRESERVED:${NC} $line"
    else
        echo -e "  ${YELLOW}? FOUND:${NC} $line"
    fi
done

echo
print_status "Cleanup script completed successfully!"
