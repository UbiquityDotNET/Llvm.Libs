class CMakeConfig
{
    [string]$Name;

    [ValidateSet('x86','x64')]
    [string]$Platform;

    [ValidateSet('Debug', 'Release', 'MinSizeRel', 'RelWithDebInfo')]
    [string]$ConfigurationType;

    [string]$BuildRoot;
    [string]$SrcRoot;
    [string]$Generator;
    [System.Collections.ArrayList]$CMakeCommandArgs;
    [System.Collections.ArrayList]$BuildCommandArgs;
    [System.Collections.ArrayList]$InheritEnvironments;
    [hashtable]$CMakeBuildVariables;

    CMakeConfig([string]$plat, [string]$config, [string]$baseBuild, [string]$srcRoot)
    {
        $this.Platform = $Plat.ToLowerInvariant()
        $this.Generator = "Visual Studio 16 2019"

        $this.Name="$($this.Platform)-$config"
        if($config -ieq "Release" )
        {
            $this.ConfigurationType = "RelWithDebInfo"
        }
        else
        {
            $this.ConfigurationType = $config
        }

        $this.BuildRoot = Join-Path $baseBuild $this.Name
        $this.SrcRoot = $srcRoot
        $this.CMakeCommandArgs = [System.Collections.ArrayList]@()
        $this.BuildCommandArgs = [System.Collections.ArrayList]@()
        $this.InheritEnvironments = [System.Collections.ArrayList]@()

        if( $this.Platform -eq "x64" )
        {
            $this.CMakeCommandArgs.Add('x64')
        }

        if([Environment]::Is64BitOperatingSystem)
        {
            $this.CMakeCommandArgs.Add('-Thost=x64')
            $this.InheritEnvironments.Add('msvc_x64_x64')
        }
        else
        {
            $this.InheritEnvironments.Add('msvc_x64')
        }

        $this.BuildCommandArgs.Add('/m')
        $this.CMakeBuildVariables = @{}
    }

    <#
    CMakeSettings.json uses an odd serialization form for the variables set.
    It is an array of hash tables with name and value properties
    e.g.:
    [
        {
            "value":  "boo",
            "name":  "baz"
        },
        {
            "value":  "bar",
            "name":  "foo"
        }
    ]
    instead of just:
    {
        "baz":  "boo",
        "foo":  "bar"
    }
    This is likely due to de-serializing to a strong type, though there are ways
    to do that and keep the simpler form. This method deals with that by doing
    a conversion to a custom object with the variables nested such that conversion
    into JSON with ConvertTo-JSON works correctly. This also filters the properties
    to only those used in the JSON file.
    #>
    hidden [hashtable] ToCMakeSettingsJsonifiable()
    {
        $baseBuild = ConvertTo-NormalizedPath ([System.IO.Path]::GetDirectoryName($this.BuildRoot))
        return @{
            name = $this.Name
            generator = $this.Generator
            inheritEnvironments = $this.InheritEnvironments
            configurationType = $this.ConfigurationType
            buildRoot = "$baseBuild`${name}"
            cmakeCommandArgs = $this.CMakeCommandArgs -join ' '
            buildCommandArgs = $this.BuildCommandArgs -join ' '
            ctestCommandArgs = ''
            variables = $this.GetVariablesForConversionToJson()
        }
    }

    #convert hash table into an array of hash tables as needed by conversion to CMakeSettings.Json
    hidden [hashtable[]]GetVariablesForConversionToJson()
    {
        return $this.CMakeBuildVariables.GetEnumerator() | %{ @{name=$_.Key; value=$_.Value} }
    }
}

function Assert-CmakeInfo([Version]$minVersion)
{
    $cmakePaths = where.exe cmake.exe 2>$null
    if( !$cmakePaths )
    {
        throw "CMAKE.EXE not found"
    }

    $cmakeInfo = cmake.exe -E capabilities | ConvertFrom-Json
    if(!$cmakeInfo)
    {
        throw "CMake version not supported. 'cmake -E capabilities' returned nothing"
    }

    $cmakeVer = [Version]::new($cmakeInfo.version.major,$cmakeInfo.version.minor,$cmakeInfo.version.patch)
    if( $cmakeVer -lt $minVersion )
    {
        throw "CMake version not supported. Found: $cmakeVer; Require >= $($minVersion)"
    }
}
Export-ModuleMember -Function Assert-CmakeInfo

function Invoke-CMakeGenerate( [CMakeConfig]$config )
{
    # Verify Cmake version info
    Assert-CmakeInfo ([Version]::new(3, 7, 1))

    $activity = "Generating solution for $($config.Name)"
    Write-Information $activity
    if(!(Test-Path -PathType Container $config.BuildRoot ))
    {
        New-Item -ItemType Container $config.BuildRoot | Out-Null
    }

    # Construct full set of args from fixed options and configuration variables
    $cmakeArgs = New-Object System.Collections.ArrayList
    $cmakeArgs.Add("-G`"$($config.Generator)`"" ) | Out-Null
    foreach( $param in $config.CMakeCommandArgs )
    {
        $cmakeArgs.Add( $param ) | Out-Null
    }

    foreach( $var in $config.CMakeBuildVariables.GetEnumerator() )
    {
        $cmakeArgs.Add( "-D$($var.Key)=$($var.Value)" ) | Out-Null
    }

    $cmakeArgs.Add( $config.SrcRoot ) | Out-Null

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    pushd $config.BuildRoot
    try
    {
        Write-Information "cmake $cmakeArgs"
        & cmake $cmakeArgs

        if($LASTEXITCODE -ne 0 )
        {
            throw "Cmake generation exited with non-zero exit code: $LASTEXITCODE"
        }
    }
    finally
    {
        $timer.Stop()
        popd
        Write-Verbose "Generation Time: $($timer.Elapsed.ToString())"
    }
}
Export-ModuleMember -Function Generate-CMake

function Invoke-CmakeBuild([CMakeConfig]$config)
{
    # Verify Cmake version info
    Assert-CmakeInfo ([Version]::new(3, 7, 1))

    Write-Information "CMake Building $($config.Name)"

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try
    {
        Write-Information "cmake --build $config.BuildRoot --config $config.ConfigurationType -- $config.BuildCommandArgs"
        cmake --build $config.BuildRoot --config $config.ConfigurationType -- $config.BuildCommandArgs
        if($LASTEXITCODE -ne 0 )
        {
            throw "Cmake build exited with non-zero exit code: $LASTEXITCODE"
        }
    }
    finally
    {
        $timer.Stop()
        Write-Information "Build Time: $($timer.Elapsed.ToString())"
    }
}
Export-ModuleMember -Function Build-CMake

function New-CmakeSettings( [Parameter(Mandatory, ValueFromPipeline)][CMakeConfig] $configuration )
{
    BEGIN
    {
        $convertedSettings = [System.Collections.Generic.List[hashtable]]::new( )
    }
    PROCESS
    {
        $convertedSettings.Add( $configuration.ToCMakeSettingsJsonifiable( ) )
    }
    END
    {
        ConvertTo-Json -Depth 4 @{ configurations = $convertedSettings }
    }
}
Export-ModuleMember -Function New-CmakeSettings

function Assert-CMakeList([Parameter(Mandatory=$true)][string] $root)
{
    $cmakeListPath = Join-Path $root CMakeLists.txt
    if( !( Test-Path -PathType Leaf $cmakeListPath ) )
    {
        throw "'CMakeLists.txt' is missing, '$root' does not appear to be a valid source directory"
    }
}
Export-ModuleMember -Function Assert-CMakeList
