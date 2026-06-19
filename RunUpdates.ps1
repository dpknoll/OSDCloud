# ============================================
# RunUpdates.ps1
# Full Windows Update Loop for OSDCloud
# ============================================

# Start logging
$LogPath = "C:\Windows\Temp\RunUpdates.log"
Start-Transcript -Path $LogPath -Append -Force

Write-Host "===== Starting Windows Update Process =====" -ForegroundColor Cyan

# Ensure TLS 1.2 (important for GitHub / Update endpoints)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install required modules
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module PSWindowsUpdate -Force -Confirm:$false | Out-Null
}

Import-Module PSWindowsUpdate -Force

# Enable Microsoft Update (Office, etc.)
Write-Host "Enabling Microsoft Update service..." -ForegroundColor Yellow
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null

# Reset Windows Update components (helps reliability)
Write-Host "Resetting Windows Update components..." -ForegroundColor Yellow
Reset-WUComponents

# Loop until fully patched
$UpdatesRemaining = $true

while ($UpdatesRemaining) {

    Write-Host "Checking for updates..." -ForegroundColor Cyan

    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    if ($updates.Count -eq 0) {
        Write-Host "No updates found. System is up to date." -ForegroundColor Green
        break
    }

    Write-Host "$($updates.Count) updates found. Installing..." -ForegroundColor Yellow

    Install-WindowsUpdate `
        -MicrosoftUpdate `
        -AcceptAll `
        -IgnoreUserInput `
        -AutoReboot

    Start-Sleep -Seconds 15

    # Check reboot status
    $rebootStatus = Get-WURebootStatus

    if ($rebootStatus.RebootRequired) {
        Write-Host "Reboot required. Restarting system..." -ForegroundColor Yellow
        Stop-Transcript
        Restart-Computer -Force
        exit
    }

    Write-Host "Continuing update scan..." -ForegroundColor Cyan
}

Write-Host "===== Windows Update Process Complete =====" -ForegroundColor Green

Stop-Transcript
