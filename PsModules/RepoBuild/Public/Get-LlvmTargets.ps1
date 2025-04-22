# validation set
#    [ValidateSet("AArch64", "AMDGPU", "ARM", "AVR", "BPF", "Hexagon", "Lanai", "LoongArch", "Mips", "MSP430", "NVPTX", "PowerPC", "RISCV", "Sparc", "SPIRV", "SystemZ", "VE", "WebAssembly", "X86", "XCore")]
# Gets the set of supported targets for LLVM
function Get-LlvmTargets
{
    return @(
        "AArch64",
        "AMDGPU",
        "ARM",
        "AVR",
        "BPF",
        "Hexagon",
        "Lanai",
        "LoongArch",
        "Mips",
        "MSP430",
        "NVPTX",
        "PowerPC",
        "RISCV",
        "Sparc",
        "SPIRV",
        "SystemZ",
        "VE",
        "WebAssembly",
        "X86",
        "XCore"
    )
}
