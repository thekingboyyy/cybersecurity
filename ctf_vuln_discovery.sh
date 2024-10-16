#!/bin/bash

# Check if an IP/URL is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <IP or URL>"
  exit 1
fi

TARGET=$1
OUTPUT_DIR="scan_results_$TARGET"
mkdir -p $OUTPUT_DIR

# Step 1: Run Nmap for open ports and services
echo "[*] Running Nmap Scan on $TARGET"
nmap -sS -sV -O -T4 $TARGET -oN $OUTPUT_DIR/nmap_results.txt
echo "[*] Nmap Scan completed. Results saved to $OUTPUT_DIR/nmap_results.txt"

# Step 2: Run Nikto for web vulnerability scanning (if web service is found)
WEB_PORTS=$(grep -E '80/tcp|443/tcp' $OUTPUT_DIR/nmap_results.txt)
if [ -n "$WEB_PORTS" ]; then
  echo "[*] Web service detected. Running Nikto Scan on $TARGET"
  nikto -h http://$TARGET -output $OUTPUT_DIR/nikto_results.txt
  echo "[*] Nikto Scan completed. Results saved to $OUTPUT_DIR/nikto_results.txt"
else
  echo "[*] No web service found. Skipping Nikto Scan."
fi

# Step 3: Use Gobuster for directory/file brute-forcing if web service exists
if [ -n "$WEB_PORTS" ]; then
  echo "[*] Running Gobuster to enumerate directories and files on $TARGET"
  gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o $OUTPUT_DIR/gobuster_results.txt
  echo "[*] Gobuster Scan completed. Results saved to $OUTPUT_DIR/gobuster_results.txt"
fi

# Step 4: Check for common vulnerabilities with Nmap scripts
echo "[*] Running Nmap NSE scripts to detect vulnerabilities on $TARGET"
nmap --script=vuln $TARGET -oN $OUTPUT_DIR/nmap_vuln_scan.txt
echo "[*] Nmap vulnerability scan completed. Results saved to $OUTPUT_DIR/nmap_vuln_scan.txt"

# Summary of findings
echo "[*] Scanning completed! Check the results in the $OUTPUT_DIR directory."
