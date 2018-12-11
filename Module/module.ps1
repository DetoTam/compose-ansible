
function Credential {
       param ( [parameter(Mandatory=$true)] 
              [string]
              $UserName,
       
       [parameter(Mandatory=$true)] 
              [string]
              $Password
       )
       
       $securePassword = convertto-securestring $Password -asplaintext -force
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

function RenameComputer{
    param ( [Parameter(Mandatory=$true)][string]$name )
    process
    {
        try
        {
            $computer = Get-WmiObject -Class Win32_ComputerSystem
            $result = $computer.Rename($name)

            switch($result.ReturnValue)
            {       
                0 { Write-Host "Success Rename Computer" }
                5 
                {
                    Write-Error "You need administrative rights to execute this cmdlet" 
                    exit
                }
                default 
                {
                    Write-Host "Error - return value of " $result.ReturnValue
                    exit
                }
            }
        }
        catch
        {
            Write-Host "Exception occurred in Rename-Computer " $Error
        }
    }
}

switch(((Get-WmiObject -Class Win32_ComputerSystem).Rename($name)).ReturnValue)
