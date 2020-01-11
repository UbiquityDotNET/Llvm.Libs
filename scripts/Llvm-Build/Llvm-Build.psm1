#Requires -Version 5.0

Set-StrictMode -Version Latest

function New-LlvmCmakeConfig([string]$platform,
                          [string]$config,
                          [string]$baseBuild = (Join-Path (Get-Location) BuildOutput),
                          [string]$srcRoot = (Join-Path (Get-Location) 'llvm\lib')
                          )
{
    [CMakeConfig]$cmakeConfig = New-Object CMakeConfig -ArgumentList $platform, $config, $baseBuild, $srcRoot
    $cmakeConfig.CMakeBuildVariables = @{
        LLVM_ENABLE_RTTI = "ON"
        LLVM_ENABLE_CXX1Y = "ON"
        LLVM_BUILD_TOOLS = "OFF"
        LLVM_BUILD_UTILS = "OFF"
        LLVM_BUILD_DOCS = "OFF"
        LLVM_BUILD_RUNTIME = "OFF"
        LLVM_BUILD_RUNTIMES = "OFF"
        LLVM_OPTIMIZED_TABLEGEN = "ON"
        LLVM_REVERSE_ITERATION = "ON"
        LLVM_TARGETS_TO_BUILD  = "all"
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

function Get-LlvmVersion( [string] $cmakeListPath )
{
    $props = @{}
    $matches = Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9])+\)" |
        %{ $_.Matches } |
        %{ $props.Add( $_.Groups[1].Value, [Convert]::ToInt32($_.Groups[2].Value) ) }
    return $props
}
Export-ModuleMember -Function Get-LlvmVersion

function LlvmBuildConfig([CMakeConfig]$configuration)
{
    Write-Information "Generating CMAKE configuration $($configuration.Name)"
    Invoke-CMakeGenerate $configuration

    Write-Information "Building CMAKE configuration $($configuration.Name)"
    Invoke-CmakeBuild $configuration
}

function New-CMakeSettingsJson
{
    $RepoInfo.CMakeConfigurations.GetEnumerator() | New-CmakeSettings | Format-Json
}
Export-ModuleMember -Function New-CMakeSettingsJson

function mkpathinfo($basePath, $path)
{
    $relativePath = ($path.FullName.Substring($basePath.Trim('\').Length + 1))
    @{
        FullPath=$path.FullName;
        RelativePath=$relativePath;
        RelativeDir=[System.IO.Path]::GetDirectoryName($relativePath);
        FileName=[System.IO.Path]::GetFileName($path.FullName);
    }
}

function LinkFile($archiveVersionName, $info)
{
    $linkPath = join-Path $archiveVersionName $info.RelativeDir
    if(!(Test-Path -PathType Container $linkPath))
    {
        md $linkPath | out-null
    }

    New-Item -ItemType HardLink -Path $linkPath -Name $info.FileName -Value $info.FullPath
}

function Compress-BuildOutput
{
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $oldPath = $env:Path
    $archiveVersionName = "llvm-libs-$($RepoInfo.LlvmVersion)-msvc-$($RepoInfo.VsInstance.InstallationVersion.Major).$($RepoInfo.VsInstance.InstallationVersion.Minor)"
    $archivePath = Join-Path $RepoInfo.BuildOutputPath "$archiveVersionName.7z"
    try
    {
        if($env:APPVEYOR)
        {
            Write-Error "Cannot pack LLVM libraries in APPVEYOR build as it requires the built libraries and the total time required will exceed the limits of an APPVEYOR Job"
        }

        pushd $RepoInfo.BuildOutputPath
        # To simplify building the 7z archive with the desired structure
        # create the layout desired using hard-links, and zip the result in a single operation
        # this also allows local testing of the package without needing to publish, download and unpack the archive
        # while avoiding unnecessary file copies
        if(!(Test-Path -PathType Container $archiveVersionName))
        {
            md $archiveVersionName
        }

        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Debug\Debug') -Name lib -Value (Join-Path $RepoInfo.BuildOutputPath 'x64-Debug\Debug\lib')
        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Release\Release') -Name lib -Value (Join-Path $RepoInfo.BuildOutputPath 'x64-Release\RelWithDebInfo\lib')

        $commonIncPath = join-Path $RepoInfo.LlvmRoot include
        & {
            dir -r x64*\include -Include ('*.h', '*.gen', '*.def', '*.inc')| %{ mkpathinfo $RepoInfo.BuildOutputPath.FullName $_}
            dir -r $commonIncPath -Exclude ('*.txt')| ?{$_ -is [System.IO.FileInfo]} | %{ mkpathinfo $RepoInfo.LlvmRoot.FullName $_ }
            dir $RepoInfo.RepoRoot -Filter Llvm-Libs.* | ?{$_ -is [System.IO.FileInfo]} | %{ mkpathinfo $RepoInfo.RepoRoot.FullName $_ }
            dir (join-path $RepoInfo.LlvmRoot 'lib\ExecutionEngine\Orc\OrcCBindingsStack.h') | %{mkpathinfo $RepoInfo.LlvmRoot.FullName $_}
        } | %{ LinkFile $archiveVersionName $_ }

        # Link RelWithDebInfo PDBs into the 7z package so that symbols are available for the release build too.
        $pdbLibDir = Join-Path $RepoInfo.BuildOutputPath 'x64-Release\RelWithDebInfo\lib'
        dir -r x64-Release\lib -Include *.pdb | %{ New-Item -ItemType HardLink -Path $pdbLibDir -Name $_.Name -Value $_.FullName}

        Compress-7Zip -ArchiveFileName $archivePath -Format SevenZip -CompressionLevel Ultra "$archiveVersionName\"
    }
    finally
    {
        $timer.Stop()
        $env:Path = $oldPath
        Write-Information "Pack Finished - Elapsed Time: $($timer.Elapsed.ToString())"
    }
}
Export-ModuleMember -Function Compress-BuildOutput

function Clear-BuildOutput()
{
    rd -Recurse -Force $RepoInfo.ToolsPath
    rd -Recurse -Force $RepoInfo.BuildOutputPath
    rd -Recurse -Force $RepoInfo.PackOutputPath
    $script:RepoInfo = Get-RepoInfo
}
Export-ModuleMember -Function Clear-BuildOutput

function Invoke-Build
{
<#
.SYNOPSIS
    Wraps CMake generation and build for LLVM as used by the LLVM.NET project

.DESCRIPTION
    This script is used to build LLVM libraries
#>
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
        Write-Warning "NUMBER_OF_PROCESSORS{ $env:NUMBER_OF_PROCESSORS } < 6;"
    }

    try
    {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        foreach( $cmakeConfig in $RepoInfo.CMakeConfigurations )
        {
            LlvmBuildConfig $cmakeConfig
        }
    }
    finally
    {
        $timer.Stop()
        Write-Information "Build Finished - Elapsed Time: $($timer.Elapsed.ToString())"
    }

    if( $Error.Count -gt 0 )
    {
        $Error.GetEnumerator() | %{ $_ }
    }
}
Export-ModuleMember -Function Invoke-Build

function EnsureBuildPath([string]$path)
{
    $resultPath = $([System.IO.Path]::Combine($PSScriptRoot, '..', '..', $path))
    if( !(Test-Path -PathType Container $resultPath) )
    {
        md $resultPath
    }
    else
    {
        Get-Item $resultPath
    }
}

function Get-RepoInfo([switch]$Force)
{
    $repoRoot = (Get-Item $([System.IO.Path]::Combine($PSScriptRoot, '..', '..')))
    $llvmroot = (Get-Item $([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'llvm', 'llvm')))
    $llvmversionInfo = (Get-LlvmVersion (Join-Path $llvmroot 'CMakeLists.txt'))
    $llvmversion = "$($llvmversionInfo.Major).$($llvmversionInfo.Minor).$($llvmversionInfo.Patch)"
    $toolsPath = EnsureBuildPath 'tools'
    $buildOuputPath = EnsureBuildPath 'BuildOutput'
    $packOutputPath = EnsureBuildPath 'packages'
    $vsInstance = Find-VSInstance -Force:$Force -Version '[16.0, 17.0)'

    if(!$vsInstance)
    {
        throw "No VisualStudion 2019 instance found! This build requires VS2019 build tools to function"
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
        CMakeConfigurations = @( (New-LlvmCmakeConfig x64 'Release' $buildOuputPath $llvmroot),
                                 (New-LlvmCmakeConfig x64 'Debug' $buildOuputPath $llvmroot)
                               )
    }
}

function Initialize-BuildEnvironment
{
    $env:Path = "$($RepoInfo.ToolsPath);$env:Path"
    $isCI = !!$env:CI

    Write-Information "Build Info:`n $($RepoInfo | Out-String )"

    $msBuildInfo = Find-MsBuild
    if( !$msBuildInfo.FoundOnPath )
    {
        Write-Information "Using MSBuild from: $($msBuildInfo.BinPath)"
        $env:Path = "$($env:Path);$($msBuildInfo.BinPath)"
    }

    $cmakePath = $(Join-Path $RepoInfo.VsInstance.InstallationPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe')
    if(!(Test-Path -PathType Leaf $cmakePath))
    {
        throw "CMAKE.EXE not found at: '$cmakePath'"
    }

    Write-Information "Using cmake from VS Instance"
    $env:Path = "$([System.IO.Path]::GetDirectoryName($cmakePath));$env:Path"

    Write-Information "cmake: $cmakePath"

    Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Force:$isCI
}
Export-ModuleMember -Function Initialize-BuildEnvironment

# --- Module init script
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$isCI = !!$env:CI

$RepoInfo = Get-RepoInfo -Force:$isCI
Export-ModuleMember -Variable RepoInfo

New-Alias -Name build -Value Invoke-Build
Export-ModuleMember -Alias build

New-Alias -Name pack -Value Compress-BuildOutput
Export-ModuleMember -Alias pack

New-Alias -Name clean -Value Clear-BuildOutput
Export-ModuleMember -Alias clean
