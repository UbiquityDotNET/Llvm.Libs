$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

Write-Information 'Updating sub-modules for repository...'
git submodule -q update --init --recursive

Write-Information 'Initializing Build Environment...'
.\scripts\Initialize-BuildEnv.ps1

Write-Information -Message 'Building...'
Invoke-Build -Publish Project
