#include <string>
#include <optional>
#include <llvm/Target/CodeGenCWrappers.h>
#include <llvm/Support/CBindingWrapping.h>
#include <llvm/Target/TargetMachine.h>

#include <llvm-c/Target.h>
#include "libllvm-c/TargetMachineBindings.h"

// cloned from llvm/lib/Target/TargetMachineC.cpp
namespace llvm {
    /// Options for LLVMCreateTargetMachine().
    struct LLVMTargetMachineOptions {
        std::string CPU;
        std::string Features;
        std::string ABI;
        CodeGenOptLevel OL = CodeGenOptLevel::Default;
        std::optional<Reloc::Model> RM;
        std::optional<CodeModel::Model> CM;
        bool JIT;
    };
} // namespace llvm

// sanity check to catch any changes in the official LLVM declaration of the class above.
// Since it is NOT declared in a public header this, sadly, **MUST** be re-validated on any changes.
#if LLVM_VERSION_MAJOR != 20 || LLVM_VERSION_MINOR != 1 || LLVM_VERSION_PATCH != 7
#error "Re-evaluate and match declaration of LLVMPassBuilderOptions; update the version test values above when validated"
#endif

using namespace llvm;
namespace
{
    TargetMachine* unwrap(LLVMTargetMachineRef P)
    {
        return reinterpret_cast<TargetMachine*>(P);
    }

    DEFINE_SIMPLE_CONVERSION_FUNCTIONS(LLVMTargetMachineOptions, LLVMTargetMachineOptionsRef)

    LLVMGlobalISelAbortMode mk_c_enum(GlobalISelAbortMode m)
    {
        // NOTE: Numeric values are ***NOT*** the same - A simple cast won't do!
        // Also NOTE: when setting, the default is Enable for any invalid/unknown
        // values. So, that is used on conversion here as the default.
        switch (m)
        {
        case llvm::GlobalISelAbortMode::Disable:
            return LLVMGlobalISelAbortDisable;

        case llvm::GlobalISelAbortMode::Enable:
        default:
            return LLVMGlobalISelAbortEnable;

        case llvm::GlobalISelAbortMode::DisableWithDiag:
            return LLVMGlobalISelAbortDisableWithDiag;
        }
    }

    LLVMCodeGenOptLevel make_c_enum(CodeGenOptLevel ol)
    {
        // simple cast is enough for this enum.
        return static_cast<LLVMCodeGenOptLevel>(ol);
    }

    LLVMRelocMode make_c_enum(std::optional<Reloc::Model> rm)
    {
        if( !rm.has_value() )
        {
            return LLVMRelocDefault;
        }

        switch (rm.value())
        {
        case llvm::Reloc::Static:
            return LLVMRelocStatic;

        case llvm::Reloc::PIC_:
            return LLVMRelocPIC;

        case llvm::Reloc::DynamicNoPIC:
            return LLVMRelocDynamicNoPic;

        case llvm::Reloc::ROPI:
            return LLVMRelocROPI;

        case llvm::Reloc::RWPI:
            return LLVMRelocRWPI;

        case llvm::Reloc::ROPI_RWPI:
            return LLVMRelocROPI_RWPI;

        default:
            return LLVMRelocDefault;
        }
    }

    LLVMCodeModel make_c_enum(std::optional<CodeModel::Model> cm, bool jit)
    {
        if(!cm.has_value())
        {
            return jit ? LLVMCodeModelJITDefault : LLVMCodeModelDefault;
        }

        switch (cm.value())
        {
        case llvm::CodeModel::Tiny:
            return LLVMCodeModelTiny;

        case llvm::CodeModel::Small:
            return LLVMCodeModelSmall;

        case llvm::CodeModel::Kernel:
            return LLVMCodeModelKernel;

        case llvm::CodeModel::Medium:
            return LLVMCodeModelMedium;

        case llvm::CodeModel::Large:
            return LLVMCodeModelLarge;

        default:
            return jit ? LLVMCodeModelJITDefault : LLVMCodeModelDefault;
        }
    }
}

LLVMBool LibLLVMGetTargetMachineAsmVerbosity(LLVMTargetMachineRef tm)
{
    return unwrap(tm)->Options.MCOptions.AsmVerbose ? 1 : 0;
}

LLVMBool LibLLVMGetTargetMachineFastISel(LLVMTargetMachineRef tm)
{
    return unwrap(tm)->Options.EnableFastISel ? 1 : 0;
}

LLVMBool LibLLVMGetTargetMachineGlobalISel(LLVMTargetMachineRef tm)
{
    return unwrap(tm)->Options.EnableGlobalISel ? 1 : 0;
}

LLVMGlobalISelAbortMode LibLLVMGetTargetMachineGlobalISelAbort(LLVMTargetMachineRef tm)
{
    return  mk_c_enum(unwrap(tm)->Options.GlobalISelAbort);
}

LLVMBool LibLLVMGetTargetMachineMachineOutliner(LLVMTargetMachineRef tm)
{
    return unwrap(tm)->Options.EnableMachineOutliner ? 1 : 0;
}

char const* LibLLVMTargetMachineOptionsGetCPU(LLVMTargetMachineOptionsRef Options, size_t* len)
{
    auto const& str = unwrap(Options)->CPU;
    *len = str.size();
    return str.data();
}

char const* LibLLVMTargetMachineOptionsGetFeatures(LLVMTargetMachineOptionsRef Options, size_t* len)
{
    auto const& str = unwrap(Options)->Features;
    *len = str.size();
    return str.data();
}

char const* LibLLVMTargetMachineOptionsGetABI(LLVMTargetMachineOptionsRef Options, size_t* len)
{
    auto const& str = unwrap(Options)->ABI;
    *len = str.size();
    return str.data();
}

LLVMCodeGenOptLevel LibLLVMTargetMachineOptionsGetCodeGenOptLevel(LLVMTargetMachineOptionsRef Options)
{
    return make_c_enum(unwrap(Options)->OL);
}

LLVMRelocMode LibLLVMTargetMachineOptionsGetRelocMode(LLVMTargetMachineOptionsRef Options)
{
    return make_c_enum(unwrap(Options)->RM);
}

LLVMCodeModel LibLLVMTargetMachineOptionsGetCodeModel(LLVMTargetMachineOptionsRef Options)
{
    auto const* options = unwrap(Options);
    return make_c_enum(options->CM, options->JIT);
}

