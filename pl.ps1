
param(
    [parameter(Mandatory=$true)]
        [string]
        $IPAddressdB = "209.190.121.252",
    
    [parameter(Mandatory=$true)]
        [string]
        $UserName = "Administrator",
    
    [parameter(Mandatory=$true)]
        [string]
        $rulename = "IISsite9000",
    
    [parameter(Mandatory=$false)]
        [string]
        $url = "https://github.com/gigazet/aspnethelloworld.git",
    
    [parameter(Mandatory=$false)]
        [string]
        $ContentPath = "Content"
    
    [parameter(Mandatory=$false)]
        [string]
        $InstallDir = "cli-tools"

        
)   
cls
$ErrorActionPreference="Stop"
$ProgressPreference="SilentlyContinue"

Import-Module .\Module\module.ps1 -Verbose -Force

Write-Host "Install WindowsFeature IIS"  -ForegroundColor Green

Install-WindowsFeature -name Web-Server -IncludeManagementTools

Import-Module BitsTransfer -Force

#git clone
$module = Get-Module -Name PowerShellGet
if(!$module) {
    Update-Module PowerShellGet -Force
}
else {
    Install-Module PowerShellGet -Force -SkipPublisherCheck
}
Install-Module Posh-Git -Scope AllUsers

if(!(Test-Path -Path $ContentPath)) {
    git clone $url $ContentPath
} else {
    set-location $ContentPath
    git pull
}
set-location $ContentPath

Write-Host "Script used to install the .NET Core CLI tools and the shared runtime"  -ForegroundColor Green
if (Test-Path $InstallDir)
    {rm -Recurse $InstallDir}
New-Item -Type "directory" -Path $InstallDir

Write-Host "Downloading the CLI installer..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "$InstallDir/dotnet-install.ps1"

Write-Host "Installing the CLI ..." -ForegroundColor Yellow
& $InstallDir/dotnet-install.ps1 -InstallDir $InstallDir

Write-Host "Downloading and installation of the SDK is complete" -ForegroundColor Green
$LocalDotnet = "$InstallDir/dotnet"

Write-Host "Install Application Request Routing" -ForegroundColor Green
    $url = "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi"
    $output = "Router_amd64.msi"
$start_time = Get-Date
    $MSIArguments = @(
                    "/q"
                    "/norestart")
    Start-BitsTransfer -Source $url -Destination $output
    Start-Process "$output" -ArgumentList $MSIArguments -passthru
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"



dotnet new razor --force



dotnet publish  --self-contained

New-WebSite -Name "TestSite" -Port 9000 -HostHeader "TestSite" -PhysicalPath "$Env:systemdrive\inetpub\testsite"

New-NetFirewallRule -DisplayName $rulename -Description $description -RemoteAddress $IPAddressdB -LocalPort 9000 -Protocol 'TCP' -Action 'Allow' -Enabled 'True'