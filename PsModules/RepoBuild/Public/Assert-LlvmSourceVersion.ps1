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
        Write-Error "Unexpected LLVM source version."
        Write-Error "Expected Version: `n$($llvmVersion | Out-String)"
        Write-Error "Actual Version: `n$($llvmRepoVersion | Out-String)"
    }
}
