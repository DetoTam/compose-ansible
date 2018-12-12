
param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressdB = "209.190.121.252",
    [parameter(Mandatory=$true)]
        [string]
        $UserName = "Administrator",
    
)   
cls

Import-Module .\Module\module.ps1 -Verbose -Force

Write-Host "Install WindowsFeature IIS"  -ForegroundColor Green

Install-WindowsFeature -name Web-Server -IncludeManagementTools

.\dotnet-install.ps1 

dotnet publish  --self-contained

New-WebSite -Name "TestSite" -Port 9000 -HostHeader "TestSite" -PhysicalPath "$Env:systemdrive\inetpub\testsite"

New-NetFirewallRule -DisplayName $rulename -Description $description -RemoteAddress $IPAddressdB -LocalPort 9000 -Protocol 'TCP' -Action 'Allow' -Enabled 'True'