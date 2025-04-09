using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Builds just the source code to produce the binaries and NUGET packages for the Ubiquity.NET.Llvm libraries

.PARAMETER Configuration
    This sets the build configuration to use, default is "Release" though for inner loop development this may be set to "Debug"

.PARAMETER FullInit
    Performs a full initialization. A full initialization includes forcing a re-capture of the time stamp for local builds
    as well as writes details of the initialization to the information and verbose streams.
#>
Param(
    [string]$Configuration="Release",
    [switch]$FullInit,
    [switch]$ZipNuget
)

Push-Location $PSScriptRoot
$oldPath = $env:Path
try
{
    # Normally FullInit is done in Build-All, which calls this
    # script. But for a local "inner loop" development this might be the only script used.
    $buildInfo = Initialize-BuildEnvironment -FullInit:$FullInit

    # TODO: Re-consider this. Experiments with building NUGET containing only the generated
    # handle source and the variations of the native LibLLVM library are promising. This
    # would allow a distinct package to cover ONLY the native code portion of the build
    # and all other layers come from a single managed solution.

    # build the Managed code support, including the final NUGET output
    $solutionPath = Join-Path 'src' 'interop.slnx'
    Write-Information "dotnet build $solutionPath -c $Configuration -p:`"LlvmVersion=$($buildInfo['LlvmVersion'])`""
    # NOTE: '-c' is quoted due to various parsing issues with parameters [see](https://github.com/PowerShell/PowerShell/issues?q=is%3Aissue+in%3Atitle+argument-parsing)
    Invoke-External dotnet build $solutionPath '-c' $Configuration -p:"LlvmVersion=$($buildInfo['LlvmVersion'])"

    # Create a ZIP file of all the nuget packages if asked.
    # This is used on PR builds to allow for access to the built NUGET package as a build artifact.
    # There is currently no support for a pre-release nuget server.
    if($ZipNuget)
    {
        Set-Location $buildInfo['NuGetOutputPath']
        Compress-Archive -Force -Path *.* -DestinationPath (join-path $buildInfo['BuildOutputPath'] Nuget.Packages.zip)
    }
}
catch
{
    # Everything from the official docs to the various articles in the blog-sphere say this isn't needed
    # and in fact it is redundant - They're all WRONG! By re-throwing the exception the original location
    # information is retained and the error reported will include the correct source file and line number
    # data for the error. Without this, only the error message is retained and the location information is
    # Line 1, Column 1, of the outer most script file, which is, of course, completely useless.
    throw
}
finally
{
    Pop-Location
    $env:Path = $oldPath
}
