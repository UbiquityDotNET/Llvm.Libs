#ifndef _LIBLLVM_TARGETMACHINE_BINDINGS_H
#define _LIBLLVM_TARGETMACHINE_BINDINGS_H

#include <llvm-c/TargetMachine.h>

LLVM_C_EXTERN_C_BEGIN
    LLVMBool LibLLVMGetTargetMachineAsmVerbosity(LLVMTargetMachineRef tm);
    LLVMBool LibLLVMGetTargetMachineFastISel(LLVMTargetMachineRef tm);
    LLVMBool LibLLVMGetTargetMachineGlobalISel(LLVMTargetMachineRef T);
    LLVMGlobalISelAbortMode LibLLVMGetTargetMachineGlobalISelAbort(LLVMTargetMachineRef tm);
    LLVMBool LibLLVMGetTargetMachineMachineOutliner(LLVMTargetMachineRef tm);

    char const* LibLLVMTargetMachineOptionsGetCPU(LLVMTargetMachineOptionsRef Options, size_t* len);
    char const* LibLLVMTargetMachineOptionsGetFeatures(LLVMTargetMachineOptionsRef Options, size_t* len);
    char const* LibLLVMTargetMachineOptionsGetABI(LLVMTargetMachineOptionsRef Options, size_t*len);
    LLVMCodeGenOptLevel LibLLVMTargetMachineOptionsGetCodeGenOptLevel(LLVMTargetMachineOptionsRef Options);
    LLVMRelocMode LibLLVMTargetMachineOptionsGetRelocMode(LLVMTargetMachineOptionsRef Options);
    LLVMCodeModel LibLLVMTargetMachineOptionsGetCodeModel(LLVMTargetMachineOptionsRef Options);
LLVM_C_EXTERN_C_END

#endif
