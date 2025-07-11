#ifndef _ANALYSIS_BINDINGS_H_
#define _ANALYSIS_BINDINGS_H_

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>

LLVM_C_EXTERN_C_BEGIN
    LLVMBool LibLLVMVerifyFunctionEx( LLVMValueRef Fn
                                      , LLVMVerifierFailureAction Action
                                      , char** OutMessages
    );
LLVM_C_EXTERN_C_END

#endif
