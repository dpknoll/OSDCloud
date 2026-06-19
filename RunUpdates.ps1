Start-Transcript -Path "C:\Windows\Temp\RunUpdates.log" -Append

Write-Output "===== Starting Windows Update (COM API) ====="

try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
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

        Write-Output "$($SearchResult.Updates.Count) updates found."

        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

        foreach ($Update in $SearchResult.Updates) {
            if (-not $Update.EulaAccepted) {
                $Update.AcceptEula()
            }
            $UpdatesToInstall.Add($Update) | Out-Null
        }

        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToInstall
        $Downloader.Download()

        $Installer = $UpdateSession.CreateUpdateInstaller()
        $Installer.Updates = $UpdatesToInstall

        Write-Output "Installing updates..."
        $Result = $Installer.Install()

        Write-Output "Result: $($Result.ResultCode)"

        if ($Result.RebootRequired) {
            Write-Output "Reboot required."
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
