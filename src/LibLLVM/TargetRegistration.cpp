#include <string_view>

#include <llvm/Support/Error.h>
#include <llvm-c/Target.h>
#include <llvm/Config/llvm-config.h>

#include "libllvm-c/TargetRegistration.h"

using namespace llvm;
using namespace std::string_view_literals;

// THESE targets are apparently "experimental";
// They do NOT appear in targets.def and therefore do NOT get any LLVM-C declarations
// in Target.h; If desired, declarations (forward refs really) may be added here
// but any consumption of them in calling code should get a clear "experimental"
// remark.
//
// EXPERIMENTAL: LLVM_HAS_ARC_TARGET
// EXPERIMENTAL: LLVM_HAS_CSKY_TARGET
// EXPERIMENTAL: LLVM_HAS_DIRECTX_TARGET
// EXPERIMENTAL: LLVM_HAS_XTENSA_TARGET

#define MK_TARGET_(t) CodeGenTarget_##t
#define MK_TARGET(t) MK_TARGET_(t)

// If not defined or empty preprocessor considers it 0; Replace with LLVM native arch
#if LIBLLVM_NATIVE_TARGET == 0
#define LIBLLVM_NATIVE_TARGET LLVM_NATIVE_ARCH
#endif

// If not defined or empty preprocessor considers it 0; Replace with native target
#if LIBLLVM_ADDITIONAL_TARGET == 0
#define LIBLLVM_ADDITIONAL_TARGET LIBLLVM_NATIVE_TARGET
#endif

namespace
{
    // maps a "stringized" form of the target name to the enum used here
    // Since the enums are used in code via a C ABI ALL enum values are
    // in the global namespace. A pain, but manageable. The values are also
    // used in the build/project system to indicate which additional targets
    // to build for/support. It's not helpful to use the full C ABI names
    // for that as they are named in such a way to provide some semblance of
    // "scoping". Thus, this constexpr function is used to map the preprocessor
    // values to an appropriate C ABI enum value.
    constexpr CodeGenTarget make_target(std::string_view s)
    {
        if (s == "Native"sv)
        {
            return CodeGenTarget_Native;
        }

        if (s == "AArch64"sv)
        {
            return CodeGenTarget_AArch64;
        }

        if (s == "AMDGPU"sv)
        {
            return CodeGenTarget_AMDGPU;
        }

        if (s == "ARM"sv)
        {
            return CodeGenTarget_ARM;
        }

        if (s == "AVR"sv)
        {
            return CodeGenTarget_AVR;
        }

        if (s == "BPF"sv)
        {
            return CodeGenTarget_BPF;
        }

        if (s == "Hexagon"sv)
        {
            return CodeGenTarget_Hexagon;
        }

        if (s == "Lanai"sv)
        {
            return CodeGenTarget_Lanai;
        }

        if (s == "LoongArch"sv)
        {
            return CodeGenTarget_LoongArch;
        }

        if (s == "MIPS"sv)
        {
            return CodeGenTarget_MIPS;
        }

        if (s == "MSP430"sv)
        {
            return CodeGenTarget_MSP430;
        }

        if (s == "NvidiaPTX"sv)
        {
            return CodeGenTarget_NvidiaPTX;
        }

        if (s == "PowerPC"sv)
        {
            return CodeGenTarget_PowerPC;
        }

        if (s == "RISCV"sv)
        {
            return CodeGenTarget_RISCV;
        }

        if (s == "Sparc"sv)
        {
            return CodeGenTarget_Sparc;
        }

        if (s == "SpirV"sv)
        {
            return CodeGenTarget_SpirV;
        }

        if (s == "SystemZ"sv)
        {
            return CodeGenTarget_SystemZ;
        }

        if (s == "VE"sv)
        {
            return CodeGenTarget_VE;
        }

        if (s == "WebAssembly"sv)
        {
            return CodeGenTarget_WebAssembly;
        }

        if (s == "X86"sv)
        {
            return CodeGenTarget_X86;
        }

        if (s == "XCore"sv)
        {
            return CodeGenTarget_XCore;
        }

        if (s == "All"sv)
        {
            return CodeGenTarget_All;
        }

        // safety check - should never hit this but an exception will break constexpr evaluation
        // so it detects a problem at compile time. Result is that an expression with an invalid
        // value is not interpreted and the result doesn't have a value. Exact message depends on
        // the compiler but is ALWAYS a compile time error.
        throw std::exception("Unknown target name");
    }

    constexpr CodeGenTarget NativeTarget = MK_TARGET(LIBLLVM_NATIVE_TARGET);
    constexpr CodeGenTarget AdditionalTarget = MK_TARGET(LIBLLVM_ADDITIONAL_TARGET);
    constexpr bool NativeOnly = NativeTarget == AdditionalTarget;
    constexpr int NumTargets = NativeOnly ? 1 : 2;

    constexpr bool is_enum_defined(CodeGenTarget target)
    {
        switch (target)
        {
        case CodeGenTarget_Native:
        case CodeGenTarget_AArch64:
        case CodeGenTarget_AMDGPU:
        case CodeGenTarget_ARM:
        case CodeGenTarget_AVR:
        case CodeGenTarget_BPF:
        case CodeGenTarget_Hexagon:
        case CodeGenTarget_Lanai:
        case CodeGenTarget_LoongArch:
        case CodeGenTarget_MIPS:
        case CodeGenTarget_MSP430:
        case CodeGenTarget_NvidiaPTX:
        case CodeGenTarget_PowerPC:
        case CodeGenTarget_RISCV:
        case CodeGenTarget_Sparc:
        case CodeGenTarget_SpirV:
        case CodeGenTarget_SystemZ:
        case CodeGenTarget_VE:
        case CodeGenTarget_WebAssembly:
        case CodeGenTarget_X86:
        case CodeGenTarget_XCore:
            return true;

        case CodeGenTarget_All: // This is just an OR of all of the values as flags and NOT considered a defined value
        default:
            return false;
        }
    }

    constexpr bool has_flag(TargetRegistrationKind value, TargetRegistrationKind flag)
    {
        return 0 != (static_cast<std::int32_t>(value) & static_cast<std::int32_t>(flag));
    }

    void RegisterTargetNative(TargetRegistrationKind registrations = TargetRegistration_All)
    {
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeNativeTarget();
        }

        /* Not supported for the this target
        if( registrations.HasFlag( TargetRegistration.TargetInfo ) )
        {
            LLVMInitializeNativeTargetInfo( );
        }

        if( registrations.HasFlag( TargetRegistration.TargetMachine ) )
        {
            LLVMInitializeNativeTargetMC( );
        }
        */

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeNativeAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeNativeDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeNativeAsmParser();
        }

    }

    void RegisterTargetAArch64(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_AARCH64_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeAArch64Target();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeAArch64TargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeAArch64TargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeAArch64AsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeAArch64Disassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeAArch64AsmParser();
        }
#endif
    }

    void RegisterTargetAMDGPU(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_AMDGPU_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeAMDGPUTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeAMDGPUTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeAMDGPUTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeAMDGPUAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeAMDGPUDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeAMDGPUAsmParser();
        }
#endif
    }

    void RegisterTargetARM(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_ARM_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeARMTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeARMTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeARMTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeARMAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeARMDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeARMAsmParser();
        }
#endif
    }

    void RegisterTargetAVR(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_AVR_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeAVRTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeAVRTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeAVRTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeAVRAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeAVRDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeAVRAsmParser();
        }
#endif
    }

    void RegisterTargetBPF(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_BPF_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeBPFTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeBPFTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeBPFTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeBPFAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeBPFDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeBPFAsmParser();
        }
#endif
    }

    void RegisterTargetHexagon(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_HEXAGON_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeHexagonTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeHexagonTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeHexagonTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeHexagonAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeHexagonDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeHexagonAsmParser();
        }
#endif
    }

    void RegisterTargetLanai(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_LANAI_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeLanaiTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeLanaiTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeLanaiTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeLanaiAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeLanaiDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeLanaiAsmParser();
        }
#endif
    }

    void RegisterTargetLoongArch(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_LOONGARCH_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeLoongArchTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeLoongArchTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeLoongArchTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeLoongArchAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeLoongArchDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeLoongArchAsmParser();
        }
#endif
    }

    void RegisterTargetMIPS(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_MIPS_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeMipsTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeMipsTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeMipsTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeMipsAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeMipsDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeMipsAsmParser();
        }
#endif
    }

    void RegisterTargetMSP430(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_MSP430_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeMSP430Target();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeMSP430TargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeMSP430TargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeMSP430AsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeMSP430Disassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeMSP430AsmParser();
        }
#endif
    }

    void RegisterTargetNvidiaPTX(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_NVPTX_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeNVPTXTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeNVPTXTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeNVPTXTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeNVPTXAsmPrinter();
        }

        /* Not supported for this target
        if( registrations.HasFlag( TargetRegistration.Disassembler ) )
        {
            LLVMInitializeNVPTXDisassembler( );
        }

        if( registrations.HasFlag( TargetRegistration.AsmParser ) )
        {
            LLVMInitializeNVPTXAsmParser( );
        }
        */
#endif
    }

    void RegisterTargetPowerPC(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_POWERPC_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializePowerPCTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializePowerPCTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializePowerPCTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializePowerPCAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializePowerPCDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializePowerPCAsmParser();
        }
#endif
    }

    void RegisterTargetRISCV(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_RISCV_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeRISCVTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeRISCVTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeRISCVTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeRISCVAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeRISCVDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeRISCVAsmParser();
        }
#endif
    }

    void RegisterTargetSparc(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_SPARC_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeSparcTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeSparcTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeSparcTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeSparcAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeSparcDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeSparcAsmParser();
        }
#endif
    }

    void RegisterTargetSpirV(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_SPIRV_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeSPIRVTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeSPIRVTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeSPIRVTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeSPIRVAsmPrinter();
        }

        /* Not supported for this target
        if( registrations.HasFlag( TargetRegistration.Disassembler ) )
        {
            LLVMInitializeSPIRVDisassembler( );
        }

        if( registrations.HasFlag( TargetRegistration.AsmParser ) )
        {
            LLVMInitializeSPIRVAsmParser( );
        }
        */
#endif
    }

    void RegisterTargetSystemZ(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_SYSTEMZ_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeSystemZTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeSystemZTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeSystemZTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeSystemZAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeSystemZDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeSystemZAsmParser();
        }
#endif
    }

    void RegisterTargetVE(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_VE_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeVETarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeVETargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeVETargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeVEAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeVEDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeVEAsmParser();
        }
#endif
    }

    void RegisterTargetWebAssembly(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_WEBASSEMBLY_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeWebAssemblyTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeWebAssemblyTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeWebAssemblyTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeWebAssemblyAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeWebAssemblyDisassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeWebAssemblyAsmParser();
        }
#endif
    }

    void RegisterTargetX86(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_X86_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeX86Target();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeX86TargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeX86TargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeX86AsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeX86Disassembler();
        }

        if (has_flag(registrations, TargetRegistration_AsmParser))
        {
            LLVMInitializeX86AsmParser();
        }
#endif
    }

    void RegisterTargetXCore(TargetRegistrationKind registrations = TargetRegistration_All)
    {
#if LLVM_HAS_XCORE_TARGET
        if (has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeXCoreTarget();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeXCoreTargetInfo();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeXCoreTargetMC();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeXCoreAsmPrinter();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeXCoreDisassembler();
        }

        /* Not supported for this target
        if( registrations.HasFlag( TargetRegistration.AsmParser ) )
        {
            LLVMInitializeXCoreAsmParser( );
        }
        */
#endif
    }
}

extern "C"
{
    LLVMErrorRef LibLLVMRegisterTarget(CodeGenTarget target, TargetRegistrationKind registrations)
    {
        if(!is_enum_defined(target))
        {
            return LLVMCreateStringError("Undefined target");
        }

        // TODO: This is compiler dependant
        // Not always redundant (Compile time dependency) redundancy if ONLY one target
        //#pragma warning(suppress:6287) // Redundant code: the left and right subexpressions are identical
        if(target != NativeTarget && target != AdditionalTarget)
        {
            return LLVMCreateStringError("Unsupported target for this build");
        }

        // NOTE: All but 2 of these will result in a NOP and won't actually be used
        //       Since the target is passed by caller it isn't a compile time constant.
        //       It is checked above for a supported value so this saves on LOTs of
        //       preprocessor conditionals. A good optimizer can see that most of these
        //       are NOP and simplify this to ONLY the supported targets.
        switch (target)
        {
        case CodeGenTarget_Native:
            RegisterTargetNative(registrations);
            return nullptr;

        case CodeGenTarget_AArch64:
            RegisterTargetAArch64(registrations);
            return nullptr;

        case CodeGenTarget_AMDGPU:
            RegisterTargetAMDGPU(registrations);
            return nullptr;

        case CodeGenTarget_ARM:
            RegisterTargetARM(registrations);
            return nullptr;

        case CodeGenTarget_AVR:
            RegisterTargetAVR(registrations);
            return nullptr;

        case CodeGenTarget_BPF:
            RegisterTargetBPF(registrations);
            return nullptr;

        case CodeGenTarget_Hexagon:
            RegisterTargetHexagon(registrations);
            return nullptr;

        case CodeGenTarget_Lanai:
            RegisterTargetLanai(registrations);
            return nullptr;

        case CodeGenTarget_LoongArch:
            RegisterTargetLoongArch(registrations);
            return nullptr;

        case CodeGenTarget_MIPS:
            RegisterTargetMIPS(registrations);
            return nullptr;

        case CodeGenTarget_MSP430:
            RegisterTargetMSP430(registrations);
            return nullptr;

        case CodeGenTarget_NvidiaPTX:
            RegisterTargetNvidiaPTX(registrations);
            return nullptr;

        case CodeGenTarget_PowerPC:
            RegisterTargetPowerPC(registrations);
            return nullptr;

        case CodeGenTarget_RISCV:
            RegisterTargetRISCV(registrations);
            return nullptr;

        case CodeGenTarget_Sparc:
            RegisterTargetSparc(registrations);
            return nullptr;

        case CodeGenTarget_SpirV:
            RegisterTargetSpirV(registrations);
            return nullptr;

        case CodeGenTarget_SystemZ:
            RegisterTargetSystemZ(registrations);
            return nullptr;

        case CodeGenTarget_VE:
            RegisterTargetVE(registrations);
            return nullptr;

        case CodeGenTarget_WebAssembly:
            RegisterTargetWebAssembly(registrations);
            return nullptr;

        case CodeGenTarget_X86:
            RegisterTargetX86(registrations);
            return nullptr;

        case CodeGenTarget_XCore:
            RegisterTargetXCore(registrations);
            return nullptr;

        case CodeGenTarget_All:
            RegisterTargetNative(registrations);
            if constexpr (!NativeOnly)
            {
                // Recursive call but not infinitely so as specific type used and ALL is blocked
                // as a valid value for the preprocessor setting via static_asserts above.
                return LibLLVMRegisterTarget(AdditionalTarget, registrations);
            }
            return nullptr;

        default:
            return LLVMCreateStringError("Unknown target type");
        }
    }

    std::int32_t LibLLVMGetNumTargets()
    {
        return NumTargets;
    }

    LLVMErrorRef LibLLVMGetRuntimeTargets(CodeGenTarget* targetArray, std::int32_t lengthOfArray)
    {
        if(lengthOfArray < NumTargets)
        {
            // sadly C++17 doesn't support constexpr std::format so providing actual number in the
            // error is not an easy option.
            return LLVMCreateStringError("Invalid array length provided");
        }

        targetArray[0] = NativeTarget;

        if constexpr (!NativeOnly)
        {
            targetArray[1] = AdditionalTarget;
        }

        return nullptr;
    }
}
