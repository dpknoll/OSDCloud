Write-Host  -ForegroundColor Cyan "Starting SeguraOSD's OSDCloud ..."
Start-Sleep -Seconds 5

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
       Write-Host  -ForegroundColor Red "**WARNING** - Make sure to select the correct driver pack"
       $OSDModuleResource.OSDCloud.Default.Edition = 'Pro'
       $OSDModuleResource.OSDCloud.Default.Activation = 'Retail'
       $OSDModuleResource.OSDCloud.Values.Name = 'Windows 11 22H2 x64','Windows 10 22H2 x64'
       $OSDModuleResource.StartOSDCloudGUI.BrandName = 'Henny Penny IT Services - OSDCloud'
       $OSDModuleResource.StartOSDCloudGUI.BrandColor = 'RED'       
       Start-Sleep -Seconds 10
       Start-OSDCloudGUI
       
#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
Write-Host "Execute OSD Cloud Cleanup Script" -ForegroundColor Green

# Copying the OOBEDeploy and AutopilotOOBE Logs
Get-ChildItem 'C:\Windows\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

# Copying OSDCloud Logs
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
}
Move-Item 'C:\ProgramData\OSDeploy\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

If (Test-Path -Path 'C:\Temp') {
    Get-ChildItem 'C:\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Get-ChildItem 'C:\Windows\Temp' -Filter *Events* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
}

# Cleanup directories
If (Test-Path -Path 'C:\OSDCloud') { Remove-Item -Path 'C:\OSDCloud' -Recurse -Force }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force }
#If (Test-Path -Path 'C:\Temp') { Remove-Item 'C:\Temp' -Recurse -Force }
Get-ChildItem 'C:\Windows\Temp' -Filter *membeer*  | Remove-Item -Force
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force   

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 10 seconds!"
Start-Sleep -Seconds 10
wpeutil reboot
