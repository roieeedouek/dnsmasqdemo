#!/bin/bash
#
# add_domain_suffix.sh - Create a copy of hosts with domain suffix
#
# This script reads the hosts file and creates a copy where each hostname
# gets a domain suffix appended (e.g., Alex -> Alex.rafael.local)
#
# Usage:
#   ./add_domain_suffix.sh [hosts_file] [domain_suffix] [output_file]
#   ./add_domain_suffix.sh --watch [hosts_file] [domain_suffix] [output_file]
#

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse arguments
WATCH_MODE=false
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    WATCH_MODE=true
    shift
fi

# Configuration
HOSTS_FILE="${1:-./hosts}"
DOMAIN_SUFFIX="${2:-.rafael.local}"
OUTPUT_FILE="${3:-./hosts.domain}"

# Function to generate domain-suffixed hosts
generate_hosts() {
    local show_output="${1:-true}"

    if [ "$show_output" = "true" ]; then
        echo "=============================================="
        echo "DNS Hosts Domain Suffix Generator"
        echo "=============================================="
        echo ""
        echo "Input file:    $HOSTS_FILE"
        echo "Domain suffix: $DOMAIN_SUFFIX"
        echo "Output file:   $OUTPUT_FILE"
        echo ""
    fi

    # Check if input file exists
    if [ ! -f "$HOSTS_FILE" ]; then
        echo -e "${RED}Error: Input file '$HOSTS_FILE' not found!${NC}"
        return 1
    fi

    # Create output file (start fresh)
    > "$OUTPUT_FILE"

    # Counter for processed entries
    local count=0
    local skipped=0

    if [ "$show_output" = "true" ]; then
        echo "Processing hosts file..."
        echo "----------------------------------------------"
    fi

    # Read the hosts file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$OUTPUT_FILE"
            continue
        fi

        # Check if line contains an IP address (192.168.x.x or 235.x.x.x range)
        if [[ "$line" =~ ^(192\.168|235)\.[0-9]+\.[0-9]+ ]]; then
            # Extract IP and hostname(s)
            local ip=$(echo "$line" | awk '{print $1}')
            local hostnames=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[[:space:]]*//')

            if [ -n "$hostnames" ]; then
                # Process each hostname and add domain suffix
                local new_hostnames=""
                for hostname in $hostnames; do
                    local new_hostname="${hostname}${DOMAIN_SUFFIX}"
                    new_hostnames="$new_hostnames $new_hostname"
                done

                # Write the new entry
                local new_line="$ip$new_hostnames"
                echo "$new_line" >> "$OUTPUT_FILE"

                # Display what was added
                if [ "$show_output" = "true" ]; then
                    echo -e "${GREEN}✓${NC} $ip → $new_hostnames"
                fi
                count=$((count + 1))
            fi
        else
            # Keep other entries as-is (localhost, etc.)
            echo "$line" >> "$OUTPUT_FILE"
            skipped=$((skipped + 1))
        fi
    done < "$HOSTS_FILE"

    if [ "$show_output" = "true" ]; then
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
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Regenerated $OUTPUT_FILE ($count entries processed)"
    fi

    return 0
}

# Function to watch for changes
watch_hosts() {
    echo "=============================================="
    echo "DNS Hosts Domain Suffix Generator - Watch Mode"
    echo "=============================================="
    echo ""
    echo "Input file:    $HOSTS_FILE"
    echo "Domain suffix: $DOMAIN_SUFFIX"
    echo "Output file:   $OUTPUT_FILE"
    echo ""

    # Check if inotify-tools is available
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${YELLOW}Warning: inotifywait not found, falling back to polling mode${NC}"
        echo ""
        watch_hosts_polling
        return
    fi

    # Generate initial version
    echo "Generating initial domain-suffixed hosts file..."
    echo ""
    generate_hosts "true"

    echo ""
    echo "=============================================="
    echo -e "${GREEN}Watching for changes...${NC}"
    echo "Press Ctrl+C to stop"
    echo "=============================================="
    echo ""

    # Watch for changes and regenerate
    while true; do
        # Wait for file modifications
        inotifywait -q -e modify,close_write "$HOSTS_FILE" 2>/dev/null

        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ${BLUE}Change detected in $HOSTS_FILE${NC}"
            generate_hosts "false"
            echo ""
        fi

        # Small delay to avoid multiple rapid triggers
        sleep 1
    done
}

# Polling-based watch (fallback when inotify is not available)
watch_hosts_polling() {
    echo "Using polling mode (checking every 5 seconds)..."
    echo ""

    # Generate initial version
    generate_hosts "true"

    echo ""
    echo "=============================================="
    echo -e "${GREEN}Watching for changes (polling)...${NC}"
    echo "Press Ctrl+C to stop"
    echo "=============================================="
    echo ""

    # Get initial checksum
    local last_checksum=$(md5sum "$HOSTS_FILE" 2>/dev/null | awk '{print $1}')

    while true; do
        sleep 5

        local current_checksum=$(md5sum "$HOSTS_FILE" 2>/dev/null | awk '{print $1}')

        if [ "$current_checksum" != "$last_checksum" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ${BLUE}Change detected in $HOSTS_FILE${NC}"
            generate_hosts "false"
            last_checksum="$current_checksum"
            echo ""
        fi
    done
}

# Main execution
if [ "$WATCH_MODE" = "true" ]; then
    watch_hosts
else
    generate_hosts "true"
    exit 0
fi
