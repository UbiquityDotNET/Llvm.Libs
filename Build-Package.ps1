using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Builds the Final Nuget pacakge that contains all platform libraries and the generated source code

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

    # Download and unpack the LLVM source from the versioned release tag if not already present
    Clone-LlvmFromTag $buildInfo

    # Build and Run source generator as it is needed to create the handle type source code in the package
    $extensionsRoot = Join-Path $buildInfo['SrcRootPath'] 'LibLLVM'
    $generatorOptions = @{
        LlvmRoot = $buildInfo['LlvmRoot']
        ExtensionsRoot = $extensionsRoot
        HandleOutputPath = Join-Path $buildInfo['BuildOutputPath'] 'GeneratedCode'
        ConfigFile = Join-Path $buildInfo['SrcRootPath'] 'LlvmBindingsGenerator' 'bindingsConfig.yml'
    }

    # run the generator so the generated handle source output is available to the pack
    Invoke-BindingsGenerator $buildInfo $generatorOptions

    # TODO: Need to build the sources as a distinct package AND each RID gets a "meta" package to
    # reference each of the target packages (each one is created distinct to allow posting
    # to NuGet service etc... Otherwise it's too big!)

    # Build Package For the generated source handles AND the per RID meta package
    # TODO: Split this out as the handles are NOT per-rid, they are a one time thing
    Invoke-external dotnet pack (Join-Path $buildInfo['SrcRootPath'] 'Ubiquity.NET.Llvm.Interop.Handles' 'Ubiquity.NET.Llvm.Interop.Handles.csproj')
    Invoke-external dotnet pack (Join-Path $buildInfo['SrcRootPath'] 'LibLLVMNugetMetaPackage' 'LibLLVMNugetMetaPackage.csproj')
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
