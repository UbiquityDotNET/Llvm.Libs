function Initialize-BuildEnvironment
{
<#
.SYNOPSIS
    Initializes the build environment for the build scripts

.PARAMETER FullInit
    Performs a full initialization. A full initialization includes forcing a re-capture of the time stamp for local builds
    as well as writes details of the initialization to the information and verbose streams.

.DESCRIPTION
    This script is used to initialize the build environment in a central place, it returns the
    build info Hashtable with properties determined for the build. Script code should use these
    properties instead of any environment variables. While this script does setup some environment
    variables for non-script tools (i.e., MSBuild) script code should not rely on those.

    This script will setup the PATH environment variable to contain the path to MSBuild so it is
    readily available for all subsequent script code.

    Environment variables set for non-script tools:

    | Name               | Description |
    |--------------------|-------------|
    | IsAutomatedBuild   | "true" if in an automated build environment "false" for local developer builds |
    | IsPullRequestBuild | "true" if this is a build from an untrusted pull request (limited build, no publish etc...) |
    | IsReleaseBuild     | "true" if this is an official release build |
    | CiBuildName        | Name of the build for Constrained Semantic Version construction |
    | BuildTime          | ISO-8601 formatted time stamp for the build (local builds are based on current time, automated builds use the time from the HEAD commit)

    The Hashtable returned from this function includes all the values retrieved from
    the common build function Initialize-CommonBuildEnvironment plus additional repository specific
    values. In essence, the result is like a derived type from the common base. The
    additional properties added are:

    | Name                       | Description                                                                                            |
    |----------------------------|--------------------------------------------------------------------------------------------------------|
    | OfficialGitRemoteUrl       | GIT Remote URL for ***this*** repository                                                               |
    | LlvmProject                | Root of the cloned LLVM project                                                                        |
    | LlvmRoot                   | Root folder of the LLVM source code (subdir of LlvmProject)                                            |
    | LlvmVersion                | Hash Table containing Version of LLVM expected by this project                                         |
    | LlvmTag                    | LLVM GitHub project tag for cloning                                                                    |
#>
    # support common parameters
    [cmdletbinding()]
    [OutputType([hashtable])]
    Param(
        $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..' '..' '..')),
        [switch]$FullInit
    )

    # use common repo-neutral function to perform most of the initialization
    $buildInfo = Initialize-CommonBuildEnvironment $repoRoot -FullInit:$FullInit
    if($IsWindows -and !(Find-OnPath cmake))
    {
        Write-Information "Adding CMAKE to PATH"
        $env:PATH += ";$(vswhere -find **\cmake.exe | split-path -parent)"
    }

    if(!(Find-OnPath cmake))
    {
        throw "CMAKE not found!"
    }

    if($IsWindows -and !(Find-OnPath MSBuild))
    {
        Write-Information "Adding MSBUILD to PATH"
        $env:PATH += ";$(vswhere -find MSBuild\Current\Bin\MSBuild.exe | split-path -parent)"
    }

    if(!(Find-OnPath MSBuild))
    {
        throw "MSBuild not found - currently required for LIBLLVM builds"
    }

    # Add repo specific values
    $buildInfo['OfficialGitRemoteUrl'] = 'https://github.com/UbiquityDotNET/Llvm.Libs.git'
    $buildInfo['LlvmProject'] = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..' '..' '..' 'llvm-project'))
    $buildInfo['LlvmRoot'] = Join-Path $buildInfo['LlvmProject'] 'llvm'

    # This is the ONE place where the expectations of the LLVM version are set.
    $buildInfo['LlvmVersion'] = @{
        Major = 20
        Minor = 1
        Patch = 1
    }

    $buildInfo['LlvmTag'] = "llvmorg-$(Get-LlvmVersionString $buildInfo)"

    if($FullInit)
    {
        Write-Host (Show-FullBuildInfo $buildInfo | out-string)
    }

    return $buildInfo
}
