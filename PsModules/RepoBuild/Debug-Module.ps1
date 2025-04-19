# This script is used for debugging the module when using the
# [Powershell Tools for VisualStudio 2022](https://marketplace.visualstudio.com/items?itemName=AdamRDriscoll.PowerShellToolsVS2022)
Import-Module $PSScriptRoot\RepoBuild.psd1 -Force -Verbose

# Get and show the Functions to export to allow easy updates of the PSD file
# this eliminates most of the error prone tedious nature of manual updates.
RepoBuild\Get-FunctionsToExport

# This is private and should not be exported - Should generate an error
$buildInfo = @{
    BuildOutputPath = 'foo/bar'
    LlvmRoot = 'foo/bar/llvm-project/llvm'
}

$config = New-LLvmCmakeConfig "x64-Release" ARM "release" $buildInfo
if(!$config -or $config -isnot [hashtable])
{
    throw "Null or wrong type returned!"
}
