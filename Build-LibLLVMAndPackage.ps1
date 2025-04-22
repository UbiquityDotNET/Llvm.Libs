using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Builds the native code Extended LLVM C API DLL for the current RID.

.PARAMETER Configuration
    This sets the build configuration to use, default is "Release" though for inner loop development this may be set to "Debug"

.PARAMETER FullInit
    Performs a full initialization. A full initialization includes forcing a re-capture of the time stamp for local builds
    as well as writes details of the initialization to the information and verbose streams.

.DESCRIPTION
    This builds the per RID Nuget library and NUGET package to indlcude it. The FullInit is important for local builds as
    it alters the version number used in naming and generation. Thus if only building some parts it is usefull for local
    builds not to set this. For an automated build it shoud always be set to force use of the commit of the repo as an ID
    for the build. In such cases the timestamp of the HEAD of the commit for the branch/PR is used so a consistent version
    is used for ALL builds of the same source - even across multiple runners operating in parallel.
#>
Param(
    [hashtable]$buildInfo,
    [ValidateSet('Release','Debug')]
    [string]$Configuration="Release",
    [switch]$FullInit,
    [switch]$SkipLLvm
)

Push-location $PSScriptRoot

$oldPath = $env:Path
try
{
    if(!$buildInfo)
    {
        $buildInfo = Initialize-BuildEnvironment -FullInit:$FullInit
    }

    $currentRid = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier

    # inner loop optimization (shaves time off build if already done)
    # Most common inner loop work is with the extended API and final DLL
    # not with LLVM itself, so this keeps the loop short.
    if(!$SkipLLvm)
    {
        # Download and unpack the LLVM source from the versioned release tag if not already present
        Clone-LlvmFromTag $buildInfo

        # Always double check the source version matches expectations, this catches a bump in the script version
        # but no download as the previous version is still there. (Mostly a local build problem but a major time
        # waster if forgotten. So, test it here as early as possible.)
        Assert-LlvmSourceVersion $buildInfo

        # Verify Cmake version info (Official minimum for LLVM as of 20.1.3)
        Assert-CmakeInfo ([Version]::new(3, 20, 0))

        $cmakeConfig = New-LlvmCMakeConfig -AllTargets -Name $currentRid -BuildConfig $Configuration -BuildInfo $buildInfo
        Generate-CMakeConfig $cmakeConfig
        Build-CmakeConfig $cmakeConfig @('lib/all')

        # Notify size of build ouput directory as that's a BIG player in total space used in an
        # automated build sceanrio. (OSS build systems often limit space so it's important to know)
        $postBuildSize = Get-ChildItem -Recurse $cmakeConfig['BuildRoot'] | Measure-Object -Property Length -sum | %{[math]::round($_.Sum /1Gb, 3)}
        Write-Information "Post Build Size: $($preDeleteSize)Gb"
    }

    # On Windows Build and run source generator as the generated exports.g.def is needed by the windows
    # version of the DLL
    if ($IsWindows)
    {
        $extensionsRoot = Join-Path $buildInfo['SrcRootPath'] 'LibLLVM'
        $generatorOptions = @{
            LlvmRoot = $buildInfo['LlvmRoot']
            ExtensionsRoot = $extensionsRoot
            ExportsDefFilePath = Join-Path $extensionsRoot 'exports.g.def'
            ConfigFile = Join-Path $buildInfo['SrcRootPath'] 'LlvmBindingsGenerator' 'bindingsConfig.yml'
        }

        # run the generator so the output is available to the DLL generation
        Invoke-BindingsGenerator $buildInfo $generatorOptions
    }

    # Build the per target LIBLLVM library (Also per rid)
    # NOTE: building a dynamic library exporting C++ is NOT an option. Despite the problems of
    # C++ not providing a stable binary ABI (even for the same vendor compiler across multiple versions)
    # there is the problem in generating the DLL on Windows (see: https://github.com/llvm/llvm-project/issues/109483)
    # Thus, this ONLY deals with the stable C ABI exported by the LLVM-C API AND an extended API sepcific
    # to this repo. If the LLVM issue of building the DLL on Windows is ever resolved, this decision
    # is worth reconsidering. (There's still the lack of binary ABI but tool vendors go through a LOT not
    # to break things from version to version so isn't as big a deal as long as the same vendor is used.)
    #
    # For now the DLL ONLY builds for Windows using MSBUILD (VCXPROJ);
    # TODO: Convert C++ code to CMAKE, this means leveraging CSmeVer build task as a standalone tool so
    # that the version Information is available to the scripts to provide to the build. (See docs generation
    # for the Ubiquity.NET.LLvm consuming project for an example of doing that so that the build versioning
    # is available to scripting) For now leave it on the legacy direct calls to MSBUILD...
    if ($IsWindows)
    {
        # now build the native DLL that consumes the generated output for the bindings

        # Need to invoke NuGet directly for restore of vcxproj as /t:Restore target doesn't support packages.config
        # and PackageReference isn't supported for native projects... [Sigh...]
        Write-Information "Restoring LibLLVM"
        $libLLVMVcxProj = Join-Path 'src' 'LibLLVM' 'LibLLVM.vcxproj'
        Invoke-External nuget restore $libLLVMVcxProj

        $libLLvmBuildProps = @{ Configuration = $Configuration
                                LlvmVersion = Get-LlvmVersionString $buildInfo
                                RuntimeIdentifier = $currentRid
                              }
        $libLlvmBuildPropList = ConvertTo-PropertyList $libLLvmBuildProps

        Write-Information "Building LibLLVM"
        $libLLVMBinLogPath = Join-Path $buildInfo['BinLogsPath'] "LibLLVM-Build-$currentRid.binlog"
        Invoke-external MSBuild '-t:Build' "-p:$libLlvmBuildPropList" "-bl:$libLLVMBinLogPath" '-v:m' $libLLVMVcxProj
    }

    # Build NuGetPackage for the target library
    Invoke-external dotnet pack (Join-Path $buildInfo['SrcRootPath'] 'LibLLVmNuget' 'LibLLVmNuget.csproj') "-p:$libLlvmBuildPropList"
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
