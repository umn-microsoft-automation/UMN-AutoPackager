function Get-NewPackageFile {
<#
.SYNOPSIS
Cmdlet that downloads a file from a web server or file share and saves it to the specified location.
.DESCRIPTION
Get-NewPackageFile is a function that when provided with a Source file path, UNC, or URI (as a string)
and a Destination path or UNC (as a string) will copy or download the Source file to the Destination.
Characters of a space (" ") or an 'escaped' space ("%20") are replaced with an underscore ("_") when
saved to the Destination.
.PARAMETER Source
A string that must be a file path, UNC, or URI of the file to be saved to the Destination location.
.PARAMETER Destination
A string that must be a file path or UNC where the Source file will be saved.
.EXAMPLE
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "D:\Temp\File2.txt"
.EXAMPLE
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "D:\Temp\"
.EXAMPLE
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "\\fileserver\Temp\File1.txt"
.EXAMPLE
Get-NewPackageFile -Source "\\fileserver\Test\File1.txt" -Destination "D:\Temp\File1.txt"
.EXAMPLE
Get-NewPackageFile -Source "\\fileserver1\Test\File1.txt" -Destination "\\fileserver2\Temp\File1.txt"
.EXAMPLE
Get-NewPackageFile -Source "https://webserver.xyz/Test/File1.txt" -Destination "C:\Temp\File1.txt"
.EXAMPLE
Get-NewPackageFile -Source "https://webserver.xyz/Test/File1.txt" -Destination "\\fileserver\Temp\File1.txt"
.INPUTS
String
.NOTES
If the Destination parameter is only a file path and does not include a filename, the filename obtained from
the Source parameter is used during the copy. Requires use of the "Get-RedirectedUri" function.
#>
    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Enter a valid Source file path, UNC, or URI.")]
        [ValidateNotNullOrEmpty()]
        [string]$Source,

        [Parameter(Mandatory = $true,
            HelpMessage = "Enter a valid Destination file path or UNC.")]
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )

    process {
        try {
            Write-Verbose "Verbose output enabled"
            #   Work with Source input
            $SourceScheme = ([System.Uri]$Source).Scheme
            if ($SourceScheme -match "file") {
                #   Do File stuff
                Write-Verbose "Source scheme is file"
                # If file does not exist, error
                if (Test-Path -LiteralPath $Source -PathType Leaf) {
                    # Put the full Source and filename into variables for use later
                    $FullSource = $Source
                    Write-Verbose "Full Source: $FullSource"
                    $SourceFile = Split-Path -Path $Source -Leaf
                    Write-Verbose "Source filename: $SourceFile"
                } else {
                    throw "Source is a directory or file does not exist: $Source"
                }
                
            } elseif ($SourceScheme -match "http") {
                #   Do HTTP(S) stuff
                Write-Verbose "Source scheme is HTTP or HTTPS"
                # Get the redirected URL of the Source so the file can be downloaded
                $FullSource = Get-RedirectedURI -URI $Source
                Write-Verbose "Source is redirected to: $FullSource"
                # Get the unescaped Source filename from the URL
                $URIFile = Split-Path $FullSource -Leaf
                Write-Verbose "Source filename: $URIFile"
                $UnescapedFile = [System.Uri]::UnescapeDataString($URIFile)
                Write-Verbose "Unescaped Source filename: $UnescapedFile"
                # Replace any space charaters with underscores
                $SourceFile = $UnescapedFile.Replace("%20","_").Replace(" ","_")
                Write-Verbose "Using this filename to download: $SourceFile"
                
            } else {
                throw "Invalid Source path type: $SourceScheme. Must be type: file, http, or https."
            }

            #   Work with Destination input
            $DestinationScheme = ([System.Uri]$Destination).Scheme
            if ($DestinationScheme -match "file") {
                # Do Destination stuff
                Write-Verbose "Destination scheme is file"
                if ($null -eq [IO.Path]::GetExtension($Destination) -or "" -eq [IO.Path]::GetExtension($Destination)) {
                    # Filename not present in Destination, use filename from Source
                    Write-Verbose "Filename not present in Destination, using Source filename"
                    $DestinationPath = $Destination
                    if ($DestinationPath.Substring($DestinationPath.Length-1) -eq "\") {
                        # Last character of Source input is a backslash, no need to add it to the full destination
                        $FullDestination = "$Destination" + "$SourceFile"
                    } else {
                        # Last character of Source input is not a backslash, add one to the full destination
                        $FullDestination = "$Destination" + "\" + "$SourceFile"
                    }
                    Write-Verbose "Full Destination path and filename: $FullDestination "
                } else {
                    # Filename present in Destination
                    # Put the Destination path into svariable for possible use later
                    Write-Verbose "Filename present in Destination"
                    $DestinationPath = Split-Path -Path $Destination
                    $FullDestination = $Destination
                    Write-Verbose "Full Destination path and filename: $FullDestination "
                }
            } else {
                throw "Invalid Destination path type: $DestinationScheme; must be type: file."
            }

            #   If Destination path doesn't exist, create it
            if (-not(Test-Path -LiteralPath $DestinationPath -PathType Container)) {
                Write-Verbose "Creating Destination directory: $DestinationPath"
                [void](New-Item -Path $DestinationPath -ItemType Directory -Force)
            }

            #   Copy or download file to destination
            if ($SourceScheme -match "file") {
                # Copy file from Source to Destination
                Write-Verbose "Copying $FullSource to $FullDestination"
                Copy-Item -Path $FullSource -Destination $FullDestination -Force
            }
            if ($SourceScheme -match "http") {
                # Download file from Source to Destination
                Write-Verbose "Downloading $FullSource to $FullDestination"
                Invoke-WebRequest -Uri $FullSource -OutFile $FullDestination
            }
            Write-Verbose "Done."

        } catch {
            throw $_
        }
    }

}


