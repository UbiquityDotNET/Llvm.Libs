function New-LlvmCmakeConfig
{
    [OutputType([hashtable])]
    param(
        [string]$name,
        [ValidateSet('AArch64', 'AMDGPU', 'ARM', 'AVR', 'BPF', 'Hexagon', 'Lanai', 'LoongArch', 'Mips', 'MSP430', 'NVPTX', 'PowerPC', 'RISCV', 'Sparc', 'SPIRV', 'SystemZ', 'VE', 'WebAssembly', 'X86', 'XCore')]
        $additionalTarget,
        [string]$buildConfig,
        [hashtable]$buildInfo,
        [string]$cmakeSrcRoot = $buildInfo['LlvmRoot'],
        [switch]$AllTargets
    )

    $cmakeConfig = New-CMakeConfig $name $buildConfig $buildInfo $cmakeSrcRoot
    $buildVars = $cmakeConfig['CMakeBuildVariables']
    $buildVars['LLVM_ENABLE_RTTI'] = 'OFF'
    $buildVars['LLVM_BUILD_TOOLS'] = 'OFF'
    $buildVars['LLVM_BUILD_UTILS'] = 'OFF'
    $buildVars['LLVM_BUILD_DOCS'] = 'OFF'
    $buildVars['LLVM_BUILD_RUNTIME'] = 'OFF'
    $buildVars['LLVM_BUILD_RUNTIMES'] = 'OFF'
    $buildVars['LLVM_BUILD_BENCHMARKS']  = 'OFF'
    $buildVars['LLVM_ENABLE_BINDINGS']  = 'OFF'
    $buildVars['LLVM_BUILD_TELEMETRY'] = 'OFF'
    $buildVars['LLVM_OPTIMIZED_TABLEGEN'] = 'ON'
    $buildVars['LLVM_REVERSE_ITERATION'] = 'OFF'
    $buildVars['LLVM_INCLUDE_BENCHMARKS'] = 'OFF'
    $buildVars['LLVM_INCLUDE_DOCS'] = 'OFF'
    $buildVars['LLVM_INCLUDE_EXAMPLES'] = 'OFF'
    $buildVars['LLVM_INCLUDE_GO_TESTS'] = 'OFF'
    $buildVars['LLVM_INCLUDE_RUNTIMES'] = 'OFF'
    $buildVars['LLVM_INCLUDE_TESTS'] = 'OFF'
    $buildVars['LLVM_INCLUDE_TOOLS'] = 'OFF'
    $buildVars['LLVM_INCLUDE_UTILS'] = 'OFF'
    $buildVars['LLVM_TARGETS_TO_BUILD']  = $AllTargets ? 'all' : '$(Get-NativeTarget);$additionalTarget'
    $buildVars['LLVM_ADD_NATIVE_VISUALIZERS_TO_SOLUTION'] = 'ON'

    #if ($IsWindows)
    #{
    #    $buildVars['LLVM_ENABLE_PDB'] = 'ON'
    #}

    return $cmakeConfig
}
