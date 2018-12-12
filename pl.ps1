
param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressdФ = "209.190.121.252",
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