#!/bin/bash

# Script to Harden a Linux System for CyberPatriot Competition with a UI
# !! make sure to install zenity before running the script with sudo apt-get install zenity

# Logging function
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a /var/log/hardening_script.log
}

# Function to show a message box
show_message() {
    zenity --info --text="$1" --title="Hardening Script" --width=300
}

# Function to confirm actions
confirm_action() {
    zenity --question --text="$1" --title="Confirm" --width=300
    return $?
}

# Start of the script
show_message "Welcome to the Linux Hardening Script!"

# Update System and Install Necessary Packages
if confirm_action "Do you want to update the system and install necessary packages?"; then
    log "Updating system and installing necessary packages..."
    if ! sudo apt-get update; then
        log "Failed to update package list."
        show_message "Failed to update package list. Check log for details."
        exit 1
    fi

    if ! sudo apt upgrade -y; then
        log "Failed to upgrade packages."
        show_message "Failed to upgrade packages. Check log for details."
        exit 1
    fi

    if ! sudo apt-get install -y ufw fail2ban rkhunter clamav unattended-upgrades auditd; then
        log "Failed to install essential packages."
        show_message "Failed to install essential packages. Check log for details."
        exit 1
    fi

    show_message "Packages installed successfully."
else
    log "User  canceled package installation."
fi

# Example of another action
if confirm_action "Do you want to secure SSH settings?"; then
    log "Securing SSH settings..."
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    show_message "SSH settings secured."
else
    log "User  canceled SSH security."
fi

# Additional steps can be added similarly...

show_message "Hardening script completed. Check log for details."