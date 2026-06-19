# ===============================
# OOBE-SAFE WINDOWS UPDATE SCRIPT
# ===============================

Start-Transcript -Path "C:\Windows\Temp\RunUpdates.log" -Append

Write-Output "===== Starting Windows Update ====="

try {
    # ---------------------------
    # Force TLS 1.2 (required)
    # ---------------------------
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # ---------------------------
    # Ensure temp working dirs
    # ---------------------------
    $TempPath = "C:\Windows\Temp\PSBootstrap"
    New-Item -Path $TempPath -ItemType Directory -Force | Out-Null

    # ---------------------------
    # Fix PowerShellGet / PSGallery
    # ---------------------------
    Write-Output "Initializing PowerShell repositories..."

    try {
        $repo = Get-PSRepository -ErrorAction SilentlyContinue

        if (-not $repo) {
            Write-Output "Registering PSGallery..."
            Register-PSRepository `
                -Name "PSGallery" `
                -SourceLocation "https://www.powershellgallery.com/api/v2" `
                -InstallationPolicy Trusted
        }
        else {
            Write-Output "Setting PSGallery to Trusted..."
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }
    }
    catch {
        Write-Warning "PSRepository initialization failed: $_"
    }

    # ---------------------------
    # Install NuGet Provider
    # ---------------------------
    Write-Output "Installing NuGet provider..."
    try {
        Install-PackageProvider -Name NuGet -Force -Scope AllUsers -ErrorAction Stop
    }
    catch {
        Write-Warning "NuGet install failed, continuing: $_"
    }

    # ---------------------------
    # Install PSWindowsUpdate
    # ---------------------------
    Write-Output "Installing PSWindowsUpdate module..."

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        try {
            Install-Module PSWindowsUpdate -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        }
        catch {
            Write-Warning "Online install failed. Checking local copy..."

            # OPTIONAL: fallback if you pre-stage module
            $LocalModule = "C:\Windows\Temp\PSModules\PSWindowsUpdate"

            if (Test-Path $LocalModule) {
                Write-Output "Using pre-staged PSWindowsUpdate..."
                Copy-Item $LocalModule -Destination "C:\Program Files\WindowsPowerShell\Modules\" -Recurse -Force
            }
            else {
                throw "PSWindowsUpdate not available."
            }
        }
    }

    # ---------------------------
    # Import Module
    # ---------------------------
    Import-Module PSWindowsUpdate -Force -ErrorAction Stop
    Write-Output "PSWindowsUpdate module loaded."

    # ---------------------------
    # Enable Microsoft Update
    # ---------------------------
    try {
        Write-Output "Enabling Microsoft Update service..."
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
    }
    catch {
        Write-Warning "Microsoft Update enable failed (continuing): $_"
    }

    # ---------------------------
    # Scan & Install Updates Loop
    # ---------------------------
    $MaxCycles = 5
    $Cycle = 1

    do {
        Write-Output "==== Update Cycle $Cycle ===="

        $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue

        if ($updates) {
            Write-Output "$($updates.Count) updates found. Installing..."

            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -AutoReboot:$false -ErrorAction Continue

            Start-Sleep -Seconds 10
        }
        else {
            Write-Output "No updates found."
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
``
