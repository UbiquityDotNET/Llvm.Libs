$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

Add-AppveyorCompilationMessage -Message 'Updating sub-modules for repository...'
git submodule -q update --init --recursive

Add-AppveyorCompilationMessage -Message 'Initializing Build Environment...'
.\Initialize-BuildEnv.ps1

Add-AppveyorCompilationMessage -Message 'Building...'
Invoke-Build -Publish Project
