function Build-LlvmLibs([hashtable]$buildinfo, [LlvmTarget]$additionalTarget)
{
    <#
    NUMBER_OF_PROCESSORS < 6;
    This is generally an inefficient number of cores available (Ideally 6-8 are needed for a timely build)
    On an automated build service this may cause the build to exceed the time limit allocated for a build
    job. (As an example AppVeyor has a 1hr per job limit with VMs containing only 2 cores, which is
    unfortunately just not capable of completing the build for a single platform+configuration in time, let alone multiple combinations.)
    #>

    if( ([int]$env:NUMBER_OF_PROCESSORS) -lt 6 )
    {
        Write-Warning "NUMBER_OF_PROCESSORS{ $env:NUMBER_OF_PROCESSORS } < 6; Performance will suffer"
    }
}
