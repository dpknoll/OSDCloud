# ==========================================
# ENTERPRISE OOBE WINDOWS UPDATE SCRIPT
# ==========================================

$ScriptURL = "https://raw.githubusercontent.com/DPKnoll/OSDCloud/main/RunUpdates.ps1"
$LogFile   = "C:\Windows\Temp\RunUpdates.log"
$CycleFile = "C:\Windows\Temp\UpdateCycle.txt"
$MaxCycles = 5

Start-Transcript -Path $LogFile -Append

Write-Output "===== Starting Windows Update (COM API) ====="

try {
    # ---------------------------
    # Cycle Tracking
    # ---------------------------
    if (Test-Path $CycleFile) {
        $Cycle = [int](Get-Content $CycleFile)
        $Cycle++
    } else {
        $Cycle = 1
    }

    Set-Content $CycleFile $Cycle
    Write-Output "Update Cycle: $Cycle"

    if ($Cycle -gt $MaxCycles) {
        Write-Output "Max cycles reached. Cleaning up and exiting."
        Remove-Item $CycleFile -Force -ErrorAction SilentlyContinue
        exit 0
    }

    # ---------------------------
    # Initialize COM
    # ---------------------------
    $Session  = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()

    Write-Output "Scanning for updates..."
    $SearchResult = $Searcher.Search("IsInstalled=0 and IsHidden=0")

    if ($SearchResult.Updates.Count -eq 0) {
        Write-Output "No updates available. Cleaning up."

        Remove-Item $CycleFile -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
            -Name "ResumeUpdates" -ErrorAction SilentlyContinue

        exit 0
    }

    # ---------------------------
    # Filter Updates
    # ---------------------------
    $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

    Write-Output "`n--- Updates Found ---"

    $index = 1
    foreach ($Update in $SearchResult.Updates) {

        # Skip drivers (you use Lenovo tools)
        if ($Update.Type -eq 2) {
            Write-Output "[SKIP DRIVER] $($Update.Title)"
            continue
        }

        # Skip preview updates
        if ($Update.Title -match "Preview") {
            Write-Output "[SKIP PREVIEW] $($Update.Title)"
            continue
        }

        $kb = ($Update.KBArticleIDs -join ",")

        Write-Output ("[{0}] {1}" -f $index, $Update.Title)
        if ($kb) { Write-Output ("     KB: {0}" -f $kb) }

        if (-not $Update.EulaAccepted) {
            $Update.AcceptEula()
        }

        $UpdatesToInstall.Add($Update) | Out-Null
        $index++
    }

    if ($UpdatesToInstall.Count -eq 0) {
        Write-Output "No applicable updates after filtering. Exiting."
        exit 0
    }

    # ---------------------------
    # Download Updates
    # ---------------------------
    Write-Output "`nDownloading updates..."

    $Downloader = $Session.CreateUpdateDownloader()
    $Downloader.Updates = $UpdatesToInstall
    $DownloadResult = $Downloader.Download()

    Write-Output "Download Result: $($DownloadResult.ResultCode)"

    # ---------------------------
    # Install Updates
    # ---------------------------
    Write-Output "`nInstalling updates..."

    $Installer = $Session.CreateUpdateInstaller()
    $Installer.Updates = $UpdatesToInstall
    $InstallResult = $Installer.Install()

    Write-Output "`n--- Installation Results ---"

    for ($i = 0; $i -lt $UpdatesToInstall.Count; $i++) {
        $update = $UpdatesToInstall.Item($i)
        $res = $InstallResult.GetUpdateResult($i)

        Write-Output "$($update.Title)"
        Write-Output "  ResultCode : $($res.ResultCode)"
        Write-Output "  HResult    : $($res.HResult)"
        Write-Output ""
    }

    # ---------------------------
    # Handle Reboot + Resume
    # ---------------------------
    if ($InstallResult.RebootRequired) {

        Write-Output "Reboot required. Scheduling resume..."

        $Command = "powershell -ExecutionPolicy Bypass -Command `"iex (irm $ScriptURL)`""

        New-ItemProperty `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
            -Name "ResumeUpdates" `
            -Value $Command `
            -PropertyType String -Force | Out-Null

        Write-Output "Rebooting system..."
        Restart-Computer -Force
        exit
    }

    Write-Output "Cycle complete. Continuing..."

}
catch {
    Write-Error "FATAL ERROR: $_"
    exit 1
}
finally {
    Stop-Transcript
}
