
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
        $Name = "VM2-FOR-TEST-CORE"
)   
cls

# For script runtime calculation:
$ScriptStartTime = Get-Date

Import-Module C:\Users\Administrator\Project\PowerTest\Module\module.ps1 -Verbose -Force

#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerB
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressdB -Force

$targetPasswordB = "dsf@Fbhc!!hc23P4P"
$securePassword = convertto-securestring $targetPasswordB -asplaintext -force
$cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)

Write-Host "New-PSSession"  -ForegroundColor Green
$Session = New-PSSession -ComputerName $IPAddressdB -Credential $cred
$Session

Write-Host "Install WindowsFeature IIS"  -ForegroundColor Green
$Config = Invoke-Command -Session $Session -JobName IIS -ScriptBlock {Install-WindowsFeature -name Web-Server -IncludeManagementTools} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name IIS).State
       $Status
       Start-Sleep -s 5
}

Write-Host "NetIPAddress"  -ForegroundColor Green
$Config = Invoke-Command -Session $Session -JobName IP -ScriptBlock {New-NetIPAddress -IPAddress $IPAddressNewB -InterfaceAlias Ethernet -AddressFamily IPv4} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name IP).State
       $Status
       Start-Sleep -s 5
}

Write-Host "Rename Computer"  -ForegroundColor Green
$Config = Invoke-Command -Session $Session -JobName RC -ScriptBlock {Rename-Computer -NewName $Name} -AsJob
$Config
$Status = ""
while ($Status -ne "Completed"){
       Start-Sleep -s 5
       $Status = (Get-Job -Name RC).State
       $Status
}

Enter-PSSession -Session $Session -Verbose
$Session
$ComputerInfo = Get-ComputerInfo
Write-Host "New computer name $($ComputerInfo.CsName)" -ForegroundColor Yellow
$IPAddress = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet
Write-Host "New ip address - $($IPAddress.IPv4Address)" -ForegroundColor Yellow

Write-Host "Restart Computer " -ForegroundColor Red
$Config = Invoke-Command -Session $Session -JobName Restart -ScriptBlock {Restart-Computer -ComputerName $Name} -AsJob
$Status = ""
while ($Status -ne "Completed"){
       $Status = (Get-Job -Name Restart).State
       $Status
       Start-Sleep -s 5
}

$ElapsedTime = GetElapsedTime($ScriptStartTime)
Write-Host "Full script execution time: $ElapsedTime" -ForegroundColor Green
