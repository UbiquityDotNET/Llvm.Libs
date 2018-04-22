$InformationPreference = Continue
Write-Information "Initializing..."
.\Initialize-BuildEnv.ps1
Write-Information "Building..."
Invoke-Build -Publish Project
