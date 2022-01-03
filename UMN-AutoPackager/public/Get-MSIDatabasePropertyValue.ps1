<#
    .SYNOPSIS
        Obtains the value for a property from an MSI database.
    .DESCRIPTION
        Given a path to an MSI and a property name (will default to ProductCode) it will return the value of that property.
    .EXAMPLE
        PS C:\> Get-MSIDatabaseProperty -Path \path\to\msi.msi
        This will return the product code for the given MSI
    .EXAMPLE
        PS C:\> Get-MSIDatabaseProperty -Path \path\to\msi.msi -Property UpgradeCode
        This will return the upgrade code from the MSI
    .PARAMETER Path
        The full path to the MSI, will check to ensure the file extension is MSI.
    .PARAMETER Property
        The property to pull the value of from the database.  This will default to ProductCode.
#>
function Get-MSIDatabasePropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Path to MSI, file extension will be validated and must be .msi"
        )]
        [ValidateScript( {
                if ([IO.Path]::GetExtension($_) -eq ".msi") {
                    Write-Output $true
                }
                else {
                    Write-Output $false
                }
            })]
        [string]$Path,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "The property to obtain the value from.  This will default to ProductCode."
        )]
        [string]$Property = "ProductCode"
    )

    Process { 
        try { 

            if ($Path.StartsWith('\\')) {
                # Get filename
                $MSIFilename = Split-path -Path $Path -Leaf

                Write-Information "MSI is on network share, need to copy to $($env:temp) to get product code"
                Copy-Item -Path $Path -Destination "$($env:temp)\$MSIFilename" -Force
                $MSIPath = "$($env:temp)\$MSIFilename"
            }
            else {
                $MSIPath = $Path
            }

            # Read property from MSI database 
            $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
            
            # Opens the database as read-only (0)
            $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($MSIPath, 0)) 
            
            $MSIQuery = "SELECT Value FROM Property WHERE Property = '$Property'" 
            
            $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($MSIQuery)) 
            
            $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null) 
            
            $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null) 
            
            $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1) 
            # Commit database and close view 
            $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null) 
            $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null) 
            $MSIDatabase = $null 
            $View = $null 
            # Return the value 
            return $Value 
        }
        catch { 
            Write-Warning -Message $_.Exception.Message ; break 
        } 
    } End { 
        # Run garbage collection and release ComObject 
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null 
        [System.GC]::Collect()
    }
}
