<#
    win-secure.ps1
    PowerShell script to automate basic Windows security implementations.
    Run as Administrator.
#>

function Enable-WindowsFirewall {
    Write-Host "Enabling Windows Firewall..." -ForegroundColor Cyan
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "Windows Firewall enabled."
}

function Check-WindowsUpdates {
    Write-Host "Checking for Windows Updates..." -ForegroundColor Cyan
    Get-WindowsUpdateLog | Out-Null
    Write-Host "Please check Windows Update settings for pending updates. (Automated update install coming soon.)"
}

function Disable-UnnecessaryServices {
    $services = @(
        'RemoteRegistry',
        'Telnet',
        'SNMP',
        'Fax'
    )
    foreach ($svc in $services) {
        Write-Host "Disabling service: $svc" -ForegroundColor Yellow
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Selected unnecessary services disabled."
}

Write-Host "=== Windows Security Automation Tool ===" -ForegroundColor Green

Enable-WindowsFirewall
Check-WindowsUpdates
Disable-UnnecessaryServices

Write-Host "Security automation complete." -ForegroundColor Green
