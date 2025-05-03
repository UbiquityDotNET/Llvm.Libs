using module '../PSModules/CommonBuild/CommonBuild.psd1'
using module '../PsModules/RepoBuild/RepoBuild.psd1'

<#
.SYNOPSIS
    Publishes the current release as a new branch to the upstream repository

.DESCRIPTION
    Generally, this function will finalize the changes for the release and create a new "merge-back"
    branch to manage any conflicts to prevent commits "AFTER" the tag is applied to the origin repository.
    After this completes it is still required to create a PR for the resulting branch to the origin's "develop"
    branch to merge any changes in this branch - including the release tag.

    Completing the PR with a release tag should trigger the start the official build via a GitHub action
    or other such automated build processes. These, normally, also include publication of the resulting
    binaries as appropriate. This function only pushes the tag, the rest is up to the back-end configuration
    of the repository.

.NOTE
    For the gory details of this process see: https://www.endoflineblog.com/implementing-oneflow-on-github-bitbucket-and-gitlab
#>

Param()
$buildInfo = Initialize-BuildEnvironment

# merging the tag to develop branch on the official repository triggers the official build and release of the Nuget Packages
$tagName = Get-BuildVersionTag $buildInfo
$officialRemoteName = Get-GitRemoteName $buildInfo official
$forkRemoteName = Get-GitRemoteName $buildInfo fork

$releaseBranch = "release/$tagName"
$officialReleaseBranch = "$officialRemoteName/$releaseBranch"
$mergeBackBranchName = "merge-back-$tagName"

Write-Information 'Fetching from official repository'
Invoke-External git fetch $officialRemoteName

Write-Information "Switching to release branch [$officialReleaseBranch]"
Invoke-External git switch '-c' $releasebranch $officialReleaseBranch

Write-Information 'Creating tag of this branch as the release'
Invoke-External git tag $tagname '-m' "Official release: $tagname"

Write-Information 'Pushing tag to official remote [Starts automated build release process]'
Invoke-External git push $officialRemoteName '--tags'

Write-Information 'Creating local merge-back branch to merge changes associated with the release'
# create a "merge-back" child branch to handle any updates/conflict resolutions when applying
# the changes made in the release branch back to the develop branch.
Invoke-External git checkout '-b' $mergeBackBranchName $releasebranch
Write-Information 'pushing merge-back branch to fork'
Invoke-External git push $forkRemoteName $mergeBackBranchName
