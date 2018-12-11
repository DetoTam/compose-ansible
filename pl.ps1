
param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressA = "209.190.121.251",

    [parameter(Mandatory=$true)]
        [string]
        $IPAddressNewB = "209.190.121.252",

    [parameter(Mandatory=$true)]
        [string]
        $IPAddressOldB = "209.190.121.252",

    [parameter(Mandatory=$true)]
        [string]
        $NameServerA = "VM2_FOR_TEST_GUI",

    [parameter(Mandatory=$true)]
        [string]
        $NameServerB = "VM2_FOR_TEST_CORE",

    [parameter(Mandatory=$true)]
        [string]
        $UserName = "Administrator"
    
)   
cls

Import-Module .\Module\module.ps1 -Verbose -Force

$targetPasswordA = "dsf@Fbhc!!hc23P3P"

#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerA
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressA -Force
$Credential = Credential -UserName $UserName -tagetPassword $targetPasswordA
$PSSession = New-PSSession -ComputerName $IPAddressA -Credential $Credential

#Configuration servise winrm for NameServerA
ConfigurationWinRM -PSSession $PSSession

#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerB
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressOldB -Force
$Credential = Credential -UserName $UserName -tagetPassword $targetPasswordB

$targetPasswordB = "dsf@Fbhc!!hc23P4P"
$securePassword = convertto-securestring $targetPasswordB -asplaintext -force
$cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)


$PSSession = New-PSSession -ComputerName $IPAddressOldB -Credential $cred

#Configuration servise winrm for NameServerB
ConfigurationWinRM -PSSession $PSSession

$wmi = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $IPAddressA -Credential $cred
New-NetIPAddress �IPAddress $IpAddress �PrefixLength 24 -DefaultGateway $DefaultGateway



Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressOldB -Force
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressNewB -Force

#Configuration winrm

 

Invoke-Command -ScriptBlock {Enable-PSRemoting -Force} -ComputerName $IPAddressA -AsJob -Credential $cred

Test-Connection -IPAddress $IPAddressA


$InfoIPAddress = Get-NetIPAddress -IPAddress 


Invoke-Command -ScriptBlock {Enable-PSRemoting -Force} -ComputerName $IPAddressA -AsJob










Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Server -DelegateComputer $ServerName -Force

Invoke-Command -ComputerName $IPAddressA -ScriptBlock {REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters /v AllowEncryptionOracle /t REG_DWORD /d 2}
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {WinRM enumerate winrm/config/listener}
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {net start winrm} -Authentication $cred
$InfoIPAddress = Get-NetIPAddress
Invoke-Command -ComputerName $IPAddressA -ScriptBlock {winrm qc}


New-PSSession -ComputerName $IPAddressA -Authentication Basic -Credential $cred

Invoke-command �computername $IPAddressA -credential $cred �scriptblock {get-service}

Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressA -Force

function Test-Connection
{Param ([Parameter(Mandatory=$True)] [ipaddress]$IPAddress)

 $result = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet

Write-Host "$result"
}


