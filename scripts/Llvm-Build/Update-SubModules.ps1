$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
Write-Information 'Updating sub-modules for repository...'
Add-AppveyorCompilationMessage -Message 'Updating sub-modules for repository...'
git submodule -q update --init --recursive
Write-Information 'Finished updating sub-modules'
Add-AppveyorCompilationMessage -Message 'Finished updating sub-modules'
