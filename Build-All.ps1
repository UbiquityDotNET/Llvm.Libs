using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Script to build all of the LLvm.NET Interop code base

.PARAMETER Configuration
    This sets the build configuration to use, default is "Release" though for inner loop development this
    may be set to "Debug".

.PARAMETER ForceClean
    Forces a complete clean (Recursive delete of the build output)

.DESCRIPTION
    This script is NOT used by the automated build to perform the actual build. Instead this
    is used to automate local builds and validate stages before commiting changes to the repo.
    The Ubiquity.NET family of projects all employ a PowerShell driven build that is generally
    divorced from the automated build infrastructure used. This is done for several reasons, but
    the most important ones are the ability to reproduce the build locally for inner development
    and for flexibility in selecting the actual back end. The back ends have changed a few times
    over the years and re-writing the entire build in terms of those back ends each time is a lot
    of wasted effort. Thus, the projects settled on PowerShell as the core automated build tooling
    and backend specific support only needs to call out to the powershell scripts to perform work.
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

    if((Test-Path -PathType Container $buildInfo['BuildOutputPath']) -and $ForceClean )
    {
        Write-Information "Cleaning output folder from previous builds"
        remove-Item -Recurse -Force -Path $buildInfo['BuildOutputPath'] -ProgressAction SilentlyContinue
    }

    New-Item -ItemType Directory $buildInfo['NuGetOutputPath'] -ErrorAction SilentlyContinue | Out-Null

    # run the matrix of targets for this run-time on this machine
    # NOTE: This will produce a VERY large output and will almost certainly fail
    #       to run in an automated build. This script is intended for use with local
    #       builds and will take a LONG time to run all of these as they must be
    #       done sequentially. (~40 mins per target * 19 targets == 12hrs of run time!)
    #       This is best done overnight after veryfying at least one target builds correctly
    # for tighter testing, this can be forced to only one target
    $targets = @([LlvmTarget]::ARM)
    #$targets = [enum]::GetValues([LlvmTarget])
    foreach($target in $targets)
    {
        .\Build-NativeAndOneTarget.ps1 $target $buildInfo -SkipLLvm:$SkipLLvm
    }

<#
Build final package:

        $generatorOptions = @{
            LlvmRoot = $buildInfo['LlvmRoot']
            ExtensionsRoot = Join-Path $buildInfo['SrcRootPath'] 'LibLLVM'
            HandleOutputPath = Join-Path $buildInfo['BuildOutputPath'] 'GeneratedCode'
            ConfigFile = Join-Path $buildInfo['SrcRootPath'] 'LlvmBindingsGenerator' 'bindingsConfig.yml'
        }

        # run the generator to get the generated handle source files for the final package
        Invoke-BindingsGenerator $buildInfo $generatorOptions
#>
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
