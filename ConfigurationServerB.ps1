
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


#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerB
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressOldB -Force

$targetPasswordB = "dsf@Fbhc!!hc23P4P"
$securePassword = convertto-securestring $targetPasswordB -asplaintext -force
$cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)

$Session = New-PSSession -ComputerName $IPAddressdB -Credential $cred
Enter-PSSession -Session $Session

Install-WindowsFeature -name Web-Server -IncludeManagementTools

New-NetIPAddress -IPAddress $IPAddressNewB -InterfaceAlias Ethernet -AddressFamily IPv4

RenameComputer -name $Name

Restart-Computer -Force

