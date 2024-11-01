#!/bin/bash

# Script to Harden a Linux System for CyberPatriot Competition

# Update System and Install Necessary Packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw fail2ban rkhunter clamav unattended-upgrades

echo "wait..."
sleep 2
# 1. User Account Management
# Remove unused/guest accounts and enforce password policies
echo "Removing guest accounts and enforcing password policies..."
sudo deluser --remove-home guest
for user in $(awk -F: '$3 < 1000 {print $1}' /etc/passwd); do
  sudo deluser --remove-home "$user"
done

echo "wait.. "
sleep 2
# Set strong password policies
echo "Setting strong password policies..."
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 10/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

echo "wait...."
sleep 2
# Enforce strong password creation with PAM
sudo sed -i '/pam_cracklib.so/s/retry=3 minlen=8 difok=3//' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=10 difok=3" | sudo tee -a /etc/security/pwquality.conf

echo "wait...."
sleep 2

# 2. Secure SSH
# Restrict SSH to secure settings and disable root login
echo "Securing SSH settings..."
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "wait...."
sleep 2


# 3. Set up Uncomplicated Firewall (UFW)
echo "Setting up UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
ufw logging on
ufw logging high
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

echo "wait...."
sleep 2


# 4. Enable Automatic Updates
echo "Enabling automatic updates..."
sudo dpkg-reconfigure -plow unattended-upgrades
echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
echo "nospoof on" | sudo tee -a /etc/host.conf

echo "wait...."
sleep 2


# 5. Configure Fail2Ban for SSH Protection
echo "Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2

echo "wait...."
sleep 2


echo "Setting file permissions for sensitive files..."
sudo chown root:root /etc/passwd /etc/shadow /etc/gshadow /etc/group
sudo chmod 600 /etc/shadow /etc/gshadow
sudo chmod 644 /etc/passwd /etc/group

echo "wait...."
sleep 2


echo "Disabling unnecessary services..."
for service in cups bluetooth avahi-daemon; do
  sudo systemctl disable "$service" --now
done

echo "wait...."
sleep 2


echo "Enforcing account lockout after failed login attempts..."
echo "auth required pam_tally2.so deny=5 unlock_time=600 onerr=fail audit even_deny_root_account silent" | sudo tee -a /etc/pam.d/common-auth

echo "wait...."
sleep 2


echo "Scheduling rootkit checks..."
echo "0 2 * * * root rkhunter --update && rkhunter --checkall" | sudo tee -a /etc/crontab

echo "wait...."
sleep 2


apt-get install auditd && auditctl -e 1
apt-get remove samba*
## Find music (probably in admin's Music folder)
find /home/ -type f \( -name "*.mp3" -o -name "*.mp4" \)
## Remove any downloaded "hacking tools" packages
find /home/ -type f \( -name "*.tar.gz" -o -name "*.tgz" -o -name "*.zip" -o -name "*.deb" \)

echo "wait...."
sleep 2



### Make sure Firefox is default browser in firefox settings
Disable guest account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf

echo "wait...."
sleep 2


#Check for weird admins
mawk -F: '$1 == "sudo"' /etc/group

echo "wait...."
sleep 2


#Check for weird users
mawk -F: '$3 > 999 && $3 < 65534 {print $1}' /etc/passwd

echo "wait...."
sleep 2


#Check for empty passwords
mawk -F: '$2 == ""' /etc/passwd

echo "wait...."
sleep 2

#Check for non-root UID 0 users
mawk -F: '$3 == 0 && $1 != "root"' /etc/passwd

echo "wait...."
sleep 2

#Remove anything samba-related
apt-get remove .*samba.* .*smb.*

echo "wait...."
sleep 2

echo "Ensure all services are legitimate."

echo "wait...."
sleep 2
######## Note section ################
# service --status-all
# Look for hacking tools, games, and other unwanted/unneccessary packages

# $ apt-cache policy $package
# $ which $package
# $ dpkg-query -l | grep -E '^ii' | less
## $ userdel -r $user
## $ groupdel $user
: ' BAD STUFF
john, nmap, vuze, frostwire, kismet, freeciv, minetest, minetest-server, medusa, hydra, truecrack, ophcrack, nikto, cryptcat, nc, netcat, tightvncserver, x11vnc, nfs, xinetd
POSSIBLY BAD STUFF
samba, postgresql, sftpd, vsftpd, apache, apache2, ftp, mysql, php, snmp, pop3, icmp, sendmail, dovecot, bind9, nginx
MEGA BAD STUFF
telnet, rlogind, rshd, rcmd, rexecd, rbootd, rquotad, rstatd, rusersd, rwalld, rexd, fingerd, tftpd, telnet, snmp, netcat, NC 
Service & Application Hardening


Configure OpenSSH Server in /etc/ssh/sshd_config

Protocol 2
LogLevel VERBOSE
X11Forwarding no
MaxAuthTries 4
IgnoreRhosts yes
HostbasedAuthentication no
PermitRootLogin no
PermitEmptyPasswords no


Configure apache2 in /etc/apache2/apache2.conf
ServerSignature Off
ServerTokens Prod

Cron


Check your users crontabs
crontab -e


Check /etc/cron.*/, /etc/crontab, and /var/spool/cron/crontabs/


Check init files in /etc/init/ and /etc/init.d/


Remove contents of /etc/rc.local
echo "exit 0" > /etc/rc.local


Check user crontabs
crontab -u $user -l


Deny users use of cron jobs
echo "ALL" >> /etc/cron.deny
'

echo " ******** All done Thank you *********"
