param(
    [parameter(Mandatory=$false)]
        [string]
        $IPAddressA = ""
)   
cls

#To add the names of particular computers to the list of trusted hosts

Set-Item wsman:\localhost\Client\TrustedHosts -Value $IPAddressA -Force

