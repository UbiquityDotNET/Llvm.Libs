#ifndef _TARGETREGISTRATION_H_
#define _TARGETREGISTRATION_H_
#include <cstdint>
#include <climits>

#include "llvm-c/Support.h"
#include <llvm-c/Error.h>

LLVM_C_EXTERN_C_BEGIN
    // This needs to provide a single target neutral registration that handles the native target AND one additional CPU
    // in a target independent stable API.

    enum LibLLVMCodeGenTarget
    {
        CodeGenTarget_None = 0,    // Invalid value
        CodeGenTarget_Native,      // Generic value for the native architecture of the current runtime (generally used for local JIT execution)
        CodeGenTarget_AArch64,     // ARM 64 bit Architecture
        CodeGenTarget_AMDGPU,      // AMD GPUs
        CodeGenTarget_ARM,         // ARM 32 bit (including thumb mode)
        CodeGenTarget_AVR,         // Atmel AVR Micro controller
        CodeGenTarget_BPF,         // Berkeley Packet Filter (Including eBPF)
        CodeGenTarget_Hexagon,     // Qualcom Hexagon DSP/NPU family
        CodeGenTarget_Lanai,       // Un[der]documented Google (Myricom) processor (see: https://q3k.org/lanai.html)
        CodeGenTarget_LoongArch,   // Loongson Custom ISA CPU (see: https://en.wikipedia.org/wiki/Loongson)
        CodeGenTarget_MIPS,        // MIPS based CPU
        CodeGenTarget_MSP430,      // TI MSP430 Mixed-signal microcontroller
        CodeGenTarget_NVPTX,       // Nvidia Parallel Thread Execution (Nvidia GPUs)
        CodeGenTarget_PowerPC,     // Apple/IBM/Motorola CPU
        CodeGenTarget_RISCV,       // Open Source RISC Architecture
        CodeGenTarget_Sparc,       // Sun Microsystems SPARC CPU
        CodeGenTarget_SPIRV,       // Standard Portable Intermediate Representation (see: https://en.wikipedia.org/wiki/Standard_Portable_Intermediate_Representation)
        CodeGenTarget_SystemZ,     // z/Architecture (IBM 64 bit CISC) (see: https://en.wikipedia.org/wiki/Z/Architecture)
        CodeGenTarget_VE,          // NEC's Vector Engine
        CodeGenTarget_WebAssembly, // Browser interpreted/JIT execution
        CodeGenTarget_X86,         // Intel X86 and AMD64
        CodeGenTarget_XCore,       // XMOS core (see: https://en.wikipedia.org/wiki/XMOS)
        CodeGenTarget_All = INT_MAX
    };

    // This is a "FLAGS" enum
    enum LibLLVMTargetRegistrationKind
    {
        TargetRegistration_None = 0x00,
        TargetRegistration_Target = 0x01,
        TargetRegistration_TargetInfo = 0x02,
        TargetRegistration_TargetMachine = 0x04,
        TargetRegistration_AsmPrinter = 0x08,
        TargetRegistration_Disassembler = 0x10,
        TargetRegistration_AsmParser = 0x20,
        TargetRegistration_CodeGenRegistration = TargetRegistration_Target | TargetRegistration_TargetInfo | TargetRegistration_TargetMachine,
        TargetRegistration_All = TargetRegistration_CodeGenRegistration | TargetRegistration_AsmPrinter | TargetRegistration_Disassembler | TargetRegistration_AsmParser
    };

    // NOTE: registrations is not value checked. ONLY valid bits are tested and additional bits are ignored (NOP)
    LLVMErrorRef LibLLVMRegisterTarget(LibLLVMCodeGenTarget target, LibLLVMTargetRegistrationKind registrations);
    int32_t LibLLVMGetNumTargets();
    LLVMErrorRef LibLLVMGetRuntimeTargets(LibLLVMCodeGenTarget* targetArray, int32_t lengthOfArray);

    // Return is the version info for this library as a string (CSemVer/CSemVer-CI)
    // Version string is a constant so there is no need to release it for marshaling.
    char const* LibLLVMGetVersion(size_t* len);
LLVM_C_EXTERN_C_END

#endif
