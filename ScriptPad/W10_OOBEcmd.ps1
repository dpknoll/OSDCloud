
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

Write-Host -ForegroundColor Cyan "Set the Global Variables for a Driver Pack name --> none"
$Global:MyOSDCloud = @{
    DriverPackName = 'none'
    #ApplyManufacturerDrivers = $false
    #ApplyCatalogDrivers = $false
    #ApplyCatalogFirmware = $false
}

$Params = @{
    OSVersion = "Windows 10"
    OSBuild = "21H2"
    OSEdition = "Pro"
    OSLanguage = "en-us"
    Firmware = $false
    ZTI = $true
}
Start-OSDCloud @Params

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host "Restarting in 20 seconds!" -ForegroundColor Green
Start-Sleep -Seconds 20
wpeutil reboot
