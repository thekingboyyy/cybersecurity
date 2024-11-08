#!/bin/bash

# Script to Harden a Linux System for CyberPatriot Competition

# Update System and Install Necessary Packages
echo "Updating system and installing necessary packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw fail2ban rkhunter clamav unattended-upgrades auditd

echo "Waiting for updates to finish..."
sleep 2

# 1. User Account Management
# Remove unused/guest accounts and enforce password policies
echo "Removing guest accounts and enforcing password policies..."
sudo deluser --remove-home guest
for user in $(awk -F: '$3 < 1000 {print $1}' /etc/passwd); do
  # Avoid removing system accounts
  if [[ "$user" != "root" && "$user" != "nobody" ]]; then
    sudo deluser --remove-home "$user"
  fi
done

echo "Setting strong password policies..."
# Set strong password policies
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 10/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

echo "Setting PAM password strength requirements..."
# Enforce strong password creation with PAM
sudo sed -i '/pam_cracklib.so/s/retry=3 minlen=8 difok=3//' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=10 difok=3" | sudo tee -a /etc/security/pwquality.conf

echo "Waiting for next step..."
sleep 2

# 2. Secure SSH
echo "Securing SSH settings..."
# Restrict SSH to secure settings and disable root login
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "Waiting for next step..."
sleep 2

# 3. Set up Uncomplicated Firewall (UFW)
echo "Setting up UFW..."
# Set up UFW firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
ufw logging on
ufw logging high

echo "Waiting for next step..."
sleep 2

# 4. Enable Automatic Updates
echo "Enabling automatic updates..."
sudo dpkg-reconfigure -plow unattended-upgrades

# Disable IPv6 only if necessary
# echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

echo "Waiting for next step..."
sleep 2

# 5. Configure Fail2Ban for SSH Protection
echo "Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo "Waiting for next step..."
sleep 2

# Set file permissions for sensitive files
echo "Setting file permissions for sensitive files..."
sudo chown root:root /etc/passwd /etc/shadow /etc/gshadow /etc/group
sudo chmod 600 /etc/shadow /etc/gshadow
sudo chmod 644 /etc/passwd /etc/group

echo "Waiting for next step..."
sleep 2

# 6. Disable Unnecessary Services
echo "Disabling unnecessary services..."
for service in cups bluetooth avahi-daemon; do
  sudo systemctl disable "$service" --now
done

echo "Waiting for next step..."
sleep 2

# 7. Enforce Account Lockout after Failed Login Attempts
echo "Enforcing account lockout after failed login attempts..."
echo "auth required pam_tally2.so deny=5 unlock_time=600 onerr=fail audit even_deny_root_account silent" | sudo tee -a /etc/pam.d/common-auth

echo "Waiting for next step..."
sleep 2

# 8. Schedule Rootkit Checks
echo "Scheduling rootkit checks..."
echo "0 2 * * * root rkhunter --update && rkhunter --checkall" | sudo tee -a /etc/crontab

echo "Waiting for next step..."
sleep 2

# 9. Audit System and Remove Suspicious Packages
echo "Auditing system for suspicious packages..."
# Find and remove any samba-related packages
sudo apt-get remove --purge -y samba* smb*

# Remove potentially dangerous archives from home directories
find /home/ -type f \( -name "*.tar.gz" -o -name "*.tgz" -o -name "*.zip" -o -name "*.deb" \) -exec rm -f {} \;

echo "Waiting for next step..."
sleep 2

# 10. Check and Disable Guest Access
echo "Disabling guest access..."
echo "allow-guest=false" | sudo tee -a /etc/lightdm/lightdm.conf

echo "Waiting for next step..."
sleep 2

# 11. Check for Abnormal Admin or User Accounts
echo "Checking for unusual admin accounts..."
mawk -F: '$1 == "sudo"' /etc/group

echo "Checking for users with UID > 999 (non-system users)..."
mawk -F: '$3 > 999 && $3 < 65534 {print $1}' /etc/passwd

echo "Checking for empty passwords..."
mawk -F: '$2 == ""' /etc/passwd

echo "Checking for non-root UID 0 users..."
mawk -F: '$3 == 0 && $1 != "root"' /etc/passwd

echo "Waiting for next step..."
sleep 2

# 12. Remove Unnecessary Services
echo "Removing unnecessary services..."
sudo apt-get remove --purge -y samba postgresql sftpd vsftpd apache apache2 ftp mysql php snmp pop3 icmp sendmail dovecot bind9 nginx

echo "Waiting for next step..."
sleep 2

# 13. Additional Security Configurations
echo "Ensuring all services are legitimate..."
# service --status-all (manual check)
# Check user crontabs
crontab -e
# Check /etc/cron.*, /etc/crontab, and /var/spool/cron/crontabs/

# Remove contents of /etc/rc.local
echo "exit 0" | sudo tee /etc/rc.local

# Deny users the use of cron jobs
echo "ALL" | sudo tee -a /etc/cron.deny

echo " ******** All done! Thank you ********* "
