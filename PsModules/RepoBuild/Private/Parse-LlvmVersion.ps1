function Parse-LlvmVersion( [hashtable]$buildInfo )
{
    # Version information is set in a repo-wide CMAKE module
    $cmakeListPath = [System.IO.Path]::Combine($buildInfo['LlvmProject'], 'cmake', 'Modules', 'LLVMVersion.cmake')
    $props = @{}
    $matches = Select-String -Path $cmakeListPath -Pattern "set\(LLVM_VERSION_(MAJOR|MINOR|PATCH) ([0-9]+)\)" |
        %{ $_.Matches } |
        %{ $props.Add( $_.Groups[1].Value, [Convert]::ToInt32($_.Groups[2].Value) ) }
    return $props
}
