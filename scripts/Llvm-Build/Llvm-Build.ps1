. (Join-Path $PSScriptRoot RepoBuild-Common.ps1)
. (Join-Path $PSScriptRoot CMake-Helpers.ps1)

function global:New-LlvmCmakeConfig(
    [string]$platform,
    [string]$config,
    $VsInstance,
    [string]$baseBuild = (Join-Path (Get-Location) BuildOutput),
    [string]$srcRoot = (Join-Path (Get-Location) 'llvm\lib')
    )
{
    [CMakeConfig]$cmakeConfig = New-Object CMakeConfig -ArgumentList $platform, $config, $baseBuild, $srcRoot, $VsInstance
    $cmakeConfig.CMakeBuildVariables = @{
        LLVM_ENABLE_RTTI = "ON"
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

function global:Get-LlvmVersion( [string] $cmakeListPath )
{
    $props = @{}
    Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9]+)\)" |
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
        New-Item -Path $linkPath -Type Directory -Force
    }

    New-Item -ItemType HardLink -Path $linkPath -Name $info.FileName -Value $info.FullPath
}

function global:LinkPdb([Parameter(Mandatory=$true, ValueFromPipeLine)]$item, [Parameter(Mandatory=$true)]$Path)
{
    $targetPath = Join-Path $Path $item.Name
    Write-Information "Linking $targetPath"
    if(Test-Path -PathType Leaf $targetPath)
    {
        Write-Information "Deleting existing PDB link"
        del -Force $targetPath
    }

    New-Item -ItemType HardLink -Path $Path -Name $item.Name -Value $item.FullName -ErrorAction Stop | Out-Null
}

function global:Create-ArchiveLayout($archiveVersionName)
{
    # To simplify building the 7z archive with the desired structure
    # create the layout desired using hard-links, and zip the result in a single operation
    # this also allows local testing of the package without needing to publish, download and unpack the archive
    # while avoiding unnecessary file copies
    Write-Information "Creating ZIP structure hardlinks in $(Join-Path $global:RepoInfo.BuildOutputPath $archiveVersionName)"
    pushd $global:RepoInfo.BuildOutputPath
    if(Test-Path -PathType Container $archiveVersionName)
    {
        del -Force -Recurse $archiveVersionName
    }

    mkdir $archiveVersionName | Out-Null

    ConvertTo-Json (Get-LlvmVersion (Join-Path $global:RepoInfo.LlvmRoot 'CMakeLists.txt')) | Out-File (Join-Path $archiveVersionName 'llvm-version.json')

    if (!$global:IsWindowsPS)
    {
        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Debug') -Name lib -Value (Join-Path $global:RepoInfo.BuildOutputPath 'x64-Debug\lib') | Out-Null
        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Release') -Name lib -Value (Join-Path $global:RepoInfo.BuildOutputPath 'x64-Release\lib') | Out-Null    
    }
    else 
    {
        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Debug\Debug') -Name lib -Value (Join-Path $global:RepoInfo.BuildOutputPath 'x64-Debug\Debug\lib') | Out-Null
        New-Item -ItemType Junction -Path (Join-path $archiveVersionName 'x64-Release\Release') -Name lib -Value (Join-Path $global:RepoInfo.BuildOutputPath 'x64-Release\RelWithDebInfo\lib') | Out-Null
    }

    $commonIncPath = join-Path $global:RepoInfo.LlvmRoot include
    & {
        Get-ChildItem -r x64*\include -Include ('*.h', '*.gen', '*.def', '*.inc') | %{ New-PathInfo $global:RepoInfo.BuildOutputPath.FullName $_}
        Get-ChildItem -r $commonIncPath -Exclude ('*.txt') | ?{$_ -is [System.IO.FileInfo]} | %{ New-PathInfo $global:RepoInfo.LlvmRoot.FullName $_ }
        Get-ChildItem $global:RepoInfo.RepoRoot -Filter Llvm-Libs.* | ?{$_ -is [System.IO.FileInfo]} | %{ New-PathInfo $global:RepoInfo.RepoRoot.FullName $_ }
        Get-ChildItem (join-path $global:RepoInfo.LlvmRoot 'lib\ExecutionEngine\Orc\OrcCBindingsStack.h') | %{ New-PathInfo $global:RepoInfo.LlvmRoot.FullName $_ }
    } | %{ LinkFile $archiveVersionName $_ } | Out-Null

    if ($global:IsWindowsPS)
    {
        # Link RelWithDebInfo PDBs into the 7z package so that symbols are available for the release build too.
        $pdbLibDir = Join-Path $archiveVersionName 'x64-Release\Release\lib'
        Get-ChildItem -r x64-Release\lib -Include *.pdb | LinkPdb -Path $pdbLibDir
    }
}

function global:Compress-BuildOutput
{
    if($env:APPVEYOR)
    {
        Write-Error "Cannot pack LLVM libraries in APPVEYOR build as it requires the built libraries and the total time required will exceed the limits of an APPVEYOR Job"
        return
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $oldPath = $env:Path
    if (!$global:IsWindowsPS -and $IsLinux)
    {
        $archiveVersionName = "llvm-libs-$($global:RepoInfo.LlvmVersion)-linux"
    }
    elseif (!$global:IsWindowsPS -and $IsMacOs) 
    {
        $archiveVersionName = "llvm-libs-$($global:RepoInfo.LlvmVersion)-macos"
    }
    else 
    {
        $archiveVersionName = "llvm-libs-$($global:RepoInfo.LlvmVersion)-msvc-$($global:RepoInfo.VsInstance.InstallationVersion.Major).$($global:RepoInfo.VsInstance.InstallationVersion.Minor)"
    }
    $archivePath = Join-Path $global:RepoInfo.BuildOutputPath "$archiveVersionName.7z"
    try
    {
        Write-Information "Creating archive layout"
        Create-ArchiveLayout $archiveVersionName

        if(Test-Path -PathType Leaf $archivePath)
        {
            del -Force $archivePath
        }

        Write-Information "Created archive layout, compressing archive"
        pushd $archiveVersionName
        try
        {
            Write-Information "Creating 7-ZIP archive $archivePath"
            7z a $archivePath '*' -r -t7z -mx=9
        }
        finally
        {
            popd
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
    del -Recurse -Force $global:RepoInfo.ToolsPath
    del -Recurse -Force $global:RepoInfo.BuildOutputPath
    del -Recurse -Force $global:RepoInfo.PackOutputPath
    $global:RepoInfo = Get-RepoInfo
}

function global:Invoke-Build([switch]$GenerateOnly)
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
        Write-Warning "NUMBER_OF_PROCESSORS{ $env:NUMBER_OF_PROCESSORS } < 6; Performance will suffer"
    }

    # Verify Cmake version info
    Assert-CmakeInfo ([Version]::new(3, 12, 1))

    try
    {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        foreach( $cmakeConfig in $global:RepoInfo.CMakeConfigurations )
        {
            Write-Information "Generating CMAKE configuration $($cmakeConfig.Name)"
            Invoke-CMakeGenerate $cmakeConfig

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
        mkdir $resultPath
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
    $llvmversionInfo = (Get-LlvmVersion (Join-Path $llvmroot 'CMakeLists.txt'))
    $llvmversion = "$($llvmversionInfo.Major).$($llvmversionInfo.Minor).$($llvmversionInfo.Patch)"
    $toolsPath = Initialize-BuildPath 'tools'
    $buildOutputPath = Initialize-BuildPath 'BuildOutput'
    $packOutputPath = Initialize-BuildPath 'packages'

    if ($global:IsWindowsPS)
    {
        $vsInstance = Find-VSInstance -Force:$Force -Version '[15.0, 17.0)'

        if(!$vsInstance)
        {
            throw "No VisualStudio instance found! This build requires VS build tools to function"
        }

        VsInstanceName = $vsInstance.DisplayName
        VsVersion = $vsInstance.InstallationVersion
        VsInstance = $vsInstance
    }
    else 
    {
        VsInstanceName = ""
        VsVersion = ""
        VsInstance = $null
    }

    $cmakeInfo = @( (New-LlvmCmakeConfig x64 'Release' $null $buildOutputPath $llvmroot),
                    (New-LlvmCmakeConfig x64 'Debug' $null $buildOutputPath $llvmroot)
                    )

    return @{
        RepoRoot = $repoRoot
        ToolsPath = $toolsPath
        BuildOutputPath = $buildOutputPath
        PackOutputPath = $packOutputPath
        LlvmRoot = $llvmroot
        LlvmVersion = $llvmversion
        Version = $llvmversion # this may differ from the LLVM Version if the packaging infrastructure is "patched"
        VsInstanceName = $vsInstance.DisplayName
        VsVersion = $vsInstance.InstallationVersion
        VsInstance = $vsInstance
        CMakeConfigurations = $cmakeInfo
    }

}

function Get-BuildPlatform
{
    if ($PSVersionTable.PSEdition -ne "Core")
    {
        $global:IsWindowsPS = $true
    }
    else 
    {
        if ($IsLinux -or $IsMacOS)
        {
            $global:IsWindowsPS = $false
        }
        else 
        {
            $global:IsWindowsPS = $true
        }
    }
}

function Initialize-BuildEnvironment
{
    $env:Path = "$($global:RepoInfo.ToolsPath);$env:Path"
    $isCI = !!$env:CI

    Write-Information "Build Info:`n $($global:RepoInfo | Out-String)"
    Write-Information "PS Version:`n $($PSVersionTable | Out-String)"

    Get-BuildPlatform

    if (!$global:IsWindowsPS)
    {
        $cmakePath = which cmake
        if(!(Test-Path -PathType Leaf $cmakePath))
        {
            throw "cmake not found at: '$cmakePath'"
        }

        Write-Information "Using cmake from $cmakePath"
    }
    else 
    {
        $cmakePath = $(Join-Path $global:RepoInfo.VsInstance.InstallationPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe')
        if(!(Test-Path -PathType Leaf $cmakePath))
        {
            throw "CMAKE.EXE not found at: '$cmakePath'"
        }

        Write-Information "Using cmake from VS Instance"
        $env:Path = "$([System.IO.Path]::GetDirectoryName($cmakePath));$env:Path"
    }

    if (!$global:IsWindowsPS)
    {
        $vsGitCmdPath = which git
        if(!(Test-Path -PathType Leaf $vsGitCmdPath))
        {
            throw "git not found at: '$vsGitCmdPath'"
        }
        
        Write-Information "Using git from $vsGitCmdPath"
    }
    else 
    {
        $vsGitCmdPath = [System.IO.Path]::Combine( $global:RepoInfo.VsInstance.InstallationPath, 'Common7', 'IDE', 'CommonExtensions', 'Microsoft', 'TeamFoundation', 'Team Explorer', 'Git', 'cmd')
        if(Test-Path -PathType Leaf ([System.IO.Path]::Combine($vsGitCmdPath, 'git.exe')))
        {
            Write-Information "Using git from VS Instance"
            $env:Path = "$vsGitCmdPath;$env:Path"
        }
    }
}

# --- Module init script
$ErrorActionPreference = 'Stop'
$InformationPreference = "Continue"

$isCI = !!$env:CI -or !!$env:GITHUB_ACTIONS

Get-BuildPlatform
$global:RepoInfo = Get-RepoInfo -Force:$isCI

New-Alias -Force -Name build -Value Invoke-Build -Scope Global
New-Alias -Force -Name pack -Value Compress-BuildOutput -Scope Global
New-Alias -Force -Name clean -Value Clear-BuildOutput -Scope Global
