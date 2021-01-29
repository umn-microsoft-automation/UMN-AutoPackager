function Get-NewPackageFile {
<#
    .SYNOPSIS
    Cmdlet that downloads a file from a web server or file share and saves it to the specified location.
    .DESCRIPTION
    Get-NewPackageFile is a function that when provided with a Source file path, UNC, or URI (as a string)
    and a Destination path or UNC (as a string) will copy or download the Source file to the Destination.
    Characters of a space (" ") or an 'escaped' space ("%20") are replaced with an underscore ("_") when
    saved to the Destination. Returns object information of the saved file.
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
    .OUTPUTS
    System.IO.FileInfo
    Get-NewPackageFile returns information on the file saved in the Destination.
    .NOTES
    If the Destination parameter is only a file path and does not include a filename, the filename obtained from
    the Source parameter is used during the copy. Requires use of the "Get-RedirectedUri" function.
#>
    
    [CmdletBinding()]
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
            #   Work with Source input
            $SourceScheme = ([System.Uri]$Source).Scheme
            if ($SourceScheme -match "file") {
                #   Do File stuff
                Write-Verbose -Message "Source scheme is file"
                # If file does not exist, error
                if (Test-Path -LiteralPath $Source -PathType Leaf) {
                    # Put the full Source and filename into variables for use later
                    $FullSource = $Source
                    $SourceFile = Split-Path -Path $Source -Leaf

                } else {
                    throw "Source is a directory or file does not exist: $Source"
                }
            } elseif ($SourceScheme -match "http") {
                #   Do HTTP(S) stuff
                Write-Verbose -Message "Source scheme is http(s)"
                # Get the redirected URL of the Source so the file can be downloaded
                $FullSource = Get-RedirectedURI -URI $Source
                # Get the unescaped Source filename from the URL
                $URIFile = Split-Path $FullSource -Leaf
                $UnescapedFile = [System.Uri]::UnescapeDataString($URIFile)
                # Replace any space charaters with underscores
                $SourceFile = $UnescapedFile.Replace("%20","_").Replace(" ","_")
            } else {
                throw "Invalid Source path type: $SourceScheme. Must be type: file, http, or https."
            }
            Write-Verbose -Message "Source filename: $SourceFile"

            #   Work with Destination input
            $DestinationScheme = ([System.Uri]$Destination).Scheme
            if ($DestinationScheme -match "file") {
                # Do Destination stuff
                Write-Verbose -Message "Destination scheme is file"
                if ($null -eq [IO.Path]::GetExtension($Destination) -or "" -eq [IO.Path]::GetExtension($Destination)) {
                    # Filename not present in Destination, use filename from Source
                    $DestinationPath = $Destination
                    if ($DestinationPath.Substring($DestinationPath.Length-1) -eq "\") {
                        # Last character of Source input is a backslash, no need to add it to the full destination
                        $FullDestination = "$Destination" + "$SourceFile"
                    } else {
                        # Last character of Source input is not a backslash, add one to the full destination
                        $FullDestination = "$Destination" + "\" + "$SourceFile"
                    }
                } else {
                    # Filename present in Destination
                    # Put the Destination path into svariable for possible use later
                    $DestinationPath = Split-Path -Path $Destination
                    $FullDestination = $Destination
                }
            } else {
                throw "Invalid Destination path type: $DestinationScheme; must be type: file."
            }

            #   If Destination path doesn't exist, create it
            if (-not(Test-Path -LiteralPath $DestinationPath -PathType Container)) {
                Write-Verbose -Message "Creating Destination directory: $DestinationPath"
                [void](New-Item -Path $DestinationPath -ItemType Directory -Force)
            }

            #   Copy or download file to destination
            Write-Verbose -Message "Saving $FullSource to $FullDestination"
            if ($SourceScheme -match "file") {
                # Copy file from Source to Destination
                Copy-Item -Path $FullSource -Destination $FullDestination -Force
            }
            if ($SourceScheme -match "http") {
                # Download file from Source to Destination
                Invoke-WebRequest -Uri $FullSource -OutFile $FullDestination
            }

            # Return object information on saved file
            Get-ChildItem -Path $FullDestination

        } catch {
            throw $_
        }
    }

}