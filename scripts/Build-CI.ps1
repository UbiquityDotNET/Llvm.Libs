$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

Write-Information 'Updating sub-modules for repository...'
git submodule -q update --init --recursive

Write-Information 'Initializing Build Environment...'
.\scripts\Initialize-BuildEnv.ps1

invoke-nuget sources Add -Source https://ci.appveyor.com/nuget/UbiquityDotNet/api/v2/package -Username $env:acctfeed_username -Password $env:acct_feed_pw

Write-Information -Message 'Building...'
Invoke-Build -Publish Project
