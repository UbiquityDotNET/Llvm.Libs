using module '../PSModules/CommonBuild/CommonBuild.psd1'
using module '../PsModules/RepoBuild/RepoBuild.psd1'

<#
.SYNOPSIS
    Clears environment variables used to fake an automated release build

.DESCRIPTION
    This is used for internal developer testing only. It allows validation and debugging of
    portions of scripts and builds that is only available for formal automated builds. Since,
    debugging an actual automated build is not possible this is the closest thing possible.

.PARAMETER Force
    Bypasses confirmation prompts and clears the environment variables for the build.
#>
[cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'High')]
Param([switch]$Force)

if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm'))
{
    $ConfirmPreference = 'None'
}

if($PSCmdlet.ShouldProcess("Environment", "Stop Fake release"))
{
    # clear values set in Start-FakeRelease.ps1
    $env:GITHUB_ACTIONS = $null
    $env:GITHUB_REF = $null
}

