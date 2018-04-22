$InformationPreference = Continue
.\Initialize-BuildEnv.ps1
Invoke-Build -Publish Project
