#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "25H2"
    OSEdition = "Pro"
    OSLanguage = "en-us"
    OSLicense = "Retail"
    ZTI = $true
    Firmware = $false
}
Start-OSDCloud @Params

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
REM Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/dpknoll/OSDCloud/9a5ab4df2700fa4d5875aa915307e683ca85d43e/CleanupOSDCloud
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"

$SetupCompleteCMD = @'

REM ============================================
REM SetupComplete - OSDCloud Finalization
REM ============================================

set LOGFILE=C:\Windows\Temp\SetupComplete.log

echo Starting SetupComplete > %LOGFILE%
echo %DATE% %TIME% >> %LOGFILE%

REM ============================================
REM Move OSDCloud Logs (your original logic)
REM ============================================

echo Moving OSDCloud logs... >> %LOGFILE%
md C:\ProgramData\Microsoft\IntuneManagementExtension\OSD 2>> %LOGFILE%
move /y C:\OSDCloud\Logs C:\ProgramData\Microsoft\IntuneManagementExtension\OSD >> %LOGFILE% 2>&1
move /y C:\ProgramData\OSDeploy C:\ProgramData\Microsoft\IntuneManagementExtension\OSD >> %LOGFILE% 2>&1

REM ============================================
REM WAIT FOR NETWORK (critical)
REM ============================================

echo Waiting for network... >> %LOGFILE%

powershell -NoL -Command ^
"$i=0; do { Start-Sleep -Seconds 5; $i++; try { Invoke-WebRequest 'https://www.microsoft.com' -UseBasicParsing -TimeoutSec 5; $ok=$true } catch { $ok=$false } } until ($ok -or $i -gt 24); if (-not $ok) { exit 1 }"

IF %ERRORLEVEL% NEQ 0 (
    echo Network not ready, skipping updates >> %LOGFILE%
    goto CLEANUP
)

echo Network ready >> %LOGFILE%

REM ============================================
REM Download Windows Update Script
REM ============================================

echo Downloading RunUpdates.ps1 >> %LOGFILE%

if not exist C:\Windows\Temp mkdir C:\Windows\Temp

powershell -NoL -ExecutionPolicy Bypass -Command ^
"try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dpknoll/OSDCloud/main/RunUpdates.ps1' -OutFile 'C:\Windows\Temp\RunUpdates.ps1' -UseBasicParsing } catch { exit 1 }"

IF %ERRORLEVEL% NEQ 0 (
    echo Failed to download RunUpdates.ps1 >> %LOGFILE%
    goto CLEANUP
)

echo Download successful >> %LOGFILE%

REM ============================================
REM Execute Windows Update Script
REM ============================================

echo Starting Windows Update script >> %LOGFILE%

powershell -NoL -ExecutionPolicy Bypass -File C:\Windows\Temp\RunUpdates.ps1 >> %LOGFILE% 2>&1

echo Windows Update script finished >> %LOGFILE%

:CLEANUP

REM ============================================
REM Cleanup (your original logic)
REM ============================================

echo Performing cleanup... >> %LOGFILE%

rd /s /q C:\Drivers >> %LOGFILE% 2>&1
rd /s /q C:\OSDCloud >> %LOGFILE% 2>&1
rd /s /q C:\Temp >> %LOGFILE% 2>&1

echo SetupComplete finished >> %LOGFILE%

'@

$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
