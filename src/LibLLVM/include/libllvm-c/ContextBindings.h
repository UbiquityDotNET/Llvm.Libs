#ifndef _CONTEXT_BINDINGS_H_
#define _CONTEXT_BINDINGS_H_

#include "llvm-c/Core.h"

LLVM_C_EXTERN_C_BEGIN
    LLVMBool LibLLVMContextGetIsODRUniquingDebugTypes( LLVMContextRef context );
    void LibLLVMContextSetIsODRUniquingDebugTypes( LLVMContextRef context, LLVMBool state );
LLVM_C_EXTERN_C_END

#endif
