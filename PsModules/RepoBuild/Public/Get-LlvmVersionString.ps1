function Get-LlvmVersionString( [hashtable]$buildInfo )
{
    $llvmVersion = $buildInfo['LlvmVersion']
    return "$($llvmVersion.Major).$($llvmVersion.Minor).$($llvmVersion.Patch)"
}

