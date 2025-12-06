#ifndef LIBLLVM_DIBUILDER_BINDINGS_H
#define LIBLLVM_DIBUILDER_BINDINGS_H

#if __cplusplus
#include <cstdint>
#else
#include <stdint.h>
#endif

#include <llvm-c/ExternC.h>
#include <llvm-c/Types.h>

LLVM_C_EXTERN_C_BEGIN
    LLVMValueRef LibLLVMBuildAlloca(LLVMBuilderRef B, LLVMTypeRef Ty, const char *Name, uint32_t addressSpace);
    LLVMValueRef LibLLVMBuildArrayAlloca(LLVMBuilderRef B, LLVMTypeRef Ty, LLVMValueRef Val, const char *Name, uint32_t addressSpace);
LLVM_C_EXTERN_C_END

#endif
