# This **IS** a dumb name but it passes the silly PS verb check when importing a module
# It is NEVER USED, instead the alias (below) contains the domain correct but unapproved
# verb term.
function Invoke-CloneLlvmFromTag([hashtable]$buildInfo)
{
    if(!(Test-Path -PathType Container -Path $buildInfo['LlvmProject']))
    {
        Invoke-External git clone --depth 1 -b $buildInfo['LlvmTag'] 'https://github.com/llvm/llvm-project.git' $buildInfo['LlvmProject']
        # remove the .git folder to help save space on automated builds as it isn't needed.
        Remove-Item (Join-Path $buildInfo['LlvmProject'] '.git') -Recurse -Force
    }
}

# workaround stupid warning about exported function verbs without an "approved" verb
# in the name. Use a sensible but unapproved alias name instead. [Sigh, what a mess...]
# see: https://github.com/PowerShell/PowerShell/issues/13637
New-Alias -Name Clone-LlvmFromTag -Value Invoke-CloneLlvmFromTag
