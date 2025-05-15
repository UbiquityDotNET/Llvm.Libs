#include <string_view>
#include <limits>

#include <llvm/Support/Error.h>
#include <llvm/Config/llvm-config.h>
#include <llvm-c/Target.h>
#include <llvm-c/Core.h>

#include "libllvm-c/TargetRegistrationBindings.h"
#include "CSemVer.h"

using namespace llvm;
using namespace std::string_view_literals;

// THESE targets are apparently "experimental";
// They do NOT appear in targets.def, AsmPrinters.def, AsmParsers.def, or Disassemblers.def.
// Therefore they do NOT get any LLVM-C declarations in Target.h; If desired, declarations
// (forward refs really) may be added here but any consumption of them in calling code should
// get a clear "experimental" remark.
//
// EXPERIMENTAL: ARC, CSKY, DirectX, M68k, XTensa

namespace
{
    template<class TCollection, typename TElement>
    constexpr bool contains(TCollection&& c, TElement v)
    {
        return std::find(std::begin(c), std::end(c), v) != std::end(c);
    };

    // Converts a string into a target; This has some flexibility
    // on casing and spellings to allow for simpler build infrastructure
    // The names used in the preprocessor symbols don't need to be
    // as exact as the symbolic names. This will translate them at
    // compile time to a constexpr value member of LibLLVMCodeGenTarget.
    constexpr LibLLVMCodeGenTarget mk_target(std::string_view s)
    {
        if (s == "Native"sv)
        {
            return CodeGenTarget_Native;
        }

        if (s == "AArch64"sv || s == "ARM64"sv)
        {
            return CodeGenTarget_AArch64;
        }

        if (s == "AMDGPU"sv || s == "AmdGPU"sv || s == "AmdGpu"sv)
        {
            return CodeGenTarget_AMDGPU;
        }

        if (s == "ARM"sv || s == "ARM32"sv || s == "Arm"sv || s == "Arm32"sv)
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

        if (s == "Hexagon"sv || s == "HEXAGON"sv)
        {
            return CodeGenTarget_Hexagon;
        }

        if (s == "Lanai"sv || s == "LANAI"sv)
        {
            return CodeGenTarget_Lanai;
        }

        if (s == "LoongArch"sv)
        {
            return CodeGenTarget_LoongArch;
        }

        if (s == "MIPS"sv || s == "Mips"sv)
        {
            return CodeGenTarget_MIPS;
        }

        if (s == "MSP430"sv || s == "Msp430"sv)
        {
            return CodeGenTarget_MSP430;
        }

        if (s == "NVPTX"sv || s == "NvidiaPTX"sv)
        {
            return CodeGenTarget_NVPTX;
        }

        if (s == "PowerPC"sv || s == "POWERPC")
        {
            return CodeGenTarget_PowerPC;
        }

        if (s == "RISCV"sv || s == "RiscV"sv)
        {
            return CodeGenTarget_RISCV;
        }

        if (s == "Sparc"sv || s == "SPARC"sv)
        {
            return CodeGenTarget_Sparc;
        }

        if (s == "SpirV"sv || s == "SPIRV"sv)
        {
            return CodeGenTarget_SPIRV;
        }

        if (s == "SystemZ"sv || s == "SYSTEMZ"sv)
        {
            return CodeGenTarget_SystemZ;
        }

        if (s == "VE"sv )
        {
            return CodeGenTarget_VE;
        }

        if (s == "WebAssembly"sv || s == "WEBASSEMBLY"sv || s == "WASM")
        {
            return CodeGenTarget_WebAssembly;
        }

        if (s == "X86"sv || s == "x86"sv)
        {
            return CodeGenTarget_X86;
        }

        if (s == "XCore"sv || s == "XCORE"sv)
        {
            return CodeGenTarget_XCore;
        }

        if (s == "All"sv || s == "ALL"sv)
        {
            return CodeGenTarget_All;
        }

        return CodeGenTarget_None;
    }

#if INCLUDE_COMPILE_TIME_UT
    namespace compile_time_UT
    {
        static_assert(sizeof(LibLLVMVersionInfo) == sizeof(uint64_t));
        static_assert(alignof(LibLLVMVersionInfo) == alignof(uint64_t));

        static_assert(mk_target("None"sv) == CodeGenTarget_None);
        static_assert(mk_target("Native"sv) == CodeGenTarget_Native);
        static_assert(mk_target("AArch64"sv) == CodeGenTarget_AArch64);
        static_assert(mk_target("AMDGPU"sv) == CodeGenTarget_AMDGPU);
        static_assert(mk_target("ARM"sv) == CodeGenTarget_ARM);
        static_assert(mk_target("AVR"sv) == CodeGenTarget_AVR);
        static_assert(mk_target("BPF"sv) == CodeGenTarget_BPF);
        static_assert(mk_target("Hexagon"sv) == CodeGenTarget_Hexagon);
        static_assert(mk_target("Lanai"sv) == CodeGenTarget_Lanai);
        static_assert(mk_target("LoongArch"sv) == CodeGenTarget_LoongArch);
        static_assert(mk_target("MIPS"sv) == CodeGenTarget_MIPS);
        static_assert(mk_target("MSP430"sv) == CodeGenTarget_MSP430);
        static_assert(mk_target("NVPTX"sv) == CodeGenTarget_NVPTX);
        static_assert(mk_target("PowerPC"sv) == CodeGenTarget_PowerPC);
        static_assert(mk_target("RISCV"sv) == CodeGenTarget_RISCV);
        static_assert(mk_target("Sparc"sv) == CodeGenTarget_Sparc);
        static_assert(mk_target("SpirV"sv) == CodeGenTarget_SPIRV);
        static_assert(mk_target("SystemZ"sv) == CodeGenTarget_SystemZ);
        static_assert(mk_target("VE"sv) == CodeGenTarget_VE);
        static_assert(mk_target("WebAssembly"sv) == CodeGenTarget_WebAssembly);
        static_assert(mk_target("X86"sv) == CodeGenTarget_X86);
        static_assert(mk_target("XCore"sv) == CodeGenTarget_XCore);
        static_assert(mk_target("All"sv) == CodeGenTarget_All);

        // validate alternate casing/spellings supported (Where available)
        static_assert(mk_target("ARM64"sv) == CodeGenTarget_AArch64);
        static_assert(mk_target("AmdGPU"sv) == CodeGenTarget_AMDGPU);
        static_assert(mk_target("AmdGpu"sv) == CodeGenTarget_AMDGPU);
        static_assert(mk_target("ARM32"sv) == CodeGenTarget_ARM);
        static_assert(mk_target("Arm"sv) == CodeGenTarget_ARM);
        static_assert(mk_target("Arm32"sv) == CodeGenTarget_ARM);
        static_assert(mk_target("HEXAGON"sv) == CodeGenTarget_Hexagon);
        static_assert(mk_target("LANAI"sv) == CodeGenTarget_Lanai);
        static_assert(mk_target("Mips"sv) == CodeGenTarget_MIPS);
        static_assert(mk_target("Msp430"sv) == CodeGenTarget_MSP430);
        static_assert(mk_target("NvidiaPTX"sv) == CodeGenTarget_NVPTX);
        static_assert(mk_target("POWERPC"sv) == CodeGenTarget_PowerPC);
        static_assert(mk_target("RiscV"sv) == CodeGenTarget_RISCV);
        static_assert(mk_target("SPARC"sv) == CodeGenTarget_Sparc);
        static_assert(mk_target("SPIRV"sv) == CodeGenTarget_SPIRV);
        static_assert(mk_target("SYSTEMZ"sv) == CodeGenTarget_SystemZ);
        static_assert(mk_target("WEBASSEMBLY"sv) == CodeGenTarget_WebAssembly);
        static_assert(mk_target("WASM"sv) == CodeGenTarget_WebAssembly);
        static_assert(mk_target("x86"sv) == CodeGenTarget_X86);
        static_assert(mk_target("XCORE"sv) == CodeGenTarget_XCore);
        static_assert(mk_target("ALL"sv) == CodeGenTarget_All);

        // validate that invalid input doesn't result in a build break for mk_target()
        // but produces an invalid target.
        static_assert(mk_target("NonExistent"sv) == CodeGenTarget_None);
    }
#endif

    // compile time const array of all supported targets for this build
    constexpr std::array AvailableTargets {
     #if (LLVM_HAS_AARCH64_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_AArch64,
     #endif
     #if (LLVM_HAS_AMDGPU_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_AMDGPU,
     #endif
     #if (LLVM_HAS_ARM_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_ARM,
     #endif
     #if (LLVM_HAS_AVR_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_AVR,
     #endif
     #if (LLVM_HAS_BPF_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_BPF,
     #endif
     #if (LLVM_HAS_HEXAGON_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_Hexagon,
     #endif
     #if (LLVM_HAS_LANAI_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_Lanai,
     #endif
     #if (LLVM_HAS_LOONGARCH_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_LoongArch,
     #endif
     #if (LLVM_HAS_MIPS_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_MIPS,
     #endif
     #if (LLVM_HAS_MSP430_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_MSP430,
     #endif
     #if (LLVM_HAS_NVPTX_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_NVPTX,
     #endif
     #if (LLVM_HAS_POWERPC_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_PowerPC,
     #endif
     #if (LLVM_HAS_RISCV_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_RISCV,
     #endif
     #if (LLVM_HAS_SPARC_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_Sparc,
     #endif
     #if (LLVM_HAS_SPIRV_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_SPIRV,
     #endif
     #if (LLVM_HAS_SYSTEMZ_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_SystemZ,
     #endif
     #if (LLVM_HAS_VE_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_VE,
     #endif
     #if (LLVM_HAS_WEBASSEMBLY_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_WebAssembly,
     #endif
     #if (LLVM_HAS_X86_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_X86,
     #endif
     #if (LLVM_HAS_XCORE_TARGET)
        LibLLVMCodeGenTarget::CodeGenTarget_XCore,
     #endif
    };

    constexpr bool is_enum_defined(LibLLVMCodeGenTarget target)
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
        case CodeGenTarget_NVPTX:
        case CodeGenTarget_PowerPC:
        case CodeGenTarget_RISCV:
        case CodeGenTarget_Sparc:
        case CodeGenTarget_SPIRV:
        case CodeGenTarget_SystemZ:
        case CodeGenTarget_VE:
        case CodeGenTarget_WebAssembly:
        case CodeGenTarget_X86:
        case CodeGenTarget_XCore:
        case CodeGenTarget_All:
            return true;

        case CodeGenTarget_None: // Not a valid value as an input, so considered undefined if received.
        default:
            return false;
        }
    }

    constexpr bool is_supported_target(LibLLVMCodeGenTarget target)
    {
        // Native and all are always "supported" [They are aliases for whatever is actually supported].
        if (target == CodeGenTarget_Native || target == CodeGenTarget_All)
        {
            return true;
        }

        return contains(AvailableTargets, target);
    }

    constexpr bool has_flag(LibLLVMTargetRegistrationKind value, LibLLVMTargetRegistrationKind flag)
    {
        return 0 != (static_cast<std::int32_t>(value) & static_cast<std::int32_t>(flag));
    }

    void RegisterTargetNative(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
    {
        // For native registration all three are done at once.
        if ( has_flag(registrations, TargetRegistration_Target)
          || has_flag(registrations, TargetRegistration_TargetInfo)
          || has_flag(registrations, TargetRegistration_TargetMachine)
        )
        {
            LLVMInitializeNativeTarget();
        }

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

    void RegisterTargetAArch64(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetAMDGPU(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetARM(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetAVR(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetBPF(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetHexagon(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetLanai(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetLoongArch(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetMIPS(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetMSP430(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetNvidiaPTX(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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
        if( has_flag(registrations, TargetRegistration_Disassembler ) )
        {
            LLVMInitializeNVPTXDisassembler( );
        }

        if( has_flag(registrations, TargetRegistration_AsmParser ) )
        {
            LLVMInitializeNVPTXAsmParser( );
        }
        */
#endif
    }

    void RegisterTargetPowerPC(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetRISCV(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetSparc(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetSPIRV(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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
        if( has_flag(registrations, TargetRegistration_Disassembler ) )
        {
            LLVMInitializeSPIRVDisassembler( );
        }

        if( has_flag(registrations, TargetRegistration_AsmParser ) )
        {
            LLVMInitializeSPIRVAsmParser( );
        }
        */
#endif
    }

    void RegisterTargetSystemZ(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetVE(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetWebAssembly(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetX86(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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

    void RegisterTargetXCore(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
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
        if( has_flag(registrations, TargetRegistration_AsmParser ) )
        {
            LLVMInitializeXCoreAsmParser( );
        }
        */
#endif
    }

    void RegisterAllTargets(LibLLVMTargetRegistrationKind registrations = TargetRegistration_All)
    {
        if ( has_flag(registrations, TargetRegistration_Target))
        {
            LLVMInitializeAllTargets();
        }

        if (has_flag(registrations, TargetRegistration_TargetInfo))
        {
            LLVMInitializeAllTargetInfos();
        }

        if (has_flag(registrations, TargetRegistration_TargetMachine))
        {
            LLVMInitializeAllTargetMCs();
        }

        if (has_flag(registrations, TargetRegistration_AsmPrinter))
        {
            LLVMInitializeAllAsmPrinters();
        }

        if (has_flag(registrations, TargetRegistration_Disassembler))
        {
            LLVMInitializeAllDisassemblers();
        }

        if( has_flag(registrations, TargetRegistration_AsmParser ) )
        {
            LLVMInitializeAllAsmParsers( );
        }
    }

    LLVMErrorRef validate_supported_target(LibLLVMCodeGenTarget target)
    {
        // If the target is not a known one then report that immediately
        if (!is_enum_defined(target))
        {
            return LLVMCreateStringError("Undefined target");
        }

        // test for a target supported by this build
        if (!is_supported_target(target))
        {
            return LLVMCreateStringError("Unsupported target for this build");
        }

        // All good - NOTE: Success for LLVMErrorRef is nullptr
        return nullptr;
    }

    bool Failed(LLVMErrorRef err)
    {
        // Success for LLVMErrorRef is nullptr
        return err != nullptr;
    }
}

extern "C"
{
    LLVMErrorRef LibLLVMRegisterTarget(LibLLVMCodeGenTarget target, LibLLVMTargetRegistrationKind registrations)
    {
        LLVMErrorRef validationResult = validate_supported_target(target);
        if (Failed(validationResult))
        {
            return validationResult;
        }

        // NOTE: Some of these may result in a NOP and won't actually be used.
        //       Since the target is passed by caller it isn't a compile time constant.
        //       It is checked above for a supported value so this will never call into
        //       the NOP stubs. This saves on LOTs of preprocessor conditionals. A good
        //       optimizer can see that any of these are NOP and simplify this to ONLY
        //       the supported targets.
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

        case CodeGenTarget_NVPTX:
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

        case CodeGenTarget_SPIRV:
            RegisterTargetSPIRV(registrations);
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
            RegisterAllTargets(registrations);
            return nullptr;

        default:
            return LLVMCreateStringError("Unknown target type");
        }
    }

    std::int32_t LibLLVMGetNumTargets()
    {
        return AvailableTargets.size();
    }

    LLVMErrorRef LibLLVMGetRuntimeTargets(LibLLVMCodeGenTarget* targetArray, std::int32_t lengthOfArray)
    {
        // size needs to have at least the available targets.
        // Unused additional elements are left uninitialized...
        if (lengthOfArray < AvailableTargets.size())
        {
            // sadly C++17 doesn't support constexpr std::format so providing actual number in the
            // error is not an easy option.
            return LLVMCreateStringError("Invalid array length provided");
        }

        std::copy_n(std::begin(AvailableTargets), lengthOfArray, targetArray);
        return nullptr;
    }

    uint64_t LibLLVMGetVersion()
    {
        return LibLLVM::FileVersion64;
    }
}
