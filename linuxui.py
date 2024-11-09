#!/usr/bin/env python3

import tkinter as tk
from tkinter import messagebox, ttk, scrolledtext
import subprocess
import os
import threading
import logging
from datetime import datetime

class LinuxUtilityApp:
    def __init__(self, master):
        # Setup logging
        logging.basicConfig(
            filename='/var/log/linux_utility.log', 
            level=logging.INFO, 
            format='%(asctime)s - %(levelname)s - %(message)s'
        )

        self.master = master
        master.title("Linux Security Utility")
        master.geometry("700x600")

        # Create main frame
        self.frame = tk.Frame(master)
        self.frame.pack(pady=10, padx=10, fill=tk.BOTH, expand=True)

        # Title
        self.label = tk.Label(
            self.frame, 
            text="Linux Security Utility", 
            font=("Helvetica", 16, "bold")
        )
        self.label.pack(pady=10)

        # Output Text Area
        self.output_text = scrolledtext.ScrolledText(
            self.frame, 
            wrap=tk.WORD, 
            height=20, 
            width=80
        )
        self.output_text.pack(pady=10)

        # Progress Bar
        self.progress = ttk.Progressbar(
            self.frame, 
            orient="horizontal", 
            length=300, 
            mode="indeterminate"
        )
        self.progress.pack(pady=10)

        # Button Frame
        self.button_frame = tk.Frame(self.frame)
        self.button_frame.pack(pady=10)

        # Buttons
        buttons = [
            ("Update System", self.update_system),
            ("Harden System", self.harden_system),
            ("Check Security", self.security_check),
            ("Delete Media Files", self.delete_media_files)
        ]

        for (text, command) in buttons:
            btn = tk.Button(
                self.button_frame, 
                text=text, 
                command=command, 
                width=20
            )
            btn.pack(pady=5)

    def run_command(self, func):
        # Clear previous output
        self.output_text.delete(1.0, tk.END)
        
        # Start progress bar
        self.progress.start()
        
        try:
            # Redirect output to both GUI and log
            def log_and_display(message):
                self.output_text.insert(tk.END, message + "\n")
                self.output_text.see(tk.END)
                logging.info(message)
                self.master.update_idletasks()

            # Run the specific function
            func(log_and_display)

            # Final success message
            self.output_text.insert(tk.END, "\nCommand completed successfully!")
        except Exception as e:
            error_msg = f"An error occurred: {str(e)}"
            self.output_text.insert(tk.END, error_msg)
            logging.error(error_msg)
        finally:
            # Stop progress bar
            self.progress.stop()

    def update_system(self):
        def update_func(log_func):
            # Ensure script is run with sudo
            if os.geteuid() != 0:
                raise PermissionError("This function requires sudo privileges")

            # Update package lists
            log_func("Updating package lists...")
            subprocess.run(['apt-get', 'update'], check=True)
            
            # Upgrade packages
            log_func("Upgrading packages...")
            subprocess.run(['apt-get', 'upgrade', '-y'], check=True)
            
            # Install essential security tools
            log_func("Installing security tools...")
            tools = [
                'ufw', 'fail2ban', 'rkhunter', 'clamav', 
                'chkrootkit', 'lynis', 'unattended-upgrades'
            ]
            subprocess.run(['apt-get', 'install', '-y'] + tools, check=True)
            
            log_func("System update completed successfully.")

        threading.Thread(target=self.run_command, args=(update_func,), daemon=True).start()

    def harden_system(self):
        def harden_func(log_func):
            # Ensure script is run with sudo
            if os.geteuid() != 0:
                raise PermissionError("This function requires sudo privileges")

            # Disable unnecessary services
            log_func("Disabling unnecessary services...")
            subprocess.run(['systemctl', 'disable', 'cups'], check=True)
            subprocess.run(['systemctl', 'disable', 'bluetooth'], check=True)
            
            # Secure SSH
            log_func("Securing SSH...")
            with open('/etc/ssh/sshd_config', 'r') as f:
                sshd_config = f.read()
            
            sshd_config = sshd_config.replace(
                '#PermitRootLogin yes', 
                'PermitRootLogin no'
            )
            sshd_config = sshd_config.replace(
                '#PasswordAuthentication yes', 
                'PasswordAuthentication no'
            )
            
            with open('/etc/ssh/sshd_config', 'w') as f:
                f.write(sshd_config)
            
            subprocess.run(['systemctl', 'restart', 'sshd'], check=True)
            
            # Configure UFW
            log_func("Configuring Firewall...")
            subprocess.run(['ufw', 'default', 'deny', 'incoming'], check=True)
            subprocess.run(['ufw', 'default', 'allow', 'outgoing'], check=True)
            subprocess.run(['ufw', 'allow', 'ssh'], check=True)
            subprocess.run(['ufw', 'enable'], check=True)
            
            # Set password policies
            log_func("Setting password policies...")
            with open('/etc/login.defs', 'r') as f:
                login_defs = f.read()
            
            login_defs = login_defs.replace(
                'PASS_MAX_DAYS\t99999', 
                'PASS_MAX_DAYS\t90'
            )
            login_defs = login_defs.replace(
                'PASS_MIN_DAYS\t0', 
                'PASS_MIN_DAYS\t10'
            )
            
            with open('/etc/login.defs', 'w') as f:
                f.write(login_defs)
            
            log_func("System hardening completed successfully.")

        threading.Thread(target=self.run_command, args=(harden_func,), daemon=True).start()

    def security_check(self):
        def check_func(log_func):
            # Ensure script is run with sudo
            if os.geteuid() != 0:
                raise PermissionError("This function requires sudo privileges")

            # Update and run rkhunter
            log_func("Running RootKit Hunter...")
            subprocess.run(['rkhunter', '--update'], check=True)
            subprocess.run(['rkhunter', '--check'], check=True)
            
            # Run chkrootkit
            log_func("Running Chkrootkit...")
            subprocess.run(['chkrootkit'], check=True)
            
            # Run Lynis
            log_func("Running Lynis security audit...")
            subprocess.run(['lynis', 'audit', 'system'], check=True)
            
            log_func("Security check completed successfully.")

        threading.Thread(target=self.run_command, args=(check_func,), daemon=True).start()

    def delete_media_files(self):
        # Confirmation dialog
        if not messagebox.askyesno("Confirm", "Are you sure you want to delete media files?"):
            return

        def delete_func(log_func):
            # Ensure script is run with sudo
            if os .geteuid() != 0:
                raise PermissionError("This function requires sudo privileges")

            log_func("Starting media file deletion...")

            # Define media file extensions
            media_extensions = [
                "*.mp3", "*.mp4", "*.avi", "*.mov", 
                "*.wav", "*.flac", "*.ogg", 
                "*.jpg", "*.jpeg", "*.png", "*.gif", 
                "*.mkv", "*.wmv"
            ]

            # Find and delete media files
            for ext in media_extensions:
                log_func(f"Deleting files with extension: {ext}")
                subprocess.run(['find', '/', '-type', 'f', '-name', ext, '-delete'], stderr=subprocess.DEVNULL)

            log_func("Media file deletion completed successfully.")

        threading.Thread(target=self.run_command, args=(delete_func,), daemon=True).start()

def main():
    root = tk.Tk()
    app = LinuxUtilityApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()