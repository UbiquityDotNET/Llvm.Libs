# Repository neutral common build support utilities
function global:Update-Submodules
{
    Write-Information "Updating submodules"
    git submodule -q update --init --recursive
}

function global:Find-OnPath
{
    [CmdletBinding()]
    Param( [Parameter(Mandatory=$True,Position=0)][string]$exeName)
    $path = $null
    Write-Information "Searching for $exeName..."
    try
    {
        $path = where.exe $exeName 2>$null | select -First 1
    }
    catch
    {}
    if($path)
    {
        Write-Information "Found $exeName at: '$path'"
    }
    return $path
}

function Find-Python
{
    # Find/Install Python
    $pythonExe = Find-OnPath 'python.exe'
    $foundOnPath = $false
    if($pythonExe)
    {
        $pythonPath = [System.IO.Path]::GetDirectoryName($pythonExe)
        $foundOnPath = $true
    }
    else
    {
        # try registry location(s) see [PEP-514](https://www.python.org/dev/peps/pep-0514/)
        if( Test-Path -PathType Container HKCU:Software\Python\*\2.7\InstallPath )
        {
            $pythonPath = dir HKCU:\Software\Python\*\2.7\InstallPath | ?{ Test-Path -PathType Leaf (Join-Path ($_.GetValue($null)) 'python.exe') } | %{ $_.GetValue($null) } | select -First 1
        }
        elseif( Test-Path -PathType Container HKLM:Software\Python\*\2.7\InstallPath )
        {
            $pythonPath = dir HKLM:\Software\Python\*\2.7\InstallPath | ?{ Test-Path -PathType Leaf (Join-Path ($_.GetValue($null)) 'python.exe') } | %{ $_.GetValue($null) } | select -First 1
        }
        elseif ( Test-Path -PathType Container HKLM:Software\Wow6432Node\Python\*\2.7\InstallPath )
        {
            $pythonPath = dir HKLM:\Software\Wow6432Node\Python\*\2.7\InstallPath | ?{ Test-Path -PathType Leaf (Join-Path ($_.GetValue($null)) 'python.exe') } | %{ $_.GetValue($null) } | select -First 1
        }

        if( !$pythonPath )
        {
            return $null
        }
        $pythonExe = Join-Path $pythonPath 'python.exe'
    }

    return @{ FullPath = $pythonExe
              BinPath = $pythonPath
              FoundOnPath = $foundOnPath
            }
}

function Install-Python
{
    param([string]$PythonPath = (Join-Path (Get-ToolsPath) 'Python27'))

    # Download installer from official Python release location
    $msiPath = (Join-Path (Get-ToolsPath) 'python-2.7.13.msi')
    Write-Information 'Downloading Python'
    Invoke-WebRequest -UseBasicParsing -Uri https://www.python.org/ftp/python/2.7.13/python-2.7.13.msi -OutFile $msiPath

    Write-Information 'Installing Python'
    msiexec /i  $msiPath "TARGETDIR=$PythonPath" /qn | Out-Null
    return $PythonPath
}

function global:ConvertTo-NormalizedPath([string]$path )
{
    if(![System.IO.Path]::IsPathRooted($path))
    {
        $path = [System.IO.Path]::Combine((pwd).Path,$path)
    }

    $path = [System.IO.Path]::GetFullPath($path)
    if( !$path.EndsWith([System.IO.Path]::DirectorySeparatorChar) -and !$path.EndsWith([System.IO.Path]::AltDirectorySeparatorChar))
    {
        $path = $path + [System.IO.Path]::DirectorySeparatorChar
    }
    return $path
}

function global:ConvertTo-PropList([hashtable]$hashTable)
{
    return ( $hashTable.GetEnumerator() | %{ @{$true=$_.Key;$false= $_.Key + "=" + $_.Value }[[string]::IsNullOrEmpty($_.Value) ] } ) -join ';'
}

function global:Invoke-TimedBlock([string]$activity, [ScriptBlock]$block )
{
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Information "Starting: $activity"
    try
    {
        $block.Invoke()
    }
    finally
    {
        $timer.Stop()
        Write-Information "Finished: $activity - Time: $($timer.Elapsed.ToString())"
    }
}

<#
This is a workaround for https://github.com/PowerShell/PowerShell/issues/2736
#>
function global:Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json)
{
  $indent = 0;
  $srcLines = $json -Split "`n|`r`n|`r"

    foreach( $srcLine in $srcLines )
    {
        if ($srcLine -match '[\}\]]')
        {
            # This line contains  ] or }, decrement the indentation level
            $indent--
        }

        $line = (' ' * $indent * 2) + $srcLine.TrimStart().Replace(':  ', ': ')
        if ($srcLine -match '[\{\[]')
        {
            # This line contains [ or {, increment the indentation level
            $indent++
        }
        $line
    }
}

function global:Get-CmdEnvironment ($cmd, $Arguments)
{
    $retVal = @{}
    Write-Verbose "Running [`"$cmd`" $Arguments >nul & set] to get environment variables"
    $envOut =  cmd /c "`"$cmd`" $Arguments >nul & set"
    foreach( $line in $envOut )
    {
        $name, $value = $line.split('=');
        $retVal.Add($name, $value)
    }
    return $retVal
}

function global:Merge-Environment( [hashtable]$OtherEnv, [string[]]$IgnoreNames )
{
<#
.SYNOPSIS
    Merges the name value pairs of a hash table into the current environment

.PARAMETER OtherEnv
    Hash table containing name value pairs to add to the environment

.PARAMETER IgnoreNames
    Names of properties in OtherEnv to ignore
.NOTES
    Standard system variables are always ignored and are blocked from merging
#>
    $SystemVars = @('COMPUTERNAME',
                    'USERPROFILE',
                    'HOMEPATH',
                    'LOCALAPPDATA',
                    'PSModulePath',
                    'PROCESSOR_ARCHITECTURE',
                    'CommonProgramFiles(x86)',
                    'ProgramFiles(x86)',
                    'PROCESSOR_LEVEL',
                    'LOGONSERVER',
                    'SystemRoot',
                    'SESSIONNAME',
                    'ALLUSERSPROFILE',
                    'PUBLIC',
                    'APPDATA',
                    'PROCESSOR_REVISION',
                    'USERNAME',
                    'CommonProgramW6432',
                    'CommonProgramFiles',
                    'OS',
                    'USERDOMAIN_ROAMINGPROFILE',
                    'PROCESSOR_IDENTIFIER',
                    'ComSpec',
                    'SystemDrive',
                    'ProgramFiles',
                    'NUMBER_OF_PROCESSORS',
                    'ProgramData',
                    'ProgramW6432',
                    'windir',
                    'USERDOMAIN'
                   )
    $IgnoreNames += $SystemVars
    $otherEnv.GetEnumerator() | ?{ !($ignoreNames -icontains $_.Name) } | %{ Set-Item -Path "env:$($_.Name)" -value $_.Value; Write-Verbose "env:$($_.Name)=$($_.Value)" }
}

function global:Expand-ArchiveStream([Parameter(Mandatory=$true, ValueFromPipeLine)]$src, [Parameter(Mandatory=$true)]$OutputPath)
{
    $zipArchive = [System.IO.Compression.ZipArchive]::new($src)
    [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $zipArchive, $OutputPath)
}

function global:Download-AndExpand([Parameter(Mandatory=$true, ValueFromPipeLine)]$uri, [Parameter(Mandatory=$true)]$OutputPath)
{
    $strm = (Invoke-WebRequest -UseBasicParsing -Uri $uri).RawContentStream
    Expand-ArchiveStream $strm $OutputPath
}

# invokes NuGet.exe, handles downloading it to the script root if it isn't already on the path
function global:Invoke-NuGet
{
    $NuGetPaths = Find-OnPath NuGet.exe -ErrorAction Continue
    if( !$NuGetPaths )
    {
        $nugetToolsPath = "$($RepoInfo.ToolsPath)\NuGet.exe"
        if( !(Test-Path $nugetToolsPath))
        {
            # Download it from official NuGet release location
            Write-Verbose "Downloading Nuget.exe to $nugetToolsPath"
            Invoke-WebRequest -UseBasicParsing -Uri https://dist.NuGet.org/win-x86-commandline/latest/NuGet.exe -OutFile $nugetToolsPath
        }
    }
    Write-Information "NuGet $args"
    NuGet $args
    $err = $LASTEXITCODE
    if($err -ne 0)
    {
        throw "Error running NuGet: $err"
    }
}

function global:Get-GitHubReleases($org, $project)
{
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$org/$project/releases"
    foreach($r in $releases)
    {
        $r
    }
}

function global:Get-GitHubTaggedRelease($org, $project, $tag)
{
    Get-GithubReleases $org $project | ?{$_.tag_name -eq $tag}
}

# use VS provided PS Module to locate VS installed instances
function global:Find-VSInstance([switch]$PreRelease, [switch]$Force, $Version = '[15.0, 17.0)')
{
    if ($IsLinux -or $IsMacOS)
    {
        $null
    }
    else
    {
        $requiredComponents = 'Microsoft.Component.MSBuild',
                              'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
                              'Microsoft.VisualStudio.Component.VC.CMake.Project'

        $existingModule = Get-InstalledModule -ErrorAction SilentlyContinue VSSetup
        if(!$existingModule)
        {
        Write-Information "Installing VSSetup module"
        Install-Module VSSetup -Scope CurrentUser -Force:$Force | Out-Null
        }

        Get-VSSetupInstance -Prerelease:$PreRelease |
        Select-VSSetupInstance -Version $Version -Require $requiredComponents |
        Select-Object -First 1
    }
}

function global:Find-MSBuild
{
    $foundOnPath = $true
    $msBuildPath = Find-OnPath msbuild.exe -ErrorAction Continue
    $foundOnPath = !!$msbuildPath
    if( !$foundOnPath )
    {
        Write-Verbose "MSBuild not found on path, using RepoInfo.VsInstance to find it"
        $vsInstall = $RepoInfo.VsInstance
        if( !$vsInstall )
        {
            throw "MSBuild not found on PATH and No instances of VS found to use"
        }

        Write-Information "VS installation found: $($vsInstall.InstallationPath)"
        $msBuildVerPath = [System.IO.Path]::Combine( $vsInstall.InstallationPath, 'MSBuild', '15.0', 'bin', 'MSBuild.exe')
        $msbuildCurrPath = [System.IO.Path]::Combine( $vsInstall.InstallationPath, 'MSBuild', 'Current', 'bin', 'MSBuild.exe')
        if( (Test-Path -PathType Leaf $msBuildVerPath ) )
        {
            $msBuildPath = $msBuildVerPath
        }
        else
        {
            if( (Test-Path -PathType Leaf $msBuildCurrPath) )
            {
                $msBuildPath = $msBuildCurrPath
            }
        }
    }

    if(!$msBuildPath -or !(Test-Path -PathType Leaf $msBuildPath ) )
    {
        Write-Verbose 'MSBuild not found'
        return $null
    }

    Write-Verbose "MSBuild Found at: $msBuildPath"
    return @{ FullPath=$msBuildPath
              BinPath=[System.IO.Path]::GetDirectoryName( $msBuildPath )
              FoundOnPath=$foundOnPath
            }
}

function global:Invoke-MSBuild([string]$project, [hashtable]$properties, [string[]]$targets, [string[]]$loggerArgs=@(), [string[]]$additionalArgs=@())
{
    $msbuildArgs = @($project, "/nr:false") + @("/t:$($targets -join ';')") + $loggerArgs + $additionalArgs
    if( $properties )
    {
        $msbuildArgs += @( "/p:$(ConvertTo-PropertyList $properties)" )
    }

    Write-Information "msbuild $($msbuildArgs -join ' ')"
    msbuild $msbuildArgs
    if($LASTEXITCODE -ne 0)
    {
        throw "Error running msbuild: $LASTEXITCODE"
    }
}

function global:Initialize-VCVars([switch]$Force, $vsInstance = ($RepoInfo.VsInstance))
{
    if($vsInstance)
    {
        $vcEnv = Get-CmdEnvironment (Join-Path $vsInstance.InstallationPath 'VC\Auxiliary\Build\vcvarsall.bat') 'x86_amd64'
        Merge-Environment $vcEnv @('Prompt')
    }
    else
    {
        Write-Error "VisualStudio instance not found"
    }
}

