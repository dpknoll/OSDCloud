Start-Transcript -Path "C:\Windows\Temp\RunUpdates.log" -Append

Write-Output "===== Starting Windows Update (COM API) ====="

try {
    $UpdateSession  = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

    $MaxCycles = 5
    $Cycle = 1

    do {
        Write-Output "=== Scan Cycle $Cycle ==="

        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")

        if ($SearchResult.Updates.Count -eq 0) {
            Write-Output "No updates available."
            break
        }

        Write-Output "`n--- Updates Found ---"
        
        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        $i = 1

        foreach ($Update in $SearchResult.Updates) {
            $kb = ($Update.KBArticleIDs -join ",")
            Write-Output ("[{0}] {1}" -f $i, $Update.Title)
            
            if ($kb) {
                Write-Output ("     KB: {0}" -f $kb)
            }

            if (-not $Update.EulaAccepted) {
                $Update.AcceptEula()
            }

            $UpdatesToInstall.Add($Update) | Out-Null
            $i++
        }

        Write-Output "----------------------`n"

        # ---------------------------
        # DOWNLOAD
        # ---------------------------
        Write-Output "Downloading updates..."

        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToInstall

        $DownloadJob = $Downloader.BeginDownload()

        while (-not $DownloadJob.IsCompleted) {
            $progress = $Downloader.GetProgress()
            Write-Progress -Activity "Downloading Updates" `
                           -Status "$($progress.PercentComplete)% Complete" `
                           -PercentComplete $progress.PercentComplete
            Start-Sleep -Seconds 2
        }

        $Downloader.EndDownload($DownloadJob)

        Write-Output "Download complete.`n"

        # ---------------------------
        # INSTALL
        # ---------------------------
        Write-Output "Installing updates..."

        $Installer = $UpdateSession.CreateUpdateInstaller()
        $Installer.Updates = $UpdatesToInstall

        $InstallJob = $Installer.BeginInstall()

        while (-not $InstallJob.IsCompleted) {
            $progress = $Installer.GetProgress()
            Write-Progress -Activity "Installing Updates" `
                           -Status "$($progress.PercentComplete)% Complete" `
                           -PercentComplete $progress.PercentComplete
            Start-Sleep -Seconds 2
        }

        $Result = $Installer.EndInstall($InstallJob)

        Write-Output "`n--- Installation Results ---"

        for ($i = 0; $i -lt $UpdatesToInstall.Count; $i++) {
            $update = $UpdatesToInstall.Item($i)
            $res = $Result.GetUpdateResult($i)

            Write-Output ("{0}" -f $update.Title)
            Write-Output ("  ResultCode : {0}" -f $res.ResultCode)
            Write-Output ("  HResult    : {0}" -f $res.HResult)
            Write-Output ""
        }

        if ($Result.RebootRequired) {
            Write-Output "Reboot required. Stopping cycles."
            break
        }

        $Cycle++
    } while ($Cycle -le $MaxCycles)

    Write-Output "===== Updates Complete ====="
}
catch {
    Write-Error "FATAL ERROR: $_"
}
finally {
    Stop-Transcript
}
