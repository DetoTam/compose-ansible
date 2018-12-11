
function Credential {
       param (
              
              [string]
              $UserName,
       
              
              [string]
              $tagetPassword
       )
       $securePassword = convertto-securestring $targetPassword -asplaintext -force
       $cred = New-Object System.Management.Automation.PsCredential($UserName, $securePassword)
}
function ConfigurationWinRM {
       param ( [parameter(Mandatory=$true)] 
              [string]
              $PSSession)

       $Config = Invoke-Command -Session $PSSession -ScriptBlock {winrm quickconfig -q} -AsJob
       while ($State.State -ge "Completed"){
           $State = Receive-Job -Job $Config.Id
           Start-Sleep -s 5
       Write-Host "winrm quickconfig -q" -ForegroundColor Green
       }
       
       $Config = Invoke-Command -Session $PSSession -ScriptBlock {winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'} -AsJob
       while ($State.State -eq "Completed"){
            $State = Receive-Job -Job $Config.Id
            Start-Sleep -s 5
            Write-Host "winrm set winrm/config/winrs MaxMemoryPerShellMB=300"  -ForegroundColor Green
       }
       
       $Config = Invoke-Command -Session $PSSession -ScriptBlock {winrm set winrm/config '@{MaxTimeoutms="1800000"}'} -AsJob
       while ($State.State -eq "Completed"){
              $State = Receive-Job -Job $Config.Id
              Start-Sleep -s 5
              Write-Host "winrm set winrm/config MaxTimeoutms=1800000"  -ForegroundColor Green
       }
       
       $Config = Invoke-Command -Session $PSSession -ScriptBlock {winrm set winrm/config/service '@{AllowUnencrypted="true"}'} -AsJob
       while ($State.State -eq "Completed"){
              $State = Receive-Job -Job $Config.Id
              Start-Sleep -s 5
              Write-Host "winrm set winrm/config/service AllowUnencrypted=true"  -ForegroundColor Green       
       }
             
       $Config = Invoke-Command -Session $PSSession -ScriptBlock {Restart-Service -Name winrm} -AsJob
       while ($State.State -eq "Completed"){
              $State = Receive-Job -Job $Config.Id
              Start-Sleep -s 5
              Write-Host "Restart-Service winrm"  -ForegroundColor Green
       }    
}


