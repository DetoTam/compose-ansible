param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressA = "209.190.121.251",
    
    [parameter(Mandatory=$true)]
        [string]
        $UserName = "Administrator",
    
    [Parameter(Mandatory=$true)]
        [string]
        $Password = "dsf@Fbhc!!hc23P3P"
    
)   
cls

Import-Module .\Module\module.ps1 -Verbose -Force


#To add the names of particular computers to the list of trusted hosts
#Creates a persistent connection to remote computer for NameServerA
Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressA -Force
$Credential = Credential -UserName $UserName -tagetPassword $targetPasswordA
$PSSession = New-PSSession -ComputerName $IPAddressA -Credential $Credential

#Configuration servise winrm for NameServerA
ConfigurationWinRM -PSSession $PSSession