#!/bin/bash

# Set exit status to 1 if a command exits with a non-zero status
set -e

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo >&2 "Error: $1 is not installed. Please install it and try again."
        exit 1
    }
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
    echo "$1" | sed 's/[^a-zA-Z0-9._-]//g'
}

# Function to run a command with optional verbose output
run_command() {
    local cmd="$1"
    local verbose="$2"

    if [ "$verbose" = true ]; then
        eval "$cmd"
    else
        eval "$cmd" >/dev/null 2>&1
    fi
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
TARGET=""

while getopts ":t:i:vh" opt; do
    case ${opt} in
        t)
            TARGET=$(sanitize_input "$OPTARG")
            ;;
        i)
            INTENSITY=$OPTARG
            ;;
        v)
            VERBOSE=true
            ;;
        h)
            echo "Usage: $0 -t <IP or URL> [-i <intensity>] [-v]"
            echo "  -t: Target IP or URL (required)"
            echo "  -i: Scan intensity (light, normal, aggressive) (default: normal)"
            echo "  -v: Verbose output"
            echo "  -h: Show this help message"
            exit 0
            ;;
        \?)
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        :)
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

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