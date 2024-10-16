#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "Error: $1 is not installed. Please install it and try again."; exit 1; }
}

# Function to check for root privileges
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to sanitize input
sanitize_input() {
    echo "$1" | sed 's/[;&|"]//g'
}

# Check required tools
check_command nmap
check_command nikto
check_command gobuster

# Check for root privileges
check_root

# Parse command line options
VERBOSE=false
INTENSITY="normal"

while getopts ":t:i:vh" opt; do
    case ${opt} in
        t )
            TARGET=$(sanitize_input "$OPTARG")
            ;;
        i )
            INTENSITY=$OPTARG
            ;;
        v )
            VERBOSE=true
            ;;
        h )
            echo "Usage: $0 -t <IP or URL> [-i <intensity>] [-v]"
            echo "  -t: Target IP or URL (required)"
            echo "  -i: Scan intensity (light, normal, aggressive) (default: normal)"
            echo "  -v: Verbose output"
            echo "  -h: Show this help message"
            exit 0
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$TARGET" ]; then
    echo "Error: Target (-t) is required."
    exit 1
fi

# Sanitize TARGET for directory naming
SANITIZED_TARGET=$(echo "$TARGET" | sed 's/[^a-zA-Z0-9]/_/g')
OUTPUT_DIR="scan_results_${SANITIZED_TARGET}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "Starting scan for target: $TARGET"
echo "Intensity: $INTENSITY"
echo "Results will be saved in: $OUTPUT_DIR"
echo "========================================"

# Set scan parameters based on intensity
case $INTENSITY in
    light)
        NMAP_SPEED="-T3"
        GOBUSTER_THREADS=10
        ;;
    normal)
        NMAP_SPEED="-T4"
        GOBUSTER_THREADS=20
        ;;
    aggressive)
        NMAP_SPEED="-T5"
        GOBUSTER_THREADS=50
        ;;
    *)
        echo "Invalid intensity. Using normal."
        NMAP_SPEED="-T4"
        GOBUSTER_THREADS=20
        ;;
esac

# Function to run command with optional verbose output
run_command() {
    if [ "$VERBOSE" = true ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Step 1: Run Nmap for open ports and services
echo "[*] Running Nmap Scan on $TARGET"
run_command nmap -sS -sV -O "$NMAP_SPEED" "$TARGET" -oN "$OUTPUT_DIR/nmap_results.txt"
echo "[*] Nmap Scan completed. Results saved to $OUTPUT_DIR/nmap_results.txt"

# Determine the protocol based on open ports
if grep -q '443/tcp' "$OUTPUT_DIR/nmap_results.txt"; then
    PROTOCOL="https"
elif grep -q '80/tcp' "$OUTPUT_DIR/nmap_results.txt"; then
    PROTOCOL="http"
else
    PROTOCOL="http"  # Default to HTTP if no common web ports found
fi

# Step 2: Run Nikto for web vulnerability scanning (if web service is found)
WEB_PORTS=$(grep -E '80/tcp|443/tcp' "$OUTPUT_DIR/nmap_results.txt")
if [ -n "$WEB_PORTS" ]; then
    echo "[*] Web service detected on ports:"
    echo "$WEB_PORTS"
    
    # Extract hostname without protocol if present
    if [[ "$TARGET" =~ ^https?:// ]]; then
        HOST="${TARGET#http*://}"
    else
        HOST="$TARGET"
    fi
    
    echo "[*] Running Nikto Scan on $PROTOCOL://$HOST"
    run_command nikto -h "$PROTOCOL://$HOST" -output "$OUTPUT_DIR/nikto_results.txt" -no404 -ssl
    echo "[*] Nikto Scan completed. Results saved to $OUTPUT_DIR/nikto_results.txt"
else
    echo "[*] No web service found. Skipping Nikto Scan."
fi

# Step 3: Use Gobuster for directory/file brute-forcing if web service exists
if [ -n "$WEB_PORTS" ]; then
    WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
    
    if [ ! -f "$WORDLIST" ]; then
        echo "Warning: Default wordlist not found. Using a smaller built-in list."
        WORDLIST="$OUTPUT_DIR/temp_wordlist.txt"
        echo -e "index.html\nadmin\nlogin\nwp-admin" > "$WORDLIST"
    fi
    
    echo "[*] Running Gobuster to enumerate directories and files on $PROTOCOL://$HOST"
    run_command gobuster dir -u "$PROTOCOL://$HOST" -w "$WORDLIST" -t "$GOBUSTER_THREADS" -o "$OUTPUT_DIR/gobuster_results.txt" -k
    echo "[*] Gobuster Scan completed. Results saved to $OUTPUT_DIR/gobuster_results.txt"
    
    # Clean up temporary wordlist if created
    [ "$WORDLIST" = "$OUTPUT_DIR/temp_wordlist.txt" ] && rm "$WORDLIST"
fi

# Step 4: Check for common vulnerabilities with Nmap scripts
echo "[*] Running Nmap NSE scripts to detect vulnerabilities on $TARGET"
run_command nmap --script=vuln "$TARGET" -oN "$OUTPUT_DIR/nmap_vuln_scan.txt"
echo "[*] Nmap vulnerability scan completed. Results saved to $OUTPUT_DIR/nmap_vuln_scan.txt"

# Summary of findings
echo "[*] Scanning completed! Check the results in the $OUTPUT_DIR directory."
echo "[!] Remember: Always ensure you have permission before scanning any systems you don't own or manage."