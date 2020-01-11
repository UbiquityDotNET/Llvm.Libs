# use VS provided PS Module to locate VS installed instances
function Find-VSInstance([switch]$PreRelease, [switch]$Force)
{
    $requiredComponents = 'Microsoft.Component.MSBuild', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', 'Microsoft.VisualStudio.Component.VC.CMake.Project'
    Install-Module VSSetup -Scope CurrentUser -Force:$Force | Out-Null
    Get-VSSetupInstance -Prerelease:$PreRelease |
        Select-VSSetupInstance -Version  '[15.0,16.0)' -Require $requiredComponents |
        select -First 1
}

function Find-MSBuild
{
    $foundOnPath = $true
    $msBuildPath = Find-OnPath msbuild.exe -ErrorAction Continue
    $foundOnPath = !!$msbuildPath
    if( !$foundOnPath )
    {
        Write-Information "MSBuild not found on path attempting to locate VS installation"
        $vsInstall = Find-VSInstance
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
Export-ModuleMember -Function Find-MSBuild

function Invoke-MSBuild([string]$project, [hashtable]$properties, [string[]]$targets, [string[]]$loggerArgs=@(), [string[]]$additionalArgs=@())
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
Export-ModuleMember -Function Invoke-MSBuild

function Initialize-VCVars([switch]$Force, $vsInstance = (Find-VSInstance -Force:$Force))
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
