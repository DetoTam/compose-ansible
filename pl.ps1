
param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressNewB = "192.168.88.3",

    [parameter(Mandatory=$true)]
        [string]
        $IPAddressdB = "209.190.121.252",
    [parameter(Mandatory=$true)]
        [string]
        $UserName = "Administrator",
    [parameter(Mandatory=$true)]
        [string]
        $Name = "VM2-FOR-TEST-CORE"
)   
cls

Import-Module .\Module\module.ps1 -Verbose -Force

$targetPasswordA = "dsf@Fbhc!!hc23P3P"


#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerB
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressOldB -Force

$targetPasswordB = "dsf@Fbhc!!hc23P4P"
$securePassword = convertto-securestring $targetPasswordB -asplaintext -force
$cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)


$Session = New-PSSession -ComputerName $IPAddressdB -Credential $cred
Enter-PSSession -Session $Session

New-NetIPAddress -IPAddress $IPAddressNewB -InterfaceAlias Ethernet -AddressFamily IPv4

Rename-Computer -NewName $ComputerName -Force -PassThru -Restart

$Connection = Test-Connection -ComputerName $IPAddressdB
Test-Connection 



$IPAddress


Invoke-Command -Session $Session -ScriptBlock {winrm quickconfig -q} -AsJob



$wmi = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $IPAddressOldB -Credential $cred

New-NetIPAddress ï¿½IPAddress $IpAddress ï¿½PrefixLength 24 -DefaultGateway $DefaultGateway





#Configuration winrm

 

Invoke-Command -ScriptBlock {Enable-PSRemoting -Force} -ComputerName $IPAddressA -AsJob -Credential $cred

Test-Connection -IPAddress $IPAddressA


$InfoIPAddress = Get-NetIPAddress -IPAddress $IPAddressOldB


Invoke-Command -ScriptBlock {Enable-PSRemoting -Force} -ComputerName $IPAddressA -AsJob










Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Server -DelegateComputer $ServerName -Force

Invoke-Command -ComputerName $IPAddressA -ScriptBlock {REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters /v AllowEncryptionOracle /t REG_DWORD /d 2}
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {WinRM enumerate winrm/config/listener}
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {net start winrm} -Authentication $cred
$InfoIPAddress = Get-NetIPAddress
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {winrm qc}


New-PSSession -ComputerName $IPAddressA -Authentication Basic -Credential $cred

Invoke-command ï¿½computername $IPAddressA -credential $cred ï¿½scriptblock {get-service}

Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressA -Force

function Test-Connection
{Param ([Parameter(Mandatory=$True)] [ipaddress]$IPAddress)

 $result = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet

Write-Host "$result"
}


