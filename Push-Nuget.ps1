param(
    [Parameter(Position=0, Mandatory=$true)]
    $apiKey,
    [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
    $pkg
)

process
{
    try
    {
        dotnet nuget push $_ -k $apiKey -s 'https://api.nuget.org/v3/index.json' -n true --skip-duplicate
    }
    catch
    {
        Write-Error "Failed to push package $_. Error: $_"
    }
}
