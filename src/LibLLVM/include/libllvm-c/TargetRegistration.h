#ifndef _TARGETREGISTRATION_H_
#define _TARGETREGISTRATION_H_
#include <cstdint>
#include <climits>

#include "llvm-c/Support.h"
#include <llvm-c/Error.h>

LLVM_C_EXTERN_C_BEGIN

// This needs to provide a single target neutral registration that handles the native target AND one additional CPU
// In a target independent stable API.

enum CodeGenTarget
{
    CodeGenTarget_Native,
    CodeGenTarget_AArch64,
    CodeGenTarget_AMDGPU,
    CodeGenTarget_ARM,
    CodeGenTarget_AVR,
    CodeGenTarget_BPF,
    CodeGenTarget_Hexagon,
    CodeGenTarget_Lanai,
    CodeGenTarget_LoongArch,
    CodeGenTarget_MIPS,
    CodeGenTarget_MSP430,
    CodeGenTarget_NvidiaPTX,
    CodeGenTarget_PowerPC,
    CodeGenTarget_RISCV,
    CodeGenTarget_Sparc,
    CodeGenTarget_SpirV,
    CodeGenTarget_SystemZ,
    CodeGenTarget_VE,
    CodeGenTarget_WebAssembly,
    CodeGenTarget_X86,
    CodeGenTarget_XCore,
    CodeGenTarget_All = INT_MAX
};

// This is a "FLAGS" enum
enum TargetRegistrationKind
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
LLVMErrorRef LibLLVMRegisterTarget(CodeGenTarget target, TargetRegistrationKind registrations);
std::int32_t LibLLVMGetNumTargets();
LLVMErrorRef LibLLVMGetRuntimeTargets(CodeGenTarget* targetArray, std::int32_t lengthOfArray);

LLVM_C_EXTERN_C_END
#endif
