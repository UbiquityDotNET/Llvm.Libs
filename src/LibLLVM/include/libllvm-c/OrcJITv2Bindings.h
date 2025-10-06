#ifndef _LIBLLVM_ORCJITV2_BINDINGS_H_
#define _LIBLLVM_ORCJITV2_BINDINGS_H_

#include "llvm-c/Orc.h"

LLVM_C_EXTERN_C_BEGIN
    LLVMErrorRef LibLLVMExecutionSessionRemoveDyLib(LLVMOrcExecutionSessionRef session, LLVMOrcJITDylibRef lib);

    // Determines if a string pool is empty. This is generally only used as a diagnostic in
    // disposers to detect erroneous ref count handling for strings in the pool.
    // Returns a true boolean (e.g. it returns a non-zero value (true) if the pool is empty and
    // a 0 value (false) if it is NOT empty)
    LLVMBool LibLLVMOrcSymbolStringPoolIsEmpty(LLVMOrcSymbolStringPoolRef SSP);

    // Diagnostic for getting a formatted version of the pool
    // Return requires LLVMDisposeMessage()
    char* LibLLVMOrcSymbolStringPoolGetDiagnosticRepresentation(LLVMOrcSymbolStringPoolRef SSP);

    // Diagnostic for getting the current ref count for a symbol
    // This is an inherently unreliable value in that it is an atomic count meaning
    // ANY thread may manipulate it's value. Thus, the return is mostly meaningless
    // and useful ONLY in very limited diagnostic conditions.
    size_t LibLLVMOrcSymbolStringPoolGetRefCount(LLVMOrcSymbolStringPoolEntryRef sspe);

    // Write contents of the pool to the debugger (if attached)
    // Currently only supported on Windows, but theoretically could operate on other
    // platforms. Any unsupported platform is a simple NOP. This is useful in tracking
    // down reference count leaking or pre-mature release scenarios. It is NOT of ANY
    // value in a retail build (It's a NOP).
    void LibLLVMOrcSymbolStringPoolWriteDebugRepresentation(LLVMOrcSymbolStringPoolRef SSP);
LLVM_C_EXTERN_C_END

#endif
