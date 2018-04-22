$InformationPreference = Continue
Write-Information "Initializing Build Environment..."
.\Initialize-BuildEnv.ps1
Write-Information "Building..."
Invoke-Build -Publish Project
