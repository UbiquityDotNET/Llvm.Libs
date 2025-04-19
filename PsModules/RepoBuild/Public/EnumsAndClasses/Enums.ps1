# NOTE: These targets are used as the NAMES of the generated libraries and NUGET packages as well
#       as the names of targets for MCKAE code generation (LLVM CMAKE variables). Thus they need to
#       match the spelling and casing expected by the LLVM CMKAE builds.
#
#       These are provided to the native library (LibLLVM) during build as a C Preporocessor define.
#       The define is converted to a string and then to an enumerated value at compile time.
#       This conversion has some flexibility on the naming to convert to the cannonical form
#       used in the library. (The names in native code match the "preferred" spelling and casing
#       as used by the LLVM APIs).
#
# From CMAKE Build with invalid target name:
#  [...<Invalid target>] It may be experimental, if so it must be passed via LLVM_EXPERIMENTAL_TARGETS_TO_BUILD.
#
#  Core tier targets:
#  AArch64;AMDGPU;ARM;AVR;BPF;Hexagon;Lanai;LoongArch;Mips;MSP430;NVPTX;PowerPC;RISCV;Sparc;SPIRV;SystemZ;VE;WebAssembly;X86;XCore
#
#
#  Known experimental targets: ARC;CSKY;DirectX;M68k;Xtensa
# see: llvm-project\llvm\CMakeLists.txt [LLVM_ALL_TARGETS][LLVM_ALL_EXPERIMENTAL_TARGETS]
# NOTE: Changes to this enum will require a completely new PS session. :(
enum LlvmTarget
{
    AArch64
    AMDGPU
    ARM
    AVR
    BPF
    Hexagon
    Lanai
    LoongArch
    Mips
    MSP430
    NVPTX
    PowerPC
    RISCV
    Sparc
    SPIRV
    SystemZ
    VE
    WebAssembly
    X86
    XCore
}
