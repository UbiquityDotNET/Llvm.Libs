<#
.SYNOPSIS
    Project/Repo specific extensions to common support

.DESCRIPTION
    This provides repository specific functionality used by the various
    scripts. It will import the common repo neutral module such that this
    can be considered an extension of that module. It is expected that the
    various build scripts will "dot source" this one to consume common
    functionality.
#>

# reference the common build library. This library is intended
# for re-use across multiple repositories so should remain independent
# of the particular details of any specific repository. Over time, this
# may migrate to a git sub module for easier sharing between projects.
using module 'PSModules\CommonBuild\CommonBuild.psd1'

Set-StrictMode -version 3.0

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

function Get-LlvmVersion( [hashtable]$buildInfo )
{
    # Version information is set in a repo-wide CMAKE module
    $cmakeListPath = [System.IO.Path]::Combine($buildInfo['LlvmProject'], 'cmake', 'Modules', 'LLVMVersion.cmake')
    $props = @{}
    $matches = Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9]+)\)" |
        %{ $_.Matches } |
        %{ $props.Add( $_.Groups[1].Value, [Convert]::ToInt32($_.Groups[2].Value) ) }
    return $props
}

function Get-LlvmVersionString( [hashtable]$buildInfo )
{
    $llvmVersion = $buildInfo['LlvmVersion']
    return "$($llvmVersion.Major).$($llvmVersion.Minor).$($llvmVersion.Patch)"
}

function Clone-LlvmFromTag([hashtable]$buildInfo)
{
    if(!(Test-Path -PathType Container -Path $buildInfo['LlvmProject']))
    {
        Invoke-Git clone --depth 1 -b $buildInfo['LlvmTag'] 'https://github.com/llvm/llvm-project.git' $buildInfo['LlvmProject']
        # remove the .git folder to help save space on automated builds as it isn't needed.
        Remove-Item (Join-Path $buildInfo['LlvmProject'] '.git') -Recurse -Force
    }
}

# Sanity check the version information to validate tag was correct and matches on-disk sources
function Assert-LlvmSourceVersion([hashtable]$buildinfo)
{
    $llvmVersion = $BuildInfo['LlvmVersion']
    Write-Verbose "Expected Version: `n$($llvmVersion | Out-String)"

    $llvmRepoVersion = Get-LlvmVersion($buildInfo);
    Write-Verbose "Actual Version: `n$($llvmRepoVersion | Out-String)"

    if($llvmRepoVersion['MAJOR'] -ne $llvmVersion.Major -or
       $llvmRepoVersion['MINOR'] -ne $llvmVersion.Minor -or
       $llvmRepoVersion['PATCH'] -ne $llvmVersion.Patch)
    {
        throw "Unexpected LLVM source version."
    }
}

# Enum of all the LLVM targets. This set MUST be checked against the LLVM sources
# with each new release to ensure it is up to date with the target support in the
# underlyiing LLVM libraries.
enum LlvmTarget
{
    AArch64
    AMDGPU
    ARM
    AVR
    BPF
    Hexagon
    Lanai
    LoongArch
    Mips
    MSP430
    NVPTX
    PowerPC
    RISCV
    Sparc
    SystemZ
    VE
    WebAssembly
    X86
    XCore
}

# get an LLVM target for the native runtime of this build
function Get-NativeTarget
{
    [OutputType([LlvmTarget])]
    param()

    $hostArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    switch($hostArch)
    {
        X86 {[LlvmTarget]::X86}
        X64 {[LlvmTarget]::X86} # 64 vs 32 bit target is a CPU/Feature option in LLVM for X86
        Arm {[LlvmTarget]::ARM}
        Armv6 {[LlvmTarget]::ARM} # distinction between ARM-32 CPUs is a CPU/Feature in LLVM
        Arm64 {[LlvmTarget]::AArch64}
        Wasm {[LlvmTarget]::WebAssembly} # unlikely to ever occur but here for for completeness
        LoongArch64 {[LlvmTarget]::LoongArch}
        Ppc64le {[LlvmTarget]::PowerPc}
        RiscV64 {[LlvmTarget]::RISCV} # 64 vs 32 is a CPU/Feature option in LLVM
        default { throw "Unknown Native environment for host: $hostArch"}
    }
}

function New-LlvmCmakeConfig
{
    param(
        [string]$name,
        [LlvmTarget]$additionalTarget,
        [string]$buildConfig,
        [hashtable]$buildInfo,
        [string]$cmakeSrcRoot = $buildInfo['LlvmRoot']
    )

    [CMakeConfig]$cmakeConfig = New-Object CMakeConfig -ArgumentList $name, $buildConfig, $buildInfo, $cmakeSrcRoot
    $cmakeConfig.CMakeBuildVariables = @{
        LLVM_ENABLE_RTTI = "OFF"
        LLVM_BUILD_TOOLS = "OFF"
        LLVM_BUILD_UTILS = "OFF"
        LLVM_BUILD_DOCS = "OFF"
        LLVM_BUILD_RUNTIME = "OFF"
        LLVM_BUILD_RUNTIMES = "OFF"
        LLVM_BUILD_BENCHMARKS  = "OFF"
        LLVM_ENABLE_BINDINGS  = "OFF"
        LLVM_BUILD_TELEMETRY = "OFF"
        LLVM_OPTIMIZED_TABLEGEN = "ON"
        LLVM_REVERSE_ITERATION = "OFF"
        LLVM_INCLUDE_BENCHMARKS = "OFF"
        LLVM_INCLUDE_DOCS = "OFF"
        LLVM_INCLUDE_EXAMPLES = "OFF"
        LLVM_INCLUDE_GO_TESTS = "OFF"
        LLVM_INCLUDE_RUNTIMES = "OFF"
        LLVM_INCLUDE_TESTS = "OFF"
        LLVM_INCLUDE_TOOLS = "OFF"
        LLVM_INCLUDE_UTILS = "OFF"
        LLVM_TARGETS_TO_BUILD = "$(Get-NativeTarget);$additionalTarget"
        LLVM_ADD_NATIVE_VISUALIZERS_TO_SOLUTION = "ON"
    }
    return $cmakeConfig
}

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
    Param([switch]$FullInit)

    # use common repo-neutral function to perform most of the initialization
    $buildInfo = Initialize-CommonBuildEnvironment $PSScriptRoot -FullInit:$FullInit

    # Add repo specific values
    $buildInfo['OfficialGitRemoteUrl'] = 'https://github.com/UbiquityDotNET/Llvm.Libs.git'
    $buildInfo['LlvmProject'] = Join-Path $PSScriptRoot 'llvm-project'
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

