
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

function GetElapsedTime {
	param ($BaseTime)
	$runtime = $(get-date) - $BaseTime
	$runtime = [string]::format("{0} hours, {1} minutes, {2}.{3} seconds", `
	$runtime.Hours, `
	$runtime.Minutes, `
	$runtime.Seconds, `
	$runtime.Milliseconds)
	return $runtime
}
