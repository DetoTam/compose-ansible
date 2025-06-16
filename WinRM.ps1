# Check if PowerShell is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "The script must be run with administrator privileges!" -ForegroundColor Red
    exit 1
}

# Domain certificate pattern to search for
$domainPattern = "*.turnkey-lender.com"

Write-Host "Searching for domain certificate with pattern: $domainPattern in WebHosting store" -ForegroundColor Green

# Get certificates from WebHosting store
$certs = Get-ChildItem -Path "Cert:\LocalMachine\WebHosting" -ErrorAction SilentlyContinue

$domainCert = $null
foreach ($cert in $certs) {
    # Check Subject (CN)
    if ($cert.Subject -like "*$domainPattern*") {
        Write-Host "Found certificate by Subject: $($cert.Subject)" -ForegroundColor Green
        $domainCert = $cert
        break
    }
    
    # Check Subject Alternative Names (SAN)
    $san = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" }
    if ($san) {
        $sanValue = $san.Format($false)
        if ($sanValue -like "*$domainPattern*") {
            Write-Host "Found certificate by SAN: $sanValue" -ForegroundColor Green
            $domainCert = $cert
            break
        }
    }
    
    # Check DNS names in certificate
    try {
        $dnsNames = $cert.DnsNameList
        foreach ($dnsName in $dnsNames) {
            if ($dnsName.Unicode -like $domainPattern) {
                Write-Host "Found certificate by DNS name: $($dnsName.Unicode)" -ForegroundColor Green
                $domainCert = $cert
                break
            }
        }
        if ($domainCert) { break }
    } catch {
        # Continue if DnsNameList is not available
    }
}

if (-not $domainCert) {
    Write-Host "Domain certificate for '$domainPattern' not found in WebHosting store" -ForegroundColor Red
    Write-Host "Available certificates in WebHosting store:" -ForegroundColor Yellow
    
    $availableCerts = Get-ChildItem -Path "Cert:\LocalMachine\WebHosting" -ErrorAction SilentlyContinue
    if ($availableCerts) {
        foreach ($cert in $availableCerts) {
            Write-Host "  Subject: $($cert.Subject)" -ForegroundColor Gray
            Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
            Write-Host "  Expires: $($cert.NotAfter)" -ForegroundColor Gray
            Write-Host "  ---"
        }
    }
    exit 1
} else {
    Write-Host "Using domain certificate:" -ForegroundColor Green
    Write-Host "  Subject: $($domainCert.Subject)" -ForegroundColor Green
    Write-Host "  Thumbprint: $($domainCert.Thumbprint)" -ForegroundColor Green
    Write-Host "  Expires: $($domainCert.NotAfter)" -ForegroundColor Green
    
    # Check if certificate is valid
    if ($domainCert.NotAfter -lt (Get-Date)) {
        Write-Host "WARNING: Certificate has expired!" -ForegroundColor Red
    } elseif ($domainCert.NotAfter -lt (Get-Date).AddDays(30)) {
        Write-Host "WARNING: Certificate expires within 30 days!" -ForegroundColor Yellow
    }
}

# Enable WinRM
Write-Host "`nEnabling the WinRM service..." -ForegroundColor Green
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

# Remove existing listeners if any
Write-Host "Removing existing WinRM listeners..." -ForegroundColor Yellow
Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate | ForEach-Object {
    Remove-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address=$_.Address; Transport=$_.Transport}
}

# HTTP Listener
Write-Host "Creating HTTP listener..." -ForegroundColor Green
New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTP"}

# HTTPS Listener with domain certificate
Write-Host "Creating HTTPS listener with domain certificate..." -ForegroundColor Green
try {
    New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$domainCert.Thumbprint}
    Write-Host "HTTPS Listener configured successfully with certificate thumbprint: $($domainCert.Thumbprint)" -ForegroundColor Green
} catch {
    Write-Host "Error configuring HTTPS listener: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Attempting to configure with hostname..." -ForegroundColor Yellow
    
    # Alternative approach: try with hostname
    $hostname = $env:COMPUTERNAME
    try {
        New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{Hostname=$hostname; CertificateThumbprint=$domainCert.Thumbprint}
        Write-Host "HTTPS Listener configured with hostname: $hostname" -ForegroundColor Green
    } catch {
        Write-Host "Error configuring HTTPS listener with hostname: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Set WinRM configuration for better security and performance
Write-Host "Configuring WinRM settings..." -ForegroundColor Green
Set-WSManInstance -ResourceURI winrm/config/service -ValueSet @{AllowUnencrypted=$false}
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet @{Basic=$false}
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet @{Kerberos=$true}
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet @{Negotiate=$true}
Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet @{Certificate=$true}

# Check the status of the WinRM service
Write-Host "`nChecking the status of the WinRM service..." -ForegroundColor Green
$winrmService = Get-Service -Name WinRM
Write-Host "WinRM Service Status: $($winrmService.Status)" -ForegroundColor Green
Write-Host "WinRM Service StartType: $($winrmService.StartType)" -ForegroundColor Green

# Display configured listeners
Write-Host "`nConfigured WinRM listeners:" -ForegroundColor Green
Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate | ForEach-Object {
    Write-Host "  Address: $($_.Address), Transport: $($_.Transport), Port: $($_.Port)" -ForegroundColor Cyan
    if ($_.Transport -eq "HTTPS") {
        Write-Host "  Certificate Thumbprint: $($_.CertificateThumbprint)" -ForegroundColor Cyan
    }
}

Write-Host "`nConfiguration completed! WinRM is ready to use with domain certificate." -ForegroundColor Green
Write-Host "You can test the connection using:" -ForegroundColor Yellow
Write-Host "  Test-WSMan -ComputerName $env:COMPUTERNAME -UseSSL" -ForegroundColor Yellow
