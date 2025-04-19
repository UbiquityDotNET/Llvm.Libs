# get an LLVM target for the native runtime of this build
function Get-NativeTarget
{
    [OutputType([LlvmTarget])]
    param()

    $hostArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    switch($hostArch)
    {
        X86 {[LlvmTarget]::X86}
        X64 {[LlvmTarget]::X86}  # 64 vs 32 is a CPU/Feature option in LLVM
        Arm {[LlvmTarget]::ARM}
        Armv6 {[LlvmTarget]::ARM} # distinction between ARM-32 CPUs is a CPU/Feature in LLVM
        Arm64 {[LlvmTarget]::AArch64}
        Wasm {[LlvmTarget]::WebAssembly} # unlikely to ever occur but here for for completeness
        LoongArch64 {[LlvmTarget]::LoongArch}
        Ppc64le {[LlvmTarget]::PowerPc}
        RiscV64 {[LlvmTarget]::RISCV} # 64 vs 32 is a CPU/Feature option in LLVM
        default { throw "Unknown Native environment for host: $hostArch"}
    }
}
