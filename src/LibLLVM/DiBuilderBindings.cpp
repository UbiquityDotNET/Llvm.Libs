#include <cstdint>
#include <llvm/IR/Type.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Value.h>

#include <llvm-c/Types.h>
#include "libllvm-c/DiBuilderBindings.h"

using namespace llvm;

// Sadly, the existing LLVM-C API as of 20.1.8 does not support the address space parameter
// so this provides extension APIs that are mostly clones of the LLVM-C API but use the
// address space.

extern "C"
{
    LLVMValueRef LibLLVMBuildAlloca(LLVMBuilderRef B, LLVMTypeRef Ty, const char *Name, uint32_t addressSpace)
    {
        return wrap(unwrap(B)->CreateAlloca(unwrap(Ty), addressSpace, nullptr, Name));
    }

    LLVMValueRef LibLLVMBuildArrayAlloca(LLVMBuilderRef B, LLVMTypeRef Ty, LLVMValueRef Val, const char *Name, uint32_t addressSpace)
    {
        return wrap(unwrap(B)->CreateAlloca(unwrap(Ty), addressSpace, unwrap(Val), Name));
    }
}
