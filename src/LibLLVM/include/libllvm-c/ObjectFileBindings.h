#ifndef _LIBLLVM_OBJECTILE_BINDINGS_H_
#define _LIBLLVM_OBJECTILE_BINDINGS_H_

#include "llvm-c/Object.h"

LLVM_C_EXTERN_C_BEGIN
    LLVMSymbolIteratorRef LibLLVMSymbolIteratorClone( LLVMSymbolIteratorRef ref );
    LLVMSectionIteratorRef LibLLVMSectionIteratorClone( LLVMSectionIteratorRef ref );
    LLVMRelocationIteratorRef LibLLVMRelocationIteratorClone( LLVMRelocationIteratorRef ref );
LLVM_C_EXTERN_C_END

#endif
