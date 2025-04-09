# Sanity check the version information to validate tag was correct and matches on-disk sources
function Assert-LlvmSourceVersion([hashtable]$buildinfo)
{
    $llvmVersion = $BuildInfo['LlvmVersion']
    Write-Verbose "Expected Version: `n$($llvmVersion | Out-String)"

    $llvmRepoVersion = Parse-LlvmVersion($buildInfo);
    Write-Verbose "Actual Version: `n$($llvmRepoVersion | Out-String)"

    if($llvmRepoVersion['MAJOR'] -ne $llvmVersion.Major -or
       $llvmRepoVersion['MINOR'] -ne $llvmVersion.Minor -or
       $llvmRepoVersion['PATCH'] -ne $llvmVersion.Patch)
    {
        throw "Unexpected LLVM source version."
    }
}
