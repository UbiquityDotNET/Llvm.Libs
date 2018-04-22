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
        CMAKE_CXX_FLAGS_RELEASE = '/MD /O2 /Ob2 /DNDEBUG /Zi /Fd$(OutDir)$(ProjectName).pdb'
        #CMAKE_MAKE_PROGRAM=Join-Path $RepoInfo.VSInstance.InstallationPath 'COMMON7\IDE\COMMONEXTENSIONS\MICROSOFT\CMAKE\Ninja\ninja.exe'
    }
    return $cmakeConfig
}
Export-ModuleMember -Function New-LlvmCmakeConfig

function Get-LlvmVersion( [string] $cmakeListPath )
{
    $props = @{}
    $matches = Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9])+\)" |
        %{ $_.Matches } |
        %{ $props.Add( $_.Groups[1].Value, [Convert]::ToInt32($_.Groups[2].Value) ) }
    return $props
}
Export-ModuleMember -Function Get-LlvmVersion

function BuildPlatformConfigPackage([CmakeConfig]$config, $repoInfo)
{
    Write-Information "Generating Llvm.Libs.$($config.Name).nupkg"
    $properties = ConvertTo-PropList @{ llvmsrcroot=$repoInfo.LlvmRoot
                                        buildoutput=$repoInfo.BuildOutputPath
                                        version=$repoInfo.Version
                                        llvmversion=$repoInfo.Llvmversion
                                        platform=$config.Platform
                                        configuration=$config.Configuration
                                      }
    $platormconfig = "$($config.Platform)-$($config.Configuration)"
    Invoke-Nuget pack "Llvm.Libs.core.$platormconfig.nuspec" -properties $properties -OutputDirectory $repoInfo.PackOutputPath
    Invoke-Nuget pack "Llvm.Libs.core.pdbs.$platormconfig.nuspec" -properties $properties -OutputDirectory $repoInfo.PackOutputPath
    Invoke-Nuget pack "Llvm.Libs.targets.$platormconfig.nuspec" -properties $properties -OutputDirectory $repoInfo.PackOutputPath
    Invoke-Nuget pack "Llvm.Libs.targets.pdbs.$platormconfig.nuspec" -properties $properties -OutputDirectory $repoInfo.PackOutputPath
}

function GenerateMultiPack($repoInfo)
{
    Write-Information "Generating meta-package"
    $properties = ConvertTo-PropList @{ llvmsrcroot=$repoInfo.LlvmRoot
                                        buildoutput=$repoInfo.BuildOutputPath
                                        version=$repoInfo.Version
                                        llvmversion=$repoInfo.Llvmversion
                                      }

    Invoke-Nuget pack 'Llvm.Libs.MetaPackage.nuspec' -Properties $properties -OutputDirectory $repoInfo.PackOutputPath
}

function LlvmBuildConfig([CMakeConfig]$configuration)
{
    Invoke-CMakeGenerate $configuration
    Invoke-CmakeBuild $configuration
}

function New-CMakeSettingsJson
{
    $RepoInfo.CMakeConfigurations.GetEnumerator() | New-CmakeSettings | Format-Json
}
Export-ModuleMember -Function New-CMakeSettingsJson

function Invoke-Build
{
<#
.SYNOPSIS
    Wraps CMake generation and build for LLVM as used by the LLVM.NET project

.DESCRIPTION
    This script is used to build LLVM libraries for Windows and bundle the results into a NuGet package.
    A NUGET package is immediately consumable by projects without requiring a complete build of the LLVM
    source code. This is particularly useful for OSS projects that leverage public build services like
    Jenkins or AppVeyor, etc... Public build services often limit the time a build can run so building
    all of the LLVM libraries for multiple platforms can be problematic as the LLVM builds take quite
    a while on their own. Furthermore public services often limit the size of each NuGet package to some
    level (Nuget.org tops out at 250MB). So the NuGet Packaging supports splitting out the libraries,
    headers and symbols into smaller packages with a top level "MetaPackage" that lists all the others
    as dependencies. The complete set of packages is:
       - Llvm.Libs.x64.<Version>.nupkg
       - Llvm.Libs.core.pdbs.x64-Debug.<Version>.nupkg
       - Llvm.Libs.core.x64-Debug.<Version>.nupkg
       - Llvm.Libs.core.x64-Release.<Version>.nupkg
       - Llvm.Libs.targets.x64-Debug.<Version>.nupkg
       - Llvm.Libs.targets.x64-Release.<Version>.nupkg

.PARAMETER BuildAll
    Switch to enable building all the platform configurations in a single run.
    > **NOTE:**
    The full build can take as much as 1.5 to 2 hours on common current hardware using most of the CPU and disk I/O capacity,
    therefore you should plan accordingly and only use this command when the system would otherwise be idle.

.PARAMETER Build
    Switch to build and pack one platform and configuration package. This will build the LLVM libraries for the particular
    platform/configuration combination and then pack them into a NuGet package.

.PARAMETER Platform
    Defines the platform to target. The AnyCPU platform has special meaning and is used to pack the platform/configuration neutral
    Meta-Package NuGet Package. That is, the Configuration parameter is ignored if Platform is AnyCPU.

.PARAMETER Configuration
    Defines the configuration to build

.PARAMETER Pack
    Set this flag to generate the NuGet packages for the libraries and headers

.PARAMETER Clean
    Clean all output folders to force a complete rebuild
#>

    [CmdletBinding(DefaultParameterSetName="build")]
    param(
       [Parameter(ParameterSetName="build")]
       [switch]$Libs,

       [Parameter(ParameterSetName="pack")]
       [switch]$Pack,

       [Parameter(ParameterSetName="clean")]
       [switch]$Clean,

       [Parameter(ParameterSetName="publish")]
       [ValidateSet('Account','Project')]
       [string]$Publish,

       [Parameter(ParameterSetName="publish")]
       [string]$ApiSetKey = $null
     )

    switch( $PsCmdlet.ParameterSetName )
    {
        "build" {
            <#
            NUMBER_OF_PROCESSORS < 6;
            This is generally an inefficient number of cores available (Ideally 6-8 are needed for a timely build)
            On an automated build service this may cause the build to exceed the time limit allocated for a build
            job. (As an example AppVeyor has a 1hr per job limit with VMs containing only 2 cores, which is
            unfortunately just not capable of completing the build for a single platform+config in time, let alone multiple combinations.)
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
        }
        "pack" {
            try
            {
                $timer = [System.Diagnostics.Stopwatch]::StartNew()
                if($env:APPVEYOR)
                {
                    Write-Error "Cannot pack LLVM libraries in APPVEYOR build as it requires the built libraries and the total time required will exceed the limits of an APPVEYOR Job"
                }

                #use nuget to pack the content in a nupkg in the output packages location
                #-Publish 'Account' command can then publish the packages to the account feed so that the
                #AppVeyor build can retrieve it and publish in the project feed (AppVeyor does not allow
                #direct publishing to the project feed when not published as an artifact from a build)
                foreach( $cmakeConfig in $RepoInfo.CMakeConfigurations )
                {
                    BuildPlatformConfigPackage $cmakeConfig $RepoInfo
                }
                GenerateMultiPack $RepoInfo
            }
            finally
            {
                $timer.Stop()
                Write-Information "Pack Finished - Elapsed Time: $($timer.Elapsed.ToString())"
            }
        }
        "clean" {
            rd -Recurse -Force $RepoInfo.ToolsPath
            rd -Recurse -Force $RepoInfo.BuildOutputPath
            rd -Recurse -Force $RepoInfo.PackOutputPath
            $script:RepoInfo = Get-RepoInfo
        }
        "publish" {
            switch($Publish)
            {
                "Account" {
                    if($env:APPVEYOR)
                    {
                        Write-Error "Cannot publish to account feed from an AppVeyor build Job"
                        return
                    }

                    if([string]::IsNullOrWhiteSpace($ApiSetKey))
                    {
                        Write-Error "ApiSetKey is required for publishing to account feed"
                        return
                    }

                    Write-Information "Publishing packages to account feed"
                    Get-ChildItem $RepoInfo.PackOutputPath -Filter '*.nupkg' |
                        %{ Invoke-Nuget push $_.FullName -Timeout 900 -ApiKey $ApiSetKey -Source https://ci.appveyor.com/nuget/UbiquityDotNet/api/v2/package }
                }
                "Project" {
                    Write-Information "Installing packages from account feed as artifacts"
                    Invoke-NuGet install Ubiquity.NET.Llvm.Libs  -OutputDirectory $RepoInfo.PackOutputPath -Source https://ci.appveyor.com/nuget/UbiquityDotNet/api/v2/package -DirectDownload -NoCache
                }
            }
        }
        default {
            Write-Error "Unknown parameter set '$PsCmdlet.ParameterSetName'"
        }
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
    $llvmroot = (Get-Item $([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'llvm')))
    $llvmversionInfo = (Get-LlvmVersion (Join-Path $llvmroot 'CMakeLists.txt'))
    $llvmversion = "$($llvmversionInfo.Major).$($llvmversionInfo.Minor).$($llvmversionInfo.Patch)"
    $toolsPath = EnsureBuildPath 'tools'
    $buildOuputPath = EnsureBuildPath 'BuildOutput'
    $packOutputPath = EnsureBuildPath 'packages'
    $vsInstance = Find-VSInstance -Force:$Force

    return @{
        ToolsPath =  $toolsPath
        BuildOutputPath = $buildOuputPath
        PackOutputPath = $packOutputPath
        LlvmRoot = $llvmroot
        LlvmVersion = $llvmversion
        Version = $llvmversion # this is may be differ from the LLVM Version if the packaging infrastructure is "patched"
        VsInstanceName = $vsInstance.DisplayName
        VsInstance = $vsInstance
        CMakeConfigurations = @( (New-LlvmCmakeConfig x64 'Release' $buildOuputPath $llvmroot),
                                 (New-LlvmCmakeConfig x64 'Debug' $buildOuputPath $llvmroot)
                               )
    }
}

function Initialize-BuildEnvironment
{
    $env:__LLVM_BUILD_INITIALIZED=1
    $env:Path = "$($RepoInfo.ToolsPath);$env:Path"

    Write-Information "Searching for cmake.exe"
    $cmakePath = Find-OnPath 'cmake.exe'
    if(!$cmakePath)
    {
        $cmakePath = $(Join-Path $RepoInfo.VsInstance.InstallationPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin' )
        $env:Path = "$env:Path;$cmakePath"
    }

    Write-Information "cmake: $cmakePath"
}
Export-ModuleMember -Function Initialize-BuildEnvironment

# --- Module init script
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$isCI = !!$env:CI
$RepoInfo = Get-RepoInfo  -Force:$isCI
Export-ModuleMember -Variable RepoInfo

New-Alias -Name build -Value Invoke-Build
Export-ModuleMember -Alias build -Variable RepoInfo

Write-Information "Build Info:`n $($RepoInfo | Out-String )"
