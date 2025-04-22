# get an LLVM target for the native runtime of this build
function Get-NativeTarget
{
    param()

    $hostArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    switch($hostArch)
    {
        X86 {'X86'}
        X64 {'X86'}  # 64 vs 32 is a CPU/Feature option in LLVM
        Arm {'ARM'}
        Armv6 {'ARM'} # distinction between ARM-32 CPUs is a CPU/Feature in LLVM
        Arm64 {'AArch64'}
        Wasm {'WebAssembly'} # unlikely to ever occur but here for for completeness
        LoongArch64 {'LoongArch'}
        Ppc64le {'PowerPc'}
        RiscV64 {'RISCV'} # 64 vs 32 is a CPU/Feature option in LLVM
        default { throw "Unknown Native environment for host: $hostArch"}
    }
}
