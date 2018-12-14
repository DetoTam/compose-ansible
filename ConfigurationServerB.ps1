
param(
    [parameter(Mandatory=$false)]
        [string]
        $IPAddressNewB = "192.168.88.3",
    [parameter(Mandatory=$false)]
        [string]
        $IPAddressdB = "209.190.121.252",
    [parameter(Mandatory=$false)]
        [string]
        $UserName = "Administrator",
    [parameter(Mandatory=$false)]
        [string]
        $Name = "VM2-FOR-TEST-CR",
    [parameter(Mandatory=$true)]
        [string]
        $targetPasswordB
)   
cls

# For script runtime calculation:
$ScriptStartTime = Get-Date

#([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Import-Module .\Module\module.ps1 -Verbose -Force

#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerB
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressdB -Force

$securePassword = convertto-securestring $targetPasswordB -asplaintext -force
$cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)

Write-Host "Configuration WinRM"  -ForegroundColor Green
$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName WinRM -FilePath .\winrm.ps1 -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name WinRM).State
       $Status
       Start-Sleep -s 5
}

Write-Host "Install WindowsFeature IIS"  -ForegroundColor Green
$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName IIS -ScriptBlock {Install-WindowsFeature -name Web-Server -IncludeManagementTools} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name IIS).State
       $Status
       Start-Sleep -s 5
}

Write-Host "NetIPAddress - $($IPAddressNewB)"  -ForegroundColor Green
$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName IIS -ScriptBlock {New-NetIPAddress -IPAddress $IPAddressNewB -AddressFamily IPv4 -InterfaceAlias EthernetNew} -AsJob
#$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName IP -ScriptBlock {Start-Job -ScriptBlock {param ($IPAddressNewB) Get-NetIpAddress | Where-Object {$_.InterfaceAlias -match "Ethernet" -and $_.AddressFamily -eq "IPv4"} | New-NetIPAddress -IPAddress $IPAddressNewB -AddressFamily IPv4 -InterfaceAlias Ethernet} -ArgumentList $IPAddressNewB -RunAsAdministrator $UserName}
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name IP).State
       $Status
       Start-Sleep -s 5
}

Write-Host "Rename Computer"  -ForegroundColor Green
$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName RC -ScriptBlock {Rename-Computer -NewName $Name} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       Start-Sleep -s 5
       $Status = (Get-Job -Name RC).State
       $Status
}

Write-Host "Restart Computer " -ForegroundColor Red
$Config = Invoke-Command -ComputerName $IPAddressdB -Credential $cred -JobName Restart -ScriptBlock {Restart-Computer -ComputerName $$IPAddressdB -Force} -AsJob
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name Restart).State
       $Status
       Start-Sleep -s 5
}

$ElapsedTime = GetElapsedTime($ScriptStartTime)
Write-Host "Full script execution time: $ElapsedTime" -ForegroundColor Green
