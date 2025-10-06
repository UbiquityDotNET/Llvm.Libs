function Invoke-BindingsGenerator([hashtable]$buildInfo , [hashtable]$Options)
{
    if (!$IsWindows)
    {
        throw "Building/using the generator is not supported and not needed for non-Windows platforms"
    }

    if(!$Options.ContainsKey('LlvmRoot') -or ($Options['LlvmRoot'] -isnot [string]))
    {
        throw "Options value for required LlvmRoot is missing or invalid"
    }

    if(!$Options.ContainsKey('ConfigPathRoot') -or ($Options['ConfigPathRoot'] -isnot [string]))
    {
        Write-Error ($Options | Format-List | Out-String)
        throw "Options value for required ConfigPathRoot is missing or invalid"
    }

    if(!$Options.ContainsKey('ExtensionsRoot') -or ($Options['ExtensionsRoot'] -isnot [string]))
    {
        throw "Options value for required ExtensionsRoot is missing or invalid"
    }

    Write-Information "Building LllvmBindingsGenerator"
    $bindingsGeneratorCsProj = Join-Path 'src' 'LlvmBindingsGenerator' 'LlvmBindingsGenerator.csproj'
    Invoke-External dotnet build $bindingsGeneratorCsProj

    # construct paths for generator using platform neutral techniques to ensure they are in proper format and reduce the length of commands
    $bindingsGeneratorTFM = 'net8.0'
    $bindingsGenerator = Join-Path $buildInfo['BuildOutputPath'] 'bin' 'LlvmBindingsGenerator' 'Release' $bindingsGeneratorTFM 'LlvmBindingsGenerator.dll'

    # run the generator so the output is available to subsequent stages
    Write-Information "Generating P/Invoke Bindings"

    $generatorArgs = [System.Collections.ArrayList]@(
        $bindingsGenerator,
        '-l', $Options['LlvmRoot'],
        '-e', $Options['ExtensionsRoot']
        '-i', $Options['ConfigPathRoot']
    )

    if ($Options.ContainsKey('ExportsDefFilePath'))
    {
        $generatorArgs.AddRange(@('-d', $Options['ExportsDefFilePath']))
    }

    Write-Information "dotnet $($generatorArgs -join ' ')"
    # NOTE: using array and splatting args to handle optional args and due to various parsing issues with parameters
    # [see](https://github.com/PowerShell/PowerShell/issues?q=is%3Aissue+in%3Atitle+argument-parsing)
    Invoke-External dotnet @generatorArgs
}
