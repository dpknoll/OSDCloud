# Ensure TLS 1.2 (important in WinPE / fresh OS)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Starting Post-OSDCloud Update Process..." -ForegroundColor Cyan

# Install PSWindowsUpdate module if not present
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers
    Install-Module PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false
}

Import-Module PSWindowsUpdate

# Enable Microsoft Update (not just Windows Update)
Write-Host "Enabling Microsoft Update..." -ForegroundColor Yellow
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null

# Optional: Reset Windows Update components (good for reliability)
Write-Host "Resetting Windows Update components..." -ForegroundColor Yellow
Reset-WUComponents

# Loop until no more updates remain
$RebootRequired = $true

while ($RebootRequired) {

    Write-Host "Checking for updates..." -ForegroundColor Cyan
    
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    if ($updates.Count -eq 0) {
        Write-Host "No more updates available." -ForegroundColor Green
        break
    }

    Write-Host "Installing $($updates.Count) updates..." -ForegroundColor Yellow

    Install-WindowsUpdate `
        -MicrosoftUpdate `
        -AcceptAll `
        -IgnoreUserInput `
        -AutoReboot

    # If AutoReboot didn’t trigger, check manually
    $RebootRequired = (Get-WURebootStatus).RebootRequired

    if ($RebootRequired) {
        Write-Host "Reboot required. Restarting..." -ForegroundColor Yellow
        Restart-Computer -Force
    } else {
        Write-Host "No reboot required, continuing..." -ForegroundColor Green
    }
}

Write-Host "Windows fully updated." -ForegroundColor Green
``
