using module "PSModules/CommonBuild/CommonBuild.psd1"
using module "PSModules/RepoBuild/RepoBuild.psd1"

<#
.SYNOPSIS
    Gets the LLVM source based on the tagged version

.DESCRIPTION
    This gets the LLVM source code from the tagged version online. The version tag is built from
    the information in the standard repo build information hash table. This script is useful for
    local builds when updating the version so that validations etc.. are performed before doing
    a full build or commit.
#>
Param([switch]$Force)

Push-location $PSScriptRoot

$buildInfo = Initialize-BuildEnvironment -FullInit:$FullInit
if ($Force)
{
    Remove-Item -Force -Path $buildInfo['LlvmProject'] | Out-Null
}

Clone-LlvmFromTag $buildInfo
