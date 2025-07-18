using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Script to build all of the LLvm.NET Interop code base.

.PARAMETER Configuration
    This sets the build configuration to use, default is "Release" though for inner loop development this
    may be set to "Debug".

.PARAMETER ForceClean
    Forces a complete clean (Recursive delete of the build output)

.PARAMETER SkipLLVM
    Skips generate and build of LLVM libraries (Assumes already done once). This can dramatically
    improve the local loop for developer work. Most of the time is spent on the actual dynamic
    library or extensions. Once a LLVM build exists for a given version it is rarely needed again
    for local use.

.DESCRIPTION
    This script is NOT used by the automated build to perform the actual build. Instead this
    is used to automate local builds and validate stages before committing changes to the repo.
    It will serialize the build for the current RID and handles. (The automated build can run
    various stages in parallel, including each RID)

    The Ubiquity.NET family of projects all employ a PowerShell driven build that is generally
    divorced from the automated build infrastructure used. This is done for several reasons, but
    the most important ones are the ability to reproduce the build locally for inner development
    and for flexibility in selecting the actual back end. The back ends have changed a few times
    over the years and re-writing the entire build in terms of those back ends each time is a lot
    of wasted effort. Thus, the projects settled on PowerShell as the core automated build tooling
    and back-end specific support only needs to call out to the PowerShell scripts to perform work.
#>
[cmdletbinding()]
Param(
    [string]$Configuration="Release",
    [switch]$ForceClean,
    [switch]$SkipLLvm
)

Push-Location $PSScriptRoot
$oldPath = $env:Path
try
{

    # force a full initialization of all the environment as this is a top level build command.
    $buildInfo = Initialize-BuildEnvironment -FullInit
    if(!$buildInfo -or $buildInfo -isnot [hashtable])
    {
        throw "build scripts BUSTED; Got null buildinfo hashtable..."
    }

    if ($ForceClean -and $SkipLLvm)
    {
        throw "ForceClean and SkipLLvm are mutually exclusive, you cannot set both!"
    }

    if((Test-Path -PathType Container $buildInfo['BuildOutputPath']) -and $ForceClean )
    {
        Write-Information "Cleaning output folder from previous builds"
        Remove-Item -Recurse -Force $buildInfo['BuildOutputPath'] -ProgressAction SilentlyContinue | Out-Null
    }

    Write-Information "Building sources"
    # TODO: iterate over all supported runtimes. Current win-x64 is the only one supported
    #       Not really sure if that's even possible for local builds as it requires the RID
    #       of this session to match the intended build...
    # On an automated build these two steps can and do occur in parallel as there are no binary
    # dependencies between them.
    .\Build-LibLLVMAndPackage.ps1 $buildInfo -SkipLLvm:$SkipLLvm -Configuration $Configuration
    .\Build-HandlesPackage.ps1 $buildInfo
    .\Build-MetaPackage.ps1 $buildInfo
}
catch
{
    # everything from the official docs to the various articles in the blog-sphere says this isn't needed
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

Write-Information "Done build"
