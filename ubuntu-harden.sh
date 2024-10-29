#!/bin/bash

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Running Ubuntu Hardening Script......."

wait 3s

# Variables
echo "Creating a backup directory"
LOGFILE="/var/log/security_hardening.log"
BACKUP_DIR="/root/security_backup_$(date +%Y%m%d_%H%M%S)"
UFW_STATUS=$(ufw status | grep -q "active")

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE
}

# Function to handle errors
handle_error() {
    log "ERROR: $1"
    exit 1
}


# Create backup directory
mkdir -p $BACKUP_DIR || handle_error "Failed to create backup directory"


log "Updating and upgrading the system..."
wait 3s
apt-get update && apt-get upgrade -y >> $LOGFILE 2>&1 || handle_error "System update failed"


log "Installing necessary security packages..."
wait 3s
apt-get install -y ufw fail2ban clamav rkhunter aide >> $LOGFILE 2>&1 || handle_error "Package installation failed"

echo "Configureing UFW (Uncomplicated Firewall)........."
if [ "$UFW_STATUS" == "" ]; then
    log "Configuring UFW..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw enable >> $LOGFILE 2>&1 || handle_error "UFW configuration failed"
else
    log "UFW is already active."
fi


log "Enhancing SSH security..."
wait 3s
cp /etc/ssh/sshd_config $BACKUP_DIR/sshd_config.bak
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
echo "Ciphers aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
systemctl restart sshd >> $LOGFILE 2>&1 || handle_error "SSH configuration failed"


log "Setting up Fail2Ban....."
wait 3s
systemctl enable fail2ban
systemctl start fail2ban >> $LOGFILE 2>&1 || handle_error "Fail2Ban setup failed"


log "Updating ClamAV database....."
wait 3s
freshclam >> $LOGFILE 2>&1 || handle_error "ClamAV update failed"


log "Initializing AIDE....."
wait 3s
aideinit >> $LOGFILE 2>&1 || handle_error "AIDE initialization failed"
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db


log "Configuring password policies....."
wait 3s
cp /etc/login.defs $BACKUP_DIR/login.defs.bak
cat <<EOL >> /etc/login.defs
PASS_MAX_DAYS   90
PASS_MIN_DAYS   10
PASS_MIN_LEN    12
EOL

echo "Disable unused services"
wait 3s
read -p "Do you want to disable avahi-daemon? (y/n) " disable_avahi
if [ "$disable_avahi" = "y" ]; then
    log "Disabling avahi-daemon..."
    systemctl disable avahi-daemon >> $LOGFILE 2>&1 || handle_error "Failed to disable avahi-daemon"
fi

read -p "Do you want to disable cups? (y/n) " disable_cups
if [ "$disable_cups" = "y" ]; then
    log "Disabling cups..."
    systemctl disable cups >> $LOGFILE 2>&1 || handle_error "Failed to disable cups"
fi


log "Setting up automatic security updates....."
wait 3s
apt-get install -y unattended-upgrades || handle_error "Failed to install unattended-upgrades"
dpkg-reconfigure --priority=low unattended-upgrades


log "Configuring sysctl for enhanced security......"
wait 3s
cp /etc/sysctl.conf $BACKUP_DIR/sysctl.conf.bak
cat <<EOL >> /etc/sysctl.conf
# Disable IP forwarding
net.ipv4.ip_forward = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
EOL
sysctl -p >> $LOGFILE 2>&1 || handle_error "sysctl configuration failed"

# Run rkhunter and AIDE checks
log "Running rkhunter check..."
wait 3s
rkhunter --check >> $LOGFILE 2>&1 || handle_error "rkhunter check failed"

log "Running AIDE check..."
wait 3s
aide --check >> $LOGFILE 2>&1 || handle_error "AIDE check failed"


log "Creating rollback script....."
wait 3s
cat <<EOL > $BACKUP_DIR/rollback.sh
#!/bin/bash
# Rollback script for Ubuntu Hardening

# Restore SSH config
cp $BACKUP_DIR/sshd_config.bak /etc/ssh/sshd_config
systemctl restart sshd

# Restore login.defs
cp $BACKUP_DIR/login.defs.bak /etc/login.defs

# Restore sysctl.conf
cp $BACKUP_DIR/sysctl.conf.bak /etc/sysctl.conf
sysctl -p

# Disable UFW
ufw disable

# Disable and stop Fail2Ban
systemctl stop fail2ban
systemctl disable fail2ban

echo "Rollback completed. Please review changes and restart services as needed."
EOL
chmod +x $BACKUP_DIR/rollback.sh

# Final message
log "System hardening completed. Backup of original configurations and rollback script stored in $BACKUP_DIR."
wait 1s
log "To rollback changes, run $BACKUP_DIR/rollback.sh as root."
wait 2s
echo "system script's has completed"
echo "Thank you"
