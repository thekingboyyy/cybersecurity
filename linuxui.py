import tkinter as tk
from tkinter import messagebox, ttk
import subprocess
import subprocess

def update_system():
    subprocess.run(["bash", "linux2.sh", "update"])

class LinuxUtilityApp:
    def __init__(self, master):
        self.master = master
        master.title("Linux Utility Tool")
        master.geometry("600x500")

        # Create a frame for better organization
        self.frame = tk.Frame(master)
        self.frame.pack(pady=10)

        self.label = tk.Label(self.frame, text="Linux Utility Tool", font=("Helvetica", 16))
        self.label.pack(pady=10)

        # Text area for output
        self.output_text = tk.Text(master, wrap=tk.WORD, height=15)
        self.output_text.pack(pady=10)

        # Progress bar
        self.progress = ttk.Progressbar(self.frame, orient="horizontal", length=300, mode="determinate")
        self.progress.pack(pady=10)

        # Buttons for different functionalities
        self.update_button = tk.Button(self.frame, text="Update System", command=lambda: self.run_script("update"))
        self.harden_button = tk.Button(self.frame, text="Harden System", command=lambda: self.run_script("harden"))
        self.delete_media_button = tk.Button(self.frame, text="Delete Media Files", command=self.confirm_delete_media)
        self.check_security_button = tk.Button(self.frame, text="Check Security", command=lambda: self.run_script("check_security"))

        self.update_button.pack(pady=5)
        self.harden_button.pack(pady=5)
        self.delete_media_button.pack(pady=5)
        self.check_security_button.pack(pady=5)

    def run_script(self, action):
        self.output_text.delete(1.0, tk.END)  # Clear previous output
        self.progress.start()  # Start the progress bar

        try:
            if action == "update":
                command = ['bash', 'linux2.sh', 'update']
            elif action == "harden":
                command = ['bash', 'linux2.sh', 'harden']
            elif action == "check_security":
                command = ['bash', 'linux2.sh', 'check_security']

            result = subprocess.run(command, capture_output=True, text=True)

            self.output_text.insert(tk.END, result.stdout)  # Display script output
            if result.stderr:
                messagebox.showerror("Error", result.stderr)  # Show errors if any
        except Exception as e:
            messagebox.showerror("Error", str(e))  # Handle exceptions
        finally:
            self.progress.stop()  # Stop the progress bar

    def confirm_delete_media(self):
        if messagebox.askyesno("Confirm Deletion", "This will delete all media files. Do you want to continue?"):
            self.run_script("delete_media")
        else:
            self.output_text.insert(tk.END, "Media file deletion canceled by user.\n")

if __name__ == "__main__":
    root = tk.Tk()
    app = LinuxUtilityApp(root)
    root.mainloop()