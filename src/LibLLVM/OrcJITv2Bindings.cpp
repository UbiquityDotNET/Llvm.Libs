#include "libllvm-c/OrcJITv2Bindings.h"
#include <llvm/Support/Error.h>
#include <llvm/Support/CBindingWrapping.h>
#include <llvm/ExecutionEngine/Orc/Core.h>
#include <llvm/ExecutionEngine/Orc/SymbolStringPool.h>

#include "OutputDebugStream.h"

using namespace llvm;
using namespace llvm::orc;

namespace
{
    DEFINE_SIMPLE_CONVERSION_FUNCTIONS(ExecutionSession, LLVMOrcExecutionSessionRef)
    DEFINE_SIMPLE_CONVERSION_FUNCTIONS(JITDylib, LLVMOrcJITDylibRef)
    DEFINE_SIMPLE_CONVERSION_FUNCTIONS(SymbolStringPool, LLVMOrcSymbolStringPoolRef)
    inline SymbolStringPoolEntryUnsafe unwrap(LLVMOrcSymbolStringPoolEntryRef E)
    {
        return reinterpret_cast<SymbolStringPoolEntryUnsafe::PoolEntry*>(E);
    }
}

extern "C"
{
    LLVMErrorRef LibLLVMExecutionSessionRemoveDyLib(LLVMOrcExecutionSessionRef session, LLVMOrcJITDylibRef lib)
    {
        return wrap(unwrap(session)->removeJITDylib(*unwrap(lib)));
    }

    LLVMBool LibLLVMOrcSymbolStringPoolIsEmpty(LLVMOrcSymbolStringPoolRef SSP)
    {
        return unwrap(SSP)->empty();
    }

    char* LibLLVMOrcSymbolStringPoolGetDiagnosticRepresentation(LLVMOrcSymbolStringPoolRef SSP)
    {
        std::string Messages;
        raw_string_ostream MsgsOS(Messages);
        SymbolStringPool& pool = *unwrap(SSP);
        MsgsOS << pool;
        return strdup(Messages.c_str());
    }

    void LibLLVMOrcSymbolStringPoolWriteDebugRepresentation(LLVMOrcSymbolStringPoolRef SSP)
    {
        SymbolStringPool const& pool = *unwrap(SSP);
        LibLLVM::raw_debug_ostream dbgStrm;
        dbgStrm << "+LibLLVMOrcSymbolStringPoolWriteDebugRepresentation";
        dbgStrm << pool;
        dbgStrm << "-LibLLVMOrcSymbolStringPoolWriteDebugRepresentation";
    }

    size_t LibLLVMOrcSymbolStringPoolGetRefCount(LLVMOrcSymbolStringPoolEntryRef sspe)
    {
        SymbolStringPoolEntryUnsafe::PoolEntry* p = unwrap(sspe).rawPtr();
        return p->getValue();
    }
}
