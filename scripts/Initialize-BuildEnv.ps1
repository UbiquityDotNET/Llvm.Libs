$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$InformationPreference = [System.Management.Automation.ActionPreference]::Continue

$env:PSModulePath = "$env:PSModulePath;$PSScriptRoot"

Write-Information "Importing module Llvm-Build"
Import-Module Llvm-Build

Write-Information "Initializing build environment for this repository"
Initialize-BuildEnvironment
