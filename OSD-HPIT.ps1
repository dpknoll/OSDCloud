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
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM https://cleanup.osdcloud.ch)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force   

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restarting in 10 seconds!"
Start-Sleep -Seconds 10
wpeutil reboot
