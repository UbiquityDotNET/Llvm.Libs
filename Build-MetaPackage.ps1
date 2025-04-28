using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Builds the Meta package for the runtime libraries AND the handle source

.PARAMETER buildInfo
    Optional hashtable of build information already created (Used by local loop Build-all script)

.PARAMETER FullInit
    Performs a full initialization. A full initialization includes forcing a re-capture of the time stamp for local builds
    as well as writes details of the initialization to the information and verbose streams.
#>
Param(
    [hashtable]$buildInfo,
    [switch]$FullInit
)

Push-location $PSScriptRoot
$oldPath = $env:Path
try
{
    if(!$buildInfo)
    {
        $buildInfo = Initialize-BuildEnvironment -FullInit:$FullInit
    }

    # Build the meta package
    Invoke-external dotnet pack (Join-Path $buildInfo['SrcRootPath'] 'Ubiquity.NET.LibLLVM' 'Ubiquity.NET.LibLLVM.csproj')
}
catch
{
    # Everything from the official docs to the various articles in the blog-sphere says this isn't needed
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
