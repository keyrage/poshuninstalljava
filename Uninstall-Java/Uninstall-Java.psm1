<#
.Synopsis
   Finds all Oracle Java products (excluding the auto updater which actually gets uninstalled when the main install is removed).
.DESCRIPTION
   Identifies and uninstalls Oracle's Java software from the local machine using WMI calls. The query to locate the installed software interogates the WIN32_Products class and includes exclusions to avoid matches to third party software that has "Java" in it's name.
   Use the -KeepVersion argument to specifiy a version to keep installed on a computer.
   Use the -Whatif switch to test the result without actually uninstalling anything.

   The script will return the results of the WMI query as an object array.
   Credit to commenter on my blog "Carsten" who supplied an expanded list of software to exclude.
   Note: this script is supplied "as is" and has not been fully tested for all possible scenarios. Use at your own risk and do full testing before using in production.

.EXAMPLE
   Uninstall-Java
   Uninstalls all versions of Java
.EXAMPLE
   Uninstall-Java -KeepVersion "7.0.45"
   Uninstalls all Java except version that starts with "7.0.45"
#>
function Uninstall-Java
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Specify a version of Java to keep on the copmputer [optional]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$KeepVersion,
        # Test the result of running the script. The script will return the software packages that would be uninstalled without the -Whatif switch.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=1)]
		[switch]$Whatif,
		[Parameter(ParameterSetName = 'Wait',
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $false,
				   Position = 2)]
		[switch]$Wait,
		[Parameter(ParameterSetName = 'Wait',
				   Mandatory = $false,
				   ValueFromPipelineByPropertyName = $false,
				   Position = 3)]
		[int32]$Timeout,
		[Parameter(Mandatory = $false,
				   ValueFromPipelineByPropertyName = $false,
				   Position = 4)]
		[switch]$Restart = $false

    )

    Begin
	{
		Write-Verbose "Uninstall-Java Started $(Get-Date)"
        #Construct query
        
        $query= "select * from win32_Product where (Name like 'Java %' or Name like 'Java(TM)%' or Name like 'J2SE%') and (Name <> 'Java Auto Updater') and ((Vendor='Sun Microsystems, Inc.') or (Vendor='Oracle') or (Vendor='Oracle Corporation')) and (NOT Name like '%CompuGROUP%') and (NOT Name like '%IBM%') and (NOT Name like '%DB%') and (NOT Name like '%Advanced Imaging%') and (NOT Name like '%Media Framework%') and (NOT Name like '%SDK%') and (NOT Name like '%Development Kit%')"
        if ($KeepVersion){$query=$query + " and (NOT Version like '$KeepVersion%')"}
    }
    Process
    {
        [array]$javas=Get-WmiObject -query $query
        if ($javas.count -gt 0)
        {
            write-Verbose "Java is Installed"
            
            if ($Whatif)
            {
                Return $javas
            }
            else
            {
				#Get all the Java processes and kill them. If java is running and the processes aren't killed then this script will invoke a sudden reboot.
				
				#get-process -Name "Java*"
				[array]$processes = Get-Process -Name "Java*"
				
				while ($processes.Count -gt 0)
				{
					Write-Verbose "$($processes.count) Java processes found running"
					if ($Wait)
					{
						Write-Verbose "Waiting for java processes to terminate"
						
						foreach ($myprocess in $processes)
						{
							write-debug "Process ID $($myprocess.id) found"
							if ($Timeout)
							{
								Try
								{
									Wait-Process -InputObject $myprocess -Verbose:$PSBoundParameters['Verbose'] -Debug:$PSBoundParameters['Debug'] -Timeout $Timeout -ErrorAction:Stop
								}
								Catch
								{
									Write-Verbose "Timeout Expired, Killing java process"
									$myprocess.kill()
									Start-Sleep -Seconds 1 -Verbose:$PSBoundParameters['Verbose'] -Debug:$PSBoundParameters['Debug']
								}
								
							}
							else { Wait-Process -InputObject $myprocess -Verbose:$PSBoundParameters['Verbose'] -Debug:$PSBoundParameters['Debug'] }
						}
					}
					else
					{
						Write-Verbose "Killing $($processes.count) Java processes"
						foreach ($myprocess in $processes)
						{
							write-debug "Process ID $($myprocess.id) found and will be killed"
							$myprocess.kill()
							
						}
					}
					$processes = Get-Process -Name "Java*"
				}
				
				#Loop through the installed Java products.
				
				foreach ($java in $javas)
				{
					write-Verbose "Uninstalling $($java.name)"
					$Uninstalled = $java.Uninstall()
					if ($Uninstalled.ReturnValue -eq 3010)
					{
						Write-Verbose "Restart Required for $($java.name)"
						$needrestart = $true
					}
					Write-Verbose "$($java.name) return code is $($Uninstalled.ReturnValue)"
				}
			}
		}
	}
	End
	{
		if ($Restart -eq $true -and ($needrestart -eq $true -or $PSBoundParameters['Debug'] -eq $true))
		{
			Write-Verbose "Restarting Computer"
			Restart-Computer -Force -AsJob -Confirm:$false -Verbose:$PSBoundParameters['Verbose'] -Debug:$PSBoundParameters['Debug']
		}
		elseif ($needrestart -eq $true)
		{
			Write-Host "Restart Required"
		}
		Write-Verbose "Uninstall-Java Complete $(Get-Date)"
    }
}
Export-ModuleMember -Function Uninstall-Java