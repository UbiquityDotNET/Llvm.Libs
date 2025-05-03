using module '../PSModules/CommonBuild/CommonBuild.psd1'
using module '../PsModules/RepoBuild/RepoBuild.psd1'

<#
.SYNOPSIS
    Creates a new public release branch the current branch state as an official release tag

.PARAMETER commit
    [Optional] Indicates the specific commit to create the branch from. Default is the head
    of the branch.

.DESCRIPTION
    This function creates and publishes a Release branch
#>

Param([string]$commit = "")
$buildInfo = Initialize-BuildEnvironment

$officialRemoteName = Get-GitRemoteName $buildInfo official
$forkRemoteName = Get-GitRemoteName $buildInfo fork

# create new local branch for the release
$branchName = "release/$(Get-BuildVersionTag $buildInfo)"
Write-Information "Creating release branch in local repo"
if ([string]::IsNullOrWhiteSpace($commit))
{
    Invoke-External git checkout -b $branchName
}
else
{
    Invoke-External git checkout -b $branchName $commit
}

# push to fork so that changes go through normal PR process
Write-Information "Pushing branch to fork"
Invoke-External git push $forkRemoteName -u $branchName

# Push to product repo so it is clear to all a release
# is in process.
Write-Information "Pushing branch to official repository (Push/Write permission required)"
Invoke-External git push $officialRemoteName $branchName
