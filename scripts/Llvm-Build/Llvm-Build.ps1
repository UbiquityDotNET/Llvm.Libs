# dot source (include) the helper scipts
. (Join-Path $PSScriptRoot RepoBuild-Common.ps1)
. (Join-Path $PSScriptRoot CMake-Helpers.ps1)

# get an LLVM target for the native runtime of this build
function global:Get-NativeTarget
{
    $hostArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    switch($hostArch)
    {
        X86 {'X86'}
        X64 {'X86'}  # 64 vs 32 is a CPU/Feature option in LLVM
        Arm {'ARM'}
        Armv6 {'ARM'} # distinction between ARM-32 CPUs is a CPU/Feature in LLVM
        Arm64 {'AArch64'}
        Wasm {'WebAssembly'} # unlikely to ever occur but here for for completeness
        LoongArch64 {'LoongArch'}
        Ppc64le {'PowerPc'}
        RiscV64 {'RISCV'} # 64 vs 32 is a CPU/Feature option in LLVM
        default { throw "Unknown Native environment for host: $hostArch"}
    }
}

function New-LlvmCmakeConfig
{
    param(
        [string]$platform,
        [string]$config,
        $VsInstance,
        [string]$baseBuild = (Join-Path (Get-Location) BuildOutput),
        [string]$srcRoot = (Join-Path (Get-Location) 'llvm\lib')
    )

    [CMakeConfig]$cmakeConfig = New-Object CMakeConfig -ArgumentList $platform, $config, $baseBuild, $srcRoot, $VsInstance
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
        LLVM_ADD_NATIVE_VISUALIZERS_TO_SOLUTION = "ON"
    }
    return $cmakeConfig
}

function global:Get-LlvmVersion( [string] $cmakeListPath )
{
    $props = @{}
    $matches = Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9]+)\)" |
        %{ $_.Matches } |
        %{ $props.Add( $_.Groups[1].Value, [Convert]::ToInt32($_.Groups[2].Value) ) }
    return $props
}

function New-CMakeSettingsJson
{
    $global:RepoInfo.CMakeConfigurations.GetEnumerator() | New-CmakeSettings | Format-Json
}

function global:New-PathInfo([Parameter(Mandatory=$true)]$BasePath, [Parameter(Mandatory=$true, ValueFromPipeLine)]$Path)
{
    $relativePath = ($Path.FullName.Substring($BasePath.Trim('\').Length + 1))
    @{
        FullPath=$Path.FullName;
        RelativePath=$relativePath;
        RelativeDir=[System.IO.Path]::GetDirectoryName($relativePath);
        FileName=[System.IO.Path]::GetFileName($Path.FullName);
    }
}

function global:LinkFile($archiveVersionName, $info)
{
    $linkPath = join-Path $archiveVersionName $info.RelativeDir
    if(!(Test-Path -PathType Container $linkPath))
    {
        New-Item -ItemType Directory $linkPath | Out-Null
    }

    New-Item -ItemType HardLink -Path $linkPath -Name $info.FileName -Value $info.FullPath
}

function global:Create-ArchiveLayout($archiveVersionName)
{
    # To simplify building the 7z archive with the desired structure
    # create the layout desired using hard-links, and zip the result in a single operation
    # this also allows local testing of the package without needing to publish, download and unpack the archive
    # while avoiding unnecessary file copies
    Write-Information "Creating archiveLayout structure hardlinks in $(Join-Path $global:RepoInfo.BuildOutputPath $archiveVersionName)"
    pushd $global:RepoInfo.BuildOutputPath
    if(Test-Path -PathType Container $archiveVersionName)
    {
        rd -Force -Recurse $archiveVersionName
    }

    New-Item -ItemType Directory $archiveVersionName | Out-Null
    Write-Information 'Creating JSON version file'
    ConvertTo-Json (Get-LlvmVersion (Join-Path $global:RepoInfo.LlvmRoot '..\cmake\Modules\LLVMVersion.cmake')) | Out-File (Join-Path $archiveVersionName 'llvm-version.json')
    # TODO: This should use some sort of input var to indicate platform AND ISA (and so should the name of the compressed file) so it isn't hardcoded to 'x64-Release`
    # TODO: on platforms where the distinction between a junction and hardlink don't exist, make the directory and link each file or other alternates...
    New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Release\Release') -Name lib -Value (Join-Path $global:RepoInfo.BuildOutputPath 'x64-Release\RelWithDebInfo\lib') | Out-Null

    $commonIncPath = join-Path $global:RepoInfo.LlvmRoot include

    # Construct a sequence of New path info values to create a hard link for each of them in the new location
    & {
        dir -r x64*\include -Include ('*.h', '*.gen', '*.def', '*.inc')| %{ New-PathInfo $global:RepoInfo.BuildOutputPath.FullName $_}
        dir -r $commonIncPath -Exclude ('*.txt')| ?{$_ -is [System.IO.FileInfo]} | %{ New-PathInfo $global:RepoInfo.LlvmRoot.FullName $_ }
        dir $global:RepoInfo.RepoRoot -Filter Llvm-Libs.* | ?{$_ -is [System.IO.FileInfo]} | %{ New-PathInfo $global:RepoInfo.RepoRoot.FullName $_ }
    } | %{ LinkFile $archiveVersionName $_ } | Out-Null
}

function global:Compress-BuildOutput($additionalTarget)
{
    if($env:APPVEYOR)
    {
        Write-Error "Cannot pack LLVM libraries in APPVEYOR build as it requires the built libraries and the total time required will exceed the limits of an APPVEYOR Job"
        return
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $oldPath = $env:Path
    # Triple format:  <arch><sub>-<vendor>-<sys>-<abi>
    # For now, the ONLY native support is Windows MSVC AMD64, eventually once support is worked out this can grow
    # But for now this is enough. The build scripts themselves have a TON of Windows assumptions and aliases etc..
    # that need fixing/updates to finallly work for true x-plat. [Baby steps...]
    $nativeTriple = "x86_64-pc-Win32-MSVC"
    $archiveVersionName = "llvm-libs-$($global:RepoInfo.LlvmVersion)-$nativeTriple-$($global:RepoInfo.VsInstance.InstallationVersion.Major).$($global:RepoInfo.VsInstance.InstallationVersion.Minor)-$additionalTarget"
    $archivePath = Join-Path $global:RepoInfo.BuildOutputPath "$archiveVersionName.7z"
    try
    {
        Write-Information "Creating archive layout"
        Create-ArchiveLayout $archiveVersionName

        if(Test-Path -PathType Leaf $archivePath)
        {
            del -Force $archivePath
        }

        Push-Location $archiveVersionName
        try
        {
            Write-Information "Creating 7-ZIP archive $archivePath"
            7z.exe a $archivePath '*' -r -t7z -mx=9
        }
        finally
        {
            Pop-Location
        }
    }
    finally
    {
        $timer.Stop()
        $env:Path = $oldPath
        Write-Information "Pack Finished - Elapsed Time: $($timer.Elapsed.ToString())"
    }
}

function global:Clear-BuildOutput()
{
    Remove-Item -Recurse -Force $global:RepoInfo.ToolsPath
    Remove-Item -Recurse -Force $global:RepoInfo.BuildOutputPath
    Remove-Item -Recurse -Force $global:RepoInfo.PackOutputPath
}

function global:Invoke-Build
{
<#
.SYNOPSIS
    Wraps CMake generation and build for LLVM as used by the LLVM.NET project

.DESCRIPTION
    This script is used to build LLVM libraries

.PARAMETER additionalTarget
    Provides the name of the additional target for the final native library. The build limits the supported targets
    to exactly the native target for this environment and one additional target. This limits the footprint and Time
    of any given build to "hopefully" allow for automated builds of the native library. Which, would in turn enable
    support for matrix builds of Non-Windows platforms to make this a truly x-plat library.
#>

    # NOTE: The validation set for the supported targets should be evaluated with each new release of LLVM to ensure it is up to date with the current support.
    param (
        [ValidateSet('AArch64', 'AMDGPU', 'ARM', 'AVR', 'BPF', 'Hexagon', 'Lanai', 'LoongArch', 'Mips', 'MSP430', 'NVPTX', 'PowerPC', 'RISCV', 'Spar', 'SystemZ', 'VE', 'WebAssembly', 'X86', 'XCore')] 
        [string] $additionalTarget,
        [switch]$GenerateOnly
    )

    if($env:APPVEYOR)
    {
        Write-Error "Cannot build LLVM libraries in APPVEYOR build as the total time required will exceed the limits of an APPVEYOR Job"
    }

    <#
    NUMBER_OF_PROCESSORS < 6;
    This is generally an inefficient number of cores available (Ideally 6-8 are needed for a timely build)
    On an automated build service this may cause the build to exceed the time limit allocated for a build
    job. (As an example AppVeyor has a 1hr per job limit with VMs containing only 2 cores, which is
    unfortunately just not capable of completing the build for a single platform+configuration in time, let alone multiple combinations.)
    #>

    if( ([int]$env:NUMBER_OF_PROCESSORS) -lt 6 )
    {
        Write-Warning "NUMBER_OF_PROCESSORS{ $env:NUMBER_OF_PROCESSORS } < 6; Performance will suffer"
    }

    # Verify Cmake version info
    Assert-CmakeInfo ([Version]::new(3, 12, 1))

    try
    {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $additionalBuildVars = @{
            LLVM_TARGETS_TO_BUILD  = "$(Get-NativeTarget);$additionalTarget"
        }

        foreach( $cmakeConfig in $global:RepoInfo.CMakeConfigurations )
        {
            Write-Information "Generating CMAKE configuration $($cmakeConfig.Name)"
            Invoke-CMakeGenerate $cmakeConfig $additionalBuildVars

            if(!$GenerateOnly)
            {
                Write-Information "Building CMAKE configuration $($cmakeConfig.Name)"
                Invoke-CmakeBuild $cmakeConfig
            }
        }
    }
    finally
    {
        $timer.Stop()
        Write-Information "Build Finished - Elapsed Time: $($timer.Elapsed.ToString())"
    }
}

function global:Initialize-BuildPath([string]$path)
{
    $resultPath = $([System.IO.Path]::Combine($PSScriptRoot, '..', '..', $path))
    if( !(Test-Path -PathType Container $resultPath) )
    {
        New-Item -ItemType Directory $resultPath
    }
    else
    {
        Get-Item $resultPath
    }
}

function global:Get-RepoInfo([switch]$Force)
{
    $repoRoot = (Get-Item $([System.IO.Path]::Combine($PSScriptRoot, '..', '..')))
    $llvmroot = (Get-Item $([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'llvm', 'llvm')))
    $llvmversionInfo = (Get-LlvmVersion (Join-Path $llvmroot '..\cmake\Modules\LLVMVersion.cmake'))
    $llvmversion = "$($llvmversionInfo.Major).$($llvmversionInfo.Minor).$($llvmversionInfo.Patch)"
    $toolsPath = Initialize-BuildPath 'tools'
    $buildOuputPath = Initialize-BuildPath 'BuildOutput'
    $packOutputPath = Initialize-BuildPath 'packages'

    # On Windows VisualStuido is used to provide the C/C++ compiler assuming targetting Windows.
    if($IsWindows)
    {
        $vsInstance = Find-VSInstance -Force:$Force -Version '[17.0, 18.0)'
        if(!$vsInstance)
        {
            throw "No VisualStudio instance found! This build requires VS build tools to function"
        }
    }
    else
    {
        throw "Non-Windows platforms not currently supported"
    }

    $pythonLocationInfo = Find-Python
    if(!$pythonLocationInfo)
    {
        throw "Python.exe not found!"
    }

    return @{
        RepoRoot = $repoRoot
        ToolsPath = $toolsPath
        BuildOutputPath = $buildOuputPath
        PackOutputPath = $packOutputPath
        LlvmRoot = $llvmroot
        LlvmVersion = $llvmversion
        Version = $llvmversion # this may differ from the LLVM Version if the packaging infrastructure is "patched"
        VsInstanceName = $vsInstance.DisplayName
        VsVersion = $vsInstance.InstallationVersion
        VsInstance = $vsInstance
        PythonLocationInfo = $pythonLocationInfo
        CMakeConfigurations = @( (New-LlvmCmakeConfig x64 'Release' $vsInstance $buildOuputPath $llvmroot))
    }
}

function Initialize-BuildEnvironment
{
    $env:Path = "$($global:RepoInfo.ToolsPath);$env:Path"
    $isCI = !!$env:CI

    Write-Information "Build Info:`n $($global:RepoInfo | Out-String)"
    Write-Information "PS Version:`n $($PSVersionTable | Out-String)"

    $msBuildInfo = Find-MsBuild
    if( !$msBuildInfo.FoundOnPath )
    {
        Write-Information "Using MSBuild from: $($msBuildInfo.BinPath)"
        $env:Path = "$($env:Path);$($msBuildInfo.BinPath)"
    }

    $cmakePath = $(Join-Path $global:RepoInfo.VsInstance.InstallationPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe')
    if(!(Test-Path -PathType Leaf $cmakePath))
    {
        throw "CMAKE.EXE not found at: '$cmakePath'"
    }

    Write-Information "Using cmake from VS Instance"
    $env:Path = "$([System.IO.Path]::GetDirectoryName($cmakePath));$env:Path"

    $vsGitCmdPath = [System.IO.Path]::Combine( $global:RepoInfo.VsInstance.InstallationPath, 'Common7', 'IDE', 'CommonExtensions', 'Microsoft', 'TeamFoundation', 'Team Explorer', 'Git', 'cmd')
    if(Test-Path -PathType Leaf ([System.IO.Path]::Combine($vsGitCmdPath, 'git.exe')))
    {
        Write-Information "Using git from VS Instance"
        $env:Path = "$vsGitCmdPath;$env:Path"
    }

    Write-Information "cmake: $cmakePath"
}

# --- Module init script
$ErrorActionPreference = 'Stop'
$InformationPreference = "Continue"

$isCI = !!$env:CI -or !!$env:GITHUB_ACTIONS

$global:RepoInfo = Get-RepoInfo -Force:$isCI

New-Alias -Name build -Value Invoke-Build -Scope Global
New-Alias -Name pack -Value Compress-BuildOutput -Scope Global
New-Alias -Name clean -Value Clear-BuildOutput -Scope Global
