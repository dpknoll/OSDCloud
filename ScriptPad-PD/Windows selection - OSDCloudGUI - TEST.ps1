Write-Host  -ForegroundColor Cyan "Starting SeguraOSD's OSDCloud ..."
Write-Host  -ForegroundColor Red "This option should only be used for testing. No support will be provided."
Start-Sleep -Seconds 7

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#Make sure I have the latest OSD Content
<#Write-Host  -ForegroundColor Cyan "Updating the OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Importing the OSD PowerShell Module"
Import-Module OSD -Force
#>
   
       Write-Host  -ForegroundColor Cyan "Starting OSDCloudGUI"
       Write-Host  -ForegroundColor Red "**WARNING** - Please make sure the correct driver pack is selected"
       $OSDModuleResource.OSDCloud.Default.Edition = 'Pro'
       $OSDModuleResource.OSDCloud.Default.Activation = 'Retail'
       $OSDModuleResource.OSDCloud.Values.Name = 'Windows 11 25H2 x64','Windows 11 23H2 x64','Windows 10 22H2 x64'
       $OSDModuleResource.StartOSDCloudGUI.BrandName = 'OSDCloud GUI'
       $OSDModuleResource.StartOSDCloudGUI.BrandColor = 'RED'       
       Start-Sleep -Seconds 10
       Start-OSDCloudGUI
       
#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
REM  Moving OSDCloud Logs
md C:\ProgramData\Microsoft\IntuneManagementExtension\OSD
move /y C:\OSDCloud\Logs C:\ProgramData\Microsoft\IntuneManagementExtension\OSD
move /y C:\ProgramData\OSDeploy C:\ProgramData\Microsoft\IntuneManagementExtension\OSD
REM Cleanup directories
rd /s /q C:\Drivers
rd /s /q C:\OSDCloud
rd /s /q C:\Temp
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 10 seconds!"
Start-Sleep -Seconds 10
wpeutil reboot
