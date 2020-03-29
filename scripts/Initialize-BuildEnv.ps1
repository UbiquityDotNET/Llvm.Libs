#Requires -Version 5.0

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

pushd $PSScriptRoot
try
{
    . .\Llvm-Build\Llvm-Build.ps1

    Write-Information "Initializing build environment for this repository"
    Initialize-BuildEnvironment
}
finally
{
    popd
}
