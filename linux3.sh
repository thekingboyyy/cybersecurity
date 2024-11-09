#!/bin/bash

# Script to Harden a Linux System for CyberPatriot Competition

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/hardening_script.log
}

# Function to update the system
update_system() {
    log "Updating system and installing necessary packages..."
    if ! sudo apt-get update; then
        log "Failed to update package list. Exiting."
        exit 1
    fi

    if ! sudo apt upgrade -y; then
        log "Failed to upgrade packages. Exiting."
        exit 1
    fi

    if ! sudo apt-get install -y ufw fail2ban rkhunter clamav unattended-upgrades auditd; then
        log "Failed to install essential packages. Exiting."
        exit 1
    fi

    if ! sudo apt-get install -y firefox hardinfo chkrootkit iptables portsentry lynis gufw sysv-rc-conf nessus; then
        log "Failed to install additional packages. Exiting."
        exit 1
    fi

    if ! sudo apt-get install --reinstall -y coreutils; then
        log "Failed to reinstall coreutils. Exiting."
        exit 1
    fi

    log "Waiting for updates to finish..."
    sleep 5 
}

# Function to harden the system
harden_system() {
    # 1. User Account Management
    log "Removing guest accounts and enforcing password policies..."
    if sudo deluser --remove-home guest; then
        log "Removed guest account."
    else
        log "Failed to remove guest account."
    fi

    for user in $(awk -F: '$3 < 1000 {print $1}' /etc/passwd); do
        if [[ "$user" != "root" && "$user" != "nobody" ]]; then
            if sudo deluser --remove-home "$user"; then
                log "Removed user account: $user"
            else
                log "Failed to remove user account: $user"
            fi
        fi
    done

    sleep 5

    log "Setting strong password policies..."
    sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 10/' /etc/login.defs
    sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
    sleep 3

    log "Setting PAM password strength requirements..."
    sudo sed -i '/pam_cracklib.so/s/retry=3 minlen=8 difok=3//' /etc/pam.d/common-password
    echo "password requisite pam_pwquality.so retry=3 minlen=10 difok=3" | sudo tee -a /etc/security/pwquality.conf

    log "Waiting for next step..."
    sleep 5

    # 2. Secure SSH
    log "Securing SSH settings..."
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    log "Waiting for next step..."
    sleep 5

    # 3. Set up Uncomplicated Firewall (UFW)
    log "Setting up UFW..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw logging on
    sudo ufw logging high

    log "Waiting for next step..."
    sleep 5

    # 4. Enable Automatic Updates
    log "Enabling automatic updates..."
    sudo dpkg-reconfigure -plow unattended-upgrades

    log "Waiting for next step..."
    sleep 5

    # 5. Configure Fail2Ban for SSH Protection
    log "Configuring Fail2Ban..."
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    log "Waiting for next step..."
    sleep 5

    # Set file permissions for sensitive files
    log "Setting file permissions for sensitive files..."
    sudo chown root:root /etc/shadow
    sudo chmod 600 /etc/shadow

    log "System hardening completed."
}

# Function to delete media files
delete_media_files() {
    log "Deleting media files..."
    find ~/ -type f -name "*.mp3" -exec rm -f {} \;
    find ~/ -type f -name "*.mp4" -exec rm -f {} \;
    log "Media files deleted."
}

# Function to check security
check_security() {
    log "Checking system security..."
    rkhunter --check
    log "Security check completed."
}

# Main script logic
case "$1" in
    update)
        update_system
        ;;
    harden)
        harden_system
        ;;
    delete)
        delete_media_files
        ;;
    check)
        check_security
        ;;
    *)
        echo "Usage: $0 {update|harden|delete|check}"
        exit 1
        ;;
esac