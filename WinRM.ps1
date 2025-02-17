# Check if PowerShell is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "The script must be run with administrator privileges!" -ForegroundColor Red
    exit 1
}

# Get the computer name
$certName = $env:COMPUTERNAME
$dnsName = $certName  # DNS name matches the computer name

# Check if a certificate with the same name already exists
Write-Host "Checking if a certificate with the name '$certName' already exists..."

$existingCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $certName }

if ($existingCert) {
    Write-Host "A certificate with the name '$certName' already exists. Skipping creation." -ForegroundColor Yellow
    Write-Host "Certificate Thumbprint: $($existingCert.Thumbprint)" -ForegroundColor Green
} else {
    # Create a self-signed certificate
    Write-Host "Creating a self-signed certificate for $certName..."
    $cert = New-SelfSignedCertificate -DnsName $dnsName -CertStoreLocation Cert:\LocalMachine\My -FriendlyName $certName

    # Add the certificate to the "Trusted Root Certification Authorities" store
    Write-Host "Adding the certificate to Trusted Root Certification Authorities..."
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()

    Write-Host "Certificate created successfully!"
    Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
}

# Enable WinRM
Write-Host "Enabling the WinRM service..." -ForegroundColor Green
Enable-PSRemoting -Force

# Set trusted hosts (optional, if you need to connect to multiple servers)
$trustedHosts = "*" # Replace "*" with a list of IP addresses or hostnames, e.g., "192.168.1.100,192.168.1.101"
Write-Host "Configuring trusted hosts: $trustedHosts" -ForegroundColor Green
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $trustedHosts -Force

# Configure firewall rules for WinRM
Write-Host "Configuring firewall rules for WinRM..." -ForegroundColor Green

# Check if HTTP rule exists and create it if necessary
$httpRuleExists = Get-NetFirewallRule -Name "WinRM_HTTP" -ErrorAction SilentlyContinue
if (-not $httpRuleExists) {
    New-NetFirewallRule -Name "WinRM_HTTP" -DisplayName "WinRM over HTTP" -Protocol TCP -LocalPort 5985 -Action Allow
    Write-Host "Firewall rule for HTTP created." -ForegroundColor Green
} else {
    Write-Host "Firewall rule for HTTP already exists. Skipping..." -ForegroundColor Yellow
}

# Check if HTTPS rule exists and create it if necessary
$httpsRuleExists = Get-NetFirewallRule -Name "WinRM_HTTPS" -ErrorAction SilentlyContinue
if (-not $httpsRuleExists) {
    New-NetFirewallRule -Name "WinRM_HTTPS" -DisplayName "WinRM over HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow
    Write-Host "Firewall rule for HTTPS created." -ForegroundColor Green
} else {
    Write-Host "Firewall rule for HTTPS already exists. Skipping..." -ForegroundColor Yellow
}

# Configure WinRM listeners
Write-Host "Configuring WinRM listeners..." -ForegroundColor Green

# HTTP Listener
if (-not (Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate | Where-Object { $_.Port -eq 5985 })) {
    Write-Host "Creating an HTTP listener..." -ForegroundColor Green
    New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTP"}
}

# HTTPS Listener
if (-not (Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate | Where-Object { $_.Port -eq 5986 })) {
    Write-Host "Creating an HTTPS listener using the generated certificate..." -ForegroundColor Green
    if ($cert -ne $null) {
        New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$cert.Thumbprint}
        Write-Host "HTTPS Listener configured with certificate: $($cert.Thumbprint)" -ForegroundColor Green
    } else {
        Write-Host "Error: certificate not found." -ForegroundColor Red
    }
}

# Check the status of the WinRM service
Write-Host "Checking the status of the WinRM service..." -ForegroundColor Green
Get-Service -Name WinRM | Select-Object Status, StartType

Write-Host "Configuration completed! WinRM is ready to use." -ForegroundColor Green
