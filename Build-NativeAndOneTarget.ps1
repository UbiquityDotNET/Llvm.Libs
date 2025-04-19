using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Builds the native code Extended LLVM C API DLL for a target

.PARAMETER Configuration
    This sets the build configuration to use, default is "Release" though for inner loop development this may be set to "Debug"

.PARAMETER AdditionalTarget
    Specifies the one target (besides the native target for the runtime of the current build).

.PARAMETER FullInit
    Performs a full initialization. A full initialization includes forcing a re-capture of the time stamp for local builds
    as well as writes details of the initialization to the information and verbose streams.

.NOTE
This script is unfortunately necessary due to several factors:
  1. SDK projects cannot reference VCXPROJ files correctly since they are multi-targeting
     and VCXproj projects are not
  2. packages.config NUGET is hostile to shared version control as it insists on placing full
     paths to the NuGet dependencies and build artifacts into the project file. (e.g. adding a
     NuGet dependency modifies the project file to inject hard coded FULL paths guaranteed to
     fail on any version controlled project when built on any other machine)
  3. Packing the final NugetPackage needs the output of the native code project AND that of
     the managed interop library. But as stated in #1 there can't be a dependency so something
     has to manage the build ordering independent of the multi-targeting.

  The solution to all of the above is a combination of elements
  1. The LlvmBindingsGenerator is an SDK project. And generally independent of the native
     code bits (State of the LLVM libs build is not relevant to this project; It only needs
     the source code [headers really] as the input)
  2. This script to control the ordering of the build so that the native code is built, then the
     interop lib is restored and finally the interop lib is built with multi-targeting.
  3. The interop assembly project includes the NuGet packing with "content" references to the
     native assemblies to place the binaries in the correct "native" "runtimes" folder for NuGet
     to handle them.
#>
Param(
    [ValidateSet("AArch64", "AMDGPU", "ARM", "AVR", "BPF", "Hexagon", "Lanai", "LoongArch", "Mips", "MSP430", "NVPTX", "PowerPC", "RISCV", "Sparc", "SPIRV", "SystemZ", "VE", "WebAssembly", "X86", "XCore")]
    $AdditionalTarget,
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

    if ([string]::IsNullOrWhiteSpace($AdditionalTarget))
    {
        throw "The AdditionalTarget parameter is required and cannot be null, empty, or all whitespace."
    }

    $AddtionalTarget = [LlvmTarget]$AdditionalTarget
    $currentRid = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier

    #inner loop optimization (shaves ~15s off build if already done)
    if(!$SkipLLvm)
    {
        # Download and unpack the LLVM source from the versioned release tag if not already present
        Clone-LlvmFromTag $buildInfo

        # Always double check the source version matches expectations, this catches a bump in the script version
        # but no download as the previous version is still there. (Mostly a local build problem but a major time
        # waster if forgotten. So, test it here as early as possible.)
        Assert-LlvmSourceVersion $buildInfo

        # Verify Cmake version info (Official minimum for LLVM as of 20.1.1)
        Assert-CmakeInfo ([Version]::new(3, 20, 0))

        $nativeTarget = Get-NativeTarget
        Invoke-TimedBlock "CMAKE generate/Build LLVM libs for '$currentRid'" {
            $cmakeConfig = New-LlvmCMakeConfig $currentRid $AdditionalTarget 'Release' $buildInfo
            Generate-CMakeConfig $cmakeConfig
            Build-CMakeConfig $cmakeConfig
        }
    }

    # On Windows Build and run source generator as it is needed by the windows Build to create the exports.g.def file
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


    # Build per target library
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

        # LibLlvm ONLY has a release configuration, the interop lib only ever references that.
        # The libraries are just too big to produce a Debug build with symbols etc...
        # Force a release build no matter what the "configuration" parameter is.
        $libLLvmBuildProps = @{ Configuration = 'Release'
                                LlvmVersion = Get-LlvmVersionString $buildInfo
                                LibLLVMNativeTarget = (Get-NativeTarget)
                                LibLLVMAdditionalTarget = $AdditionalTarget
                                RuntimeIdentifier = $currentRid
                              }
        $libLlvmBuildPropList = ConvertTo-PropertyList $libLLvmBuildProps

        Write-Information "Building LibLLVM"
        $libLLVMBinLogPath = Join-Path $buildInfo['BinLogsPath'] "LibLLVM-Build-$currentRid-$AdditionalTarget.binlog"
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
