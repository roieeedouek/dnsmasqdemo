#!/bin/bash
#
# add_domain_suffix.sh - Create a copy of hosts with domain suffix
#
# This script reads the hosts file and creates a copy where each hostname
# gets a domain suffix appended (e.g., Alex -> Alex.rafael.local)
#

set -e

# Configuration
HOSTS_FILE="${1:-./hosts}"
DOMAIN_SUFFIX="${2:-.rafael.local}"
OUTPUT_FILE="${3:-./hosts.domain}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "DNS Hosts Domain Suffix Generator"
echo "=============================================="
echo ""
echo "Input file:    $HOSTS_FILE"
echo "Domain suffix: $DOMAIN_SUFFIX"
echo "Output file:   $OUTPUT_FILE"
echo ""

# Check if input file exists
if [ ! -f "$HOSTS_FILE" ]; then
    echo "Error: Input file '$HOSTS_FILE' not found!"
    exit 1
fi

# Create output file (start fresh)
> "$OUTPUT_FILE"

# Counter for processed entries
count=0
skipped=0

echo "Processing hosts file..."
echo "----------------------------------------------"

# Read the hosts file line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        echo "$line" >> "$OUTPUT_FILE"
        continue
    fi

    # Check if line contains an IP address (192.168.x.x range)
    if [[ "$line" =~ ^192\.168\.[0-9]+\.[0-9]+ ]]; then
        # Extract IP and hostname(s)
        ip=$(echo "$line" | awk '{print $1}')
        hostnames=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[[:space:]]*//')

        if [ -n "$hostnames" ]; then
            # Process each hostname and add domain suffix
            new_hostnames=""
            for hostname in $hostnames; do
                new_hostname="${hostname}${DOMAIN_SUFFIX}"
                new_hostnames="$new_hostnames $new_hostname"
            done

            # Write the new entry
            new_line="$ip$new_hostnames"
            echo "$new_line" >> "$OUTPUT_FILE"

            # Display what was added
            echo -e "${GREEN}✓${NC} $ip → $new_hostnames"
            count=$((count + 1))
        fi
    else
        # Keep other entries as-is (localhost, etc.)
        echo "$line" >> "$OUTPUT_FILE"
        skipped=$((skipped + 1))
    fi
done < "$HOSTS_FILE"

echo "----------------------------------------------"
echo ""
echo "Summary:"
echo "  ${GREEN}✓${NC} Processed entries:  $count"
echo "  ${YELLOW}○${NC} Skipped entries:   $skipped"
echo ""
echo "Output written to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""
echo "=============================================="

# Display the output file
echo ""
echo "Generated hosts file with domain suffix:"
echo "----------------------------------------------"
cat "$OUTPUT_FILE"
echo "----------------------------------------------"
echo ""

exit 0
