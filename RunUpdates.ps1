# ============================================
# RunUpdates.ps1 (Resilient Version)
# ============================================

$LogPath = "C:\Windows\Temp\RunUpdates.log"
Start-Transcript -Path $LogPath -Append -Force

Write-Host "===== Starting Windows Update ====="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ensure module
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module PSWindowsUpdate -Force -Confirm:$false | Out-Null
}

Import-Module PSWindowsUpdate

# Enable Microsoft Update
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null

# ---- Create scheduled task for persistence ----
$TaskName = "RunUpdatesResume"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoL -ExecutionPolicy Bypass -File C:\Windows\Temp\RunUpdates.ps1"

$Trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Force | Out-Null

do {
    Write-Host "Scanning for updates..."

    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    if ($updates.Count -eq 0) {
        Write-Host "No more updates."
        break
    }

    Write-Host "Installing $($updates.Count) updates..."

    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    $reboot = (Get-WURebootStatus).RebootRequired

    if ($reboot) {
        Write-Host "Reboot required..."
        Stop-Transcript
        Restart-Computer -Force
        exit
    }

} while ($true)

# Cleanup scheduled task when done
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "===== Updates Complete ====="

Stop-Transcript
