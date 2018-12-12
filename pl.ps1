
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
$Config = Invoke-Command -Session $Session -JobName IIS -ScriptBlock {Install-WindowsFeature -name Web-Server -IncludeManagementTools} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name IIS).State
       $Status
       Start-Sleep -s 5
}
