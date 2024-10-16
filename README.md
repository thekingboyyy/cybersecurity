WebHacker
A Python script for web hacking and penetration testing

Description
WebHacker is a Python script designed to help you perform various web hacking tasks, such as web scanning, SQL injection, cross-site scripting, directory brute force, and password cracking. This script is intended for educational purposes only and should not be used to hack websites without permission.

Features
Web scanning: scans a target website for vulnerabilities
SQL injection: attempts to inject SQL code into a vulnerable website
Cross-site scripting: injects malicious JavaScript code into a vulnerable website
Directory brute force: attempts to brute-force a website's directory structure
Password cracking: attempts to crack a website's password using a dictionary attack
Usage
Clone this repository: git clone https://github.com/thekingboyyy/cybersecurity.git
Install the required dependencies: pip install requests
Run the script: python webhacker.py
Choose an option from the menu to perform a web hacking task
Note
This script is for educational purposes only and should not be used to hack websites without permission. Additionally, this script is not exhaustive and there are many more web hacking techniques that can be used.

______________________________________________________________________________________________________________________________________________________________________
How it Works:
Nmap Scan: It performs a service and OS detection scan to find open ports and running services on the target.
Nikto Scan: If a web service is detected on ports 80 or 443, it runs nikto, a web vulnerability scanner, to look for web-based issues such as outdated software and known vulnerabilities.
Gobuster: If a web server is found, it also brute-forces directories and files using gobuster to find hidden files or directories that could be exploited.
Nmap Vulnerability Scan: It runs nmap's NSE vulnerability scripts to identify known vulnerabilities in services.
Requirements:
nmap: for network discovery and vulnerability scanning.
nikto: to scan for web application vulnerabilities.
gobuster: for directory and file enumeration on web servers.
To Install These Tools:
On Kali Linux or other pentesting distributions, you can install them using:
bash

sudo apt-get install nmap nikto gobuster
How to Run:

chmod +x ctf_vuln_discovery.sh
./ctf_vuln_discovery.sh <TARGET_IP_OR_URL>
Example:
bash

./ctf_vuln_discovery.sh 192.168.1.100
This script should help automate the initial discovery phase during CTF competitions by quickly identifying services, web vulnerabilities, hidden directories, and known exploits.


License
these scripts are licensed under the MIT License. See the LICENSE file for more information.

Contributing
Contributions are welcome! If you'd like to contribute to this script, please open an issue or submit a pull request.
