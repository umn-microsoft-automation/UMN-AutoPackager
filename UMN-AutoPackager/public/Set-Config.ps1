# Set-Config -Path .\config.json -Object ConfigMgr -Name SiteCode  -Value "UMN"
# Set-Config -Path .\config.json -Name Company  -Value "University of Minnesota"
# (Get-CMSite).SiteCode | Set-Config -Path .\config.json -Object ConfigMgr  -Name SiteCode
function Set-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand) Updating $key with $value"
    }
    process {
        $json = Get-Content $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        foreach ($k in $Keys) {
            Write-Verbose -Message "Querying $k"
            if ($config.$k.gettype().Name -eq 'String') {
                Write-Verbose "$k is a string"
                if ($k -eq $Key) {
                    Write-Verbose "Found match $k setting new value"
                    $config.$k = $Value
                    $config.LastModified = (Get-Date).ToString()
                    $config | convertto-json | Set-Content $path
                    Write-Verbose -Message "$key is updated with $value"
                }
            }
            if ($config.$k.gettype().Name -eq "Object[]") {
               Write-Verbose "$k is Array"
               if ($k -eq $Key) {
                   Write-Verbose "Found match for $k"
                   if ($config.$k -contains $value) {
                       Write-Verbose -Message "Already contains $value"
                   }
                   else {
                    [System.collections.ArrayList]$new = $config.$k
                    $new.add("$value") > $null
                    $config.$k = $new
                    $config.LastModified = (Get-Date).ToString()
                    $config | convertto-json | Set-Content $path
                    Write-Verbose -Message "$key is updated with $value"
                   }
               }
            }
        } #foreach $key
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Get-Config
Set-Config -Path C:\Users\thoen008\Desktop\GlobalConfig.json -Key "RecipeLocations" -Value "\\somewhere.new4" -Verbose
