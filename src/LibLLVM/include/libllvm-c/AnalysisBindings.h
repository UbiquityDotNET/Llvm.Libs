#ifndef _ANALYSIS_BINDINGS_H_
#define _ANALYSIS_BINDINGS_H_

#include <llvm-c/Analysis.h>
#include <llvm-c/ExternC.h>
#include <llvm-c/Types.h>

LLVM_C_EXTERN_C_BEGIN
    LLVMBool LibLLVMVerifyFunctionEx( LLVMValueRef Fn
                                      , LLVMVerifierFailureAction Action
                                      , char** OutMessages
    );
LLVM_C_EXTERN_C_END

#endif
